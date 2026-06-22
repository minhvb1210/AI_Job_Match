"""Seed an admin user account. Password: 123456"""
from app.core.database import SessionLocal, engine, Base
from app.models.models import User, UserRole
from app.core.auth import get_password_hash

def seed_admin():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        existing = db.query(User).filter(User.email == "admin@test.com").first()
        if existing:
            # Make sure role is admin
            existing.role = UserRole.admin
            db.commit()
            print("Admin user already exists — role updated to admin.")
        else:
            admin = User(
                email="admin@test.com",
                hashed_password=get_password_hash("123456"),
                role=UserRole.admin,
                full_name="System Administrator",
            )
            db.add(admin)
            db.commit()
            print("Admin user created: admin@test.com / 123456")
    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_admin()
