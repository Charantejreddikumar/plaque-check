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

    logger.info("[DB INIT] Initializing clean single-source user database (patient_users, doctor_users, admin_users)")
    from database import init_all_tables
    init_all_tables()
    with get_db_connection() as (db_type, conn):
        cursor = conn.cursor()
        _seed_default_admin_internal(cursor, db_type)

    _user_db_initialized = True



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
                cursor.execute(f"SELECT id FROM {table_name} WHERE LOWER(email) = LOWER(%s)", (email,))
                user_row = cursor.fetchone()
                if not user_row:
                    cursor.execute(
                        f"INSERT INTO {table_name} (name, email, password_hash, status, created_at, updated_at) VALUES (%s, %s, %s, %s, %s, %s) RETURNING id",
                        (name, email, default_pass, status, now_str, now_str),
                    )
                    uid = cursor.fetchone()[0]
                else:
                    uid = user_row["id"] if isinstance(user_row, dict) else user_row[0]
                    cursor.execute(
                        f"UPDATE {table_name} SET password_hash = %s, status = %s, updated_at = %s WHERE id = %s",
                        (default_pass, status, now_str, uid),
                    )

                if role == "doctor":
                    cursor.execute(
                        "INSERT INTO doctors (user_id, mobile, qualification, specialization, registration_number, clinic_name, hospital_name, approval_status, created_at) VALUES (%s, '555-0199', 'BDS, MDS', 'Periodontics', 'MC-998822', 'PlaqueCheck Dental', 'City Dental Hospital', 'approved', %s) ON CONFLICT (user_id) DO UPDATE SET approval_status = 'approved'",
                        (uid, now_str),
                    )
                elif role == "patient":
                    cursor.execute(
                        "INSERT INTO patients (user_id, age, gender, phone, medical_history, created_at) VALUES (%s, 30, 'Other', '555-0100', 'None', %s) ON CONFLICT (user_id) DO NOTHING",
                        (uid, now_str),
                    )
            except Exception as exc:
                logger.warning("[SEED EXCEPTION] Failed seeding PostgreSQL %s: %s", email, exc)
        else:
            try:
                cursor.execute(f"SELECT id FROM {table_name} WHERE LOWER(email) = LOWER(?)", (email,))
                user_row = cursor.fetchone()
                if not user_row:
                    cursor.execute(
                        f"INSERT INTO {table_name} (name, email, password_hash, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
                        (name, email, default_pass, status, now_str, now_str),
                    )
                    uid = cursor.lastrowid
                else:
                    uid = user_row[0]
                    cursor.execute(
                        f"UPDATE {table_name} SET password_hash = ?, status = ?, updated_at = ? WHERE id = ?",
                        (default_pass, status, now_str, uid),
                    )

                if role == "doctor":
                    cursor.execute(
                        "UPDATE doctors SET approval_status = 'approved' WHERE user_id = ?",
                        (uid,),
                    )
                    if cursor.rowcount == 0:
                        cursor.execute(
                            "INSERT INTO doctors (user_id, mobile, qualification, specialization, registration_number, clinic_name, hospital_name, approval_status, created_at) VALUES (?, '555-0199', 'BDS, MDS', 'Periodontics', 'MC-998822', 'PlaqueCheck Dental', 'City Dental Hospital', 'approved', ?)",
                            (uid, now_str),
                        )
                elif role == "patient":
                    cursor.execute(
                        "INSERT OR IGNORE INTO patients (user_id, age, gender, phone, medical_history, created_at) VALUES (?, 30, 'Other', '555-0100', 'None', ?)",
                        (uid, now_str),
                    )
            except Exception as exc:
                logger.warning("[SEED EXCEPTION] Failed seeding SQLite %s: %s", email, exc)


# Role-Isolated Lookup Functions
def find_patient_user_by_email(email: str) -> dict | None:
    init_user_database()
    target = email.strip().lower()
    with get_db_connection() as (db_type, conn):
        logger.info("[DB LOOKUP] Querying patient_users table for email: %s (DB: %s)", target, db_type)
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute("SELECT id, name, email, password_hash, status, created_at FROM patient_users WHERE LOWER(email) = LOWER(%s)", (target,))
            row = cursor.fetchone()
            if row:
                d = dict(row)
                d["role"] = "patient"
                return d
            return None
        else:
            conn.row_factory = sqlite3.Row
            row = conn.execute("SELECT id, name, email, password_hash, status, created_at FROM patient_users WHERE LOWER(email) = LOWER(?)", (target,)).fetchone()
            if row:
                d = dict(row)
                d["role"] = "patient"
                return d
            return None


