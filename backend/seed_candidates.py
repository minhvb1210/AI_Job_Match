"""
Seed realistic candidate profiles for AI Talent Sourcing demo.
Adds 8 diverse candidates with rich CV data across multiple industries.
Password for all: 123456
"""
from app.core.database import SessionLocal, engine, Base
from app.models.models import User, UserRole, CandidateProfile
from app.core.auth import get_password_hash

CANDIDATES = [
    {
        "email": "nguyenvana@demo.com",
        "full_name": "Nguyen Van A",
        "phone": "0901234567",
        "cv": (
            "Software Engineer with 3 years of experience in Python, FastAPI, Django and Flask. "
            "Strong backend development skills including REST API design, database optimization with PostgreSQL and MySQL. "
            "Experience with Docker, Docker Compose, CI/CD pipelines using GitHub Actions. "
            "Knowledge of cloud services AWS EC2, S3, Lambda. Built microservices architecture serving 10k+ users. "
            "Familiar with Redis caching, message queues RabbitMQ. Unit testing with pytest. "
            "Education: BSc Computer Science, Vietnam National University."
        ),
    },
    {
        "email": "tranthib@demo.com",
        "full_name": "Tran Thi B",
        "phone": "0912345678",
        "cv": (
            "Frontend Developer specializing in React, TypeScript and Next.js with 2 years of professional experience. "
            "Proficient in modern CSS frameworks including Tailwind CSS, Styled Components, and responsive design. "
            "Experience building single-page applications, Progressive Web Apps, and e-commerce platforms. "
            "Strong knowledge of state management with Redux, Zustand, and React Query. "
            "Familiar with Figma for UI/UX collaboration. Experience with Git, Agile/Scrum methodology. "
            "Contributed to open source projects on GitHub. Graduated from Da Nang University of Technology."
        ),
    },
    {
        "email": "lequangc@demo.com",
        "full_name": "Le Quang C",
        "phone": "0923456789",
        "cv": (
            "Flutter Mobile Developer with expertise in Dart, Flutter, and cross-platform mobile development. "
            "Published 5 apps on Google Play Store with 50k+ combined downloads. "
            "Strong experience with Firebase Authentication, Firestore, Cloud Messaging, and Crashlytics. "
            "Backend integration using REST APIs and GraphQL. State management with Provider and Riverpod. "
            "Knowledge of native Android (Kotlin) and iOS (Swift) for platform-specific integrations. "
            "Experience with CI/CD using Codemagic and Fastlane. GoRouter for navigation. "
            "Education: BSc Software Engineering, VKU University."
        ),
    },
    {
        "email": "phamthid@demo.com",
        "full_name": "Pham Thi D",
        "phone": "0934567890",
        "cv": (
            "Data Scientist and Machine Learning Engineer with 4 years of experience in NLP and Computer Vision. "
            "Expert in Python, PyTorch, TensorFlow, Scikit-Learn, and Hugging Face Transformers. "
            "Built and deployed BERT-based text classification models achieving 95% accuracy. "
            "Experience with recommendation systems using collaborative filtering and content-based methods. "
            "Strong skills in data preprocessing with Pandas, NumPy, and feature engineering. "
            "Deployed ML models using FastAPI, Docker, and AWS SageMaker. "
            "Published 2 research papers on Vietnamese NLP at international conferences. "
            "MSc Artificial Intelligence, Ho Chi Minh City University of Technology."
        ),
    },
    {
        "email": "hoangmine@demo.com",
        "full_name": "Hoang Minh E",
        "phone": "0945678901",
        "cv": (
            "DevOps Engineer with 3 years managing cloud infrastructure on AWS and Google Cloud Platform. "
            "Expert in Docker, Kubernetes, Terraform, and Ansible for infrastructure automation. "
            "Built CI/CD pipelines using Jenkins, GitHub Actions, GitLab CI reducing deployment time by 70%. "
            "Monitoring and observability with Prometheus, Grafana, and ELK Stack. "
            "Experience with networking, load balancing, and security (SSL/TLS, WAF, IAM policies). "
            "Automated infrastructure provisioning with Terraform managing 200+ cloud resources. "
            "Linux system administration (Ubuntu, CentOS). Shell scripting (Bash, Python). "
            "BSc Information Technology, Hanoi University of Science and Technology."
        ),
    },
    {
        "email": "vuthif@demo.com",
        "full_name": "Vu Thi F",
        "phone": "0956789012",
        "cv": (
            "UI/UX Designer with 3 years of experience creating user-centered digital products. "
            "Expert in Figma, Adobe XD, Sketch, and prototyping tools like InVision and Principle. "
            "Conducted user research, usability testing, and A/B testing for mobile and web applications. "
            "Created design systems and component libraries for enterprise SaaS products. "
            "Strong understanding of interaction design, information architecture, and accessibility standards (WCAG). "
            "Collaboration with development teams using Agile methodology, Jira, and Confluence. "
            "Portfolio includes redesign of banking app increasing user engagement by 40%. "
            "BA Design, Ho Chi Minh City University of Fine Arts."
        ),
    },
    {
        "email": "dangvangg@demo.com",
        "full_name": "Dang Van G",
        "phone": "0967890123",
        "cv": (
            "Full-stack Developer with 3 years of experience in Node.js, Express, React, and MongoDB. "
            "Built RESTful APIs and real-time applications using Socket.IO and WebSocket. "
            "Experience with both SQL (PostgreSQL, MySQL) and NoSQL (MongoDB, Redis) databases. "
            "Frontend skills include React, Next.js, Vue.js, and Tailwind CSS. "
            "Implemented authentication systems with JWT, OAuth 2.0, and Firebase Auth. "
            "Experience with payment integration (Stripe, VNPay) and third-party API integrations. "
            "Agile development, code review, and mentoring junior developers. "
            "BSc Computer Science, Can Tho University."
        ),
    },
    {
        "email": "ngothih@demo.com",
        "full_name": "Ngo Thi H",
        "phone": "0978901234",
        "cv": (
            "QA Automation Engineer with 2 years of experience in software testing and quality assurance. "
            "Expert in Selenium WebDriver, Cypress, and Appium for web and mobile test automation. "
            "Writing test scripts in Python and JavaScript with pytest and Jest frameworks. "
            "Experience with API testing using Postman, REST Assured, and automated regression suites. "
            "Performance testing with JMeter and load testing with k6. "
            "Knowledge of CI/CD integration for automated test execution with Jenkins and GitHub Actions. "
            "Strong understanding of SDLC, Agile methodology, and bug tracking with Jira. "
            "BSc Information Technology, Da Nang University."
        ),
    },
]


