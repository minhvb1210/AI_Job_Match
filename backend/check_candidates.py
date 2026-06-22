"""Quick check: how many candidate profiles exist and have CV data."""
from app.core.database import SessionLocal
from app.models.models import CandidateProfile, User

db = SessionLocal()

# 1. Count candidate users
candidates = db.query(User).filter(User.role == "candidate").all()
print(f"Total candidate users: {len(candidates)}")

# 2. Count candidate profiles
profiles = db.query(CandidateProfile).all()
print(f"Total CandidateProfiles: {len(profiles)}")

# 3. Check which have actual CV text
for p in profiles:
    txt = p.skills_text or ""
    user = db.query(User).filter(User.id == p.user_id).first()
    email = user.email if user else "N/A"
    print(f"  Profile #{p.id} | user={email} | skills_len={len(txt)} | has_cv={'YES' if len(txt) > 10 else 'NO'}")
    if len(txt) > 10:
        print(f"    Preview: {txt[:120]}...")

db.close()
