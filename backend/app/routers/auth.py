from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.responses import success_response
from app.models.models import User, UserRole
from app.schemas.schemas import UserCreate, UserLogin, UserResponse, Token
from app.core.auth import get_password_hash, verify_password, create_access_token

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/register")
def register(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    # Validate role against enum values
    valid_roles = [r.value for r in UserRole]
    if user.role not in valid_roles:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid role '{user.role}'. Must be one of: {valid_roles}",
        )

    hashed_pw = get_password_hash(user.password)
    new_user  = User(
        email=user.email,
        hashed_password=hashed_pw,
        role=UserRole(user.role),
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return success_response(
        data=UserResponse.model_validate(new_user).model_dump(),
        message="User registered successfully",
    )


@router.post("/login")
def login(user: UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect email or password",
        )

    try:
        is_valid = verify_password(user.password, db_user.hashed_password)
    except Exception as e:
        import logging
        logging.getLogger("ai_jobmatch").warning("verify_password error for %s: %s", user.email, e)
        is_valid = False

    if not is_valid:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect email or password",
        )

    print(f"DEBUG: USER LOGIN - Email: {db_user.email}, Role: {db_user.role}")
    access_token = create_access_token(
        data={"sub": db_user.email, "role": db_user.role.value if db_user.role else "candidate", "id": db_user.id}
    )
    return success_response(
        data={"access_token": access_token, "token_type": "bearer"},
        message="Login successful",
    )
