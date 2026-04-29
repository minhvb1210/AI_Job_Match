import requests
import time
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List, Optional

from app.core.database import get_db
from app.core.responses import success_response, paginated_response
from app.models.models import Job, User
from app.schemas.schemas import JobCreate, JobResponse
from app.core.auth import get_current_employer, get_current_user
from app.services.ai.vectorization import VectorizerCache

router = APIRouter(prefix="/jobs", tags=["jobs"])

# ── External Jobs Cache ──────────────────────────────────────────────────────
# Memory cache for external jobs to avoid hitting Remotive API too often.
_external_jobs_cache = {
    "items": [],
    "last_fetch": 0.0
}
CACHE_TTL_SECONDS = 1200 # 20 minutes

@router.get("/external")
def get_external_jobs(
    limit: int = 20,
    category: Optional[str] = None
):
    """
    Fetches remote jobs from Remotive API. 
    Uses a hybrid approach: Memory Cache + API Fallback.
    """
    now = time.time()
    
    # Try to use cache if not expired
    if _external_jobs_cache["items"] and (now - _external_jobs_cache["last_fetch"] < CACHE_TTL_SECONDS):
        items = _external_jobs_cache["items"]
    else:
        try:
            # Fetch from Remotive
            # Mapping category if provided (Remotive uses specific slugs)
            url = "https://remotive.com/api/remote-jobs"
            params = {}
            if category and category != "All":
                params["category"] = category.lower()
            
            resp = requests.get(url, params=params, timeout=10)
            resp.raise_for_status()
            data = resp.json()
            
            raw_jobs = data.get("jobs", [])
            # Map to a clean internal-compatible schema
            items = []
            for j in raw_jobs:
                items.append({
                    "id": j.get("id"),
                    "title": j.get("title"),
                    "company": j.get("company_name"),
                    "location": "Remote",
                    "category": j.get("category"),
                    "job_type": j.get("job_type"),
                    "description": j.get("description"),
                    "url": j.get("url"),
                    "logo_url": j.get("company_logo"),
                    "is_external": True
                })
            
            # Update cache
            _external_jobs_cache["items"] = items
            _external_jobs_cache["last_fetch"] = now
            
        except Exception as e:
            # Fallback to stale cache if API fails
            if _external_jobs_cache["items"]:
                items = _external_jobs_cache["items"]
            else:
                raise HTTPException(status_code=503, detail="External job service currently unavailable")

    # Client-side limit
    return success_response(data=items[:limit])


@router.post("/")
def create_job(
    job: JobCreate,
    db: Session = Depends(get_db),
    current_employer: User = Depends(get_current_employer),
):
    print(f"DEBUG: JOB CREATE ATTEMPT - User: {current_employer.email} (Role: {current_employer.role})")
    from app.models.models import Company
    db_company = db.query(Company).filter(Company.employer_id == current_employer.id).first()
    
    if not db_company:
        print(f"DEBUG: JOB CREATE FAILED - User {current_employer.email} has no company profile")
        raise HTTPException(
            status_code=400, 
            detail="You must create a company profile before posting jobs. Visit Company Profile section."
        )

    print(f"DEBUG: JOB CREATE - Linking to company: {db_company.name} (ID: {db_company.id})")
    company_id = db_company.id

    new_job = Job(**job.model_dump(), employer_id=current_employer.id, company_id=company_id)
    db.add(new_job)
    db.commit()
    db.refresh(new_job)
    VectorizerCache.invalidate()   # job corpus changed
    print(f"DEBUG: JOB CREATE SUCCESS - Job ID: {new_job.id}")
    return success_response(
        data=JobResponse.model_validate(new_job).model_dump(),
        message="Job created successfully",
    )


@router.get("/search")
def search_jobs(
    q: Optional[str] = None,
    category: Optional[str] = None,
    job_type: Optional[str] = None,
    experience_level: Optional[str] = None,
    location: Optional[str] = None,
    min_salary: Optional[int] = None,
    sort_by: Optional[str] = 'newest', # newest or salary
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(get_db),
):
    query = db.query(Job)
    if q and q.strip():
        search = f"%{q.strip()}%"
        query = query.filter(
            or_(Job.title.ilike(search), Job.company.ilike(search), Job.skills.ilike(search))
        )
    if category and category != "All":
        query = query.filter(Job.category == category)
    if job_type and job_type != "All":
        query = query.filter(Job.job_type == job_type)
    if experience_level and experience_level != "All":
        query = query.filter(Job.experience_level == experience_level)
    if location and location.strip():
        query = query.filter(Job.location.ilike(f"%{location}%"))
    if min_salary is not None:
        query = query.filter(Job.salary_min >= min_salary)

    # Sorting
    if sort_by == 'salary':
        query = query.order_by(Job.salary_min.desc())
    else:
        query = query.order_by(Job.id.desc())

    total  = query.count()
    offset = (page - 1) * limit
    items  = query.offset(offset).limit(limit).all()
    return paginated_response(
        items=[JobResponse.model_validate(j).model_dump() for j in items],
        total=total,
        page=page,
        limit=limit,
    )


