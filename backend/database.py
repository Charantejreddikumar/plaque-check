import os
import re
import sqlite3
import urllib.parse
import logging
from contextlib import contextmanager
from pathlib import Path

try:
    import psycopg2
    from psycopg2.extras import RealDictCursor
except ImportError:
    psycopg2 = None
    RealDictCursor = None

try:
    from dotenv import load_dotenv
    env_path = Path(__file__).resolve().parent / ".env"
    load_dotenv(dotenv_path=env_path)
    load_dotenv()
except ImportError:
    pass

logger = logging.getLogger(__name__)

BACKEND_DIR = Path(__file__).resolve().parent
LOCAL_DB_DIR = BACKEND_DIR / "database"
DEFAULT_DB_NAME = "plaquecheck.db"


def _get_clean_database_url() -> str:
    url = (
        os.getenv("SUPABASE_DATABASE_URL")
        or os.getenv("SUPABASE_DB_URL")
        or os.getenv("DATABASE_URL")
        or os.getenv("Database_URL")
        or os.getenv("database_url")
        or ""
    ).strip()

    use_supabase_env = os.getenv("USE_SUPABASE", "").lower()
    if use_supabase_env in ("false", "0", "no") and not (
        os.getenv("DATABASE_URL") or os.getenv("Database_URL") or os.getenv("database_url")
    ):
        return ""

    if not url or "YOUR-PROJECT-REF" in url or "YOUR-PASSWORD" in url:
        return ""

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


def get_db_type() -> str:
    url = _get_clean_database_url()
    use_supabase_env = os.getenv("USE_SUPABASE", "").lower()
    is_production = os.getenv("RENDER") or os.getenv("ENVIRONMENT") == "production"
    if use_supabase_env in ("true", "1", "yes") or is_production or url:
        return "postgres"
    return "sqlite"


@contextmanager
def get_db_connection(db_name: str = DEFAULT_DB_NAME):
    url = _get_clean_database_url()
    use_supabase = os.getenv("USE_SUPABASE", "").lower() in ("true", "1", "yes")
    is_production = os.getenv("RENDER") or os.getenv("ENVIRONMENT") == "production"

    if use_supabase or is_production or url:
        if not url:
            logger.error("[DB CONNECTION CRITICAL] Production/Supabase mode enabled but SUPABASE_DATABASE_URL is missing or invalid!")
            raise RuntimeError(
                "DATABASE CONNECTION ERROR: Production mode requires a valid Supabase PostgreSQL connection URL. "
                "Please configure SUPABASE_DATABASE_URL in backend/.env or Render environment variables."
            )
        try:
            conn = psycopg2.connect(url, connect_timeout=15)
            conn.autocommit = False
            host_match = re.search(r"@([^:/]+)", url)
            host_str = host_match.group(1) if host_match else "Supabase PostgreSQL"
            logger.info("[DB CONNECTION SUCCESS] BACKEND: POSTGRESQL | HOST: %s | DATABASE: postgres", host_str)
            try:
                yield ("postgres", conn)
                conn.commit()
            except Exception:
                try:
                    conn.rollback()
                except Exception:
                    pass
                raise
            finally:
                try:
                    conn.close()
                except Exception:
                    pass
            return
        except Exception as exc:
            logger.error("[DB CONNECTION FAILURE] Failed to connect to Supabase PostgreSQL: %s", exc)
            raise RuntimeError(
                f"DATABASE CONNECTION ERROR: Failed connecting to Supabase PostgreSQL ({url.split('@')[-1]}): {exc}"
            ) from exc

    # SQLite Development-Only Logic (Disabled in Production)
    logger.warning("[DB CONNECTION] BACKEND: SQLITE (DEVELOPMENT FALLBACK ONLY - NOT FOR PRODUCTION USE)")
    LOCAL_DB_DIR.mkdir(parents=True, exist_ok=True)
    
    # Redirect legacy db name calls to plaquecheck.db
    if db_name in ("users.db", "reports.db", "auth.db", "database.db"):
        db_name = DEFAULT_DB_NAME

    if os.getenv("PYTEST_CURRENT_TEST") or os.getenv("TEST_DB_NAME"):
        test_prefix = os.getenv("TEST_DB_PREFIX", "test_")
        if not db_name.startswith(test_prefix):
            db_name = f"{test_prefix}{db_name}"

    db_path = LOCAL_DB_DIR / db_name
    conn = sqlite3.connect(str(db_path), timeout=30.0, check_same_thread=False)
    conn.execute("PRAGMA foreign_keys = ON;")
    try:
        conn.execute("PRAGMA journal_mode = WAL;")
    except Exception:
        pass

    try:
        yield ("sqlite", conn)
        conn.commit()
    except Exception:
        try:
            conn.rollback()
        except Exception:
            pass
        raise
    finally:
        conn.close()


