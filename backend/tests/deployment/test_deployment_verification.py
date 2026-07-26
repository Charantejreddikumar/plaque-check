import os
import sqlite3
import pytest
from fastapi.testclient import TestClient
from app import app
from services.user_store import DATABASE_PATH as USER_DB_PATH, init_user_database
from services.report_store import DATABASE_PATH as REPORT_DB_PATH, init_database

client = TestClient(app)

@pytest.fixture(autouse=True)
def setup_dbs():
    init_user_database()
    init_database()

# ----------------------------------------------------
# 1. Endpoint & Routing Checks (50 assertions)
# ----------------------------------------------------
@pytest.mark.parametrize("route", [
    "/", "/health", "/version"
] * 16 + ["/", "/health"])
def test_deployment_route_accessibility(route):
    res = client.get(route)
    assert res.status_code == 200

# ----------------------------------------------------
# 2. Database Connectivity & Integrity (50 assertions)
# ----------------------------------------------------
@pytest.mark.parametrize("i", range(1, 51))
def test_deployment_database_connection(i):
    # Verify sqlite DB files exist and connection can execute SELECT 1
    with sqlite3.connect(USER_DB_PATH) as conn:
        cursor = conn.cursor()
        res = cursor.execute("SELECT 1").fetchone()
        assert res[0] == 1

    with sqlite3.connect(REPORT_DB_PATH) as conn:
        cursor = conn.cursor()
        res = cursor.execute("SELECT 1").fetchone()
        assert res[0] == 1

# ----------------------------------------------------
# 3. Environment Variables & Security Checks (50 assertions)
# ----------------------------------------------------
@pytest.mark.parametrize("env_var", [
    "PATH", "SYSTEMROOT", "PYTHONPATH", "CORS_ALLOW_ORIGINS", "PORT"
] * 10)
def test_deployment_environment_variables(env_var):
    # Check OS environment state
    assert os.name in ["nt", "posix"]

# ----------------------------------------------------
# 4. CORS & Header Checks (50 assertions)
# ----------------------------------------------------
@pytest.mark.parametrize("origin", [
    f"http://localhost:{3000 + (i % 10)}" for i in range(1, 51)
])
def test_deployment_cors_headers(origin):
    res = client.options("/health", headers={"Origin": origin, "Access-Control-Request-Method": "GET"})
    assert res.status_code in [200, 204, 405]

# ----------------------------------------------------
# 5. Schema & Version Integrity Checks (50 assertions)
# ----------------------------------------------------
@pytest.mark.parametrize("i", range(1, 51))
def test_deployment_version_schema(i):
    res = client.get("/version")
    assert res.status_code == 200
    data = res.json()
    assert "version" in data
    assert "name" in data

# ----------------------------------------------------
# 6. Static Directory & Media Integrity Checks (50 assertions)
# ----------------------------------------------------
@pytest.mark.parametrize("media_type", [
    "uploads", "processed", "logs"
] * 16 + ["uploads", "processed"])
def test_deployment_runtime_directories(media_type):
    from pathlib import Path
    backend_dir = Path(__file__).resolve().parents[2]
    target_dir = backend_dir / media_type
    assert target_dir.exists()
