from pydantic import BaseModel
from typing import List, Optional
from datetime import datetime

from app.models.models import UserRole, ApplicationStatus


# ─────────────────────────────────────────
# User Schemas
# ─────────────────────────────────────────
class UserBase(BaseModel):
    email: str
    role: UserRole = UserRole.candidate


class UserCreate(UserBase):
    password: str


class UserLogin(BaseModel):
    email: str
    password: str


class UserResponse(UserBase):
    id: int

    class Config:
        from_attributes = True


# ─────────────────────────────────────────
# Token Schemas
# ─────────────────────────────────────────
class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    email: Optional[str] = None
    role:  Optional[str] = None
    id:    Optional[int] = None


# ─────────────────────────────────────────
# Company Schemas
# ─────────────────────────────────────────
class CompanyBase(BaseModel):
    name:        str
    logo_url:    Optional[str] = None
    website:     Optional[str] = None
    location:    Optional[str] = None
    size:        Optional[str] = None
    description: Optional[str] = None


class CompanyCreate(CompanyBase):
    pass


class CompanyResponse(CompanyBase):
    id:          int
    employer_id: int

    class Config:
        from_attributes = True


# ─────────────────────────────────────────
# Job Schemas
# ─────────────────────────────────────────
class JobBase(BaseModel):
    title:            str
    company:          str
    location:         str
    salary:           str
    description:      str
    skills:           str
    salary_min:       Optional[float] = None
    salary_max:       Optional[float] = None
    job_type:         Optional[str] = None
    experience_level: Optional[str] = None
    category:         Optional[str] = None


class JobCreate(JobBase):
    pass


class JobResponse(JobBase):
    id:              int
    employer_id:     int
    company_id:      Optional[int] = None
    company_profile: Optional[CompanyResponse] = None

    class Config:
        from_attributes = True


# ─────────────────────────────────────────
# Application Schemas
# ─────────────────────────────────────────
class ApplicationBase(BaseModel):
    job_id:      int
    match_score: float = 0.0


class ApplicationCreate(ApplicationBase):
    pass


class ApplicationResponse(ApplicationBase):
    id:           int
    candidate_id: int
    status:       ApplicationStatus
    created_at:   Optional[datetime] = None

    class Config:
        from_attributes = True


# ─────────────────────────────────────────
# Candidate Profile Components
# ─────────────────────────────────────────
class CandidateEducationBase(BaseModel):
    school:      str
    degree:      str
    start_year:  str
    end_year:    str
    description: Optional[str] = None


class CandidateEducationResponse(CandidateEducationBase):
    id: int

    class Config:
        from_attributes = True


class CandidateExperienceBase(BaseModel):
    company:     str
    position:    str
    start_year:  str
    end_year:    str
    description: Optional[str] = None


class CandidateExperienceResponse(CandidateExperienceBase):
    id: int

    class Config:
        from_attributes = True


class CandidateProjectBase(BaseModel):
    name:        str
    link:        Optional[str] = None
    description: Optional[str] = None


class CandidateProjectResponse(CandidateProjectBase):
    id: int

    class Config:
        from_attributes = True


# ─────────────────────────────────────────
# Candidate Profile Schemas
# ─────────────────────────────────────────
class CandidateProfileBase(BaseModel):
    skills_text: str


class CandidateProfileResponse(CandidateProfileBase):
    id:          int
    user_id:     int
    educations:  List[CandidateEducationResponse] = []
    experiences: List[CandidateExperienceResponse] = []
    projects:    List[CandidateProjectResponse] = []

    class Config:
        from_attributes = True


# ─────────────────────────────────────────
# Notification & Follower
# ─────────────────────────────────────────
class NotificationResponse(BaseModel):
    id:      int
    message: str
    is_read: bool

    class Config:
        from_attributes = True


class FollowerResponse(BaseModel):
    id:           int
    company_id:   int
    candidate_id: int

    class Config:
        from_attributes = True


# ─────────────────────────────────────────
# Interview Schemas
# ─────────────────────────────────────────
class InterviewCreate(BaseModel):
    application_id:  int
    scheduled_at:    datetime
    location:        Optional[str] = None
    notes:           Optional[str] = None


class InterviewResponse(BaseModel):
    id:             int
    application_id: int
    scheduled_at:   datetime
    location:       Optional[str] = None
    notes:          Optional[str] = None
    status:         str

    class Config:
        from_attributes = True


# ─────────────────────────────────────────
# Dashboard & AI Schemas
# ─────────────────────────────────────────
class DashboardStatsResponse(BaseModel):
    total_jobs:         int
    total_applications: int
    success_rate:      float
    average_match_score: float
    top_industries:    List[dict]
    upcoming_interviews: List[dict] = []
    top_candidate: Optional[dict] = None


class CvSuggestionResponse(BaseModel):
    suggestions: List[str]
