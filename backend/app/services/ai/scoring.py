"""
app/services/ai/scoring.py

Core matching logic:
  - match_cv_to_jobs        : rank jobs for a given CV (uses VectorizerCache)
  - match_candidates_to_job : rank candidate profiles for a given job
  - explain_job_match       : full score breakdown for a single CV ↔ job pair
  - calculate_missing_skills: skills required by job but absent from CV
"""
import re
import logging

from sklearn.metrics.pairwise import cosine_similarity

from app.services.ai.preprocessing import clean_text, preprocess_text
from app.services.ai.vectorization  import VectorizerCache, build_tfidf_matrix, compute_cosine_scores
from app.services.ai.industry        import INDUSTRY_KEYWORDS, predict_cv_industry

ai_logger = logging.getLogger("ai_scoring")

# ─────────────────────────────────────────
# Scoring constants  (unchanged)
# ─────────────────────────────────────────
_COSINE_SCALE     = 1.0    # raw cosine mapped directly to % (0.5 → 50%)
_KW_BONUS_PER     = 2      # % per matched keyword
_KW_BONUS_MAX     = 20     # % cap on keyword bonus
_INDUSTRY_BONUS   = 5      # % when CV & job industries match
_INDUSTRY_PENALTY = -25    # % when they don't
_TOP_N_RESULTS    = 10


# ─────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────
def _keyword_bonus(cleaned_cv: str, job_category: str) -> tuple[int, list[str]]:
    """Return (bonus_pct, matched_keywords) for a CV against a job category."""
    cat_key = next(
        (k for k in INDUSTRY_KEYWORDS if k.upper() == job_category.upper()), "IT"
    )
    matched = [
        kw for kw in INDUSTRY_KEYWORDS[cat_key]
        if re.search(r"\b" + re.escape(kw.lower()) + r"\b", cleaned_cv)
    ]
    return min(len(matched) * _KW_BONUS_PER, _KW_BONUS_MAX), matched


def _industry_adjustment(cv_industry: str, job_category: str) -> tuple[int, bool]:
    """Return (adjustment_pct, is_match)."""
    match = cv_industry.upper() == job_category.upper()
    return (_INDUSTRY_BONUS if match else _INDUSTRY_PENALTY), match


def _final_score(cosine_pct: float, kw_bonus: int, industry_adj: int) -> float:
    return max(min(round(cosine_pct + kw_bonus + industry_adj, 2), 100.0), 0.0)


# ─────────────────────────────────────────
# Public API
# ─────────────────────────────────────────
def match_cv_to_jobs(cv_text: str, jobs: list) -> list[dict]:
    """
    Rank a list of Job ORM objects against a CV text.

    Uses VectorizerCache so the TF-IDF vectorizer is fitted on the job
    corpus only once (re-fitted only when job content changes).

    Returns (max _TOP_N_RESULTS) dicts, sorted by score descending:
      {
        "job":            <Job ORM>,
        "score":          <float 0-100>,
        "missing_skills": [<str>, ...]   # skills required but absent in CV
      }
    """
    cleaned_cv   = clean_text(cv_text)
    processed_cv = preprocess_text(cv_text)

    if not processed_cv:
        ai_logger.warning("match_cv_to_jobs: empty processed CV text — returning no results")
        return []

    # ── Industry detection ────────────────────────────────────────────────────
    try:
        cv_industry, confidence = predict_cv_industry(cv_text)
    except Exception as exc:
        ai_logger.exception("Industry detection failed: %s", exc)
        cv_industry, confidence = "IT", 0.0

    ai_logger.info(
        "CV Industry: %s (confidence=%.1f%%) | preview=%.80r",
        cv_industry, confidence * 100, cleaned_cv,
    )

    # ── Hybrid BM25+SBERT (cached) ───────────────────────────────────────────
    hybrid_scorer, job_embeddings, id_to_idx = VectorizerCache.get(jobs)
    cosine_scores = hybrid_scorer.score_cv(processed_cv)   # shape (n_jobs,), range [0,1]

    # ── Score each job ────────────────────────────────────────────────────────
    results = []
    for job in jobs:
        idx = id_to_idx.get(job.id)
        if idx is None:
            continue

        cosine_raw  = float(cosine_scores[idx])
        cosine_pct  = min((cosine_raw / _COSINE_SCALE) * 100, 100)

        job_category            = (job.category or "IT").strip()
        kw_bonus, matched_kw    = _keyword_bonus(cleaned_cv, job_category)
        industry_adj, ind_match = _industry_adjustment(cv_industry, job_category)

        final = _final_score(cosine_pct, kw_bonus, industry_adj)
        missing = calculate_missing_skills(cv_text, job.skills)

        ai_logger.info(
            '[SCORE] Job #%d "%s" (%s) | cosine=%.1f%% + kw_bonus=+%d%% (%d kw) '
            '+ industry=%+d%% [%s] = final=%.2f%%',
            job.id, job.title, job_category,
            cosine_pct, kw_bonus, len(matched_kw),
            industry_adj, "MATCH" if ind_match else "MISS",
            final,
        )
        if matched_kw:
            ai_logger.debug("  Keywords matched: %s", matched_kw[:10])
        if missing:
            ai_logger.debug("  Missing skills:   %s", missing[:10])

        if final >= 40.0:
            results.append({
                "job":            job,
                "score":          final,
                "missing_skills": missing,
            })

    results.sort(key=lambda x: x["score"], reverse=True)
    top = results[:_TOP_N_RESULTS]

    ai_logger.info(
        "Top-%d results: %s",
        len(top),
        [(r["job"].title, r["score"]) for r in top],
    )
    return top


