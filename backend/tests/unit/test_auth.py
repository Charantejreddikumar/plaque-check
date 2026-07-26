# pyrefly: ignore [missing-import]
import pytest
from fastapi.testclient import TestClient
from app import app
from services.user_store import init_user_database

client = TestClient(app)

@pytest.fixture(autouse=True)
def setup_db():
    init_user_database()

def test_register_success():
    email = f"user_{pytest.importorskip('uuid').uuid4().hex[:8]}@example.com"
    response = client.post(
        "/register",
        json={"name": "Test User", "email": email, "password": "password123"},
    )
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["success"] is True
    assert json_data["message"] == "Account created"

def test_register_duplicate_email():
    email = f"user_{pytest.importorskip('uuid').uuid4().hex[:8]}@example.com"
    payload = {"name": "Test User", "email": email, "password": "password123"}
    res1 = client.post("/register", json=payload)
    assert res1.status_code == 200

    res2 = client.post("/register", json=payload)
    assert res2.status_code == 400
    assert "Email already registered" in res2.json()["detail"]

def test_register_invalid_inputs():
    res1 = client.post("/register", json={"name": "", "email": "test@example.com", "password": "pass"})
    assert res1.status_code == 400

    res2 = client.post("/register", json={"name": "User", "email": "invalid-email", "password": "password123"})
    assert res2.status_code == 400

    res3 = client.post("/register", json={"name": "User", "email": "valid@example.com", "password": "123"})
    assert res3.status_code == 400

def test_login_success_and_invalid_credentials():
    email = f"login_{pytest.importorskip('uuid').uuid4().hex[:8]}@example.com"
    client.post("/register", json={"name": "Login User", "email": email, "password": "securepassword"})

    # Valid login
    res = client.post("/login", json={"email": email, "password": "securepassword"})
    assert res.status_code == 200
    body = res.json()
    assert body["success"] is True
    assert "access_token" in body
    assert body["token_type"] == "bearer"

    # Invalid password
    res_bad = client.post("/login", json={"email": email, "password": "wrongpassword"})
    assert res_bad.status_code == 401
