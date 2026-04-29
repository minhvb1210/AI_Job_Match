from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.core.database import get_db
from app.core.responses import success_response
from app.core.auth import get_current_user
from app.models.models import Job, Application, User, ApplicationStatus, Interview
from app.schemas.schemas import DashboardStatsResponse
import datetime

router = APIRouter(prefix="/dashboard", tags=["dashboard"])

@router.get("/stats")
def get_dashboard_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Returns high-level statistics for the recruiter/admin dashboard.
    """
    if current_user.role not in ["recruiter", "admin"]:
        raise HTTPException(status_code=403, detail="Recruiter or Admin access required")

    # Filters based on role
    job_filter = Job.employer_id == current_user.id if current_user.role == "recruiter" else True
    
    # 1. Basic Counts
    total_jobs = db.query(Job).filter(job_filter).count()
    
    # Subquery for applications to these jobs
    job_ids_query = db.query(Job.id).filter(job_filter)
    job_ids = [jid[0] for jid in job_ids_query.all()]
    
    total_apps = db.query(Application).filter(Application.job_id.in_(job_ids)).count()
    
    # 2. Success Rate & Avg Match Score
    accepted_apps = db.query(Application).filter(
        Application.job_id.in_(job_ids),
        Application.status == ApplicationStatus.accepted
    ).count()
    
    success_rate = (accepted_apps / total_apps * 100) if total_apps > 0 else 0.0

    avg_score_row = db.query(func.avg(Application.match_score)).filter(
        Application.job_id.in_(job_ids)
    ).first()
    average_match_score = float(avg_score_row[0]) if avg_score_row and avg_score_row[0] else 0.0
    
    # 3. Top Industries (Categories)
    industry_stats = db.query(
        Job.category, 
        func.count(Job.id).label("count")
    ).filter(job_filter).group_by(Job.category).order_by(func.count(Job.id).desc()).limit(5).all()
    
    top_industries = [{"category": row.category or "Other", "count": row.count} for row in industry_stats]

    # 4. Upcoming Interviews
    # Join Application and Job to ensure the recruiter owns the interview
    upcoming_interviews = db.query(Interview).join(Application).join(Job).filter(
        Job.employer_id == current_user.id,
        Interview.scheduled_time >= datetime.datetime.utcnow()
    ).order_by(Interview.scheduled_time.asc()).limit(5).all()

    interviews_data = []
    for iv in upcoming_interviews:
        # Get candidate email via application
        candidate = db.query(User).filter(User.id == iv.application.candidate_id).first()
        interviews_data.append({
            "id": iv.id,
            "candidate_email": candidate.email if candidate else "Unknown",
            "job_title": iv.application.job.title,
            "scheduled_time": iv.scheduled_time.isoformat(),
            "location": iv.location
        })

    # 5. Top Candidate highlight
    top_app = db.query(Application).join(Job).filter(
        Job.employer_id == current_user.id
    ).order_by(Application.match_score.desc()).first()

    top_candidate_data = None
    if top_app:
        cand_user = db.query(User).filter(User.id == top_app.candidate_id).first()
        top_candidate_data = {
            "email": cand_user.email if cand_user else "Unknown",
            "score": top_app.match_score,
            "job_title": top_app.job.title
        }

    return success_response(
        data={
            "total_jobs": total_jobs,
            "total_applications": total_apps,
            "success_rate": round(success_rate, 2),
            "average_match_score": round(average_match_score, 2),
            "top_industries": top_industries,
            "upcoming_interviews": interviews_data,
            "top_candidate": top_candidate_data
        },
        message="Dashboard stats retrieved"
    )
