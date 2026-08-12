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


def test_supabase_connection(custom_url: str = None):
    url = custom_url or (
        os.getenv("SUPABASE_DATABASE_URL")
        or os.getenv("SUPABASE_DB_URL")
        or os.getenv("DATABASE_URL")
        or ""
    ).strip()

    if not url or "YOUR-PROJECT-REF" in url or "YOUR-PASSWORD" in url:
        print("\n[FAIL] SUPABASE CONNECTION: FAIL")
        print("Reason: SUPABASE_DATABASE_URL is missing or contains placeholder values.")
        print("Configure SUPABASE_DATABASE_URL in backend/.env or pass connection string as argument.\n")
        return False

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

    host_match = re.search(r"@([^:/]+)", url)
    host_name = host_match.group(1) if host_match else "Supabase PostgreSQL"

    try:
        conn = psycopg2.connect(url, connect_timeout=10)
        cursor = conn.cursor(cursor_factory=RealDictCursor)
        
        cursor.execute("SELECT current_database();")
        db_name = cursor.fetchone()["current_database"]

        cursor.execute("SELECT current_user;")
        curr_user = cursor.fetchone()["current_user"]

        cursor.execute("SELECT COUNT(*) as count FROM public.patient_users;")
        patient_users_count = cursor.fetchone()["count"]

        cursor.execute("SELECT COUNT(*) as count FROM public.patients;")
        patients_count = cursor.fetchone()["count"]

        conn.close()

        print("\n========================================================")
        print("[PASS] SUPABASE CONNECTION: PASS")
        print(f"DATABASE: {db_name}")
        print(f"USER: {curr_user}")
        print(f"HOST: {host_name}")
        print(f"EXISTING PATIENT_USERS COUNT: {patient_users_count}")
        print(f"EXISTING PATIENTS COUNT: {patients_count}")
        print("========================================================\n")
        return True

    except Exception as exc:
        print("\n========================================================")
        print("[FAIL] SUPABASE CONNECTION: FAIL")
        print(f"HOST: {host_name}")
        print(f"ERROR: {exc}")
        print("========================================================\n")
        return False


if __name__ == "__main__":
    url_arg = sys.argv[1] if len(sys.argv) > 1 else None
    test_supabase_connection(url_arg)
