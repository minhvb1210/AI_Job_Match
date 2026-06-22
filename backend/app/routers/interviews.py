from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from datetime import datetime
from pydantic import BaseModel

from app.core.database import get_db
from app.core.responses import success_response
from app.models.models import Application, User, Job, Interview, Notification, ApplicationStatus, InterviewStatus
from app.core.auth import get_current_employer
from app.services.email_service import EmailService
import asyncio

router = APIRouter(prefix="/interviews", tags=["interviews"])

from app.schemas.schemas import InterviewCreate

@router.post("/schedule")
async def schedule_interview(
    data: InterviewCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_employer)
):
    # 1. Verify application ownership
    app = db.query(Application).filter(Application.id == data.application_id).first()
    if not app:
        raise HTTPException(status_code=404, detail="Application not found")
    
    job = db.query(Job).filter(Job.id == app.job_id).first()
    if job.employer_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized")

    # 2. Update application status
    app.status = ApplicationStatus.interviewing
    
    # 3. Create Interview record
    try:
        dt = datetime.fromisoformat(data.scheduled_time.replace("Z", "+00:00"))
    except:
        raise HTTPException(status_code=400, detail="Invalid date format")

    interview = Interview(
        application_id=app.id,
        scheduled_time=dt,
        location=data.location,
        note=data.note,
        status=InterviewStatus.scheduled
    )
    db.add(interview)

    # 4. Create in-app notification for candidate
    candidate = db.query(User).filter(User.id == app.candidate_id).first()
    recruiter_name = current_user.full_name or current_user.email
    notification = Notification(
        user_id=app.candidate_id,
        message=f"📅 Interview scheduled for '{job.title}' on {dt.strftime('%b %d, %Y at %H:%M')}. Location: {data.location or 'TBD'}. Scheduled by {recruiter_name}.",
    )
    db.add(notification)

    db.commit()
    db.refresh(interview)

    # 5. Send Email to Candidate (async, non-blocking)
    if candidate:
        asyncio.create_task(EmailService.send_interview_invitation(
            candidate_email=candidate.email,
            candidate_name=candidate.full_name or "Candidate",
            job_title=job.title,
            interview_date=dt.strftime("%Y-%m-%d"),
            interview_time=dt.strftime("%H:%M"),
            location=data.location,
            recruiter_name=recruiter_name
        ))

    return success_response(
        data={"interview_id": interview.id, "status": "scheduled"},
        message="Interview scheduled and invitation email sent."
    )