def seed_candidates():
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    password_hash = get_password_hash("123456")
    added = 0

    try:
        for c in CANDIDATES:
            existing = db.query(User).filter(User.email == c["email"]).first()
            if existing:
                # Update CV if profile exists but has no CV
                profile = db.query(CandidateProfile).filter(CandidateProfile.user_id == existing.id).first()
                if profile and (not profile.skills_text or len(profile.skills_text) < 10):
                    profile.skills_text = c["cv"]
                    added += 1
                    print(f"  Updated CV for {c['email']}")
                elif not profile:
                    profile = CandidateProfile(user_id=existing.id, skills_text=c["cv"])
                    db.add(profile)
                    added += 1
                    print(f"  Created profile for existing user {c['email']}")
                else:
                    print(f"  Skipped {c['email']} (already has CV)")
                continue

            # Create new user
            user = User(
                email=c["email"],
                hashed_password=password_hash,
                role=UserRole.candidate,
                full_name=c["full_name"],
                phone_number=c.get("phone"),
            )
            db.add(user)
            db.flush()

            # Create profile with rich CV
            profile = CandidateProfile(user_id=user.id, skills_text=c["cv"])
            db.add(profile)
            added += 1
            print(f"  Added candidate: {c['full_name']} ({c['email']})")

        db.commit()
        print(f"\nDone! Added/updated {added} candidate profiles.")
        
        # Verify
        total = db.query(CandidateProfile).count()
        with_cv = db.query(CandidateProfile).filter(CandidateProfile.skills_text != "", CandidateProfile.skills_text != None).count()
        print(f"Total profiles: {total} | With CV data: {with_cv}")

    except Exception as e:
        db.rollback()
        print(f"Error: {e}")
    finally:
        db.close()


if __name__ == "__main__":
    seed_candidates()
