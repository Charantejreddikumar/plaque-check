import pytest
from fastapi.testclient import TestClient
from app import app
from services.user_store import create_user, create_session, init_user_database
from services.report_store import init_database, save_report
from passlib.context import CryptContext

client = TestClient(app)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

@pytest.fixture(autouse=True)
def setup_db():
    init_user_database()
    init_database()

def test_list_reports_unauthorized():
    res = client.get("/reports")
    assert res.status_code == 401

def test_list_reports_empty_and_populated():
    email = f"reports_user_{pytest.importorskip('uuid').uuid4().hex[:8]}@example.com"
    user = create_user("Reports User", email, pwd_context.hash("password123"))
    token = create_session(user["id"])
    headers = {"Authorization": f"Bearer {token}"}

    # Empty
    res1 = client.get("/reports", headers=headers)
    assert res1.status_code == 200
    assert res1.json() == []

    # Save a report
    save_report(
        user["id"],
        {
            "image_path": "uploads/test.jpg",
            "processed_image": "processed/test.png",
            "plaque_percent": 15,
            "severity": "Low",
            "confidence": 0.9,
            "recommendation": "Maintain hygiene",
        },
    )

    res2 = client.get("/reports", headers=headers)
    assert res2.status_code == 200
    reports = res2.json()
    assert len(reports) == 1
    assert reports[0]["plaque_percent"] == 15
    assert reports[0]["user_id"] == user["id"]
