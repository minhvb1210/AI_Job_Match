"""
app/routers/ai.py

AI-specific endpoints:
  GET  /ai/explain/{job_id}   — full score breakdown for authenticated user's CV vs a job
  POST /ai/explain/{job_id}   — same, but accepts raw CV text in the request body
  GET  /ai/cache/status       — cache diagnostics (admin use)
  POST /ai/cache/invalidate   — force cache eviction (admin use)
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.responses import success_response, error_response
from app.core.auth import get_current_user
from app.models.models import Job, CandidateProfile, User
from app.services.ai.scoring import explain_job_match
from app.services.ai.vectorization import VectorizerCache
from app.services.ai.industry import INDUSTRY_KEYWORDS, predict_cv_industry
from app.schemas.schemas import CvSuggestionResponse

router = APIRouter(prefix="/ai", tags=["AI"])


# ── Request schema for POST variant ──────────────────────────────────────────
class ExplainRequest(BaseModel):
    cv_text: str


class BatchMatchRequest(BaseModel):
    job_ids: List[int]


# ─────────────────────────────────────────────────────────────────────────────
# Endpoints
# ─────────────────────────────────────────────────────────────────────────────
@router.get("/explain/{job_id}")
def explain_from_profile(
    job_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Return the full AI scoring breakdown for the authenticated user's saved
    CV profile against a specific job.

    Response shape:
    {
      "success": true,
      "message": "...",
      "data": {
        "job_id":              int,
        "job_title":           str,
        "job_category":        str,
        "cv_industry":         str,
        "industry_confidence": float,     # 0.0–1.0
        "cosine_raw":          float,     # raw cosine similarity 0–1
        "cosine_pct":          float,     # scaled % contribution to score
        "matched_keywords":    [str, ...],
        "kw_bonus":            int,       # keyword bonus % contribution
        "industry_match":      bool,
        "industry_adjustment": int,       # +10 or -15
        "final_score":         float,     # 0–100
        "missing_skills":      [str, ...]
      }
    }
    """
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail=f"Job #{job_id} not found")

    profile = db.query(CandidateProfile).filter(
        CandidateProfile.user_id == current_user.id
    ).first()
    if not profile or not (profile.skills_text or "").strip():
        raise HTTPException(
            status_code=400,
            detail="No CV profile found. Upload a CV or update your profile first.",
        )

    # Load all jobs to ensure the vectorizer cache includes this job
    all_jobs = db.query(Job).all()

    breakdown = explain_job_match(
        cv_text=profile.skills_text,
        job=job,
        jobs=all_jobs,
    )
    return success_response(
        data=breakdown,
        message=f"Score breakdown for '{job.title}'",
    )


@router.post("/explain/{job_id}")
def explain_from_text(
    job_id: int,
    body: ExplainRequest,
    db: Session = Depends(get_db),
):
    """
    Return the full AI scoring breakdown for arbitrary CV text (no auth required).
    Useful for testing or anonymous scoring previews.
    """
    if not body.cv_text.strip():
        raise HTTPException(status_code=400, detail="cv_text must not be empty")

    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail=f"Job #{job_id} not found")

    all_jobs = db.query(Job).all()

    breakdown = explain_job_match(
        cv_text=body.cv_text,
        job=job,
        jobs=all_jobs,
    )
    return success_response(
        data=breakdown,
        message=f"Score breakdown for '{job.title}'",
    )


@router.get("/cache/status")
def cache_status():
    """Return current VectorizerCache state — for diagnostics."""
    entry = VectorizerCache._entry
    if entry is None:
        return success_response(
            data={"cached": False},
            message="Vectorizer cache is empty — will fit on next request",
        )
    return success_response(
        data={
            "cached":      True,
            "job_count":   entry.job_count,
            "corpus_hash": entry.corpus_hash[:16] + "…",
        },
        message="Vectorizer cache is warm",
    )


@router.post("/cache/invalidate")
def invalidate_cache(current_user: User = Depends(get_current_user)):
    """Force-evict the vectorizer cache (admin only)."""
    if current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    VectorizerCache.invalidate()
    return success_response(message="Vectorizer cache invalidated. Will refit on next scoring request.")


@router.post("/match-jobs-batch")
def match_jobs_batch(
    body: BatchMatchRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Asynchronously calculate scores for a list of job IDs based on the 
    authenticated user's CV profile.
    
    Returns: {"scores": {job_id: score | null}}
    """
    profile = db.query(CandidateProfile).filter(CandidateProfile.user_id == current_user.id).first()
    if not profile or not (profile.skills_text or "").strip():
        # No CV? Return empty map or nulls
        return success_response(data={"scores": {jid: None for jid in body.job_ids}})

    # Load all jobs to warm the VectorizerCache (context for scoring)
    all_jobs = db.query(Job).all()
    
    # Identify the specific jobs requested
    target_jobs = [j for j in all_jobs if j.id in body.job_ids]
    
    scores = {}
    for job_id in body.job_ids:
        job = next((j for j in target_jobs if j.id == job_id), None)
        if not job:
            scores[job_id] = None
            continue
            
        try:
            # Re-use the existing explain logic but only return the final score
            breakdown = explain_job_match(
                cv_text=profile.skills_text,
                job=job,
                jobs=all_jobs,
            )
            scores[job_id] = breakdown["final_score"]
        except Exception:
            # "If scoring fails -> return null. Do NOT throw errors."
            scores[job_id] = None
            
    return success_response(
        data={"scores": scores},
        message=f"Calculated scores for {len(scores)} jobs"
    )


@router.post("/cv-suggestions")
def get_cv_suggestions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Generate actionable suggestions to improve the user's CV based on
    industry alignment and professional best practices.
    """
    profile = db.query(CandidateProfile).filter(CandidateProfile.user_id == current_user.id).first()
    if not profile or not (profile.skills_text or "").strip():
        return success_response(data={"suggestions": [
            "Please upload your CV or update your skills first to get personalized suggestions.",
            "Include your contact information and social links.",
            "Add a clear professional summary."
        ]})

    cv_text = profile.skills_text
    suggestions = []

    # 1. Industry-based suggestions
    try:
        industry, confidence = predict_cv_industry(cv_text)
        suggestions.append(f"Detected Industry: {industry} (Match Strength: {int(confidence*100)}%)")
        
        # Keyword gap analysis
        industry_kws = INDUSTRY_KEYWORDS.get(industry, [])
        import re
        missing = [
            kw for kw in industry_kws 
            if not re.search(r"\b" + re.escape(kw.lower()) + r"\b", cv_text.lower())
        ]
        
        if missing:
            top_missing = missing[:5]
            suggestions.append(f"High-impact skills to add: {', '.join(top_missing)}")
            suggestions.append(f"Matching these core skills will significantly boost your score for {industry} roles.")
    except Exception:
        pass

    # 2. Rule-based Professional Tips (Mandatory per request)
    suggestions.extend([
        "Highlight Measurable Achievements: Use numbers (e.g., 'Increased sales by 20%') to demonstrate impact.",
        "Showcase Projects: Link to GitHub, your portfolio, or case studies to provide concrete evidence of your work.",
        "Action Verbs: Start bullet points with strong verbs like 'Lead', 'Developed', 'Optimized'.",
        "Keep it Concise: Ensure your most relevant experience is on the first page.",
        "Add Portfolio Link: Including a GitHub or personal portfolio URI helps recruiters verify technical skills instantly."
    ])

    return success_response(
        data={"suggestions": suggestions},
        message="AI CV suggestions generated"
    )
