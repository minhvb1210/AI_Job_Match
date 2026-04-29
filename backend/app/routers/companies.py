from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.responses import success_response, paginated_response
from app.models.models import Company, User, Job, Follower
from app.schemas.schemas import CompanyCreate, CompanyResponse, JobResponse
from app.core.auth import get_current_user, get_current_employer

router = APIRouter(prefix="/companies", tags=["Companies"])


@router.post("/")
def create_or_update_company(
    company: CompanyCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_employer),
):

    db_company = db.query(Company).filter(Company.employer_id == current_user.id).first()
    if db_company:
        for key, value in company.model_dump(exclude_unset=True).items():
            setattr(db_company, key, value)
    else:
        db_company = Company(**company.model_dump(), employer_id=current_user.id)
        db.add(db_company)

    db.commit()
    db.refresh(db_company)
    return success_response(
        data=CompanyResponse.model_validate(db_company).model_dump(),
        message="Company profile saved",
    )


@router.get("/my-company")
def get_my_company(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_employer),
):
    print(f"DEBUG: COMPANY API - GET /my-company for user: {current_user.email} (Role: {current_user.role})")
    db_company = db.query(Company).filter(Company.employer_id == current_user.id).first()
    if not db_company:
        print("DEBUG: COMPANY API - Company profile not found")
        raise HTTPException(status_code=404, detail="Company profile not found")

    print(f"DEBUG: COMPANY API - Found company: {db_company.name}")
    return success_response(data=CompanyResponse.model_validate(db_company).model_dump())


@router.post("/my-company")
@router.put("/my-company")
def create_or_update_my_company(
    company: CompanyCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_employer),
):
    print(f"DEBUG: COMPANY API - POST/PUT /my-company for user: {current_user.email}")
    db_company = db.query(Company).filter(Company.employer_id == current_user.id).first()
    
    if db_company:
        print(f"DEBUG: COMPANY API - Updating existing company: {db_company.name}")
        for key, value in company.model_dump(exclude_unset=True).items():
            setattr(db_company, key, value)
    else:
        print(f"DEBUG: COMPANY API - Creating new company: {company.name}")
        db_company = Company(**company.model_dump(), employer_id=current_user.id)
        db.add(db_company)

    db.commit()
    db.refresh(db_company)
    print("DEBUG: COMPANY API - Company profile saved successfully")
    return success_response(
        data=CompanyResponse.model_validate(db_company).model_dump(),
        message="Company profile saved",
    )


@router.get("/")
def get_all_companies(
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(get_db),
):
    query  = db.query(Company)
    total  = query.count()
    offset = (page - 1) * limit
    items  = query.offset(offset).limit(limit).all()
    return paginated_response(
        items=[CompanyResponse.model_validate(c).model_dump() for c in items],
        total=total,
        page=page,
        limit=limit,
    )


@router.get("/{company_id}")
def get_company(company_id: int, db: Session = Depends(get_db)):
    db_company = db.query(Company).filter(Company.id == company_id).first()
    if not db_company:
        raise HTTPException(status_code=404, detail="Company not found")
    return success_response(data=CompanyResponse.model_validate(db_company).model_dump())


@router.get("/{company_id}/jobs")
def get_company_jobs(
    company_id: int,
    page: int = 1,
    limit: int = 20,
    db: Session = Depends(get_db),
):
    company = db.query(Company).filter(Company.id == company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")

    query  = db.query(Job).filter(Job.company_id == company_id)
    total  = query.count()
    offset = (page - 1) * limit
    jobs   = query.offset(offset).limit(limit).all()
    return paginated_response(
        items=[JobResponse.model_validate(j).model_dump() for j in jobs],
        total=total,
        page=page,
        limit=limit,
    )


@router.post("/{company_id}/follow")
def follow_company(
    company_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if current_user.role != "candidate":
        raise HTTPException(status_code=403, detail="Only candidates can follow companies")

    company = db.query(Company).filter(Company.id == company_id).first()
    if not company:
        raise HTTPException(status_code=404, detail="Company not found")

    follow = db.query(Follower).filter(
        Follower.company_id == company_id,
        Follower.candidate_id == current_user.id,
    ).first()
    if follow:
        db.delete(follow)
        db.commit()
        return success_response(data={"is_following": False}, message="Unfollowed company")

    new_follow = Follower(company_id=company_id, candidate_id=current_user.id)
    db.add(new_follow)
    db.commit()
    return success_response(data={"is_following": True}, message="Followed company")


@router.get("/{company_id}/follow-status")
def get_follow_status(
    company_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    follow = db.query(Follower).filter(
        Follower.company_id == company_id,
        Follower.candidate_id == current_user.id,
    ).first()
    return success_response(data={"is_following": bool(follow)})
