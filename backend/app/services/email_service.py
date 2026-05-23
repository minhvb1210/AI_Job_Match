import os
from fastapi_mail import ConnectionConfig, FastMail, MessageSchema, MessageType
from pydantic import EmailStr
from dotenv import load_dotenv

load_dotenv()

conf = ConnectionConfig(
    MAIL_USERNAME=os.getenv("MAIL_USERNAME"),
    MAIL_PASSWORD=os.getenv("MAIL_PASSWORD"),
    MAIL_FROM=os.getenv("MAIL_FROM"),
    MAIL_PORT=int(os.getenv("MAIL_PORT", 587)),
    MAIL_SERVER=os.getenv("MAIL_SERVER"),
    MAIL_FROM_NAME=os.getenv("MAIL_FROM_NAME"),
    MAIL_STARTTLS=True,
    MAIL_SSL_TLS=False,
    USE_CREDENTIALS=True,
    VALIDATE_CERTS=True
)

class EmailService:
    @staticmethod
    async def send_application_notification(
        recruiter_email: str,
        candidate_name: str,
        candidate_email: str,
        job_title: str,
        match_score: float,
        cv_link: str = "N/A"
    ):
        html = f"""
        <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
            <h2 style="color: #4F46E5;">New Job Application Received</h2>
            <p>Hello,</p>
            <p>A new candidate has applied for the position: <strong>{job_title}</strong></p>
            <div style="background-color: #F3F4F6; padding: 15px; border-radius: 8px;">
                <p><strong>Candidate:</strong> {candidate_name}</p>
                <p><strong>Email:</strong> {candidate_email}</p>
                <p><strong>AI Match Score:</strong> <span style="color: #059669; font-weight: bold;">{match_score}%</span></p>
                <p><strong>Resume Link:</strong> <a href="{cv_link}">View Resume</a></p>
            </div>
            <p style="margin-top: 20px;">Please login to the Recruiter Portal to review the application.</p>
            <hr style="border: 0; border-top: 1px solid #EEE;">
            <p style="font-size: 12px; color: #666;">AI Recruitment Platform - Automated Notification</p>
        </div>
        """
        
        message = MessageSchema(
            subject=f"New Application: {candidate_name} for {job_title}",
            recipients=[recruiter_email],
            body=html,
            subtype=MessageType.html
        )
        
        fm = FastMail(conf)
        await fm.send_message(message)

    @staticmethod
    async def send_interview_invitation(
        candidate_email: str,
        candidate_name: str,
        job_title: str,
        interview_date: str,
        interview_time: str,
        location: str,
        recruiter_name: str
    ):
        html = f"""
        <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
            <h2 style="color: #4F46E5;">Interview Invitation</h2>
            <p>Dear {candidate_name},</p>
            <p>Congratulations! We have reviewed your application for <strong>{job_title}</strong> and would like to invite you for an interview.</p>
            <div style="border-left: 4px solid #4F46E5; padding-left: 15px; margin: 20px 0;">
                <p><strong>Date:</strong> {interview_date}</p>
                <p><strong>Time:</strong> {interview_time}</p>
                <p><strong>Location/Link:</strong> {location}</p>
            </div>
            <p>Please confirm your availability by replying to this email or through our platform.</p>
            <p>Best regards,<br>{recruiter_name}</p>
        </div>
        """
        
        message = MessageSchema(
            subject=f"Interview Invitation: {job_title} position",
            recipients=[candidate_email],
            body=html,
            subtype=MessageType.html
        )
        
        fm = FastMail(conf)
        await fm.send_message(message)
