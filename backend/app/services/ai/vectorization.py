from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sentence_transformers import SentenceTransformer
import scipy.sparse
import numpy as np
import logging
import threading
from dataclasses import dataclass
import hashlib

logger = logging.getLogger("ai_scoring")

_sbert_model = None

def _get_sbert_model():
    global _sbert_model
    if _sbert_model is None:
        logger.info("Loading SBERT model (keepitreal/vietnamese-sbert)...")
        _sbert_model = SentenceTransformer("keepitreal/vietnamese-sbert")
    return _sbert_model

# ─────────────────────────────────────────────────────────────────────────────
# Cache dataclass
# ─────────────────────────────────────────────────────────────────────────────
@dataclass
class _CacheEntry:
    vectorizer:     TfidfVectorizer
    job_matrix:     scipy.sparse.csr_matrix
    job_embeddings: np.ndarray
    job_id_to_idx:  dict
    corpus_hash:    str
    job_count:      int
    bm25_index:     object = None

class VectorizerCache:
    """
    Thread-safe singleton cache cho Hybrid TF-IDF + SBERT engine.
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
                scorer = _HybridScorer(cls._entry.vectorizer, cls._entry.job_matrix, cls._entry.job_embeddings)
                return scorer, cls._entry.job_matrix, cls._entry.job_id_to_idx

            logger.info(
                "VectorizerCache MISS — rebuilding on %d jobs (hash=%s)",
                len(jobs), current_hash[:8],
            )
            vectorizer, job_matrix, job_embeddings, id_to_idx = cls._build(jobs)
            cls._entry = _CacheEntry(
                vectorizer    = vectorizer,
                job_matrix    = job_matrix,
                job_embeddings= job_embeddings,
                job_id_to_idx = id_to_idx,
                corpus_hash   = current_hash,
                job_count     = len(jobs),
            )
            scorer = _HybridScorer(vectorizer, job_matrix, job_embeddings)
            # return job_matrix to keep backward compatibility with id_to_idx
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
            job_embeddings = np.zeros((0, 384), dtype=np.float32)
        else:
            job_matrix = vectorizer.fit_transform(job_texts)
            sbert = _get_sbert_model()
            job_embeddings = sbert.encode(
                job_texts,
                show_progress_bar=False,
                convert_to_numpy=True,
                normalize_embeddings=True,
            )
            
        logger.info("Hybrid TF-IDF + SBERT matrix built for %d jobs", len(sorted_jobs))

        id_to_idx = {j.id: idx for idx, j in enumerate(sorted_jobs)}
        return vectorizer, job_matrix, job_embeddings, id_to_idx


class _HybridScorer:
    """
    Kết hợp TF-IDF (keyword) + SBERT (semantic) để tính hybrid score.
    """
    def __init__(self, vectorizer: TfidfVectorizer, job_matrix: scipy.sparse.csr_matrix, job_embeddings: np.ndarray, alpha: float = 0.5):
        self.vectorizer = vectorizer
        self.job_matrix = job_matrix
        self.job_embeddings = job_embeddings
        self.alpha = alpha

    def score_cv(self, processed_cv_text: str) -> np.ndarray:
        if self.job_matrix.shape[0] == 0:
            return np.array([])
            
        cv_tfidf = self.vectorizer.transform([processed_cv_text])
        tfidf_scores = cosine_similarity(cv_tfidf, self.job_matrix).flatten()
        
        sbert = _get_sbert_model()
        cv_embedding = sbert.encode(
            [processed_cv_text],
            convert_to_numpy=True,
            normalize_embeddings=True,
        )
        sbert_scores = (self.job_embeddings @ cv_embedding.T).flatten()
        
        hybrid_scores = self.alpha * tfidf_scores + (1 - self.alpha) * sbert_scores
        return hybrid_scores

    def transform(self, texts: list[str]) -> np.ndarray:
        sbert = _get_sbert_model()
        return sbert.encode(texts, convert_to_numpy=True, normalize_embeddings=True)

# ─────────────────────────────────────────────────────────────────────────────
# Legacy helpers
# ─────────────────────────────────────────────────────────────────────────────
def build_tfidf_matrix(documents: list[str]):
    from sklearn.feature_extraction.text import TfidfVectorizer
    vectorizer   = TfidfVectorizer()
    tfidf_matrix = vectorizer.fit_transform(documents)
    return vectorizer, tfidf_matrix


def compute_cosine_scores(tfidf_matrix) -> list[float]:
    scores = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:]).flatten()
    return scores.tolist()
