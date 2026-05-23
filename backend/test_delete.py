"""
Test script to verify DELETE /jobs/{job_id} authorization flow.

Tests:
  1. Login as a recruiter
  2. Fetch only MY jobs via /jobs/my-jobs 
  3. Create a new job (owned by us)
  4. Delete the new job (should succeed — owner match)
  5. Try to delete Job 2 (owned by a different recruiter — should fail with 403)
"""
import requests

BASE_URL = "http://127.0.0.1:8000"


def test_delete():
    # ── 1. Login as recruiter@test.com ─────────────────────────────
    print("=" * 60)
    print("STEP 1: Login as recruiter@test.com")
    resp = requests.post(f"{BASE_URL}/auth/login", json={"email": "recruiter@test.com", "password": "123456"})
    if resp.status_code != 200:
        print(f"  ❌ Login failed ({resp.status_code}): {resp.text}")
        return
    token = resp.json()["data"]["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    print(f"  ✅ Login successful. Token: {token[:30]}...")

    # ── 2. Fetch MY jobs (should only show jobs I own) ─────────────
    print("\nSTEP 2: Fetch /jobs/my-jobs")
    resp = requests.get(f"{BASE_URL}/jobs/my-jobs", headers=headers)
    if resp.status_code == 200:
        my_jobs = resp.json().get("data", {}).get("items", [])
        print(f"  ✅ Found {len(my_jobs)} of my jobs:")
        for j in my_jobs:
            print(f"     - Job ID={j['id']}: {j['title']} (employer_id={j['employer_id']})")
    else:
        print(f"  ❌ Failed ({resp.status_code}): {resp.text}")

    # ── 3. Create a new job ────────────────────────────────────────
    print("\nSTEP 3: Create a new test job")
    job_payload = {
        "title": "DELETE TEST JOB",
        "company": "Test Company",
        "location": "Remote",
        "salary": "100k",
        "job_type": "Full-time",
        "category": "IT",
        "experience_level": "Junior",
        "description": "A temporary job to test deletion",
        "skills": "Python",
    }
    resp = requests.post(f"{BASE_URL}/jobs/", json=job_payload, headers=headers)
    if resp.status_code != 200:
        print(f"  ❌ Create failed ({resp.status_code}): {resp.text}")
        return
    new_job_id = resp.json()["data"]["id"]
    print(f"  ✅ Created Job ID: {new_job_id}")

    # ── 4. Delete the job we just created (should SUCCEED) ─────────
    print(f"\nSTEP 4: Delete Job {new_job_id} (owned by us → should succeed)")
    resp = requests.delete(f"{BASE_URL}/jobs/{new_job_id}", headers=headers)
    print(f"  Status: {resp.status_code}")
    print(f"  Body:   {resp.json()}")
    if resp.status_code == 200:
        print(f"  ✅ Delete succeeded!")
    else:
        print(f"  ❌ Delete failed unexpectedly!")

    # ── 5. Try to delete Job 2 (owned by recruiter@meta.com → should FAIL) ──
    print(f"\nSTEP 5: Delete Job 2 (NOT owned by us → should fail with 403)")
    resp = requests.delete(f"{BASE_URL}/jobs/2", headers=headers)
    print(f"  Status: {resp.status_code}")
    print(f"  Body:   {resp.json()}")
    if resp.status_code == 403:
        print(f"  ✅ Correctly denied! Ownership check works.")
    else:
        print(f"  ❌ Unexpected result — ownership check may be broken!")

    print("\n" + "=" * 60)
    print("TEST COMPLETE")


if __name__ == "__main__":
    test_delete()