@router.get("/saved")
def get_saved_jobs(
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from app.models.models import SavedJob
    query  = db.query(SavedJob).filter(SavedJob.candidate_id == current_user.id)
    total  = query.count()
    offset = (page - 1) * limit
    saved_entries = query.offset(offset).limit(limit).all()
    return paginated_response(
        items=[JobResponse.model_validate(entry.job).model_dump() for entry in saved_entries],
        total=total,
        page=page,
        limit=limit,
    )


@router.post("/{job_id}/save")
@router.post("/save/{job_id}")
def save_job(
    job_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from app.models.models import SavedJob
    if current_user.role != "candidate":
        raise HTTPException(status_code=403, detail="Only candidates can save jobs")

    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    existing = db.query(SavedJob).filter(
        SavedJob.candidate_id == current_user.id, SavedJob.job_id == job_id
    ).first()
    if existing:
        return success_response(message="Already saved")

    saved = SavedJob(job_id=job_id, candidate_id=current_user.id)
    db.add(saved)
    db.commit()
    return success_response(message="Job saved")


@router.delete("/{job_id}/save")
def unsave_job(
    job_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from app.models.models import SavedJob
    saved = db.query(SavedJob).filter(
        SavedJob.candidate_id == current_user.id, SavedJob.job_id == job_id
    ).first()
    if saved:
        db.delete(saved)
        db.commit()
    return success_response(message="Job unsaved")


@router.put("/{job_id}")
def update_job(
    job_id: int,
    job_update: JobCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_employer),
):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    if job.employer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to edit this job")

    for field, value in job_update.model_dump().items():
        setattr(job, field, value)

    db.commit()
    db.refresh(job)
    VectorizerCache.invalidate()   # job corpus changed
    return success_response(
        data=JobResponse.model_validate(job).model_dump(),
        message="Job updated successfully",
    )


@router.delete("/{job_id}")
def delete_job(
    job_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_employer),
):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    if job.employer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to delete this job")

    # SavedJob cascade handles deletion; Applications are preserved
    db.delete(job)
    db.commit()
    VectorizerCache.invalidate()   # job corpus changed
    return success_response(message="Job deleted successfully")


@router.get("/{job_id}")
def get_job_detail(
    job_id: int,
    db: Session = Depends(get_db),
):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    
    return success_response(
        data=JobResponse.model_validate(job).model_dump(),
        message="Job retrieved successfully",
    )


@router.get("/{job_id}/ai-suggested-candidates")
def suggest_candidates_for_job(
    job_id: int,
    page: int = 1,
    limit: int = 10,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_employer),
):
    """Suggest candidates whose profile matches this job (even without applying)."""
    from app.services.ai_engine import match_candidates_to_job
    from app.models.models import CandidateProfile

    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    if job.employer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    all_profiles = db.query(CandidateProfile).all()
    if not all_profiles:
        return paginated_response(items=[], total=0, page=page, limit=limit)

    job_text        = f"{job.title} {job.description} {job.skills}"
    recommendations = match_candidates_to_job(job_text, all_profiles)
    total           = len(recommendations)

    # Manual pagination on the already-ranked results list
    offset = (page - 1) * limit
    paged  = recommendations[offset : offset + limit]

    items = []
    for rec in paged:
        profile        = rec["profile"]
        candidate_user = db.query(User).filter(User.id == profile.user_id).first()
        if candidate_user:
            items.append({
                "score":             rec["score"],
                "candidate_user_id": candidate_user.id,
                "candidate_email":   candidate_user.email,
                "matched_skills_text": (profile.skills_text or "")[:100] + "...",
            })

    return paginated_response(items=items, total=total, page=page, limit=limit)


@router.get("/")
def get_jobs(
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(get_db),
):
    query  = db.query(Job)
    total  = query.count()
    offset = (page - 1) * limit
    jobs   = query.offset(offset).limit(limit).all()
    return paginated_response(
        items=[JobResponse.model_validate(j).model_dump() for j in jobs],
        total=total,
        page=page,
        limit=limit,
    )

import httpx
import time

# Simple in-memory cache for Remotive jobs
EXTERNAL_JOBS_CACHE = {
    "data": [],
    "last_updated": 0,
    "ttl": 1800  # 30 minutes
}

@router.get("/external")
async def get_external_jobs(category: Optional[str] = None, limit: int = 20):
    """Fetch remote jobs from Remotive with caching."""
    now = time.time()
    
    # Return cache if valid
    if EXTERNAL_JOBS_CACHE["data"] and (now - EXTERNAL_JOBS_CACHE["last_updated"] < EXTERNAL_JOBS_CACHE["ttl"]):
        data = EXTERNAL_JOBS_CACHE["data"]
    else:
        try:
            async with httpx.AsyncClient() as client:
                url = "https://remotive.com/api/remote-jobs"
                params = {"limit": 100} # Fetch more for filtering
                if category and category != "All":
                    params["category"] = category
                
                response = await client.get(url, params=params, timeout=10.0)
                if response.status_code == 200:
                    raw_data = response.json()
                    jobs = raw_data.get("jobs", [])
                    
                    # Normalize for frontend
                    formatted = []
                    for j in jobs:
                        formatted.append({
                            "id": j.get("id"),
                            "title": j.get("title"),
                            "company": j.get("company_name"),
                            "location": "Remote",
                            "salary": j.get("salary") or "Competitive",
                            "description": j.get("description"),
                            "skills": j.get("tags", []),
                            "url": j.get("url"),
                            "logo_url": j.get("company_logo"),
                            "job_type": j.get("job_type", "Remote"),
                            "is_external": True
                        })
                    
                    EXTERNAL_JOBS_CACHE["data"] = formatted
                    EXTERNAL_JOBS_CACHE["last_updated"] = now
                    data = formatted
                else:
                    data = EXTERNAL_JOBS_CACHE["data"] # Fallback to stale cache if API error
        except Exception:
            data = EXTERNAL_JOBS_CACHE["data"] # Fallback to stale cache
            
    # Apply local limit
    return success_response(data=data[:limit])
