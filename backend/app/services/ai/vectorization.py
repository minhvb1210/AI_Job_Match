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

# ─────────────────────────────────────────────────────────────────────────────
# Bỏ SBERT để chạy mượt trên Render gói Free (tránh lỗi hết RAM 512MB)
# Chỉ sử dụng thuật toán BM25 siêu nhẹ.
# ─────────────────────────────────────────────────────────────────────────────
class _DummySBERT:
    def encode(self, texts: list[str], **kwargs) -> np.ndarray:
        # Dummy embedding shape (n, 384)
        return np.zeros((len(texts), 384), dtype=np.float32)

_sbert_model = _DummySBERT()

def _get_sbert_model() -> _DummySBERT:
    return _sbert_model

def _tokenize_vi(text: str) -> list[str]:
    """Tokenize đơn giản cho BM25 — split theo khoảng trắng sau khi lowercase."""
    return text.lower().split()


# ─────────────────────────────────────────────────────────────────────────────
# Cache dataclass — cập nhật để lưu cả BM25 và SBERT
# ─────────────────────────────────────────────────────────────────────────────
@dataclass
class _CacheEntry:
    # Giữ tên field để tương thích với ai.py (ai.py đọc entry.job_count, entry.corpus_hash)
    bm25_index:    BM25Okapi
    job_embeddings: np.ndarray          # shape (n_jobs, embedding_dim)
    job_id_to_idx:  dict                # {job.id -> row index}
    corpus_hash:    str
    job_count:      int
    # Giữ vectorizer field = None để không crash nếu có code cũ đọc field này
    vectorizer:     object = None
    job_matrix:     object = None       # alias → job_embeddings (scipy sparse compat)


class VectorizerCache:
    """
    Thread-safe singleton cache cho Hybrid BM25+SBERT engine.

    Interface PUBLIC không đổi so với phiên bản TF-IDF cũ:
      vectorizer, job_matrix, id_to_idx = VectorizerCache.get(jobs)

    Thay đổi nội bộ:
      - vectorizer  → HybridScorer object (có method .score_cv())
      - job_matrix  → numpy array embeddings (thay scipy sparse matrix)
      - id_to_idx   → dict như cũ
    """

    _lock:  threading.Lock = threading.Lock()
    _entry: "_CacheEntry | None" = None

    @classmethod
    def get(cls, jobs: list) -> tuple:
        """
        Trả về (hybrid_scorer, job_embeddings, job_id_to_idx).
        Chỉ rebuild khi job corpus thay đổi.
        """
        current_hash = cls._compute_hash(jobs)
        with cls._lock:
            if cls._entry is not None and cls._entry.corpus_hash == current_hash:
                logger.debug(
                    "HybridCache HIT — %d jobs, hash=%s",
                    cls._entry.job_count, current_hash[:8],
                )
                scorer = _HybridScorer(cls._entry.bm25_index, cls._entry.job_embeddings)
                return scorer, cls._entry.job_embeddings, cls._entry.job_id_to_idx

            logger.info(
                "HybridCache MISS — rebuilding on %d jobs (hash=%s)",
                len(jobs), current_hash[:8],
            )
            bm25_index, job_embeddings, id_to_idx = cls._build(jobs)
            cls._entry = _CacheEntry(
                bm25_index     = bm25_index,
                job_embeddings = job_embeddings,
                job_id_to_idx  = id_to_idx,
                corpus_hash    = current_hash,
                job_count      = len(jobs),
            )
            scorer = _HybridScorer(bm25_index, job_embeddings)
            return scorer, job_embeddings, id_to_idx

    @classmethod
    def invalidate(cls) -> None:
        """Force cache eviction — giữ nguyên để ai.py /cache/invalidate vẫn hoạt động."""
        with cls._lock:
            cls._entry = None
        logger.info("HybridCache invalidated")

    @staticmethod
    def _compute_hash(jobs: list) -> str:
        """MD5 hash của job corpus — giữ nguyên logic cũ."""
        content = "|".join(
            f"{j.id}:{j.title}:{j.skills or ''}"
            for j in sorted(jobs, key=lambda j: j.id)
        )
        return hashlib.md5(content.encode("utf-8")).hexdigest()

    @staticmethod
    def _build(jobs: list) -> tuple:
        """Build BM25 index và SBERT embeddings cho toàn bộ job corpus."""
        from app.services.ai.preprocessing import preprocess_text

        sorted_jobs = sorted(jobs, key=lambda j: j.id)
        job_texts   = [
            preprocess_text(f"{j.title} {j.description} {j.skills}")
            for j in sorted_jobs
        ]

        # BM25
        tokenized_jobs = [_tokenize_vi(text) for text in job_texts]
        bm25_index     = BM25Okapi(tokenized_jobs)
        logger.info("BM25 index built for %d jobs", len(sorted_jobs))

        # SBERT embeddings
        sbert = _get_sbert_model()
        job_embeddings = sbert.encode(
            job_texts,
            batch_size=32,
            show_progress_bar=False,
            convert_to_numpy=True,
            normalize_embeddings=True,   # L2 normalize → cosine = dot product
        )
        logger.info(
            "SBERT embeddings built: shape=%s", job_embeddings.shape
        )

        id_to_idx = {j.id: idx for idx, j in enumerate(sorted_jobs)}
        return bm25_index, job_embeddings, id_to_idx


# ─────────────────────────────────────────────────────────────────────────────
# HybridScorer — được trả về từ VectorizerCache.get() thay cho TfidfVectorizer
# ─────────────────────────────────────────────────────────────────────────────
class _HybridScorer:
    """
    Kết hợp BM25 + SBERT để tính similarity scores.
    Được dùng bởi scoring.py thay cho TfidfVectorizer.
    """

    def __init__(self, bm25_index: BM25Okapi, job_embeddings: np.ndarray, alpha: float = 1.0):
        self.bm25_index     = bm25_index
        self.job_embeddings = job_embeddings
        self.alpha          = alpha  # trọng số BM25

    def score_cv(self, processed_cv_text: str) -> np.ndarray:
        """
        Tính hybrid score giữa CV và toàn bộ job corpus.
        Trả về numpy array shape (n_jobs,), giá trị [0, 1].
        """
        # --- BM25 ---
        tokens      = _tokenize_vi(processed_cv_text)
        bm25_scores = np.array(self.bm25_index.get_scores(tokens), dtype=float)

        # --- SBERT ---
        sbert       = _get_sbert_model()
        cv_embedding = sbert.encode(
            [processed_cv_text],
            convert_to_numpy=True,
            normalize_embeddings=True,
        )
        # Dot product = cosine similarity vì đã normalize L2
        sbert_scores = (self.job_embeddings @ cv_embedding.T).flatten()

        # --- Normalize về [0, 1] ---
        def _normalize(arr: np.ndarray) -> np.ndarray:
            mn, mx = arr.min(), arr.max()
            if mx == mn:
                return np.zeros_like(arr)
            return (arr - mn) / (mx - mn)

        bm25_norm  = _normalize(bm25_scores)
        sbert_norm = _normalize(sbert_scores)

        hybrid = self.alpha * bm25_norm + (1 - self.alpha) * sbert_norm
        return hybrid

    # Giữ method transform() để không crash nếu scoring.py gọi vectorizer.transform()
    def transform(self, texts: list[str]) -> np.ndarray:
        """Compatibility shim — trả về SBERT embedding của texts."""
        sbert = _get_sbert_model()
        return sbert.encode(texts, convert_to_numpy=True, normalize_embeddings=True)


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
