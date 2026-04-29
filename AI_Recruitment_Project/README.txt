AI Recruitment Platform - Submission Package

Project: AI Recruitment Platform
Version: 1.0 (Production Release)

==================================================
1. Project Overview
==================================================
The AI Recruitment Platform is a full-stack solution designed to streamline the hiring process using intelligent CV matching. It features a modern Flutter frontend (Web/Mobile compatible) and a robust FastAPI backend.

Key Features:
- AI-Powered CV Matching: TF-IDF and Cosine Similarity for precise job-candidate alignment.
- Dynamic Discovery: Intelligent job search with real-time filtering.
- Recruiter Command Center: Advanced dashboard for job management and applicant tracking.
- Brand Profile Builder: Employer branding and company profile management.
- Real-time Status Updates: Transparent application tracking for candidates.

==================================================
2. Tech Stack
==================================================
- Frontend: Flutter (Material Design, Shadcn UI components)
- Backend: FastAPI (Python 3.12)
- Database: SQLite (Production-ready MySQL migration scripts included)
- AI Engine: TF-IDF Vectorization, Cosine Similarity scoring
- Deployment: Docker & Docker Compose

==================================================
3. How to Run
==================================================

Backend:
1. Navigate to /backend
2. Ensure Docker is running
3. Run: docker-compose up -d
4. Seed database: python seed_db.py

Frontend (Source Build):
1. Navigate to /ai_job_match
2. Run: flutter pub get
3. Run: flutter run -d chrome (for Web) OR flutter build apk --release (for Android)

==================================================
4. Demo Accounts
==================================================

Candidate:
Email: demo_candidate@test.com
Password: 123456

Recruiter:
Email: recruiter@test.com
Password: 123456

==================================================
5. Note on APK Build
==================================================
The source code is fully configured for production (BaseUrl: 192.168.2.182:8000). To generate the APK, ensure the Android SDK is installed and run 'flutter build apk --release'.

==================================================
Submission Date: April 28, 2026
Status: GRADUATION READY
