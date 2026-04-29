import sqlite3

def alter_db():
    conn = sqlite3.connect("ai_job_match.db")
    cursor = conn.cursor()
    
    # create companies table
    cursor.execute('''CREATE TABLE IF NOT EXISTS companies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        employer_id INTEGER UNIQUE REFERENCES users(id),
        name VARCHAR,
        logo_url VARCHAR,
        website VARCHAR,
        location VARCHAR,
        size VARCHAR,
        description TEXT
    )''')
    # create new tables for CV Builder and Notifications
    cursor.executescript('''
        CREATE TABLE IF NOT EXISTS candidate_educations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER REFERENCES candidate_profiles(id),
            school VARCHAR,
            degree VARCHAR,
            start_year VARCHAR,
            end_year VARCHAR,
            description TEXT
        );
        CREATE TABLE IF NOT EXISTS candidate_experiences (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER REFERENCES candidate_profiles(id),
            company VARCHAR,
            position VARCHAR,
            start_year VARCHAR,
            end_year VARCHAR,
            description TEXT
        );
        CREATE TABLE IF NOT EXISTS candidate_projects (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            profile_id INTEGER REFERENCES candidate_profiles(id),
            name VARCHAR,
            link VARCHAR,
            description TEXT
        );
        CREATE TABLE IF NOT EXISTS notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER REFERENCES users(id),
            message VARCHAR,
            is_read BOOLEAN DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        );
        CREATE TABLE IF NOT EXISTS followers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            company_id INTEGER REFERENCES companies(id),
            candidate_id INTEGER REFERENCES users(id)
        );
    ''')
    print("Ensured new CV and Notification tables exist.")
    
    users_columns = [
        "full_name VARCHAR", 
        "phone_number VARCHAR", 
        "address VARCHAR", 
        "avatar_url VARCHAR", 
        "company_name VARCHAR", 
        "company_description TEXT", 
        "company_logo VARCHAR"
    ]
    
    jobs_columns = [
        "salary_min FLOAT",
        "salary_max FLOAT",
        "job_type VARCHAR",
        "experience_level VARCHAR",
        "category VARCHAR",
        "company_id INTEGER REFERENCES companies(id)"
    ]
    
    for col_def in users_columns:
        try:
            cursor.execute(f"ALTER TABLE users ADD COLUMN {col_def}")
            print(f"Added column {col_def} to users")
        except sqlite3.OperationalError as e:
            if "duplicate column name" in str(e).lower():
                pass
            else:
                print(f"Error adding {col_def} to users: {e}")
                
    for col_def in jobs_columns:
        try:
            cursor.execute(f"ALTER TABLE jobs ADD COLUMN {col_def}")
            print(f"Added column {col_def} to jobs")
        except sqlite3.OperationalError as e:
            if "duplicate column name" in str(e).lower():
                pass
            else:
                print(f"Error adding {col_def} to jobs: {e}")
                
    conn.commit()
    conn.close()

if __name__ == "__main__":
    alter_db()
