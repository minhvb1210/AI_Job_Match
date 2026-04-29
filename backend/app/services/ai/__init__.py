"""
app/services/ai/__init__.py

Public API re-exports for the AI service package.
Import from here instead of individual sub-modules.
"""
from app.services.ai.preprocessing import (
    clean_text,
    preprocess_text,
    extract_text_from_pdf,
    extract_text_from_docx,
    extract_text_from_image,
)
from app.services.ai.industry import (
    INDUSTRY_KEYWORDS,
    predict_cv_industry,
)
from app.services.ai.vectorization import (
    VectorizerCache,
    build_tfidf_matrix,
    compute_cosine_scores,
)
from app.services.ai.scoring import (
    match_cv_to_jobs,
    match_candidates_to_job,
    calculate_missing_skills,
    explain_job_match,
)

__all__ = [
    # preprocessing
    "clean_text",
    "preprocess_text",
    "extract_text_from_pdf",
    "extract_text_from_docx",
    "extract_text_from_image",
    # industry
    "INDUSTRY_KEYWORDS",
    "predict_cv_industry",
    # vectorization
    "VectorizerCache",
    "build_tfidf_matrix",
    "compute_cosine_scores",
    # scoring
    "match_cv_to_jobs",
    "match_candidates_to_job",
    "calculate_missing_skills",
    "explain_job_match",
]
