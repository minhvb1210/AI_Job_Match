"""
app/routers/profile.py

Unified profile endpoints for both candidate and recruiter users.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.responses import success_response
from app.core.auth import get_current_user
from app.models.models import (
    User, Company, CandidateProfile, Job, Application, SavedJob,
)
from app.schemas.schemas import (
    ProfileUpdateRequest,
    CandidateProfileFullResponse,
    RecruiterProfileFullResponse,
    CandidateEducationResponse,
    CandidateExperienceResponse,
    CandidateProjectResponse,
    CompanyResponse,
)

router = APIRouter(prefix="/profile", tags=["profile"])


# ─────────────────────────────────────────
# GET /profile/me
# ─────────────────────────────────────────
@router.get("/me")
def get_my_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Return full profile for the currently authenticated user.
    Automatically detects role and returns the appropriate schema."""

    role_value = current_user.role.value if hasattr(current_user.role, "value") else str(current_user.role)

    if role_value in ("recruiter", "employer"):
        return _build_recruiter_profile(current_user, db)
    else:
        return _build_candidate_profile(current_user, db)


def _build_candidate_profile(user: User, db: Session) -> dict:
    """Assemble full candidate profile response."""
    # Fetch or create candidate profile
    profile = db.query(CandidateProfile).filter(
        CandidateProfile.user_id == user.id
    ).first()

    educations = []
    experiences = []
    projects = []
    skills_text = ""

    if profile:
        skills_text = profile.skills_text or ""
        educations = [
            CandidateEducationResponse.model_validate(e).model_dump()
            for e in profile.educations
        ]
        experiences = [
            CandidateExperienceResponse.model_validate(e).model_dump()
            for e in profile.experiences
        ]
        projects = [
            CandidateProjectResponse.model_validate(e).model_dump()
            for e in profile.projects
        ]

    # Stats
    saved_count = db.query(SavedJob).filter(SavedJob.candidate_id == user.id).count()
    applied_count = db.query(Application).filter(Application.candidate_id == user.id).count()

    data = CandidateProfileFullResponse(
        id=user.id,
        email=user.email,
        role=user.role.value if hasattr(user.role, "value") else str(user.role),
        full_name=user.full_name,
        phone_number=user.phone_number,
        address=user.address,
        avatar_url=user.avatar_url,
        auth_provider=user.auth_provider,
        bio=getattr(user, "bio", None),
        date_of_birth=getattr(user, "date_of_birth", None),
        skills_text=skills_text,
        educations=educations,
        experiences=experiences,
        projects=projects,
        saved_jobs_count=saved_count,
        applied_jobs_count=applied_count,
    ).model_dump()

    return success_response(data=data, message="Candidate profile loaded")


def _build_recruiter_profile(user: User, db: Session) -> dict:
    """Assemble full recruiter profile response."""
    # Company
    company_obj = db.query(Company).filter(Company.employer_id == user.id).first()
    company_data = None
    if company_obj:
        company_data = CompanyResponse.model_validate(company_obj).model_dump()

    # Stats
    jobs_count = db.query(Job).filter(Job.employer_id == user.id).count()
    # Count total applicants across all the recruiter's jobs
    job_ids = [j.id for j in db.query(Job.id).filter(Job.employer_id == user.id).all()]
    applicants_count = 0
    if job_ids:
        applicants_count = db.query(Application).filter(
            Application.job_id.in_(job_ids)
        ).count()

    data = RecruiterProfileFullResponse(
        id=user.id,
        email=user.email,
        role=user.role.value if hasattr(user.role, "value") else str(user.role),
        full_name=user.full_name,
        phone_number=user.phone_number,
        address=user.address,
        avatar_url=user.avatar_url,
        auth_provider=user.auth_provider,
        bio=getattr(user, "bio", None),
        website=getattr(user, "website", None),
        industry=getattr(user, "industry", None),
        company=company_data,
        jobs_posted_count=jobs_count,
        total_applicants_count=applicants_count,
    ).model_dump()

    return success_response(data=data, message="Recruiter profile loaded")


# ─────────────────────────────────────────
# PUT /profile/update
# ─────────────────────────────────────────
@router.put("/update")
def update_my_profile(
    profile_update: ProfileUpdateRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """Update the currently authenticated user's profile fields.
    Only non-null fields in the request body are updated."""

    update_data = profile_update.model_dump(exclude_unset=True, exclude_none=True)

    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update.")

    allowed_fields = {
        "full_name", "phone_number", "address", "avatar_url",
        "bio", "date_of_birth", "website", "industry",
    }

    updated_fields = []
    for field, value in update_data.items():
        if field in allowed_fields and hasattr(current_user, field):
            setattr(current_user, field, value)
            updated_fields.append(field)

    if not updated_fields:
        raise HTTPException(status_code=400, detail="No valid fields to update.")

    db.commit()
    db.refresh(current_user)

    print(f"DEBUG PROFILE UPDATE: user_id={current_user.id}, updated={updated_fields}")

    # Return full profile after update
    role_value = current_user.role.value if hasattr(current_user.role, "value") else str(current_user.role)
    if role_value in ("recruiter", "employer"):
        return _build_recruiter_profile(current_user, db)
    else:
        return _build_candidate_profile(current_user, db)