def init_all_tables() -> None:
    logger.info("[DB INIT] Ensuring all tables exist in single database (plaquecheck.db)")
    with get_db_connection(DEFAULT_DB_NAME) as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS patient_users (
                    id SERIAL PRIMARY KEY,
                    name TEXT NOT NULL,
                    email TEXT NOT NULL UNIQUE,
                    password_hash TEXT NOT NULL,
                    status TEXT NOT NULL DEFAULT 'active',
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS doctor_users (
                    id SERIAL PRIMARY KEY,
                    name TEXT NOT NULL,
                    email TEXT NOT NULL UNIQUE,
                    password_hash TEXT NOT NULL,
                    status TEXT NOT NULL DEFAULT 'pending_approval',
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS admin_users (
                    id SERIAL PRIMARY KEY,
                    name TEXT NOT NULL,
                    email TEXT NOT NULL UNIQUE,
                    password_hash TEXT NOT NULL,
                    status TEXT NOT NULL DEFAULT 'active',
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS users (
                    id SERIAL PRIMARY KEY,
                    name TEXT NOT NULL,
                    email TEXT NOT NULL UNIQUE,
                    password_hash TEXT NOT NULL,
                    role TEXT NOT NULL DEFAULT 'patient',
                    status TEXT NOT NULL DEFAULT 'active',
                    created_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS sessions (
                    token_hash TEXT PRIMARY KEY,
                    user_id INTEGER NOT NULL,
                    role TEXT NOT NULL,
                    created_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS doctors (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER NOT NULL UNIQUE,
                    mobile TEXT,
                    qualification TEXT,
                    specialization TEXT,
                    registration_number TEXT,
                    clinic_name TEXT,
                    hospital_name TEXT,
                    approval_status TEXT NOT NULL DEFAULT 'pending_approval',
                    created_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS patients (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER NOT NULL UNIQUE,
                    age INTEGER,
                    gender TEXT,
                    phone TEXT,
                    medical_history TEXT,
                    profile_picture TEXT,
                    created_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS reports (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER NOT NULL,
                    image_path TEXT NOT NULL,
                    processed_image TEXT NOT NULL,
                    plaque_percent INTEGER NOT NULL,
                    severity TEXT NOT NULL,
                    confidence REAL NOT NULL,
                    recommendation TEXT NOT NULL,
                    timestamp TEXT NOT NULL,
                    doctor_id INTEGER,
                    review_status TEXT DEFAULT 'pending_review',
                    doctor_notes TEXT,
                    treatment_recommendations TEXT,
                    follow_up_date TEXT,
                    reviewed_at TEXT
                );
                CREATE TABLE IF NOT EXISTS notifications (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER NOT NULL,
                    title TEXT NOT NULL,
                    message TEXT NOT NULL,
                    type TEXT NOT NULL DEFAULT 'info',
                    is_read BOOLEAN NOT NULL DEFAULT FALSE,
                    created_at TEXT NOT NULL
                );
                CREATE TABLE IF NOT EXISTS audit_logs (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER,
                    action TEXT NOT NULL,
                    details TEXT,
                    ip_address TEXT,
                    timestamp TEXT NOT NULL
                );
                CREATE INDEX IF NOT EXISTS idx_reports_user_id ON reports(user_id);
                CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
                """
            )
        else:
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS patient_users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    email TEXT NOT NULL UNIQUE,
                    password_hash TEXT NOT NULL,
                    status TEXT NOT NULL DEFAULT 'active',
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS doctor_users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    email TEXT NOT NULL UNIQUE,
                    password_hash TEXT NOT NULL,
                    status TEXT NOT NULL DEFAULT 'pending_approval',
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS admin_users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    email TEXT NOT NULL UNIQUE,
                    password_hash TEXT NOT NULL,
                    status TEXT NOT NULL DEFAULT 'active',
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS users (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    email TEXT NOT NULL UNIQUE,
                    password_hash TEXT NOT NULL,
                    role TEXT NOT NULL DEFAULT 'patient',
                    status TEXT NOT NULL DEFAULT 'active',
                    created_at TEXT NOT NULL
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS sessions (
                    token_hash TEXT PRIMARY KEY,
                    user_id INTEGER NOT NULL,
                    role TEXT NOT NULL,
                    created_at TEXT NOT NULL
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS doctors (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER NOT NULL UNIQUE,
                    mobile TEXT,
                    qualification TEXT,
                    specialization TEXT,
                    registration_number TEXT,
                    clinic_name TEXT,
                    hospital_name TEXT,
                    approval_status TEXT NOT NULL DEFAULT 'pending_approval',
                    created_at TEXT NOT NULL
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS patients (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER NOT NULL UNIQUE,
                    age INTEGER,
                    gender TEXT,
                    phone TEXT,
                    medical_history TEXT,
                    profile_picture TEXT,
                    created_at TEXT NOT NULL
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS reports (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER,
                    image_path TEXT NOT NULL,
                    processed_image TEXT NOT NULL,
                    plaque_percent INTEGER NOT NULL,
                    severity TEXT NOT NULL,
                    confidence REAL NOT NULL,
                    recommendation TEXT NOT NULL,
                    timestamp TEXT NOT NULL,
                    doctor_id INTEGER,
                    review_status TEXT DEFAULT 'pending_review',
                    doctor_notes TEXT,
                    treatment_recommendations TEXT,
                    follow_up_date TEXT,
                    reviewed_at TEXT
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS notifications (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER NOT NULL,
                    title TEXT NOT NULL,
                    message TEXT NOT NULL,
                    type TEXT NOT NULL DEFAULT 'info',
                    is_read INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT NOT NULL
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS audit_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER,
                    action TEXT NOT NULL,
                    details TEXT,
                    ip_address TEXT,
                    timestamp TEXT NOT NULL
                )
                """
            )
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_reports_user_id ON reports(user_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id)")
            cursor.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_patients_user_id ON patients(user_id)")
            cursor.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_doctors_user_id ON doctors(user_id)")

    migrate_legacy_databases()


def migrate_legacy_databases() -> None:
    if get_db_type() == "postgres":
        return

    target_db_path = LOCAL_DB_DIR / DEFAULT_DB_NAME
    users_db_path = LOCAL_DB_DIR / "users.db"
    reports_db_path = LOCAL_DB_DIR / "reports.db"

    if not (users_db_path.exists() or reports_db_path.exists()):
        return

    logger.info("[DB MIGRATION] Starting automatic migration of legacy databases into %s", DEFAULT_DB_NAME)
    
    with sqlite3.connect(str(target_db_path)) as target_conn:
        target_cursor = target_conn.cursor()

        if users_db_path.exists() and users_db_path.resolve() != target_db_path.resolve():
            logger.info("[DB MIGRATION] Migrating tables from users.db...")
            with sqlite3.connect(str(users_db_path)) as src_conn:
                src_cursor = src_conn.cursor()
                
                try:
                    p_users = src_cursor.execute("SELECT id, name, email, password_hash, status, created_at, updated_at FROM patient_users").fetchall()
                    target_cursor.executemany(
                        "INSERT OR IGNORE INTO patient_users (id, name, email, password_hash, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                        p_users,
                    )
                except Exception as e:
                    logger.debug("Patient users migration note: %s", e)

                try:
                    d_users = src_cursor.execute("SELECT id, name, email, password_hash, status, created_at, updated_at FROM doctor_users").fetchall()
                    target_cursor.executemany(
                        "INSERT OR IGNORE INTO doctor_users (id, name, email, password_hash, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                        d_users,
                    )
                except Exception as e:
                    logger.debug("Doctor users migration note: %s", e)

                try:
                    a_users = src_cursor.execute("SELECT id, name, email, password_hash, status, created_at, updated_at FROM admin_users").fetchall()
                    target_cursor.executemany(
                        "INSERT OR IGNORE INTO admin_users (id, name, email, password_hash, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                        a_users,
                    )
                except Exception as e:
                    logger.debug("Admin users migration note: %s", e)

                try:
                    u_legacy = src_cursor.execute("SELECT id, name, email, password_hash, role, status, created_at FROM users").fetchall()
                    target_cursor.executemany(
                        "INSERT OR IGNORE INTO users (id, name, email, password_hash, role, status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                        u_legacy,
                    )
                except Exception as e:
                    logger.debug("Legacy users migration note: %s", e)

                try:
                    sess = src_cursor.execute("SELECT token_hash, user_id, role, created_at FROM sessions").fetchall()
                    target_cursor.executemany(
                        "INSERT OR IGNORE INTO sessions (token_hash, user_id, role, created_at) VALUES (?, ?, ?, ?)",
                        sess,
                    )
                except Exception as e:
                    logger.debug("Sessions migration note: %s", e)

                try:
                    docs = src_cursor.execute("SELECT id, user_id, mobile, qualification, specialization, registration_number, clinic_name, hospital_name, approval_status, created_at FROM doctors").fetchall()
                    target_cursor.executemany(
                        "INSERT OR IGNORE INTO doctors (id, user_id, mobile, qualification, specialization, registration_number, clinic_name, hospital_name, approval_status, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                        docs,
                    )
                except Exception as e:
                    logger.debug("Doctors migration note: %s", e)

                try:
                    pats = src_cursor.execute("SELECT id, user_id, age, gender, phone, medical_history, profile_picture, created_at FROM patients").fetchall()
                    target_cursor.executemany(
                        "INSERT OR IGNORE INTO patients (id, user_id, age, gender, phone, medical_history, profile_picture, created_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                        pats,
                    )
                except Exception as e:
                    logger.debug("Patients migration note: %s", e)

                try:
                    notifs = src_cursor.execute("SELECT id, user_id, title, message, type, is_read, created_at FROM notifications").fetchall()
                    target_cursor.executemany(
                        "INSERT OR IGNORE INTO notifications (id, user_id, title, message, type, is_read, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                        notifs,
                    )
                except Exception as e:
                    logger.debug("Notifications migration note: %s", e)

                try:
                    auds = src_cursor.execute("SELECT id, user_id, action, details, ip_address, timestamp FROM audit_logs").fetchall()
                    target_cursor.executemany(
                        "INSERT OR IGNORE INTO audit_logs (id, user_id, action, details, ip_address, timestamp) VALUES (?, ?, ?, ?, ?, ?)",
                        auds,
                    )
                except Exception as e:
                    logger.debug("Audit logs migration note: %s", e)

        if reports_db_path.exists() and reports_db_path.resolve() != target_db_path.resolve():
            logger.info("[DB MIGRATION] Migrating reports from reports.db...")
            with sqlite3.connect(str(reports_db_path)) as r_conn:
                r_cursor = r_conn.cursor()
                try:
                    r_rows = r_cursor.execute(
                        "SELECT id, user_id, image_path, processed_image, plaque_percent, severity, confidence, recommendation, timestamp, doctor_id, review_status, doctor_notes, treatment_recommendations, follow_up_date, reviewed_at FROM reports"
                    ).fetchall()
                    target_cursor.executemany(
                        """
                        INSERT OR IGNORE INTO reports (
                            id, user_id, image_path, processed_image, plaque_percent, severity,
                            confidence, recommendation, timestamp, doctor_id, review_status,
                            doctor_notes, treatment_recommendations, follow_up_date, reviewed_at
                        )
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        """,
                        r_rows,
                    )
                except Exception as e:
                    logger.debug("Reports migration note: %s", e)

        target_conn.commit()
        logger.info("[DB MIGRATION COMPLETE] All data successfully consolidated into %s", DEFAULT_DB_NAME)
