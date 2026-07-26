import pytest
from services.user_store import (
    init_user_database,
    create_user,
    find_user_by_email,
    create_session,
    find_user_by_token,
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
