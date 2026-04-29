import enum
import datetime
from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, Text, DateTime, Enum as SAEnum
from sqlalchemy.orm import relationship

from app.core.database import Base


# ─────────────────────────────────────────
# Python Enums
# ─────────────────────────────────────────
class UserRole(str, enum.Enum):
    candidate = "candidate"
    recruiter = "recruiter"
    admin     = "admin"


class ApplicationStatus(str, enum.Enum):
    pending   = "pending"
    reviewing = "reviewing"
    interviewing = "interviewing"
    accepted  = "accepted"
    rejected  = "rejected"


class InterviewStatus(str, enum.Enum):
    scheduled = "scheduled"
    done      = "done"
    cancelled = "cancelled"


# ─────────────────────────────────────────
# Models
# ─────────────────────────────────────────
class User(Base):
    __tablename__ = "users"

    id              = Column(Integer, primary_key=True, index=True)
    email           = Column(String(255), unique=True, index=True)
    hashed_password = Column(String(255))
    # native_enum=False → stored as VARCHAR in MySQL (no ALTER TABLE needed for new values)
    role            = Column(SAEnum(UserRole, native_enum=False), default=UserRole.candidate)

    # Common Info
    full_name    = Column(String(255), nullable=True)
    phone_number = Column(String(50), nullable=True)
    address      = Column(String(500), nullable=True)
    avatar_url   = Column(String(500), nullable=True)

    # Legacy employer fields (kept for backward compat)
    company_name        = Column(String(255), nullable=True)
    company_description = Column(Text, nullable=True)
    company_logo        = Column(String(500), nullable=True)

    # Relationships — cascade delete-orphan only where records have no standalone meaning
    profile       = relationship("CandidateProfile", back_populates="user",
                                  uselist=False, cascade="all, delete-orphan")
    notifications = relationship("Notification", back_populates="user",
                                  cascade="all, delete-orphan")
    saved_jobs    = relationship("SavedJob", back_populates="candidate",
                                  cascade="all, delete-orphan")
    followers     = relationship("Follower", foreign_keys="Follower.candidate_id",
                                  back_populates="candidate", cascade="all, delete-orphan")
    company       = relationship("Company", back_populates="employer", uselist=False)

    # Applications preserved — NO delete-orphan (preserve history)
    jobs          = relationship("Job", back_populates="employer")
    applications  = relationship("Application", back_populates="candidate")


class Company(Base):
    __tablename__ = "companies"

    id          = Column(Integer, primary_key=True, index=True)
    employer_id = Column(Integer, ForeignKey("users.id"), unique=True)
    name        = Column(String(255), index=True)
    logo_url    = Column(String(500), nullable=True)
    website     = Column(String(500), nullable=True)
    location    = Column(String(255), nullable=True)
    size        = Column(String(50), nullable=True)
    description = Column(Text, nullable=True)

    employer  = relationship("User", back_populates="company")
    # Jobs preserved — NO delete-orphan (job listings outlive company profile edits)
    jobs      = relationship("Job", back_populates="company_profile")
    followers = relationship("Follower", foreign_keys="Follower.company_id",
                              back_populates="company", cascade="all, delete-orphan")


class CandidateProfile(Base):
    __tablename__ = "candidate_profiles"

    id          = Column(Integer, primary_key=True, index=True)
    user_id     = Column(Integer, ForeignKey("users.id"))
    skills_text = Column(Text, default="")

    user        = relationship("User", back_populates="profile")
    educations  = relationship("CandidateEducation", back_populates="profile",
                                cascade="all, delete-orphan")
    experiences = relationship("CandidateExperience", back_populates="profile",
                                cascade="all, delete-orphan")
    projects    = relationship("CandidateProject", back_populates="profile",
                                cascade="all, delete-orphan")


class CandidateEducation(Base):
    __tablename__ = "candidate_educations"

    id          = Column(Integer, primary_key=True, index=True)
    profile_id  = Column(Integer, ForeignKey("candidate_profiles.id"))
    school      = Column(String(255))
    degree      = Column(String(255))
    start_year  = Column(String(10))
    end_year    = Column(String(10))
    description = Column(Text, nullable=True)

    profile = relationship("CandidateProfile", back_populates="educations")


