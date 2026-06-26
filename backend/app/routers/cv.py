from fastapi import APIRouter, File, UploadFile, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.responses import success_response, error_response
from app.models.models import Job, CandidateProfile, User, CandidateEducation, CandidateExperience, CandidateProject
from app.schemas import schemas
from app.core.auth import get_current_user
# All AI utilities come from the modular package (via the shim keeps backward compat)
from app.services.ai_engine import (
    extract_text_from_pdf,
    extract_text_from_docx,
    extract_text_from_image,
    match_cv_to_jobs,
    # calculate_missing_skills is now embedded in match_cv_to_jobs result
)
from app.services.ai.scoring import extract_skills_from_cv

router = APIRouter(prefix="/cv", tags=["cv"])

@router.post("/upload-match")
async def upload_match_cv(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """Public endpoint for testing — no authentication required."""
    jobs = db.query(Job).all()
    if not jobs:
        return error_response(message="Jobs database is empty", data={"matches": []})

    file_bytes = await file.read()
    filename   = file.filename.lower()

    try:
        if filename.endswith(".pdf"):
            cv_text = extract_text_from_pdf(file_bytes)
        elif filename.endswith(".docx"):
            cv_text = extract_text_from_docx(file_bytes)
        elif filename.endswith((".png", ".jpg", ".jpeg")):
            cv_text = extract_text_from_image(file_bytes)
        else:
            return error_response(message="Unsupported file format.", data={"matches": []})
    except Exception as e:
        return error_response(message=f"Error parsing file: {str(e)}", data={"matches": []})

    if not cv_text.strip():
        return error_response(message="Could not extract text from the file.", data={"matches": []})

    results = match_cv_to_jobs(cv_text, jobs)

    formatted_results = []
    for res in results:
        job = res["job"]
        # missing_skills is already computed inside match_cv_to_jobs
        formatted_results.append({
            "score":          res["score"],
            "missing_skills": res.get("missing_skills", []),
            "job": {
                "id":       job.id,
                "title":    job.title,
                "company":  job.company,
                "location": job.location,
                "salary":   job.salary,
                "skills":   job.skills.split(",") if job.skills else [],
            },
        })

    # Extract skills actually found in the CV
    extracted_skills = extract_skills_from_cv(cv_text)

    # Aggregate top missing skills across all matched jobs (deduplicated)
    seen_gaps = set()
    top_skill_gaps = []
    for res in formatted_results:
        for skill in res.get("missing_skills", []):
            normalized = skill.strip().title()
            if normalized not in seen_gaps:
                seen_gaps.add(normalized)
                top_skill_gaps.append(normalized)
            if len(top_skill_gaps) >= 10:
                break
        if len(top_skill_gaps) >= 10:
            break

    return success_response(
        data={
            "extracted_text_preview": cv_text[:200] + "...",
            "extracted_skills": extracted_skills,
            "top_skill_gaps": top_skill_gaps,
            "matches": formatted_results,
        },
        message=f"Found {len(formatted_results)} matching jobs",
    )

@router.get("/saved-matches")
def get_saved_matches(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    profile = db.query(CandidateProfile).filter(CandidateProfile.user_id == current_user.id).first()
    if not profile or not profile.skills_text:
        return error_response(message="No saved profile found.", data={"matches": []})

    jobs = db.query(Job).all()
    if not jobs:
        return error_response(message="Jobs database is empty", data={"matches": []})

    results = match_cv_to_jobs(profile.skills_text, jobs)

    formatted_results = []
    for res in results:
        job = res["job"]
        formatted_results.append({
            "score":          res["score"],
            "missing_skills": res.get("missing_skills", []),
            "job": {
                "id":       job.id,
                "title":    job.title,
                "company":  job.company,
                "location": job.location,
                "salary":   job.salary,
                "skills":   job.skills.split(",") if job.skills else [],
            },
        })
    extracted_skills = extract_skills_from_cv(profile.skills_text)

    seen_gaps = set()
    top_skill_gaps = []
    for res in formatted_results:
        for skill in res.get("missing_skills", []):
            normalized = skill.strip().title()
            if normalized not in seen_gaps:
                seen_gaps.add(normalized)
                top_skill_gaps.append(normalized)
            if len(top_skill_gaps) >= 10:
                break
        if len(top_skill_gaps) >= 10:
            break

    return success_response(
        data={
            "extracted_text_preview": profile.skills_text[:200] + "...",
            "extracted_skills": extracted_skills,
            "top_skill_gaps": top_skill_gaps,
            "matches": formatted_results,
        },
        message=f"Found {len(formatted_results)} matching jobs",
    )

from pydantic import BaseModel
class ProfileUpdate(BaseModel):
    skills_text: str

from fastapi import BackgroundTasks

def recalculate_candidate_applications(candidate_id: int, cv_text: str):
    from app.core.database import SessionLocal
    from app.models.models import Application, Job
    from app.services.ai.scoring import explain_job_match
    
    if not cv_text.strip():
        return
        
    db = SessionLocal()
    try:
        apps = db.query(Application).filter(Application.candidate_id == candidate_id).all()
        if apps:
            all_jobs = db.query(Job).all()
            for app in apps:
                job = next((j for j in all_jobs if j.id == app.job_id), None)
                if job:
                    try:
                        breakdown = explain_job_match(cv_text=cv_text, job=job, jobs=all_jobs)
                        app.match_score = breakdown["final_score"]
                    except Exception:
                        pass
            db.commit()
    except Exception as e:
        import logging
        logging.error(f"Failed to recalculate application scores: {e}")
    finally:
        db.close()

@router.put("/profile")
@router.post("/save")
def save_profile(
    profile_update: ProfileUpdate, 
    background_tasks: BackgroundTasks,
    db: Session = Depends(get_db), 
    current_user: User = Depends(get_current_user)
):
    profile = db.query(CandidateProfile).filter(CandidateProfile.user_id == current_user.id).first()
    if not profile:
        profile = CandidateProfile(user_id=current_user.id, skills_text=profile_update.skills_text)
        db.add(profile)
    else:
        profile.skills_text = profile_update.skills_text

    db.commit()
    
    background_tasks.add_task(recalculate_candidate_applications, current_user.id, profile_update.skills_text)
    
    return success_response(message="Profile saved successfully.")

@router.get("/my-profile")
@router.get("/my-cv")
def get_my_profile(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    profile = db.query(CandidateProfile).filter(CandidateProfile.user_id == current_user.id).first()
    if not profile:
        profile = CandidateProfile(user_id=current_user.id, skills_text="")
        db.add(profile)
        db.commit()
        db.refresh(profile)
    
    # Return standard response plus 'raw_text' alias for frontend compatibility
    data = schemas.CandidateProfileResponse.model_validate(profile).model_dump()
    data['raw_text'] = profile.skills_text
    return success_response(data=data)


@router.get("/me")
def get_my_cv_info(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """Return the current user's CV profile or null if they haven't uploaded one."""
    profile = db.query(CandidateProfile).filter(CandidateProfile.user_id == current_user.id).first()
    if not profile or not profile.skills_text:
        return success_response(data=None, message="No CV profile found")
    
    return success_response(
        data={
            "id": profile.id,
            "skills_text_length": len(profile.skills_text),
            "created_at": None, # Profile doesn't have created_at field yet
        },
        message="CV profile found"
    )

@router.post("/education")
def add_education(edu: schemas.CandidateEducationBase, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    profile = db.query(CandidateProfile).filter(CandidateProfile.user_id == current_user.id).first()
    if not profile:
        profile = CandidateProfile(user_id=current_user.id)
        db.add(profile)
        db.commit()
        
    db_edu = CandidateEducation(**edu.dict(), profile_id=profile.id)
    db.add(db_edu)
    db.commit()
    db.refresh(db_edu)
    return success_response(data=schemas.CandidateEducationResponse.model_validate(db_edu).model_dump(), message="Education added")

@router.post("/experience")
def add_experience(exp: schemas.CandidateExperienceBase, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    profile = db.query(CandidateProfile).filter(CandidateProfile.user_id == current_user.id).first()
    if not profile:
        profile = CandidateProfile(user_id=current_user.id)
        db.add(profile)
        db.commit()
        
    db_exp = CandidateExperience(**exp.dict(), profile_id=profile.id)
    db.add(db_exp)
    db.commit()
    db.refresh(db_exp)
    return success_response(data=schemas.CandidateExperienceResponse.model_validate(db_exp).model_dump(), message="Experience added")

@router.post("/project")
def add_project(proj: schemas.CandidateProjectBase, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    profile = db.query(CandidateProfile).filter(CandidateProfile.user_id == current_user.id).first()
    if not profile:
        profile = CandidateProfile(user_id=current_user.id)
        db.add(profile)
        db.commit()
        
    db_proj = CandidateProject(**proj.dict(), profile_id=profile.id)
    db.add(db_proj)
    db.commit()
    db.refresh(db_proj)
    return success_response(data=schemas.CandidateProjectResponse.model_validate(db_proj).model_dump(), message="Project added")

