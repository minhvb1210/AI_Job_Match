from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.responses import success_response, error_response
from app.core.auth import get_current_user
from app.models.models import Application, Interview, User, ApplicationStatus, Notification
from app.schemas.schemas import InterviewCreate, InterviewResponse
import datetime

router = APIRouter(prefix="/interviews", tags=["interviews"])

@router.post("/create")
def create_interview(
    data: InterviewCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    Schedule an interview for an application.
    Expected Role: Recruiter or Admin (checking if they own the job)
    """
    # 1. Check application & ownership
    app = db.query(Application).filter(Application.id == data.application_id).first()
    if not app:
        raise HTTPException(status_code=404, detail="Application not found")

    # Only the employer of the job (or Admin) can schedule
    if current_user.role != "admin" and app.job.employer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to schedule for this job")

    # 2. Create the Interview
    new_interview = Interview(
        application_id=data.application_id,
        scheduled_at=data.scheduled_at,
        location=data.location,
        notes=data.notes,
        status="scheduled"
    )
    db.add(new_interview)
    
    # 3. Update Application Status to interviewing
    app.status = ApplicationStatus.interviewing
    
    # 4. Create Notification for the candidate
    notif = Notification(
        user_id=app.candidate_id,
        message=f"You have a new interview scheduled for {app.job.title} at {data.scheduled_at.strftime('%Y-%m-%d %H:%M')}.",
        is_read=False
    )
    db.add(notif)
    
    db.commit()
    db.refresh(new_interview)
    
    return success_response(
        data=new_interview,
        message="Interview scheduled successfully"
    )
