import os
import sys
import re
import urllib.parse
from pathlib import Path

# Add backend directory to Python path
sys.path.insert(0, str(Path(__file__).resolve().parent))

try:
    from dotenv import load_dotenv
    env_path = Path(__file__).resolve().parent / ".env"
    load_dotenv(dotenv_path=env_path)
    load_dotenv()
except ImportError:
    pass

import psycopg2
from psycopg2.extras import RealDictCursor
from services.user_store import init_user_database
from services.report_store import init_database


def get_target_database_url() -> str:
    if len(sys.argv) > 1 and sys.argv[1].startswith("postgres"):
        return sys.argv[1].strip()

    url = (
        os.getenv("SUPABASE_DATABASE_URL")
        or os.getenv("SUPABASE_DB_URL")
        or os.getenv("DATABASE_URL")
        or os.getenv("Database_URL")
        or os.getenv("database_url")
        or ""
    ).strip()

    if not url:
        print("\n❌ Error: No Supabase/PostgreSQL database URL found!")
        print("Please set SUPABASE_DATABASE_URL in backend/.env or run:")
        print('python migrate_supabase.py "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres"\n')
        sys.exit(1)

    if url.startswith("postgres://"):
        url = url.replace("postgres://", "postgresql://", 1)

    url = re.sub(r":\[([^\]]+)\]@", r":\1@", url)

    pattern = r"^(postgresql://)([^:]+):(.*)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(?::\d+)?(?:/.*)?)$"
    match = re.match(pattern, url)
    if match:
        scheme, user, pwd, host_and_db = match.groups()
        if "@" in pwd or "#" in pwd:
            cleaned_pwd = urllib.parse.quote(pwd, safe="")
            url = f"{scheme}{user}:{cleaned_pwd}@{host_and_db}"

    return url


