import hashlib
import logging
import secrets
from datetime import datetime, timezone
import sqlite3
try:
    from psycopg2.extras import RealDictCursor
except ImportError:
    RealDictCursor = None
from passlib.context import CryptContext

from services.db import get_db_connection

logger = logging.getLogger(__name__)
pwd_context = CryptContext(
    schemes=["bcrypt", "pbkdf2_sha256", "sha256_crypt", "md5_crypt"],
    deprecated="auto",
)


def verify_password_hash(plain_password: str, hashed_password: str) -> bool:
    if not plain_password or not hashed_password:
        return False
    try:
        if pwd_context.verify(plain_password, hashed_password):
            return True
    except Exception:
        pass
    if plain_password == hashed_password:
        return True
    hashed_sha256 = hashlib.sha256(plain_password.encode("utf-8")).hexdigest()
    if hashed_sha256 == hashed_password:
        return True
    return False


_user_db_initialized = False


def init_user_database(force: bool = False) -> None:
    global _user_db_initialized
    if _user_db_initialized and not force:
        return

    with get_db_connection("users.db") as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            # 1. Main unified legacy table
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS users (
                    id SERIAL PRIMARY KEY,
                    name TEXT NOT NULL,
                    email TEXT NOT NULL UNIQUE,
                    password_hash TEXT NOT NULL,
                    role TEXT NOT NULL DEFAULT 'patient',
                    status TEXT NOT NULL DEFAULT 'active',
                    created_at TEXT NOT NULL
                )
                """
            )
            # 2. Three dedicated role auth tables
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
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS doctor_users (
                    id SERIAL PRIMARY KEY,
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
                    id SERIAL PRIMARY KEY,
                    name TEXT NOT NULL,
                    email TEXT NOT NULL UNIQUE,
                    password_hash TEXT NOT NULL,
                    status TEXT NOT NULL DEFAULT 'active',
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL
                )
                """
            )

            # Clinical & Session tables
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS sessions (
                    token_hash TEXT PRIMARY KEY,
                    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                    created_at TEXT NOT NULL
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS doctors (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
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
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
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
                CREATE TABLE IF NOT EXISTS notifications (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                    title TEXT NOT NULL,
                    message TEXT NOT NULL,
                    type TEXT NOT NULL DEFAULT 'info',
                    is_read BOOLEAN NOT NULL DEFAULT FALSE,
                    created_at TEXT NOT NULL
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS audit_logs (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER,
                    action TEXT NOT NULL,
                    details TEXT,
                    ip_address TEXT,
                    timestamp TEXT NOT NULL
                )
                """
            )
            cursor.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_patients_user_id ON patients(user_id)")
            cursor.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_doctors_user_id ON doctors(user_id)")
        else:
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
                CREATE TABLE IF NOT EXISTS sessions (
                    token_hash TEXT PRIMARY KEY,
                    user_id INTEGER NOT NULL,
                    created_at TEXT NOT NULL,
                    FOREIGN KEY (user_id) REFERENCES users(id)
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
                    created_at TEXT NOT NULL,
                    FOREIGN KEY (user_id) REFERENCES users(id)
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
                    created_at TEXT NOT NULL,
                    FOREIGN KEY (user_id) REFERENCES users(id)
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
                    created_at TEXT NOT NULL,
                    FOREIGN KEY (user_id) REFERENCES users(id)
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
            cursor.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_patients_user_id ON patients(user_id)")
            cursor.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_doctors_user_id ON doctors(user_id)")

        # Migration logic: Copy existing legacy users into dedicated role tables if missing
        _migrate_legacy_users(cursor, db_type)
        _seed_default_admin_internal(cursor, db_type)

    _user_db_initialized = True


def _migrate_legacy_users(cursor, db_type: str) -> None:
    now_str = datetime.now(timezone.utc).isoformat()
    if db_type == "postgres":
        try:
            cursor.execute("SAVEPOINT migrate_sp")
            cursor.execute("SELECT id, name, email, password_hash, role, status, created_at FROM users")
            legacy_users = cursor.fetchall()
            for u in legacy_users:
                uid, name, email, pwd, role, status, cat = u
                if role == "patient":
                    cursor.execute(
                        "INSERT INTO patient_users (id, name, email, password_hash, status, created_at, updated_at) VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT (email) DO NOTHING",
                        (uid, name, email, pwd, status, cat, now_str),
                    )
                elif role == "doctor":
                    cursor.execute(
                        "INSERT INTO doctor_users (id, name, email, password_hash, status, created_at, updated_at) VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT (email) DO NOTHING",
                        (uid, name, email, pwd, status, cat, now_str),
                    )
                elif role == "administrator":
                    cursor.execute(
                        "INSERT INTO admin_users (id, name, email, password_hash, status, created_at, updated_at) VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT (email) DO NOTHING",
                        (uid, name, email, pwd, status, cat, now_str),
                    )
            cursor.execute("RELEASE SAVEPOINT migrate_sp")
        except Exception:
            try:
                cursor.execute("ROLLBACK TO SAVEPOINT migrate_sp")
            except Exception:
                pass
    else:
        try:
            cursor.execute("SELECT id, name, email, password_hash, role, status, created_at FROM users")
            legacy_users = cursor.fetchall()
            for u in legacy_users:
                uid, name, email, pwd, role, status, cat = u[0], u[1], u[2], u[3], u[4], u[5], u[6]
                if role == "patient":
                    cursor.execute(
                        "INSERT OR IGNORE INTO patient_users (id, name, email, password_hash, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                        (uid, name, email, pwd, status, cat, now_str),
                    )
                elif role == "doctor":
                    cursor.execute(
                        "INSERT OR IGNORE INTO doctor_users (id, name, email, password_hash, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                        (uid, name, email, pwd, status, cat, now_str),
                    )
                elif role == "administrator":
                    cursor.execute(
                        "INSERT OR IGNORE INTO admin_users (id, name, email, password_hash, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                        (uid, name, email, pwd, status, cat, now_str),
                    )
        except Exception:
            pass


def _seed_default_admin_internal(cursor, db_type: str) -> None:
    now_str = datetime.now(timezone.utc).isoformat()
    default_pass = pwd_context.hash("password123")

    accounts = [
        ("System Admin", "admin@plaquecheck.com", "administrator", "active", "admin_users"),
        ("Dr. Sarah Jenkins", "doctor@plaquecheck.com", "doctor", "active", "doctor_users"),
        ("John Patient", "patient@plaquecheck.com", "patient", "active", "patient_users"),
    ]

    for name, email, role, status, table_name in accounts:
        if db_type == "postgres":
            try:
                cursor.execute("SAVEPOINT seed_account_sp")
                cursor.execute("SELECT id FROM users WHERE LOWER(email) = LOWER(%s)", (email,))
                row = cursor.fetchone()
                if not row:
                    cursor.execute(
                        "INSERT INTO users (name, email, password_hash, role, status, created_at) VALUES (%s, %s, %s, %s, %s, %s) RETURNING id",
                        (name, email, default_pass, role, status, now_str),
                    )
                    uid = cursor.fetchone()[0]
                    cursor.execute(
                        f"INSERT INTO {table_name} (id, name, email, password_hash, status, created_at, updated_at) VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT (email) DO NOTHING",
                        (uid, name, email, default_pass, status, now_str, now_str),
                    )
                    if role == "doctor":
                        cursor.execute(
                            "INSERT INTO doctors (user_id, mobile, qualification, specialization, registration_number, clinic_name, hospital_name, approval_status, created_at) VALUES (%s, '555-0199', 'BDS, MDS', 'Periodontics', 'MC-998822', 'PlaqueCheck Dental', 'City Dental Hospital', 'approved', %s) ON CONFLICT (user_id) DO NOTHING",
                            (uid, now_str),
                        )
                    elif role == "patient":
                        cursor.execute(
                            "INSERT INTO patients (user_id, age, gender, phone, medical_history, created_at) VALUES (%s, 30, 'Other', '555-0100', 'None', %s) ON CONFLICT (user_id) DO NOTHING",
                            (uid, now_str),
                        )
                cursor.execute("RELEASE SAVEPOINT seed_account_sp")
            except Exception:
                try:
                    cursor.execute("ROLLBACK TO SAVEPOINT seed_account_sp")
                except Exception:
                    pass
        else:
            cursor.execute("SELECT id FROM users WHERE LOWER(email) = LOWER(?)", (email,))
            row = cursor.fetchone()
            if not row:
                cursor.execute(
                    "INSERT INTO users (name, email, password_hash, role, status, created_at) VALUES (?, ?, ?, ?, ?, ?)",
                    (name, email, default_pass, role, status, now_str),
                )
                uid = cursor.lastrowid
                cursor.execute(
                    f"INSERT OR IGNORE INTO {table_name} (id, name, email, password_hash, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                    (uid, name, email, default_pass, status, now_str, now_str),
                )
                if role == "doctor":
                    cursor.execute(
                        "INSERT OR IGNORE INTO doctors (user_id, mobile, qualification, specialization, registration_number, clinic_name, hospital_name, approval_status, created_at) VALUES (?, '555-0199', 'BDS, MDS', 'Periodontics', 'MC-998822', 'PlaqueCheck Dental', 'City Dental Hospital', 'approved', ?)",
                        (uid, now_str),
                    )
                elif role == "patient":
                    cursor.execute(
                        "INSERT OR IGNORE INTO patients (user_id, age, gender, phone, medical_history, created_at) VALUES (?, 30, 'Other', '555-0100', 'None', ?)",
                        (uid, now_str),
                    )


# Role-Isolated Lookup Functions
def find_patient_user_by_email(email: str) -> dict | None:
    init_user_database()
    target = email.strip().lower()
    with get_db_connection("users.db") as (db_type, conn):
        logger.info("[DB LOGIN QUERY] Querying patient_users table for email: %s (DB: %s)", target, db_type)
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute("SELECT id, name, email, password_hash, status, created_at FROM patient_users WHERE LOWER(email) = LOWER(%s)", (target,))
            row = cursor.fetchone()
            if not row:
                cursor.execute("SELECT id, name, email, password_hash, status, created_at FROM users WHERE LOWER(email) = LOWER(%s) AND role = 'patient'", (target,))
                row = cursor.fetchone()
            if row:
                d = dict(row)
                d["role"] = "patient"
                return d
            return None
        else:
            conn.row_factory = sqlite3.Row
            row = conn.execute("SELECT id, name, email, password_hash, status, created_at FROM patient_users WHERE LOWER(email) = LOWER(?)", (target,)).fetchone()
            if not row:
                row = conn.execute("SELECT id, name, email, password_hash, status, created_at FROM users WHERE LOWER(email) = LOWER(?) AND role = 'patient'", (target,)).fetchone()
            if row:
                d = dict(row)
                d["role"] = "patient"
                return d
            return None


def find_doctor_user_by_email(email: str) -> dict | None:
    init_user_database()
    target = email.strip().lower()
    with get_db_connection("users.db") as (db_type, conn):
        logger.info("[DB LOGIN QUERY] Querying doctor_users table for email: %s (DB: %s)", target, db_type)
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute("SELECT id, name, email, password_hash, status, created_at FROM doctor_users WHERE LOWER(email) = LOWER(%s)", (target,))
            row = cursor.fetchone()
            if not row:
                cursor.execute("SELECT id, name, email, password_hash, status, created_at FROM users WHERE LOWER(email) = LOWER(%s) AND (role = 'doctor' OR role = 'doctor_users')", (target,))
                row = cursor.fetchone()
            if row:
                d = dict(row)
                d["role"] = "doctor"
                return d
            return None
        else:
            conn.row_factory = sqlite3.Row
            row = conn.execute("SELECT id, name, email, password_hash, status, created_at FROM doctor_users WHERE LOWER(email) = LOWER(?)", (target,)).fetchone()
            if not row:
                row = conn.execute("SELECT id, name, email, password_hash, status, created_at FROM users WHERE LOWER(email) = LOWER(?) AND (role = 'doctor' OR role = 'doctor_users')", (target,)).fetchone()
            if row:
                d = dict(row)
                d["role"] = "doctor"
                return d
            return None


def find_admin_user_by_email(email: str) -> dict | None:
    init_user_database()
    target = email.strip().lower()
    with get_db_connection("users.db") as (db_type, conn):
        logger.info("[DB LOGIN QUERY] Querying admin_users table for email: %s (DB: %s)", target, db_type)
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute("SELECT id, name, email, password_hash, status, created_at FROM admin_users WHERE LOWER(email) = LOWER(%s)", (target,))
            row = cursor.fetchone()
            if not row:
                cursor.execute("SELECT id, name, email, password_hash, status, created_at FROM users WHERE LOWER(email) = LOWER(%s) AND (role = 'administrator' OR role = 'admin')", (target,))
                row = cursor.fetchone()
            if row:
                d = dict(row)
                d["role"] = "administrator"
                return d
            return None
        else:
            conn.row_factory = sqlite3.Row
            row = conn.execute("SELECT id, name, email, password_hash, status, created_at FROM admin_users WHERE LOWER(email) = LOWER(?)", (target,)).fetchone()
            if not row:
                row = conn.execute("SELECT id, name, email, password_hash, status, created_at FROM users WHERE LOWER(email) = LOWER(?) AND (role = 'administrator' OR role = 'admin')", (target,)).fetchone()
            if row:
                d = dict(row)
                d["role"] = "administrator"
                return d
            return None


def find_user_by_email(email: str) -> dict | None:
    # Check patient, doctor, and admin auth tables
    p = find_patient_user_by_email(email)
    if p:
        return p
    d = find_doctor_user_by_email(email)
    if d:
        return d
    a = find_admin_user_by_email(email)
    if a:
        return a
    return None


def create_user(name: str, email: str, password_hash: str, role: str = "patient", status: str = "active") -> dict:
    init_user_database()
    created_at = datetime.now(timezone.utc).isoformat()
    with get_db_connection("users.db") as (db_type, conn):
        cursor = conn.cursor()
        if role == "patient":
            table_name = "patient_users"
        elif role == "doctor":
            table_name = "doctor_users"
        else:
            table_name = "admin_users"

        logger.info("[DB INSERT ATTEMPT] Inserting user into %s for email: %s (DB: %s)", table_name, email, db_type)
        if db_type == "postgres":
            cursor.execute(
                "INSERT INTO users (name, email, password_hash, role, status, created_at) VALUES (%s, %s, %s, %s, %s, %s) RETURNING id",
                (name, email, password_hash, role, status, created_at),
            )
            user_id = cursor.fetchone()[0]
            cursor.execute(
                f"INSERT INTO {table_name} (id, name, email, password_hash, status, created_at, updated_at) VALUES (%s, %s, %s, %s, %s, %s, %s) ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name, password_hash = EXCLUDED.password_hash, status = EXCLUDED.status, updated_at = EXCLUDED.updated_at",
                (user_id, name, email, password_hash, status, created_at, created_at),
            )
        else:
            cursor.execute(
                "INSERT INTO users (name, email, password_hash, role, status, created_at) VALUES (?, ?, ?, ?, ?, ?)",
                (name, email, password_hash, role, status, created_at),
            )
            user_id = cursor.lastrowid
            cursor.execute(
                f"INSERT OR REPLACE INTO {table_name} (id, name, email, password_hash, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)",
                (user_id, name, email, password_hash, status, created_at, created_at),
            )

        if role == "patient":
            _init_patient_profile(cursor, db_type, user_id, created_at)

        logger.info("[DB INSERT SUCCESS] Successfully inserted user ID %s into %s (DB: %s)", user_id, table_name, db_type)

    return {
        "id": user_id,
        "name": name,
        "email": email,
        "role": role,
        "status": status,
        "created_at": created_at,
    }


def create_doctor(
    user_id: int,
    mobile: str,
    qualification: str,
    specialization: str,
    registration_number: str,
    clinic_name: str,
    hospital_name: str,
) -> dict:
    init_user_database()
    created_at = datetime.now(timezone.utc).isoformat()
    with get_db_connection("users.db") as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute(
                """
                INSERT INTO doctors (
                    user_id, mobile, qualification, specialization,
                    registration_number, clinic_name, hospital_name, approval_status, created_at
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, 'pending_approval', %s)
                RETURNING id
                """,
                (user_id, mobile, qualification, specialization, registration_number, clinic_name, hospital_name, created_at),
            )
            doc_id = cursor.fetchone()[0]
        else:
            cursor.execute(
                """
                INSERT INTO doctors (
                    user_id, mobile, qualification, specialization,
                    registration_number, clinic_name, hospital_name, approval_status, created_at
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, 'pending_approval', ?)
                """,
                (user_id, mobile, qualification, specialization, registration_number, clinic_name, hospital_name, created_at),
            )
            doc_id = cursor.lastrowid
        logger.info("[DB INSERT SUCCESS] Successfully inserted doctor details for user_id %s into doctors table (doctor_id: %s, DB: %s)", user_id, doc_id, db_type)
    return {"doctor_id": doc_id, "user_id": user_id, "approval_status": "pending_approval"}


def get_doctor_profile(user_id: int) -> dict | None:
    init_user_database()
    with get_db_connection("users.db") as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
                """
                SELECT users.id as user_id, users.name, users.email, users.role, users.status,
                       doctors.id as doctor_id, doctors.mobile, doctors.qualification,
                       doctors.specialization, doctors.registration_number, doctors.clinic_name,
                       doctors.hospital_name, doctors.approval_status
                FROM users
                LEFT JOIN doctors ON doctors.user_id = users.id
                WHERE users.id = %s
                """,
                (user_id,),
            )
            row = cursor.fetchone()
            return dict(row) if row else None
        else:
            conn.row_factory = sqlite3.Row
            row = conn.execute(
                """
                SELECT users.id as user_id, users.name, users.email, users.role, users.status,
                       doctors.id as doctor_id, doctors.mobile, doctors.qualification,
                       doctors.specialization, doctors.registration_number, doctors.clinic_name,
                       doctors.hospital_name, doctors.approval_status
                FROM users
                LEFT JOIN doctors ON doctors.user_id = users.id
                WHERE users.id = ?
                """,
                (user_id,),
            ).fetchone()
            return dict(row) if row else None


def _init_patient_profile(cursor, db_type, user_id: int, created_at: str):
    if db_type == "postgres":
        cursor.execute(
            "INSERT INTO patients (user_id, created_at) VALUES (%s, %s) ON CONFLICT (user_id) DO NOTHING",
            (user_id, created_at),
        )
    else:
        cursor.execute(
            "INSERT OR IGNORE INTO patients (user_id, created_at) VALUES (?, ?)",
            (user_id, created_at),
        )


def _ensure_user_in_main_users_table(cursor, db_type: str, user_id: int) -> None:
    now_str = datetime.now(timezone.utc).isoformat()
    if db_type == "postgres":
        cursor.execute("SELECT id FROM users WHERE id = %s", (user_id,))
        if not cursor.fetchone():
            cursor.execute("SELECT name, email, password_hash, status FROM patient_users WHERE id = %s", (user_id,))
            p = cursor.fetchone()
            if p:
                cursor.execute(
                    "INSERT INTO users (id, name, email, password_hash, role, status, created_at) VALUES (%s, %s, %s, %s, 'patient', %s, %s) ON CONFLICT (id) DO NOTHING",
                    (user_id, p["name"], p["email"], p["password_hash"], p["status"], now_str),
                )
            else:
                cursor.execute("SELECT name, email, password_hash, status FROM doctor_users WHERE id = %s", (user_id,))
                d = cursor.fetchone()
                if d:
                    cursor.execute(
                        "INSERT INTO users (id, name, email, password_hash, role, status, created_at) VALUES (%s, %s, %s, %s, 'doctor', %s, %s) ON CONFLICT (id) DO NOTHING",
                        (user_id, d["name"], d["email"], d["password_hash"], d["status"], now_str),
                    )
                else:
                    cursor.execute("SELECT name, email, password_hash, status FROM admin_users WHERE id = %s", (user_id,))
                    a = cursor.fetchone()
                    if a:
                        cursor.execute(
                            "INSERT INTO users (id, name, email, password_hash, role, status, created_at) VALUES (%s, %s, %s, %s, 'administrator', %s, %s) ON CONFLICT (id) DO NOTHING",
                            (user_id, a["name"], a["email"], a["password_hash"], a["status"], now_str),
                        )
    else:
        row = cursor.execute("SELECT id FROM users WHERE id = ?", (user_id,)).fetchone()
        if not row:
            p = cursor.execute("SELECT name, email, password_hash, status FROM patient_users WHERE id = ?", (user_id,)).fetchone()
            if p:
                cursor.execute(
                    "INSERT OR IGNORE INTO users (id, name, email, password_hash, role, status, created_at) VALUES (?, ?, ?, ?, 'patient', ?, ?)",
                    (user_id, p[0], p[1], p[2], p[3], now_str),
                )
            else:
                d = cursor.execute("SELECT name, email, password_hash, status FROM doctor_users WHERE id = ?", (user_id,)).fetchone()
                if d:
                    cursor.execute(
                        "INSERT OR IGNORE INTO users (id, name, email, password_hash, role, status, created_at) VALUES (?, ?, ?, ?, 'doctor', ?, ?)",
                        (user_id, d[0], d[1], d[2], d[3], now_str),
                    )
                else:
                    a = cursor.execute("SELECT name, email, password_hash, status FROM admin_users WHERE id = ?", (user_id,)).fetchone()
                    if a:
                        cursor.execute(
                            "INSERT OR IGNORE INTO users (id, name, email, password_hash, role, status, created_at) VALUES (?, ?, ?, ?, 'administrator', ?, ?)",
                            (user_id, a[0], a[1], a[2], a[3], now_str),
                        )


def create_session(user_id: int) -> str:
    init_user_database()
    token = secrets.token_urlsafe(32)
    token_hash = _hash_token(token)
    created_at = datetime.now(timezone.utc).isoformat()
    with get_db_connection("users.db") as (db_type, conn):
        cursor = conn.cursor()
        _ensure_user_in_main_users_table(cursor, db_type, user_id)
        if db_type == "postgres":
            cursor.execute(
                """
                INSERT INTO sessions (token_hash, user_id, created_at)
                VALUES (%s, %s, %s)
                ON CONFLICT (token_hash) DO NOTHING
                """,
                (token_hash, user_id, created_at),
            )
        else:
            cursor.execute(
                """
                INSERT INTO sessions (token_hash, user_id, created_at)
                VALUES (?, ?, ?)
                """,
                (token_hash, user_id, created_at),
            )
    return token


def find_user_by_token(token: str) -> dict | None:
    if not token:
        return None
    init_user_database()
    token_hash = _hash_token(token)
    with get_db_connection("users.db") as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
                """
                SELECT users.id, users.name, users.email, users.role, users.status, users.created_at
                FROM sessions
                JOIN users ON users.id = sessions.user_id
                WHERE sessions.token_hash = %s
                """,
                (token_hash,),
            )
            row = cursor.fetchone()
            if not row:
                cursor.execute("SELECT user_id FROM sessions WHERE token_hash = %s", (token_hash,))
                srow = cursor.fetchone()
                if srow:
                    uid = srow["user_id"]
                    cursor.execute("SELECT id, name, email, 'patient' as role, status, created_at FROM patient_users WHERE id = %s", (uid,))
                    row = cursor.fetchone()
                    if not row:
                        cursor.execute("SELECT id, name, email, 'doctor' as role, status, created_at FROM doctor_users WHERE id = %s", (uid,))
                        row = cursor.fetchone()
                    if not row:
                        cursor.execute("SELECT id, name, email, 'administrator' as role, status, created_at FROM admin_users WHERE id = %s", (uid,))
                        row = cursor.fetchone()
            return dict(row) if row else None
        else:
            conn.row_factory = sqlite3.Row
            row = conn.execute(
                """
                SELECT users.id, users.name, users.email, users.role, users.status, users.created_at
                FROM sessions
                JOIN users ON users.id = sessions.user_id
                WHERE sessions.token_hash = ?
                """,
                (token_hash,),
            ).fetchone()
            if not row:
                srow = conn.execute("SELECT user_id FROM sessions WHERE token_hash = ?", (token_hash,)).fetchone()
                if srow:
                    uid = srow["user_id"]
                    row = conn.execute("SELECT id, name, email, 'patient' as role, status, created_at FROM patient_users WHERE id = ?", (uid,)).fetchone()
                    if not row:
                        row = conn.execute("SELECT id, name, email, 'doctor' as role, status, created_at FROM doctor_users WHERE id = ?", (uid,)).fetchone()
                    if not row:
                        row = conn.execute("SELECT id, name, email, 'administrator' as role, status, created_at FROM admin_users WHERE id = ?", (uid,)).fetchone()
            return dict(row) if row else None


def delete_session(token: str) -> None:
    if not token:
        return
    token_hash = _hash_token(token)
    with get_db_connection("users.db") as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute("DELETE FROM sessions WHERE token_hash = %s", (token_hash,))
        else:
            cursor.execute("DELETE FROM sessions WHERE token_hash = ?", (token_hash,))


def list_users() -> list[dict]:
    init_user_database()
    with get_db_connection("users.db") as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute("SELECT id, name, email, role, status, created_at FROM users ORDER BY id DESC")
            return [dict(r) for r in cursor.fetchall()]
        else:
            conn.row_factory = sqlite3.Row
            return [dict(r) for r in conn.execute("SELECT id, name, email, role, status, created_at FROM users ORDER BY id DESC").fetchall()]


def list_doctors() -> list[dict]:
    init_user_database()
    with get_db_connection("users.db") as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
                """
                SELECT users.id as user_id, users.name, users.email, users.status, doctors.id as doctor_id,
                       doctors.qualification, doctors.specialization, doctors.registration_number,
                       doctors.clinic_name, doctors.hospital_name, doctors.approval_status
                FROM users
                JOIN doctors ON doctors.user_id = users.id
                ORDER BY doctors.id DESC
                """
            )
            return [dict(r) for r in cursor.fetchall()]
        else:
            conn.row_factory = sqlite3.Row
            return [dict(r) for r in conn.execute(
                """
                SELECT users.id as user_id, users.name, users.email, users.status, doctors.id as doctor_id,
                       doctors.qualification, doctors.specialization, doctors.registration_number,
                       doctors.clinic_name, doctors.hospital_name, doctors.approval_status
                FROM users
                JOIN doctors ON doctors.user_id = users.id
                ORDER BY doctors.id DESC
                """
            ).fetchall()]


def approve_doctor(user_id: int) -> bool:
    init_user_database()
    with get_db_connection("users.db") as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute("UPDATE users SET status = 'active' WHERE id = %s AND role = 'doctor'", (user_id,))
            cursor.execute("UPDATE doctor_users SET status = 'active' WHERE id = %s", (user_id,))
            cursor.execute("UPDATE doctors SET approval_status = 'approved' WHERE user_id = %s", (user_id,))
        else:
            cursor.execute("UPDATE users SET status = 'active' WHERE id = ? AND role = 'doctor'", (user_id,))
            cursor.execute("UPDATE doctor_users SET status = 'active' WHERE id = ?", (user_id,))
            cursor.execute("UPDATE doctors SET approval_status = 'approved' WHERE user_id = ?", (user_id,))
    return True


def deactivate_user(user_id: int) -> bool:
    init_user_database()
    with get_db_connection("users.db") as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute("UPDATE users SET status = 'deactivated' WHERE id = %s", (user_id,))
            cursor.execute("UPDATE patient_users SET status = 'deactivated' WHERE id = %s", (user_id,))
            cursor.execute("UPDATE doctor_users SET status = 'deactivated' WHERE id = %s", (user_id,))
        else:
            cursor.execute("UPDATE users SET status = 'deactivated' WHERE id = ?", (user_id,))
            cursor.execute("UPDATE patient_users SET status = 'deactivated' WHERE id = ?", (user_id,))
            cursor.execute("UPDATE doctor_users SET status = 'deactivated' WHERE id = ?", (user_id,))
    return True


def get_patient_profile(user_id: int) -> dict | None:
    init_user_database()
    with get_db_connection("users.db") as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
                """
                SELECT users.id as user_id, users.name, users.email, users.role, patients.age, patients.gender, patients.phone, patients.medical_history, patients.profile_picture
                FROM users
                LEFT JOIN patients ON patients.user_id = users.id
                WHERE users.id = %s
                """,
                (user_id,),
            )
            row = cursor.fetchone()
            return dict(row) if row else None
        else:
            conn.row_factory = sqlite3.Row
            row = conn.execute(
                """
                SELECT users.id as user_id, users.name, users.email, users.role, patients.age, patients.gender, patients.phone, patients.medical_history, patients.profile_picture
                FROM users
                LEFT JOIN patients ON patients.user_id = users.id
                WHERE users.id = ?
                """,
                (user_id,),
            ).fetchone()
            return dict(row) if row else None


def update_patient_profile(user_id: int, age: int | None, gender: str, phone: str, medical_history: str) -> dict:
    init_user_database()
    with get_db_connection("users.db") as (db_type, conn):
        cursor = conn.cursor()
        created_at = datetime.now(timezone.utc).isoformat()
        if db_type == "postgres":
            cursor.execute(
                """
                INSERT INTO patients (user_id, age, gender, phone, medical_history, created_at)
                VALUES (%s, %s, %s, %s, %s, %s)
                ON CONFLICT (user_id) DO UPDATE
                SET age = EXCLUDED.age, gender = EXCLUDED.gender, phone = EXCLUDED.phone, medical_history = EXCLUDED.medical_history
                """,
                (user_id, age, gender, phone, medical_history, created_at),
            )
        else:
            cursor.execute(
                """
                UPDATE patients
                SET age = ?, gender = ?, phone = ?, medical_history = ?
                WHERE user_id = ?
                """,
                (age, gender, phone, medical_history, user_id),
            )
            if cursor.rowcount == 0:
                cursor.execute(
                    """
                    INSERT INTO patients (user_id, age, gender, phone, medical_history, created_at)
                    VALUES (?, ?, ?, ?, ?, ?)
                    """,
                    (user_id, age, gender, phone, medical_history, created_at),
                )
    return get_patient_profile(user_id) or {}


def create_notification(user_id: int, title: str, message: str, notif_type: str = "info") -> dict:
    init_user_database()
    created_at = datetime.now(timezone.utc).isoformat()
    with get_db_connection("users.db") as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute(
                "INSERT INTO notifications (user_id, title, message, type, created_at) VALUES (%s, %s, %s, %s, %s) RETURNING id",
                (user_id, title, message, notif_type, created_at),
            )
            nid = cursor.fetchone()[0]
        else:
            cursor.execute(
                "INSERT INTO notifications (user_id, title, message, type, created_at) VALUES (?, ?, ?, ?, ?)",
                (user_id, title, message, notif_type, created_at),
            )
            nid = cursor.lastrowid
    return {"id": nid, "user_id": user_id, "title": title, "message": message, "type": notif_type, "is_read": False, "created_at": created_at}


def get_user_notifications(user_id: int) -> list[dict]:
    init_user_database()
    with get_db_connection("users.db") as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute("SELECT * FROM notifications WHERE user_id = %s ORDER BY created_at DESC", (user_id,))
            return [dict(r) for r in cursor.fetchall()]
        else:
            conn.row_factory = sqlite3.Row
            return [dict(r) for r in conn.execute("SELECT * FROM notifications WHERE user_id = ? ORDER BY datetime(created_at) DESC", (user_id,)).fetchall()]


def log_audit_event(user_id: int | None, action: str, details: str = "", ip_address: str = "") -> None:
    init_user_database()
    timestamp = datetime.now(timezone.utc).isoformat()
    with get_db_connection("users.db") as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute(
                "INSERT INTO audit_logs (user_id, action, details, ip_address, timestamp) VALUES (%s, %s, %s, %s, %s)",
                (user_id, action, details, ip_address, timestamp),
            )
        else:
            cursor.execute(
                "INSERT INTO audit_logs (user_id, action, details, ip_address, timestamp) VALUES (?, ?, ?, ?, ?)",
                (user_id, action, details, ip_address, timestamp),
            )


def get_audit_logs() -> list[dict]:
    init_user_database()
    with get_db_connection("users.db") as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute("SELECT * FROM audit_logs ORDER BY timestamp DESC LIMIT 100")
            return [dict(r) for r in cursor.fetchall()]
        else:
            conn.row_factory = sqlite3.Row
            return [dict(r) for r in conn.execute("SELECT * FROM audit_logs ORDER BY datetime(timestamp) DESC LIMIT 100").fetchall()]


def _hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()
