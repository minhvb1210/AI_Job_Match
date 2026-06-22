"""
Admin API endpoints — user management, job oversight, platform statistics.
All endpoints require role == 'admin'.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.core.database import get_db
from app.core.responses import success_response, paginated_response
from app.core.auth import get_current_user
from app.models.models import (
    User, Job, Application, CandidateProfile, Company,
    Notification, UserRole,
)

router = APIRouter(prefix="/admin", tags=["admin"])


# ── Auth Guard ────────────────────────────────────────────────────────────────
def get_current_admin(current_user: User = Depends(get_current_user)):
    role_value = current_user.role.value if hasattr(current_user.role, "value") else str(current_user.role)
    if role_value != "admin":
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user


# ── Dashboard Stats ───────────────────────────────────────────────────────────
@router.get("/stats")
def get_admin_stats(
    db: Session = Depends(get_db),
    _: User = Depends(get_current_admin),
):
    total_users       = db.query(User).count()
    total_candidates  = db.query(User).filter(User.role == UserRole.candidate).count()
    total_recruiters  = db.query(User).filter(
        (User.role == UserRole.recruiter) | (User.role == UserRole.employer)
    ).count()
    total_admins      = db.query(User).filter(User.role == UserRole.admin).count()
    total_jobs        = db.query(Job).count()
    total_applications = db.query(Application).count()
    total_companies   = db.query(Company).count()

    return success_response(data={
        "total_users":        total_users,
        "total_candidates":   total_candidates,
        "total_recruiters":   total_recruiters,
        "total_admins":       total_admins,
        "total_jobs":         total_jobs,
        "total_applications": total_applications,
        "total_companies":    total_companies,
    })


# ── List Users ────────────────────────────────────────────────────────────────
@router.get("/users")
def list_users(
    page: int = 1,
    limit: int = 20,
    role: str | None = None,
    q: str | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_admin),
):
    query = db.query(User)
    if role and role != "all":
        query = query.filter(User.role == role)
    if q and q.strip():
        search = f"%{q.strip()}%"
        query = query.filter(
            (User.email.ilike(search)) | (User.full_name.ilike(search))
        )

    total  = query.count()
    offset = (page - 1) * limit
    users  = query.order_by(User.id.desc()).offset(offset).limit(limit).all()

    items = []
    for u in users:
        role_val = u.role.value if hasattr(u.role, "value") else str(u.role)
        profile  = db.query(CandidateProfile).filter(CandidateProfile.user_id == u.id).first()
        items.append({
            "id":         u.id,
            "email":      u.email,
            "full_name":  u.full_name,
            "role":       role_val,
            "phone":      u.phone_number,
            "avatar_url": u.avatar_url,
            "has_cv":     bool(profile and profile.skills_text and len(profile.skills_text) > 10),
            "created_at": None,  # model doesn't have created_at on User
        })

    return paginated_response(items=items, total=total, page=page, limit=limit)


# ── Delete User ───────────────────────────────────────────────────────────────
@router.delete("/users/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_admin: User = Depends(get_current_admin),
):
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if user.id == current_admin.id:
        raise HTTPException(status_code=400, detail="Cannot delete your own admin account")

    # Clean up related data
    db.query(Application).filter(Application.candidate_id == user_id).delete(synchronize_session=False)
    db.query(Notification).filter(Notification.user_id == user_id).delete(synchronize_session=False)

    # If recruiter, clean their jobs too
    role_val = user.role.value if hasattr(user.role, "value") else str(user.role)
    if role_val in ("recruiter", "employer"):
        jobs = db.query(Job).filter(Job.employer_id == user_id).all()
        for job in jobs:
            db.query(Application).filter(Application.job_id == job.id).delete(synchronize_session=False)
        db.query(Job).filter(Job.employer_id == user_id).delete(synchronize_session=False)
        db.query(Company).filter(Company.employer_id == user_id).delete(synchronize_session=False)

    db.delete(user)
    db.commit()

    return success_response(message=f"User {user.email} deleted successfully")


# ── List Jobs (Admin view) ────────────────────────────────────────────────────
@router.get("/jobs")
def list_all_jobs(
    page: int = 1,
    limit: int = 20,
    q: str | None = None,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_admin),
):
    query = db.query(Job)
    if q and q.strip():
        search = f"%{q.strip()}%"
        query = query.filter(
            (Job.title.ilike(search)) | (Job.company.ilike(search))
        )

    total  = query.count()
    offset = (page - 1) * limit
    jobs   = query.order_by(Job.id.desc()).offset(offset).limit(limit).all()

    items = []
    for j in jobs:
        app_count = db.query(Application).filter(Application.job_id == j.id).count()
        employer  = db.query(User).filter(User.id == j.employer_id).first()
        items.append({
            "id":             j.id,
            "title":          j.title,
            "company":        j.company,
            "location":       j.location,
            "category":       j.category,
            "job_type":       j.job_type,
            "salary":         j.salary,
            "skills":         j.skills,
            "applicants":     app_count,
            "employer_email": employer.email if employer else "N/A",
        })

    return paginated_response(items=items, total=total, page=page, limit=limit)


# ── Delete Job (Admin) ────────────────────────────────────────────────────────
@router.delete("/jobs/{job_id}")
def admin_delete_job(
    job_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(get_current_admin),
):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    db.query(Application).filter(Application.job_id == job_id).delete(synchronize_session=False)
    from app.models.models import SavedJob
    db.query(SavedJob).filter(SavedJob.job_id == job_id).delete(synchronize_session=False)
    db.delete(job)
    db.commit()

    return success_response(message=f"Job '{job.title}' deleted successfully")
