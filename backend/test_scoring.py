from app.core.database import SessionLocal
from app.models.models import Job
from app.services.ai.scoring import match_cv_to_jobs

db = SessionLocal()
jobs = db.query(Job).all()
print(f"Total jobs: {len(jobs)}")

# CV 1: Software Engineer (Java, C++, Python)
cv1 = "Experienced Software Engineer with 5+ years of experience in developing high-quality software solutions. Highly skilled in Java C++ and Python. Coding Debugging Algorithms Database Agile Object-Oriented"
results1 = match_cv_to_jobs(cv1, jobs)
print("\n=== CV1: Software Engineer ===")
for r in results1[:5]:
    print(f"  {r['job'].title}: {r['score']}%")

# CV 2: Community Manager (French, social media)
cv2 = "Community Manager. Passionnee par les reseaux sociaux et la creation de contenu. Reseaux Sociaux Creation de contenu Analyse des donnees Strategies de croissance Gestion de crise en ligne Referencement"
results2 = match_cv_to_jobs(cv2, jobs)
print("\n=== CV2: Community Manager ===")
for r in results2[:5]:
    print(f"  {r['job'].title}: {r['score']}%")

print("\n=== COMPARISON ===")
print(f"CV1 top job: {results1[0]['job'].title} = {results1[0]['score']}%" if results1 else "CV1: no results")
print(f"CV2 top job: {results2[0]['job'].title} = {results2[0]['score']}%" if results2 else "CV2: no results")
same = [r["job"].id for r in results1[:3]] == [r["job"].id for r in results2[:3]]
print(f"Same top 3? {same}")
