import os
import sqlite3
import pytest
from fastapi.testclient import TestClient

from app import app
from services.db import get_db_type, get_db_connection, _get_clean_database_url

client = TestClient(app)


def test_db_type_dynamic():
    # Verify get_db_type returns sqlite when DATABASE_URL is empty
    env_keys = ("SUPABASE_DATABASE_URL", "SUPABASE_DB_URL", "DATABASE_URL", "Database_URL", "database_url")
    orig_env = {k: os.environ.get(k) for k in env_keys}
    try:
        for k in env_keys:
            os.environ.pop(k, None)
        os.environ["DATABASE_URL"] = ""
        assert get_db_type() == "sqlite"

        os.environ["DATABASE_URL"] = "postgresql://user:pass@localhost:5432/dbname"
        assert get_db_type() == "postgres"
    finally:
        for k, v in orig_env.items():
            if v is None:
                os.environ.pop(k, None)
            else:
                os.environ[k] = v


def test_clean_database_url_bracket_and_case_handling():
    env_keys = ("SUPABASE_DATABASE_URL", "SUPABASE_DB_URL", "DATABASE_URL", "Database_URL", "database_url")
    orig_env = {k: os.environ.get(k) for k in env_keys}
    try:
        for k in env_keys:
            os.environ.pop(k, None)

        # Test Database_URL casing tolerance and [bracket] stripping + '#' encoding
        os.environ["Database_URL"] = "postgresql://postgres:[Bunny_a2005#]@db.supabase.co:5432/postgres"
        cleaned = _get_clean_database_url()
        assert cleaned == "postgresql://postgres:Bunny_a2005%23@db.supabase.co:5432/postgres"
        assert get_db_type() == "postgres"

        # Test password containing '@' and '#'
        os.environ["DATABASE_URL"] = "postgresql://postgres:Bunny_@2005#@db.xksvrcqllfevtqndchml.supabase.co:5432/postgres"
        cleaned_at = _get_clean_database_url()
        assert cleaned_at == "postgresql://postgres:Bunny_%402005%23@db.xksvrcqllfevtqndchml.supabase.co:5432/postgres"
    finally:
        for k, v in orig_env.items():
            if v is None:
                os.environ.pop(k, None)
            else:
                os.environ[k] = v




from uuid import uuid4

def test_auth_registration_and_login_flow():
    email = f"testuser_persistence_{uuid4().hex[:8]}@example.com"
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
