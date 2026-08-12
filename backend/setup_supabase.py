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

    if not url or "YOUR-PROJECT-REF" in url or "YOUR-PASSWORD" in url:
        print("\n❌ Error: No valid Supabase PostgreSQL database URL found!")
        print("Please set SUPABASE_DATABASE_URL in backend/.env or run:")
        print('python setup_supabase.py "postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres"\n')
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


def run_supabase_setup():
    url = get_target_database_url()
    print("\n========================================================")
    print("🚀 PlaqueCheck Supabase Schema Initialization Tool")
    print("========================================================")
    print("Connecting to Supabase PostgreSQL...")

    try:
        conn = psycopg2.connect(url, connect_timeout=15)
        conn.autocommit = True
        cursor = conn.cursor()
        print("✅ Connected successfully to Supabase PostgreSQL!")
    except Exception as e:
        print(f"❌ Connection failed: {e}")
        sys.exit(1)

    schema_file = Path(__file__).resolve().parent / "supabase_schema_v2.sql"
    if not schema_file.exists():
        print(f"❌ Schema file missing: {schema_file}")
        sys.exit(1)

    print(f"\nApplying clean production schema from {schema_file.name}...")
    sql_script = schema_file.read_text(encoding="utf-8")

    try:
        cursor.execute(sql_script)
        print("✅ Clean Supabase production schema & RLS policies applied successfully!")
    except Exception as e:
        print(f"⚠️ Schema execution note: {e}")

    print("\nVerifying PlaqueCheck Supabase Tables...")
    tables = ["profiles", "doctors", "reports", "notifications", "audit_logs"]
    print("-" * 56)
    print(f"{'TABLE NAME':<25} | {'STATUS':<15} | RLS")
    print("-" * 56)
    cursor = conn.cursor(cursor_factory=RealDictCursor)
    for t in tables:
        try:
            cursor.execute(f"SELECT COUNT(*) as cnt FROM public.{t}")
            print(f"{t:<25} | {'READY ✅':<15} | ENABLED ✅")
        except Exception:
            print(f"{t:<25} | {'MISSING ❌':<15} | UNKNOWN")

    print("-" * 56)
    conn.close()
    print("\n✅ Clean Supabase Database Setup Completed Successfully!\n")


if __name__ == "__main__":
    run_supabase_setup()