class CandidateExperience(Base):
    __tablename__ = "candidate_experiences"

    id          = Column(Integer, primary_key=True, index=True)
    profile_id  = Column(Integer, ForeignKey("candidate_profiles.id"))
    company     = Column(String(255))
    position    = Column(String(255))
    start_year  = Column(String(10))
    end_year    = Column(String(10))
    description = Column(Text, nullable=True)

    profile = relationship("CandidateProfile", back_populates="experiences")


class CandidateProject(Base):
    __tablename__ = "candidate_projects"

    id          = Column(Integer, primary_key=True, index=True)
    profile_id  = Column(Integer, ForeignKey("candidate_profiles.id"))
    name        = Column(String(255))
    link        = Column(String(500), nullable=True)
    description = Column(Text, nullable=True)

    profile = relationship("CandidateProfile", back_populates="projects")


class Notification(Base):
    __tablename__ = "notifications"

    id         = Column(Integer, primary_key=True, index=True)
    user_id    = Column(Integer, ForeignKey("users.id"))
    message    = Column(String(1000))
    is_read    = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

    user = relationship("User", back_populates="notifications")


class Follower(Base):
    __tablename__ = "followers"

    id           = Column(Integer, primary_key=True, index=True)
    company_id   = Column(Integer, ForeignKey("companies.id"))
    candidate_id = Column(Integer, ForeignKey("users.id"))

    company   = relationship("Company", foreign_keys=[company_id], back_populates="followers")
    candidate = relationship("User", foreign_keys=[candidate_id], back_populates="followers")


class Job(Base):
    __tablename__ = "jobs"

    id               = Column(Integer, primary_key=True, index=True)
    title            = Column(String(255), index=True)
    company          = Column(String(255))   # Legacy string field
    location         = Column(String(255))
    salary           = Column(String(100))   # Legacy string
    salary_min       = Column(Float, nullable=True)
    salary_max       = Column(Float, nullable=True)
    job_type         = Column(String(50), nullable=True)   # Full-time, Part-time, Remote
    experience_level = Column(String(50), nullable=True)   # Intern, Fresher, Junior…
    category         = Column(String(100), nullable=True)  # IT, Marketing, Sales…
    description      = Column(Text)
    skills           = Column(String(1000))

    employer_id = Column(Integer, ForeignKey("users.id"))
    company_id  = Column(Integer, ForeignKey("companies.id"), nullable=True)

    employer         = relationship("User", back_populates="jobs")
    company_profile  = relationship("Company", back_populates="jobs")
    # Applications preserved — NO delete-orphan (preserve history when job is deleted)
    applications     = relationship("Application", back_populates="job")
    # SavedJob entries are ephemeral — safe to cascade
    saved_by         = relationship("SavedJob", back_populates="job",
                                     cascade="all, delete-orphan")


class Application(Base):
    __tablename__ = "applications"

    id           = Column(Integer, primary_key=True, index=True)
    job_id       = Column(Integer, ForeignKey("jobs.id"))
    candidate_id = Column(Integer, ForeignKey("users.id"))
    # native_enum=False → VARCHAR storage for MySQL compat
    status       = Column(SAEnum(ApplicationStatus, native_enum=False),
                           default=ApplicationStatus.pending)
    match_score  = Column(Float, default=0.0)
    created_at   = Column(DateTime, default=datetime.datetime.utcnow)

    job       = relationship("Job", back_populates="applications")
    candidate = relationship("User", back_populates="applications")
    interview = relationship("Interview", back_populates="application", uselist=False, cascade="all, delete-orphan")


class SavedJob(Base):
    __tablename__ = "saved_jobs"

    id           = Column(Integer, primary_key=True, index=True)
    job_id       = Column(Integer, ForeignKey("jobs.id"))
    candidate_id = Column(Integer, ForeignKey("users.id"))
    created_at   = Column(DateTime, default=datetime.datetime.utcnow)

    job       = relationship("Job", back_populates="saved_by")
    candidate = relationship("User", back_populates="saved_jobs")


class Interview(Base):
    __tablename__ = "interviews"

    id             = Column(Integer, primary_key=True, index=True)
    application_id = Column(Integer, ForeignKey("applications.id"))
    scheduled_time = Column(DateTime)
    location       = Column(String(500))
    note           = Column(Text, nullable=True)
    status         = Column(SAEnum(InterviewStatus, native_enum=False), default=InterviewStatus.scheduled)
    created_at     = Column(DateTime, default=datetime.datetime.utcnow)

    application = relationship("Application", back_populates="interview", uselist=False)