def find_doctor_user_by_email(email: str) -> dict | None:
    init_user_database()
    target = email.strip().lower()
    with get_db_connection() as (db_type, conn):
        logger.info("[DB LOOKUP] Querying doctor_users table for email: %s (DB: %s)", target, db_type)
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute("SELECT id, name, email, password_hash, status, created_at FROM doctor_users WHERE LOWER(email) = LOWER(%s)", (target,))
            row = cursor.fetchone()
            if row:
                d = dict(row)
                d["role"] = "doctor"
                return d
            return None
        else:
            conn.row_factory = sqlite3.Row
            row = conn.execute("SELECT id, name, email, password_hash, status, created_at FROM doctor_users WHERE LOWER(email) = LOWER(?)", (target,)).fetchone()
            if row:
                d = dict(row)
                d["role"] = "doctor"
                return d
            return None


def find_admin_user_by_email(email: str) -> dict | None:
    init_user_database()
    target = email.strip().lower()
    with get_db_connection() as (db_type, conn):
        logger.info("[DB LOOKUP] Querying admin_users table for email: %s (DB: %s)", target, db_type)
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute("SELECT id, name, email, password_hash, status, created_at FROM admin_users WHERE LOWER(email) = LOWER(%s)", (target,))
            row = cursor.fetchone()
            if row:
                d = dict(row)
                d["role"] = "administrator"
                return d
            return None
        else:
            conn.row_factory = sqlite3.Row
            row = conn.execute("SELECT id, name, email, password_hash, status, created_at FROM admin_users WHERE LOWER(email) = LOWER(?)", (target,)).fetchone()
            if row:
                d = dict(row)
                d["role"] = "administrator"
                return d
            return None


def find_user_by_email(email: str) -> dict | None:
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
    if role == "patient":
        table_name = "patient_users"
    elif role == "doctor":
        table_name = "doctor_users"
    else:
        table_name = "admin_users"

    logger.info("[DB INSERT START] Inserting new %s into %s for email: %s", role, table_name, email)
    with get_db_connection() as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute(
                f"INSERT INTO {table_name} (name, email, password_hash, status, created_at, updated_at) VALUES (%s, %s, %s, %s, %s, %s) RETURNING id",
                (name, email, password_hash, status, created_at, created_at),
            )
            user_id = cursor.fetchone()[0]
        else:
            cursor.execute(
                f"INSERT INTO {table_name} (name, email, password_hash, status, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?)",
                (name, email, password_hash, status, created_at, created_at),
            )
            user_id = cursor.lastrowid

        if role == "patient":
            _init_patient_profile(cursor, db_type, user_id, created_at)

        logger.info("[DB INSERT SUCCESS] Created %s account (ID: %s) in %s", role, user_id, table_name)

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
    with get_db_connection() as (db_type, conn):
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
        logger.info("[DB INSERT SUCCESS] Inserted doctor details for user_id %s into doctors table (doctor_id: %s)", user_id, doc_id)
    return {"doctor_id": doc_id, "user_id": user_id, "approval_status": "pending_approval"}


