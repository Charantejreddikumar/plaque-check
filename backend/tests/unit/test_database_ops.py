import pytest
from services.user_store import (
    get_db_connection,
    init_user_database,
    create_user,
    find_user_by_email,
    create_session,
    find_user_by_token,
    pwd_context,
)
from services.report_store import init_database, save_report, list_reports

def test_user_and_session_db_operations():
    init_user_database()
    email = f"db_user_{pytest.importorskip('uuid').uuid4().hex[:8]}@example.com"

    # User creation & lookup
    user = create_user("DB User", email, "hashed_secret")
    assert user["id"] is not None
    assert user["email"] == email

    found = find_user_by_email(email)
    assert found is not None
    assert found["name"] == "DB User"

    # Session creation & token lookup
    token = create_session(user["id"])
    assert token is not None

    session_user = find_user_by_token(token)
    assert session_user is not None
    assert session_user["id"] == user["id"]

    # Invalid token lookup
    assert find_user_by_token("invalid_token_string") is None
    assert find_user_by_token("") is None


def test_role_stamped_session_resolves_login_role_when_role_tables_collide():
    init_user_database(force=True)
    password_hash = pwd_context.hash("password123")
    with get_db_connection() as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute("SELECT COALESCE(MAX(id), 0) + 1000 FROM patient_users")
            user_id = cursor.fetchone()[0]
            cursor.execute(
                "INSERT INTO patient_users (id, name, email, password_hash, status, created_at, updated_at) VALUES (%s, %s, %s, %s, 'active', %s, %s)",
                (user_id, "Patient Collision", f"patient_collision_{user_id}@example.com", password_hash, "2026-01-01T00:00:00+00:00", "2026-01-01T00:00:00+00:00"),
            )
            cursor.execute(
                "INSERT INTO doctor_users (id, name, email, password_hash, status, created_at, updated_at) VALUES (%s, %s, %s, %s, 'active', %s, %s)",
                (user_id, "Doctor Collision", f"doctor_collision_{user_id}@example.com", password_hash, "2026-01-01T00:00:00+00:00", "2026-01-01T00:00:00+00:00"),
            )
        else:
            cursor.execute("SELECT COALESCE(MAX(id), 0) + 1000 FROM patient_users")
            user_id = cursor.fetchone()[0]
            cursor.execute(
                "INSERT INTO patient_users (id, name, email, password_hash, status, created_at, updated_at) VALUES (?, ?, ?, ?, 'active', ?, ?)",
                (user_id, "Patient Collision", f"patient_collision_{user_id}@example.com", password_hash, "2026-01-01T00:00:00+00:00", "2026-01-01T00:00:00+00:00"),
            )
            cursor.execute(
                "INSERT INTO doctor_users (id, name, email, password_hash, status, created_at, updated_at) VALUES (?, ?, ?, ?, 'active', ?, ?)",
                (user_id, "Doctor Collision", f"doctor_collision_{user_id}@example.com", password_hash, "2026-01-01T00:00:00+00:00", "2026-01-01T00:00:00+00:00"),
            )

    token = create_session(user_id, role="doctor")
    session_user = find_user_by_token(token)

    assert session_user is not None
    assert session_user["role"] == "doctor"
    assert session_user["email"] == f"doctor_collision_{user_id}@example.com"

def test_report_db_operations():
    init_database()
    pred = {
        "image_path": "uploads/1/a.jpg",
        "processed_image": "processed/1/a.png",
        "plaque_percent": 25,
        "severity": "Moderate",
        "confidence": 0.8,
        "recommendation": "Brush thoroughly",
    }
    saved = save_report(99, pred)
    assert saved["report_id"] is not None
    assert saved["user_id"] == 99

    user_reports = list_reports(99)
    assert len(user_reports) >= 1
    assert any(r["report_id"] == saved["report_id"] for r in user_reports)