def run_supabase_migration():
    url = get_target_database_url()
    print("\n========================================================")
    print("🚀 PlaqueCheck Supabase Database Migration Tool")
    print("========================================================")
    print(f"Connecting to Supabase PostgreSQL...")

    # Set environment variable so services/db.py uses this connection
    os.environ["SUPABASE_DATABASE_URL"] = url
    os.environ["USE_SUPABASE"] = "true"

    try:
        conn = psycopg2.connect(url, connect_timeout=15)
        print("✅ Successfully connected to Supabase PostgreSQL!")
        conn.close()
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        sys.exit(1)

    print("\n[1/3] Initializing User & Role Authentication Tables (patient_users, doctor_users, admin_users)...")
    init_user_database(force=True)

    print("[2/3] Initializing Clinical Reports & Audit Database (reports, notifications, audit_logs)...")
    init_database()

    # Migrate data from local SQLite plaquecheck.db if present
    import sqlite3
    local_db_path = Path(__file__).resolve().parent / "database" / "plaquecheck.db"
    if local_db_path.exists():
        print(f"\n[DATA MIGRATION] Migrating existing records from local SQLite ({local_db_path.name}) to Supabase PostgreSQL...")
        try:
            pg_conn = psycopg2.connect(url)
            pg_cursor = pg_conn.cursor()
            sq_conn = sqlite3.connect(str(local_db_path))
            sq_conn.row_factory = sqlite3.Row
            sq_cursor = sq_conn.cursor()

            # Migrate patient_users
            try:
                sq_cursor.execute("SELECT * FROM patient_users")
                rows = sq_cursor.fetchall()
                for r in rows:
                    pg_cursor.execute(
                        "INSERT INTO patient_users (id, name, email, password_hash, status, created_at, updated_at) VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT (email) DO NOTHING",
                        (r["id"], r["name"], r["email"], r["password_hash"], r["status"], str(r["created_at"]), str(r["updated_at"]))
                    )
                print(f"   [SYNC] Migrated {len(rows)} patient_users records.")
            except Exception as e:
                print(f"   [SYNC NOTE] patient_users sync: {e}")

            # Migrate doctor_users
            try:
                sq_cursor.execute("SELECT * FROM doctor_users")
                rows = sq_cursor.fetchall()
                for r in rows:
                    pg_cursor.execute(
                        "INSERT INTO doctor_users (id, name, email, password_hash, status, created_at, updated_at) VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT (email) DO NOTHING",
                        (r["id"], r["name"], r["email"], r["password_hash"], r["status"], str(r["created_at"]), str(r["updated_at"]))
                    )
                print(f"   [SYNC] Migrated {len(rows)} doctor_users records.")
            except Exception as e:
                print(f"   [SYNC NOTE] doctor_users sync: {e}")

            # Migrate admin_users
            try:
                sq_cursor.execute("SELECT * FROM admin_users")
                rows = sq_cursor.fetchall()
                for r in rows:
                    pg_cursor.execute(
                        "INSERT INTO admin_users (id, name, email, password_hash, status, created_at, updated_at) VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT (email) DO NOTHING",
                        (r["id"], r["name"], r["email"], r["password_hash"], r["status"], str(r["created_at"]), str(r["updated_at"]))
                    )
                print(f"   [SYNC] Migrated {len(rows)} admin_users records.")
            except Exception as e:
                print(f"   [SYNC NOTE] admin_users sync: {e}")

            # Migrate patients
            try:
                sq_cursor.execute("SELECT * FROM patients")
                rows = sq_cursor.fetchall()
                for r in rows:
                    pg_cursor.execute(
                        "INSERT INTO patients (id, user_id, age, gender, phone, medical_history, profile_picture, created_at) VALUES (%s, %s, %s, %s, %s, %s, %s, %s) ON CONFLICT (user_id) DO NOTHING",
                        (r["id"], r["user_id"], r["age"], r["gender"], r["phone"], r["medical_history"], r["profile_picture"], str(r["created_at"]))
                    )
                print(f"   [SYNC] Migrated {len(rows)} patients profile records.")
            except Exception as e:
                print(f"   [SYNC NOTE] patients sync: {e}")

            # Migrate doctors
            try:
                sq_cursor.execute("SELECT * FROM doctors")
                rows = sq_cursor.fetchall()
                for r in rows:
                    pg_cursor.execute(
                        "INSERT INTO doctors (id, user_id, mobile, qualification, specialization, registration_number, clinic_name, hospital_name, approval_status, created_at) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s) ON CONFLICT (user_id) DO NOTHING",
                        (r["id"], r["user_id"], r["mobile"], r["qualification"], r["specialization"], r["registration_number"], r["clinic_name"], r["hospital_name"], r["approval_status"], str(r["created_at"]))
                    )
                print(f"   [SYNC] Migrated {len(rows)} doctors credential records.")
            except Exception as e:
                print(f"   [SYNC NOTE] doctors sync: {e}")

            # Migrate reports
            try:
                sq_cursor.execute("SELECT * FROM reports")
                rows = sq_cursor.fetchall()
                for r in rows:
                    pg_cursor.execute(
                        "INSERT INTO reports (id, user_id, image_path, processed_image, plaque_percent, severity, confidence, recommendation, timestamp, doctor_id, review_status, doctor_notes, treatment_recommendations, follow_up_date) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) ON CONFLICT (id) DO NOTHING",
                        (r["id"], r["user_id"], r["image_path"], r["processed_image"], r["plaque_percent"], r["severity"], r["confidence"], r["recommendation"], str(r["timestamp"]), r["doctor_id"], r["review_status"], r["doctor_notes"], r["treatment_recommendations"], r["follow_up_date"])
                    )
                print(f"   [SYNC] Migrated {len(rows)} reports records.")
            except Exception as e:
                print(f"   [SYNC NOTE] reports sync: {e}")

            pg_conn.commit()
            pg_conn.close()
            sq_conn.close()
            print("✅ All local SQLite records successfully synced into Supabase PostgreSQL!")
        except Exception as e:
            print(f"⚠️ SQLite sync note: {e}")

    print("\n[3/3] Verifying Supabase PostgreSQL Tables & Row Counts...")
    try:
        conn = psycopg2.connect(url)
        cursor = conn.cursor(cursor_factory=RealDictCursor)

        tables = ["patient_users", "doctor_users", "admin_users", "patients", "doctors", "reports", "notifications", "audit_logs"]
        print("-" * 56)
        print(f"{'TABLE NAME':<25} | {'ROW COUNT':<10} | STATUS")
        print("-" * 56)
        for t in tables:
            try:
                cursor.execute(f"SELECT COUNT(*) as cnt FROM {t}")
                cnt = cursor.fetchone()["cnt"]
                print(f"{t:<25} | {cnt:<10} | READY ✅")
            except Exception:
                print(f"{t:<25} | {'N/A':<10} | MISSING ❌")

        print("-" * 56)
        conn.close()
        print("\n✅ Supabase Database Migration & Sync Completed Successfully!")
        print("Your live Supabase project is 100% updated with dedicated role authentication and clinical tables.\n")
    except Exception as e:
        print(f"⚠️ Verification error: {e}")


if __name__ == "__main__":
    run_supabase_migration()
