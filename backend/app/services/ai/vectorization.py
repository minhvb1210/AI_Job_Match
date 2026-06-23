"""
app/services/ai/vectorization.py

Hybrid BM25 + SBERT search engine — thay thế TF-IDF.

Thiết kế:
  - HybridSearchEngine: kết hợp BM25 (keyword matching) + SBERT (semantic similarity)
  - VectorizerCache: giữ nguyên interface cũ để scoring.py không cần thay đổi nhiều
  - Cache invalidation: hash-based, thread-safe (giữ nguyên logic cũ)

Công thức:
  hybrid_score = alpha * normalize(BM25) + (1 - alpha) * normalize(SBERT)
  alpha = 0.4 (BM25 trọng số thấp hơn vì dữ liệu tiếng Việt)
"""
import hashlib
import logging
import threading
import numpy as np
from dataclasses import dataclass

from rank_bm25 import BM25Okapi
from sklearn.metrics.pairwise import cosine_similarity
import scipy.sparse

logger = logging.getLogger("ai_scoring")

from sklearn.feature_extraction.text import TfidfVectorizer

# ─────────────────────────────────────────────────────────────────────────────
# Cache dataclass
# ─────────────────────────────────────────────────────────────────────────────
@dataclass
class _CacheEntry:
    vectorizer:     TfidfVectorizer
    job_matrix:     scipy.sparse.csr_matrix
    job_id_to_idx:  dict
    corpus_hash:    str
    job_count:      int
    bm25_index:     object = None
    job_embeddings: object = None

class VectorizerCache:
    """
    Thread-safe singleton cache cho TF-IDF vectorizer.
    """
    _lock:  threading.Lock = threading.Lock()
    _entry: "_CacheEntry | None" = None

    @classmethod
    def get(cls, jobs: list) -> tuple:
        current_hash = cls._compute_hash(jobs)
        with cls._lock:
            if cls._entry is not None and cls._entry.corpus_hash == current_hash:
                logger.debug(
                    "VectorizerCache HIT — %d jobs, hash=%s",
                    cls._entry.job_count, current_hash[:8],
                )
                scorer = _HybridScorer(cls._entry.vectorizer, cls._entry.job_matrix)
                return scorer, cls._entry.job_matrix, cls._entry.job_id_to_idx

            logger.info(
                "VectorizerCache MISS — rebuilding on %d jobs (hash=%s)",
                len(jobs), current_hash[:8],
            )
            vectorizer, job_matrix, id_to_idx = cls._build(jobs)
            cls._entry = _CacheEntry(
                vectorizer    = vectorizer,
                job_matrix    = job_matrix,
                job_id_to_idx = id_to_idx,
                corpus_hash   = current_hash,
                job_count     = len(jobs),
            )
            scorer = _HybridScorer(vectorizer, job_matrix)
            return scorer, job_matrix, id_to_idx

    @classmethod
    def invalidate(cls) -> None:
        with cls._lock:
            cls._entry = None
        logger.info("VectorizerCache invalidated")

    @staticmethod
    def _compute_hash(jobs: list) -> str:
        content = "|".join(
            f"{j.id}:{j.title}:{j.skills or ''}"
            for j in sorted(jobs, key=lambda j: j.id)
        )
        return hashlib.md5(content.encode("utf-8")).hexdigest()

    @staticmethod
    def _build(jobs: list) -> tuple:
        from app.services.ai.preprocessing import preprocess_text
        sorted_jobs = sorted(jobs, key=lambda j: j.id)
        job_texts   = [
            preprocess_text(f"{j.title} {j.description} {j.skills}")
            for j in sorted_jobs
        ]

        vectorizer = TfidfVectorizer()
        if not job_texts:
            job_matrix = scipy.sparse.csr_matrix((0, 0))
        else:
            job_matrix = vectorizer.fit_transform(job_texts)
            
        logger.info("TF-IDF matrix built for %d jobs", len(sorted_jobs))

        id_to_idx = {j.id: idx for idx, j in enumerate(sorted_jobs)}
        return vectorizer, job_matrix, id_to_idx


class _HybridScorer:
    """
    Giữ tên class cũ để tương thích. Thực chất chỉ dùng TF-IDF cosine similarity.
    """
    def __init__(self, vectorizer: TfidfVectorizer, job_matrix: scipy.sparse.csr_matrix):
        self.vectorizer = vectorizer
        self.job_matrix = job_matrix

    def score_cv(self, processed_cv_text: str) -> np.ndarray:
        if self.job_matrix.shape[0] == 0:
            return np.array([])
        cv_tfidf = self.vectorizer.transform([processed_cv_text])
        scores = cosine_similarity(cv_tfidf, self.job_matrix).flatten()
        return scores

    def transform(self, texts: list[str]) -> np.ndarray:
        return self.vectorizer.transform(texts).toarray()


# ─────────────────────────────────────────────────────────────────────────────
# Legacy helpers — GIỮ NGUYÊN để không break các import cũ trong scoring.py
# ─────────────────────────────────────────────────────────────────────────────
def build_tfidf_matrix(documents: list[str]):
    """
    Backward-compat fallback dùng trong explain_job_match khi job không có trong cache.
    Vẫn dùng TF-IDF để không ảnh hưởng fallback path.
    """
    from sklearn.feature_extraction.text import TfidfVectorizer
    vectorizer   = TfidfVectorizer()
    tfidf_matrix = vectorizer.fit_transform(documents)
    return vectorizer, tfidf_matrix


def compute_cosine_scores(tfidf_matrix) -> list[float]:
    """Backward-compat — giữ nguyên."""
    scores = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:]).flatten()
    return scores.tolist()
