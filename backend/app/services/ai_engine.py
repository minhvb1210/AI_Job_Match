"""
app/services/ai_engine.py — Compatibility shim.

All logic has been migrated to the app/services/ai/ package.
This module re-exports everything so legacy imports continue to work
without modification:

    from app.services.ai_engine import match_cv_to_jobs, ...
"""
from app.services.ai import (  # noqa: F401
    clean_text,
    preprocess_text,
    extract_text_from_pdf,
    extract_text_from_docx,
    extract_text_from_image,
    INDUSTRY_KEYWORDS,
    predict_cv_industry,
    VectorizerCache,
    build_tfidf_matrix,
    compute_cosine_scores,
    match_cv_to_jobs,
    match_candidates_to_job,
    calculate_missing_skills,
    explain_job_match,
)
