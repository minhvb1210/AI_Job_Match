"""
app/services/ai/industry.py

Industry keyword dictionary and detection logic (SVM model + keyword fallback).
"""
import re
import os
import pickle
import numpy as np

from app.services.ai.preprocessing import clean_text

# ─────────────────────────────────────────────────────────────────────────────
# Industry keyword dictionary
# ─────────────────────────────────────────────────────────────────────────────
INDUSTRY_KEYWORDS: dict[str, list[str]] = {
    "IT": [
        # Programming Languages
        "python", "java", "javascript", "typescript", "c++", "c#", "php",
        "go", "rust", "kotlin", "swift",
        # Web
        "react", "angular", "vue", "nextjs", "nodejs", "express",
        "spring", "spring boot", "html", "css", "sass", "tailwind", "bootstrap",
        # Mobile
        "flutter", "dart", "android", "ios", "react native",
        # Database
        "sql", "mysql", "postgresql", "mongodb", "redis", "firebase", "nosql",
        # DevOps & Cloud
        "docker", "kubernetes", "aws", "azure", "gcp", "ci cd",
        "jenkins", "github actions", "terraform", "linux", "nginx",
        # AI / Data
        "machine learning", "deep learning", "data science", "pandas", "numpy",
        "tensorflow", "pytorch", "scikit learn", "nlp", "computer vision",
        # Concepts
        "rest api", "graphql", "microservices", "oop", "design patterns",
        "agile", "scrum",
    ],
    "Marketing": [
        "digital marketing", "online marketing", "seo", "sem", "google ads",
        "facebook ads", "tiktok ads", "email marketing", "content marketing",
        "content creation", "copywriting", "social media", "social media marketing",
        "branding", "storytelling",
        "google analytics", "data analysis", "marketing analytics",
        "conversion rate", "a b testing", "crm",
        "hubspot", "mailchimp", "canva", "hootsuite",
    ],
    "Accounting": [
        "accounting", "financial accounting", "management accounting",
        "bookkeeping", "ledger", "journal entries",
        "finance", "financial analysis", "budgeting", "forecasting",
        "cash flow", "financial reporting",
        "tax", "taxation", "audit", "internal audit", "compliance",
        "excel", "quickbooks", "sap", "erp",
        "cpa", "acca",
    ],
    "HR": [
        "recruitment", "talent acquisition", "headhunting", "interviewing",
        "human resources", "hr management", "employee relations",
        "onboarding", "offboarding", "payroll", "benefits",
        "training", "learning development", "performance management",
        "labor law", "hr policy", "compliance",
        "hris", "workday", "sap hr",
    ],
    "Design": [
        "ui design", "ux design", "user interface", "user experience",
        "wireframe", "prototype", "usability",
        "figma", "sketch", "adobe xd", "photoshop", "illustrator",
        "graphic design", "branding", "typography", "layout", "visual design",
        "video editing", "after effects", "motion graphics", "3d design", "blender",
    ],
}

# Module-level cache so the SVM model is only loaded once
_industry_model_data = None


def get_industry_classifier():
    """Load SVM classifier from disk (cached after first load)."""
    global _industry_model_data
    if _industry_model_data is not None:
        return _industry_model_data

    current_dir = os.path.dirname(os.path.abspath(__file__))
    possible_paths = [
        os.path.join(current_dir, "..", "..", "..", "..", "d:/AI_JOB", "text_classifier.pkl"),
        os.path.join(current_dir, "text_classifier.pkl"),
        "d:/AI_JOB/text_classifier.pkl",
    ]
    for path in possible_paths:
        if os.path.exists(path):
            try:
                with open(path, "rb") as f:
                    _industry_model_data = pickle.load(f)
                return _industry_model_data
            except Exception:
                continue
    return None


def _keyword_based_detection(cleaned_cv: str) -> tuple[str, dict]:
    """Count industry keyword hits as fallback detection."""
    scores = {cat: 0 for cat in INDUSTRY_KEYWORDS}
    for cat, keywords in INDUSTRY_KEYWORDS.items():
        for kw in keywords:
            pattern = r"\b" + re.escape(kw.lower()) + r"\b"
            if re.search(pattern, cleaned_cv):
                scores[cat] += 1
    predicted = max(scores, key=scores.get)
    if scores[predicted] == 0:
        return "IT", scores   # Default fallback
    return predicted, scores


def predict_cv_industry(cv_text: str) -> tuple[str, float]:
    """
    Predict industry for a CV text.

    Returns:
        (industry_label, confidence)  — confidence is 0.0 for keyword fallback.
    """
    cleaned_cv = clean_text(cv_text)

    # 1. Try SVM model
    model_data = get_industry_classifier()
    if model_data:
        try:
            vectorizer = model_data["vectorizer"]
            model      = model_data["model"]
            categories = model_data["categories"]
            X = vectorizer.transform([cleaned_cv])

            if hasattr(model, "predict_proba"):
                proba         = model.predict_proba(X)[0]
                max_confidence = float(np.max(proba))
                pred_idx       = int(np.argmax(proba))
                prediction     = categories[pred_idx]
                if max_confidence > 0.40:
                    return prediction, max_confidence
                # Confidence too low — fall through to keyword detection
            else:
                pred_idx = model.predict(X)[0]
                if isinstance(pred_idx, str):
                    return pred_idx, 1.0
                return categories[pred_idx], 1.0
        except Exception:
            pass  # Fall through to keyword detection

    # 2. Keyword-based fallback
    predicted, scores = _keyword_based_detection(cleaned_cv)
    total = sum(scores.values()) or 1
    confidence = scores[predicted] / total
    return predicted, confidence
