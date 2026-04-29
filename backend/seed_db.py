import json
import logging
from app.core.database import SessionLocal, engine, Base
from app.models.models import Job, User, UserRole, CandidateProfile, Application, Interview, Company
from app.core.auth import get_password_hash
import datetime

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ai_jobmatch")

def seed_database():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    
    try:
        # ── 1. Create Default Users ──────────────────────────────────
        default_password = get_password_hash("123456")
        
        # Candidate
        candidate = db.query(User).filter(User.email == "candidate@test.com").first()
        if not candidate:
            candidate = User(
                email="candidate@test.com",
                hashed_password=default_password,
                role=UserRole.candidate,
                full_name="Alex Candidate"
            )
            db.add(candidate)
            db.flush()
            logger.info("Seeded candidate user")
        
        # ── 2. Create Companies and Recruiters ───────────────────────
        companies_data = [
            {"name": "Google", "location": "Mountain View, CA", "email": "recruiter@google.com", "desc": "Leading search engine and tech giant."},
            {"name": "Meta", "location": "Menlo Park, CA", "email": "recruiter@meta.com", "desc": "Social media and metaverse pioneer."},
            {"name": "Amazon", "location": "Seattle, WA", "email": "recruiter@amazon.com", "desc": "E-commerce and cloud computing leader."},
            {"name": "FPT Software", "location": "Hanoi, Vietnam", "email": "recruiter@fpt.com", "desc": "Global IT services and outsourcing company."},
            {"name": "Shopee", "location": "Singapore", "email": "recruiter@shopee.com", "desc": "Leading e-commerce platform in SE Asia."},
            {"name": "General Recruiter", "location": "Remote", "email": "recruiter@test.com", "desc": "Generic recruitment agency."}
        ]

        seeded_companies = []
        for c_data in companies_data:
            recruiter = db.query(User).filter(User.email == c_data["email"]).first()
            if not recruiter:
                recruiter = User(
                    email=c_data["email"],
                    hashed_password=default_password,
                    role=UserRole.recruiter,
                    full_name=f"{c_data['name']} HR"
                )
                db.add(recruiter)
                db.flush()
            
            company = db.query(Company).filter(Company.name == c_data["name"]).first()
            if not company:
                company = Company(
                    name=c_data["name"],
                    location=c_data["location"],
                    description=c_data["desc"],
                    employer_id=recruiter.id
                )
                db.add(company)
                db.flush()
                logger.info(f"Seeded company: {c_data['name']}")
            seeded_companies.append(company)
        
        db.commit()

        # ── 3. Load Jobs ──────────────────────────────────────────────
        jobs_to_seed = [
            {"title": "Senior Backend Engineer", "category": "IT", "skills": "Python,FastAPI,PostgreSQL", "salary": "$120k - $180k", "type": "Full-time", "company_idx": 0},
            {"title": "Machine Learning Research Scientist", "category": "AI", "skills": "PyTorch,TensorFlow,Scikit-Learn", "salary": "$150k - $220k", "type": "Remote", "company_idx": 1},
            {"title": "Cloud Architect", "category": "IT", "skills": "AWS,Docker,Kubernetes", "salary": "$140k - $200k", "type": "Full-time", "company_idx": 2},
            {"title": "Flutter Mobile Developer", "category": "IT", "skills": "Dart,Flutter,Firebase", "salary": "$80k - $120k", "type": "Full-time", "company_idx": 3},
            {"title": "Frontend Engineer (React)", "category": "IT", "skills": "React,TypeScript,Tailwind", "salary": "$90k - $140k", "type": "Part-time", "company_idx": 4},
            {"title": "Senior AI Developer", "category": "AI", "skills": "LLMs,LangChain,Python", "salary": "$130k - $190k", "type": "Remote", "company_idx": 0},
            {"title": "DevOps Engineer", "category": "IT", "skills": "CI/CD,Jenkins,Terraform", "salary": "$110k - $160k", "type": "Full-time", "company_idx": 1},
            {"title": "UI/UX Designer", "category": "Design", "skills": "Figma,Adobe XD,Prototyping", "salary": "$70k - $110k", "type": "Remote", "company_idx": 4},
            {"title": "Product Manager", "category": "Other", "skills": "Agile,Scrum,Roadmapping", "salary": "$100k - $150k", "type": "Full-time", "company_idx": 2},
            {"title": "Full-stack Developer", "category": "IT", "skills": "Node.js,React,MongoDB", "salary": "$95k - $145k", "type": "Full-time", "company_idx": 5},
        ]

        for j_data in jobs_to_seed:
            company = seeded_companies[j_data["company_idx"]]
            existing_job = db.query(Job).filter(Job.title == j_data["title"], Job.company_id == company.id).first()
            if not existing_job:
                new_job = Job(
                    title=j_data["title"],
                    company=company.name, # legacy string field
                    location=company.location,
                    salary=j_data["salary"],
                    description=f"Great opportunity at {company.name} for a {j_data['title']}.",
                    skills=j_data["skills"],
                    category=j_data["category"],
                    job_type=j_data["type"],
                    employer_id=company.employer_id,
                    company_id=company.id
                )
                db.add(new_job)
                logger.info(f"Seeded job: {j_data['title']} at {company.name}")
        
        db.commit()

        # ── 4. Create Candidate Profile ──────────────────────────────
        profile = db.query(CandidateProfile).filter(CandidateProfile.user_id == candidate.id).first()
        if not profile:
            profile = CandidateProfile(
                user_id=candidate.id,
                skills_text="Experienced Flutter developer with strong Dart and Firebase skills. Knowledgeable in Python and FastAPI for backend development. Passionate about AI and ML."
            )
            db.add(profile)
            logger.info("Seeded candidate profile")
        
        db.commit()
        print("Database re-seeded successfully.")

    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_database()