def explain_job_match(cv_text: str, job, jobs: list) -> dict:
    """
    Return a complete score breakdown for a single CV ↔ job pair.

    The breakdown uses the same VectorizerCache as match_cv_to_jobs so
    scores are guaranteed to be identical.

    Parameters
    ----------
    cv_text : raw CV text (not pre-processed)
    job     : single Job ORM object to explain
    jobs    : ALL Job ORM objects (needed to warm / validate the cache)

    Returns
    -------
    {
      "job_id":               int,
      "job_title":            str,
      "job_category":         str,
      "cv_industry":          str,
      "industry_confidence":  float,       # 0–1
      "cosine_raw":           float,       # raw cosine similarity 0–1
      "cosine_pct":           float,       # scaled % contribution
      "matched_keywords":     [str, ...],
      "kw_bonus":             int,         # % contribution
      "industry_match":       bool,
      "industry_adjustment":  int,         # % contribution (positive or negative)
      "final_score":          float,       # 0–100
      "missing_skills":       [str, ...],  # required skills absent from CV
    }
    """
    cleaned_cv   = clean_text(cv_text)
    processed_cv = preprocess_text(cv_text)

    # Industry
    try:
        cv_industry, confidence = predict_cv_industry(cv_text)
    except Exception as exc:
        ai_logger.exception("explain_job_match: industry detection failed: %s", exc)
        cv_industry, confidence = "IT", 0.0

    # Hybrid scoring via cache
    hybrid_scorer, job_embeddings, id_to_idx = VectorizerCache.get(jobs)
    idx = id_to_idx.get(job.id)

    if idx is None:
        # Fallback: job không có trong cache — dùng SBERT trực tiếp
        ai_logger.warning("explain_job_match: job #%d not in cache, using SBERT fallback", job.id)
        from app.services.ai.vectorization import _get_sbert_model
        sbert = _get_sbert_model()
        processed_job = preprocess_text(f"{job.title} {job.description} {job.skills}")
        cv_emb  = sbert.encode([processed_cv], normalize_embeddings=True)
        job_emb = sbert.encode([processed_job], normalize_embeddings=True)
        cosine_raw = float((cv_emb @ job_emb.T).flatten()[0])
    else:
        all_scores = hybrid_scorer.score_cv(processed_cv)
        cosine_raw = float(all_scores[idx])

    cosine_pct              = min((cosine_raw / _COSINE_SCALE) * 100, 100)
    job_category            = (job.category or "IT").strip()
    kw_bonus, matched_kw    = _keyword_bonus(cleaned_cv, job_category)
    industry_adj, ind_match = _industry_adjustment(cv_industry, job_category)
    final                   = _final_score(cosine_pct, kw_bonus, industry_adj)
    missing                 = calculate_missing_skills(cv_text, job.skills)

    # Narrative generation
    narrative = f"Our AI analyzed your profile and identified a strong alignment with the **{job_category}** industry."
    if ind_match:
        narrative += f" Your expertise in **{cv_industry}** is a direct match for this role."
    else:
        narrative += f" While your primary background is in **{cv_industry}**, your transferable skills show potential for this **{job_category}** position."
    
    if matched_kw:
        narrative += f" We found significant keyword overlaps in key areas: **{', '.join(matched_kw[:3])}**."
    
    if final > 80:
        narrative += " You are an **Elite Match** for this position. We highly recommend applying immediately."
    elif final > 60:
        narrative += " You have a **Strong Profile** for this role with just a few skill gaps to bridge."
    else:
        narrative += " This is a **Potential Match**. Consider highlighting your related projects to stand out."

    ai_logger.info(
        '[EXPLAIN] Job #%d "%s" | cv_industry=%s | cosine=%.1f%% kw=+%d%% industry=%+d%% → %.2f%%',
        job.id, job.title, cv_industry, cosine_pct, kw_bonus, industry_adj, final,
    )

    return {
        "job_id":              job.id,
        "job_title":           job.title,
        "job_category":        job_category,
        "cv_industry":         cv_industry,
        "industry_confidence": round(confidence, 4),
        "cosine_raw":          round(cosine_raw, 6),
        "cosine_pct":          round(cosine_pct, 2),
        "matched_keywords":    matched_kw,
        "kw_bonus":            kw_bonus,
        "industry_match":      ind_match,
        "industry_adjustment": industry_adj,
        "final_score":         final,
        "missing_skills":      missing,
        "narrative":           narrative,
    }