def get_doctor_profile(user_id: int) -> dict | None:
    init_user_database()
    with get_db_connection() as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
                """
                SELECT doctor_users.id as user_id, doctor_users.name, doctor_users.email, 'doctor' as role, doctor_users.status,
                       doctors.id as doctor_id, doctors.mobile, doctors.qualification,
                       doctors.specialization, doctors.registration_number, doctors.clinic_name,
                       doctors.hospital_name, doctors.approval_status
                FROM doctor_users
                LEFT JOIN doctors ON doctors.user_id = doctor_users.id
                WHERE doctor_users.id = %s
                """,
                (user_id,),
            )
            row = cursor.fetchone()
            return dict(row) if row else None
        else:
            conn.row_factory = sqlite3.Row
            row = conn.execute(
                """
                SELECT doctor_users.id as user_id, doctor_users.name, doctor_users.email, 'doctor' as role, doctor_users.status,
                       doctors.id as doctor_id, doctors.mobile, doctors.qualification,
                       doctors.specialization, doctors.registration_number, doctors.clinic_name,
                       doctors.hospital_name, doctors.approval_status
                FROM doctor_users
                LEFT JOIN doctors ON doctors.user_id = doctor_users.id
                WHERE doctor_users.id = ?
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


def _find_user_by_id_and_role(conn_or_cursor, db_type: str, user_id: int, role: str | None) -> dict | None:
    if role == "patient":
        query = "SELECT id, name, email, 'patient' as role, status, created_at FROM patient_users WHERE id = {}"
    elif role == "doctor":
        query = "SELECT id, name, email, 'doctor' as role, status, created_at FROM doctor_users WHERE id = {}"
    elif role in ("administrator", "admin"):
        query = "SELECT id, name, email, 'administrator' as role, status, created_at FROM admin_users WHERE id = {}"
    else:
        return None

    if db_type == "postgres":
        conn_or_cursor.execute(query.format("%s"), (user_id,))
        row = conn_or_cursor.fetchone()
    else:
        row = conn_or_cursor.execute(query.format("?"), (user_id,)).fetchone()
    return dict(row) if row else None


def create_session(user_id: int, role: str = "patient") -> str:
    init_user_database()
    token = secrets.token_urlsafe(32)
    token_hash = _hash_token(token)
    created_at = datetime.now(timezone.utc).isoformat()
    with get_db_connection() as (db_type, conn):
        cursor = conn.cursor()
        logger.info("[SESSION CREATION] Creating session for user_id=%s, role=%s", user_id, role)
        if db_type == "postgres":
            cursor.execute(
                """
                INSERT INTO sessions (token_hash, user_id, role, created_at)
                VALUES (%s, %s, %s, %s)
                ON CONFLICT (token_hash) DO NOTHING
                """,
                (token_hash, user_id, role, created_at),
            )
        else:
            cursor.execute(
                """
                INSERT INTO sessions (token_hash, user_id, role, created_at)
                VALUES (?, ?, ?, ?)
                """,
                (token_hash, user_id, role, created_at),
            )
    return token


def find_user_by_token(token: str) -> dict | None:
    if not token:
        return None
    init_user_database()
    token_hash = _hash_token(token)
    with get_db_connection() as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
                "SELECT user_id, role FROM sessions WHERE token_hash = %s",
                (token_hash,),
            )
            session_row = cursor.fetchone()
            if session_row:
                user_id = session_row["user_id"]
                role = session_row.get("role")
                role_row = _find_user_by_id_and_role(cursor, db_type, user_id, role)
                if role_row:
                    return role_row
            return None
        else:
            conn.row_factory = sqlite3.Row
            session_row = conn.execute(
                "SELECT user_id, role FROM sessions WHERE token_hash = ?",
                (token_hash,),
            ).fetchone()
            if session_row:
                role_row = _find_user_by_id_and_role(conn, db_type, session_row["user_id"], session_row["role"])
                if role_row:
                    return role_row
            return None


def delete_session(token: str) -> None:
    if not token:
        return
    token_hash = _hash_token(token)
    with get_db_connection() as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute("DELETE FROM sessions WHERE token_hash = %s", (token_hash,))
        else:
            cursor.execute("DELETE FROM sessions WHERE token_hash = ?", (token_hash,))


def list_users() -> list[dict]:
    init_user_database()
    with get_db_connection() as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
                """
                SELECT id, name, email, 'patient' as role, status, created_at FROM patient_users
                UNION ALL
                SELECT id, name, email, 'doctor' as role, status, created_at FROM doctor_users
                UNION ALL
                SELECT id, name, email, 'administrator' as role, status, created_at FROM admin_users
                ORDER BY created_at DESC
                """
            )
            return [dict(r) for r in cursor.fetchall()]
        else:
            conn.row_factory = sqlite3.Row
            return [dict(r) for r in conn.execute(
                """
                SELECT id, name, email, 'patient' as role, status, created_at FROM patient_users
                UNION ALL
                SELECT id, name, email, 'doctor' as role, status, created_at FROM doctor_users
                UNION ALL
                SELECT id, name, email, 'administrator' as role, status, created_at FROM admin_users
                ORDER BY created_at DESC
                """
            ).fetchall()]


def list_doctors() -> list[dict]:
    init_user_database()
    with get_db_connection() as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
                """
                SELECT doctor_users.id as user_id, doctor_users.name, doctor_users.email, doctor_users.status, doctors.id as doctor_id,
                       doctors.qualification, doctors.specialization, doctors.registration_number,
                       doctors.clinic_name, doctors.hospital_name, doctors.approval_status
                FROM doctor_users
                JOIN doctors ON doctors.user_id = doctor_users.id
                ORDER BY doctors.id DESC
                """
            )
            return [dict(r) for r in cursor.fetchall()]
        else:
            conn.row_factory = sqlite3.Row
            return [dict(r) for r in conn.execute(
                """
                SELECT doctor_users.id as user_id, doctor_users.name, doctor_users.email, doctor_users.status, doctors.id as doctor_id,
                       doctors.qualification, doctors.specialization, doctors.registration_number,
                       doctors.clinic_name, doctors.hospital_name, doctors.approval_status
                FROM doctor_users
                JOIN doctors ON doctors.user_id = doctor_users.id
                ORDER BY doctors.id DESC
                """
            ).fetchall()]


def approve_doctor(user_id: int) -> bool:
    init_user_database()
    with get_db_connection() as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute("UPDATE doctor_users SET status = 'active' WHERE id = %s", (user_id,))
            cursor.execute("UPDATE doctors SET approval_status = 'approved' WHERE user_id = %s", (user_id,))
        else:
            cursor.execute("UPDATE doctor_users SET status = 'active' WHERE id = ?", (user_id,))
            cursor.execute("UPDATE doctors SET approval_status = 'approved' WHERE user_id = ?", (user_id,))
    return True


def deactivate_user(user_id: int) -> bool:
    init_user_database()
    with get_db_connection() as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute("UPDATE patient_users SET status = 'deactivated' WHERE id = %s", (user_id,))
            cursor.execute("UPDATE doctor_users SET status = 'deactivated' WHERE id = %s", (user_id,))
            cursor.execute("UPDATE admin_users SET status = 'deactivated' WHERE id = %s", (user_id,))
        else:
            cursor.execute("UPDATE patient_users SET status = 'deactivated' WHERE id = ?", (user_id,))
            cursor.execute("UPDATE doctor_users SET status = 'deactivated' WHERE id = ?", (user_id,))
            cursor.execute("UPDATE admin_users SET status = 'deactivated' WHERE id = ?", (user_id,))
    return True


def get_patient_profile(user_id: int) -> dict | None:
    init_user_database()
    with get_db_connection() as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
                """
                SELECT patient_users.id as user_id, patient_users.name, patient_users.email, 'patient' as role, patients.age, patients.gender, patients.phone, patients.medical_history, patients.profile_picture
                FROM patient_users
                LEFT JOIN patients ON patients.user_id = patient_users.id
                WHERE patient_users.id = %s
                """,
                (user_id,),
            )
            row = cursor.fetchone()
            return dict(row) if row else None
        else:
            conn.row_factory = sqlite3.Row
            row = conn.execute(
                """
                SELECT patient_users.id as user_id, patient_users.name, patient_users.email, 'patient' as role, patients.age, patients.gender, patients.phone, patients.medical_history, patients.profile_picture
                FROM patient_users
                LEFT JOIN patients ON patients.user_id = patient_users.id
                WHERE patient_users.id = ?
                """,
                (user_id,),
            ).fetchone()
            return dict(row) if row else None


def update_patient_profile(user_id: int, age: int | None, gender: str, phone: str, medical_history: str) -> dict:
    init_user_database()
    with get_db_connection() as (db_type, conn):
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
    with get_db_connection() as (db_type, conn):
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
    with get_db_connection() as (db_type, conn):
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
    with get_db_connection() as (db_type, conn):
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
    with get_db_connection() as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute("SELECT * FROM audit_logs ORDER BY timestamp DESC LIMIT 100")
            return [dict(r) for r in cursor.fetchall()]
        else:
            conn.row_factory = sqlite3.Row
            return [dict(r) for r in conn.execute("SELECT * FROM audit_logs ORDER BY datetime(timestamp) DESC LIMIT 100").fetchall()]


def _hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()
