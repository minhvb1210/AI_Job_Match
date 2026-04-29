"""
app/services/ai/vectorization.py

TF-IDF vectorization with a process-level cache for the job corpus.

Design:
  - VectorizerCache fits the vectorizer on the job corpus once.
  - On subsequent requests, if the job corpus is unchanged (same hash),
    the vectorizer is reused and only the new CV text is transformed.
  - Cache is invalidated automatically when any job's id/title/skills changes.

Why jobs-only vocabulary:
  A vocabulary fixed to the job corpus is the standard production approach.
  It eliminates vocabulary drift caused by one-off CV terms and makes the
  explain endpoint produce scores identical to the batch match endpoint.
"""
import hashlib
import logging
import threading
from dataclasses import dataclass, field

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import scipy.sparse

logger = logging.getLogger("ai_scoring")


# ─────────────────────────────────────────────────────────────────────────────
# Cache dataclass
# ─────────────────────────────────────────────────────────────────────────────
@dataclass
class _CacheEntry:
    vectorizer:     TfidfVectorizer
    job_matrix:     scipy.sparse.csr_matrix   # shape (n_jobs, vocab)
    job_id_to_idx:  dict                       # {job.id -> row index in job_matrix}
    corpus_hash:    str
    job_count:      int


class VectorizerCache:
    """
    Thread-safe singleton that caches a TF-IDF vectorizer fitted on the
    full set of job texts.

    Usage
    -----
    vectorizer, job_matrix, id_to_idx = VectorizerCache.get(jobs)
    cv_vec = vectorizer.transform([processed_cv_text])
    cosine  = cosine_similarity(cv_vec, job_matrix).flatten()
    """

    _lock:  threading.Lock = threading.Lock()
    _entry: "_CacheEntry | None" = None

    # ── Public API ────────────────────────────────────────────────────────────
    @classmethod
    def get(cls, jobs: list) -> tuple[TfidfVectorizer, "scipy.sparse.csr_matrix", dict]:
        """
        Return (vectorizer, job_matrix, job_id_to_idx).
        Refits only when the job corpus has changed.
        """
        current_hash = cls._compute_hash(jobs)
        with cls._lock:
            if cls._entry is not None and cls._entry.corpus_hash == current_hash:
                logger.debug(
                    "VectorizerCache HIT — %d jobs, hash=%s",
                    cls._entry.job_count, current_hash[:8],
                )
                return cls._entry.vectorizer, cls._entry.job_matrix, cls._entry.job_id_to_idx

            # Cache MISS — (re)fit
            logger.info(
                "VectorizerCache MISS — refitting on %d jobs (hash=%s)",
                len(jobs), current_hash[:8],
            )
            vectorizer, job_matrix, id_to_idx = cls._fit(jobs)
            cls._entry = _CacheEntry(
                vectorizer    = vectorizer,
                job_matrix    = job_matrix,
                job_id_to_idx = id_to_idx,
                corpus_hash   = current_hash,
                job_count     = len(jobs),
            )
            return vectorizer, job_matrix, id_to_idx

    @classmethod
    def invalidate(cls) -> None:
        """Force cache eviction on the next request (e.g., after a job is created/updated)."""
        with cls._lock:
            cls._entry = None
        logger.info("VectorizerCache invalidated")

    # ── Internals ─────────────────────────────────────────────────────────────
    @staticmethod
    def _compute_hash(jobs: list) -> str:
        """MD5 of sorted (id, title, skills) tuples — cheap and stable."""
        content = "|".join(
            f"{j.id}:{j.title}:{j.skills or ''}"
            for j in sorted(jobs, key=lambda j: j.id)
        )
        return hashlib.md5(content.encode("utf-8")).hexdigest()

    @staticmethod
    def _fit(jobs: list) -> tuple[TfidfVectorizer, "scipy.sparse.csr_matrix", dict]:
        """Fit vectorizer on job corpus; return (vectorizer, job_matrix, id→idx)."""
        from app.services.ai.preprocessing import preprocess_text

        sorted_jobs = sorted(jobs, key=lambda j: j.id)
        job_texts   = [
            preprocess_text(f"{j.title} {j.description} {j.skills}")
            for j in sorted_jobs
        ]
        vectorizer  = TfidfVectorizer()
        job_matrix  = vectorizer.fit_transform(job_texts)
        id_to_idx   = {j.id: idx for idx, j in enumerate(sorted_jobs)}
        return vectorizer, job_matrix, id_to_idx


# ─────────────────────────────────────────────────────────────────────────────
# Low-level helpers (used by scoring.py when cache is bypassed)
# ─────────────────────────────────────────────────────────────────────────────
def build_tfidf_matrix(documents: list[str]):
    """
    Fit a TF-IDF vectorizer on `documents` and return (vectorizer, tfidf_matrix).
    The first element is the query; the rest are the corpus.
    Kept for backward compatibility — prefer VectorizerCache in production.
    """
    vectorizer   = TfidfVectorizer()
    tfidf_matrix = vectorizer.fit_transform(documents)
    return vectorizer, tfidf_matrix


def compute_cosine_scores(tfidf_matrix) -> list[float]:
    """
    Cosine similarity between row 0 (query) and rows 1..N (corpus).
    Returns a flat list of floats in [0, 1].
    """
    scores = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:]).flatten()
    return scores.tolist()
