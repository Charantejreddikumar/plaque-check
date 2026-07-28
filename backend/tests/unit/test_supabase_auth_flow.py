import os
import sqlite3
import pytest
from fastapi.testclient import TestClient

from app import app
from services.db import get_db_type, get_db_connection
from services.user_store import create_user, find_user_by_email, create_session, find_user_by_token

client = TestClient(app)


def test_db_type_dynamic():
    # Verify get_db_type returns sqlite when DATABASE_URL is empty
    orig_env = os.environ.get("DATABASE_URL")
    try:
        os.environ["DATABASE_URL"] = ""
        assert get_db_type() == "sqlite"

        os.environ["DATABASE_URL"] = "postgresql://user:pass@localhost:5432/dbname"
        assert get_db_type() == "postgres"
    finally:
        if orig_env is None:
            os.environ.pop("DATABASE_URL", None)
        else:
            os.environ["DATABASE_URL"] = orig_env


def test_auth_registration_and_login_flow():
    email = "testuser_persistence@example.com"
    password = "secretpassword123"
    name = "Test Persistence User"

    # 1. Register new user via API endpoint
    reg_response = client.post(
        "/register",
        json={"name": name, "email": email, "password": password},
    )
    assert reg_response.status_code == 200
    assert reg_response.json()["success"] is True

    # 2. Attempt duplicate registration (should return 400 Email already registered)
    dup_response = client.post(
        "/register",
        json={"name": name, "email": email.upper(), "password": password},
    )
    assert dup_response.status_code == 400
    assert "Email already registered" in dup_response.json()["detail"]

    # 3. Log in with original credentials
    login_response = client.post(
        "/login",
        json={"email": email, "password": password},
    )
    assert login_response.status_code == 200
    login_data = login_response.json()
    assert login_data["success"] is True
    assert login_data["email"] == email.lower()
    assert "access_token" in login_data

    # 4. Log in with uppercase email variation (verifying case insensitivity)
    login_response_upper = client.post(
        "/login",
        json={"email": email.upper(), "password": password},
    )
    assert login_response_upper.status_code == 200
    assert login_response_upper.json()["user_id"] == login_data["user_id"]

    # 5. Invalid password attempt should return 401
    bad_pass_response = client.post(
        "/login",
        json={"email": email, "password": "wrongpassword"},
    )
    assert bad_pass_response.status_code == 401
    assert "Invalid credentials" in bad_pass_response.json()["detail"]