def match_candidates_to_job(job_text: str, profiles: list) -> list[dict]:
    """
    Rank CandidateProfile ORM objects against a job description using SBERT + BM25.
    Returns (max _TOP_N_RESULTS) dicts sorted by score descending.
    """
    if not profiles:
        return []

    processed_job      = preprocess_text(job_text)
    processed_profiles = [preprocess_text(p.skills_text or "") for p in profiles]

    from app.services.ai.vectorization import _get_sbert_model, _tokenize_vi
    from rank_bm25 import BM25Okapi
    import numpy as np

    # 1. BM25
    tokenized_profiles = [_tokenize_vi(text) for text in processed_profiles]
    bm25_index = BM25Okapi(tokenized_profiles)
    job_tokens = _tokenize_vi(processed_job)
    bm25_scores = np.array(bm25_index.get_scores(job_tokens), dtype=float)
    max_bm25 = max(bm25_scores.max(), 10.0)
    bm25_norm = bm25_scores / max_bm25 if max_bm25 > 0 else np.zeros_like(bm25_scores)

    # 2. SBERT
    sbert = _get_sbert_model()
    job_emb = sbert.encode([processed_job], convert_to_numpy=True, normalize_embeddings=True)
    profile_embs = sbert.encode(processed_profiles, convert_to_numpy=True, normalize_embeddings=True)
    sbert_scores = (profile_embs @ job_emb.T).flatten()
    sbert_norm = np.clip(sbert_scores, 0, 1)

    # 3. Hybrid (alpha=0.5)
    hybrid_scores = 0.5 * bm25_norm + 0.5 * sbert_norm

    results = []
    for i, score in enumerate(hybrid_scores):
        scaled = min(round((float(score) / _COSINE_SCALE) * 100, 2), 100.0)
        
        # Hard threshold filter: Drop very poor matches to keep results highly relevant
        if scaled < 30.0:
            continue
            
        ai_logger.info(
            "[CANDIDATE] Profile #%d | hybrid_score=%.4f → scaled=%.2f%%",
            profiles[i].id, score, scaled,
        )
        results.append({"profile": profiles[i], "score": scaled})

    results.sort(key=lambda x: x["score"], reverse=True)
    return results[:_TOP_N_RESULTS]


def calculate_missing_skills(cv_text: str, job_skills: str) -> list[str]:
    """Return list of skills required by the job but not found in the CV."""
    if not job_skills:
        return []
    cv_lower    = cv_text.lower()
    skills_list = [s.strip() for s in job_skills.split(",") if s.strip()]
    return [
        skill for skill in skills_list
        if not re.search(r"\b" + re.escape(skill.lower()) + r"\b", cv_lower)
    ]
