from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import Optional

from app.core.database import get_db
from app.core.responses import success_response, paginated_response, error_response
from app.models.models import Job, User, Application, CandidateProfile, Notification
from app.models.models import ApplicationStatus
from app.schemas.schemas import ApplicationCreate, ApplicationResponse
from app.core.auth import get_current_user, get_current_employer
from app.services.ai.scoring import calculate_missing_skills

router = APIRouter(prefix="/applications", tags=["applications"])


@router.post("/")
def apply_for_job(
    application: ApplicationCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "candidate":
        raise HTTPException(status_code=403, detail="Only candidates can apply for jobs.")

    job = db.query(Job).filter(Job.id == application.job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")

    existing = db.query(Application).filter(
        Application.job_id == application.job_id,
        Application.candidate_id == current_user.id,
    ).first()
    if existing:
        raise HTTPException(status_code=400, detail="You have already applied for this job.")

    new_app = Application(
        job_id=application.job_id,
        candidate_id=current_user.id,
        match_score=application.match_score,
        status=ApplicationStatus.pending,
    )
    db.add(new_app)
    db.commit()
    db.refresh(new_app)
    return success_response(
        data=ApplicationResponse.model_validate(new_app).model_dump(),
        message="Application submitted successfully",
    )


@router.get("/my-applications")
def get_my_applications(
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "candidate":
        raise HTTPException(status_code=403, detail="Must be a candidate.")

    query  = db.query(Application).filter(Application.candidate_id == current_user.id)
    total  = query.count()
    offset = (page - 1) * limit
    apps   = query.offset(offset).limit(limit).all()

    items = []
    for app in apps:
        job = db.query(Job).filter(Job.id == app.job_id).first()
        items.append({
            "id":          app.id,
            "job_id":      app.job_id,
            "status":      app.status.value if app.status else "pending",
            "match_score": app.match_score,
            "created_at":  app.created_at.isoformat() if app.created_at else None,
            "job": {
                "id":      job.id,
                "title":   job.title,
                "company": job.company,
            } if job else None,
        })

    return paginated_response(items=items, total=total, page=page, limit=limit)


@router.get("/employer-job/{job_id}")
def get_applications_for_job(
    job_id: int,
    page: int = 1,
    limit: int = 50,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_employer),
):
    job = db.query(Job).filter(Job.id == job_id).first()
    if not job:
        raise HTTPException(status_code=404, detail="Job not found")
    if job.employer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to view this job's applications")

    # Fetch all, sort by AI match_score descending so top candidates appear first
    apps = db.query(Application).filter(Application.job_id == job_id).all()
    apps.sort(key=lambda a: (a.match_score or 0), reverse=True)

    total  = len(apps)
    offset = (page - 1) * limit
    paged  = apps[offset: offset + limit]

    items = []
    for i, app in enumerate(paged):
        candidate = db.query(User).filter(User.id == app.candidate_id).first()
        profile   = db.query(CandidateProfile).filter(
            CandidateProfile.user_id == app.candidate_id
        ).first() if candidate else None

        cv_text = (profile.skills_text or "") if profile else ""
        missing = calculate_missing_skills(cv_text, job.skills or "")

        items.append({
            "id":               app.id,
            "rank":             offset + i + 1,
            "status":           app.status.value if app.status else "pending",
            "match_score":      app.match_score or 0,
            "created_at":       app.created_at.isoformat() if app.created_at else None,
            "candidate_id":     candidate.id if candidate else None,
            "candidate_email":  candidate.email if candidate else "Unknown",
            "candidate_skills": cv_text[:500] if cv_text else "No profile provided",
            "missing_skills":   missing,
            "is_top_candidate": (i < 3),   # Top 3 highlighted with gold/silver/bronze
        })

    return paginated_response(items=items, total=total, page=page, limit=limit)


@router.put("/{application_id}/status")
def update_application_status(
    application_id: int,
    status_update: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_employer),
):
    raw_status = status_update.get("status")

    valid_values = [s.value for s in ApplicationStatus]
    if raw_status not in valid_values:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid status '{raw_status}'. Must be one of: {valid_values}",
        )

    app = db.query(Application).filter(Application.id == application_id).first()
    if not app:
        raise HTTPException(status_code=404, detail="Application not found")

    job = db.query(Job).filter(Job.id == app.job_id).first()
    if not job or job.employer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    app.status = ApplicationStatus(raw_status)

    notification = Notification(
        user_id=app.candidate_id,
        message=f"Your application for '{job.title}' has been updated to '{raw_status}'.",
    )
    db.add(notification)
    db.commit()
    db.refresh(app)

    return success_response(
        data={"application_id": app.id, "new_status": raw_status},
        message="Application status updated successfully",
    )
