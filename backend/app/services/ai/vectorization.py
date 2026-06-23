from rank_bm25 import BM25Okapi
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

def _tokenize_vi(text: str) -> list[str]:
    """Tokenize đơn giản cho BM25 — split theo khoảng trắng sau khi lowercase."""
    return text.lower().split()

# ─────────────────────────────────────────────────────────────────────────────
# Cache dataclass
# ─────────────────────────────────────────────────────────────────────────────
@dataclass
class _CacheEntry:
    bm25_index:     BM25Okapi
    job_embeddings: np.ndarray
    job_id_to_idx:  dict
    corpus_hash:    str
    job_count:      int
    vectorizer:     object = None
    job_matrix:     object = None

class VectorizerCache:
    """
    Thread-safe singleton cache cho Hybrid BM25 + SBERT engine.
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
                scorer = _HybridScorer(cls._entry.bm25_index, cls._entry.job_embeddings)
                return scorer, cls._entry.job_embeddings, cls._entry.job_id_to_idx

            logger.info(
                "VectorizerCache MISS — rebuilding on %d jobs (hash=%s)",
                len(jobs), current_hash[:8],
            )
            bm25_index, job_embeddings, id_to_idx = cls._build(jobs)
            cls._entry = _CacheEntry(
                bm25_index    = bm25_index,
                job_embeddings= job_embeddings,
                job_id_to_idx = id_to_idx,
                corpus_hash   = current_hash,
                job_count     = len(jobs),
            )
            scorer = _HybridScorer(bm25_index, job_embeddings)
            return scorer, job_embeddings, id_to_idx

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

        if not job_texts:
            bm25_index = BM25Okapi([[]])
            job_embeddings = np.zeros((0, 384), dtype=np.float32)
        else:
            tokenized_jobs = [_tokenize_vi(text) for text in job_texts]
            bm25_index     = BM25Okapi(tokenized_jobs)
            
            sbert = _get_sbert_model()
            job_embeddings = sbert.encode(
                job_texts,
                show_progress_bar=False,
                convert_to_numpy=True,
                normalize_embeddings=True,
            )
            
        logger.info("Hybrid BM25 + SBERT matrix built for %d jobs", len(sorted_jobs))

        id_to_idx = {j.id: idx for idx, j in enumerate(sorted_jobs)}
        return bm25_index, job_embeddings, id_to_idx


class _HybridScorer:
    """
    Kết hợp BM25 (keyword) + SBERT (semantic) để tính hybrid score.
    """
    def __init__(self, bm25_index: BM25Okapi, job_embeddings: np.ndarray, alpha: float = 0.5):
        self.bm25_index = bm25_index
        self.job_embeddings = job_embeddings
        self.alpha = alpha

    def score_cv(self, processed_cv_text: str) -> np.ndarray:
        if self.job_embeddings.shape[0] == 0:
            return np.array([])
            
        # 1. BM25 Score
        tokens      = _tokenize_vi(processed_cv_text)
        bm25_scores = np.array(self.bm25_index.get_scores(tokens), dtype=float)
        
        # Soft normalization for BM25 to prevent tiny scores from becoming 1.0
        # A good match usually scores above 10.0 in BM25
        max_bm25 = max(bm25_scores.max(), 10.0)
        bm25_norm = bm25_scores / max_bm25 if max_bm25 > 0 else np.zeros_like(bm25_scores)
        
        # 2. SBERT Score
        sbert = _get_sbert_model()
        cv_embedding = sbert.encode(
            [processed_cv_text],
            convert_to_numpy=True,
            normalize_embeddings=True,
        )
        sbert_scores = (self.job_embeddings @ cv_embedding.T).flatten()
        sbert_norm = np.clip(sbert_scores, 0, 1) # Ensure within [0, 1]
        
        # 3. Hybrid Score
        hybrid_scores = self.alpha * bm25_norm + (1 - self.alpha) * sbert_norm
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
