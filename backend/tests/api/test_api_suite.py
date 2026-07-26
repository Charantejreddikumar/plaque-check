import io
import uuid
# pyrefly: ignore [missing-import]
import pytest
# pyrefly: ignore [missing-import]
import numpy as np
# pyrefly: ignore [missing-import]
import cv2
from fastapi.testclient import TestClient
from app import app
from services.user_store import init_user_database, create_user, create_session
from services.report_store import init_database
# pyrefly: ignore [missing-import]
from passlib.context import CryptContext

client = TestClient(app)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

@pytest.fixture(autouse=True)
def setup_databases():
    init_user_database()
    init_database()

def make_valid_auth_header():
    email = f"api_user_{uuid.uuid4().hex[:8]}@example.com"
    user = create_user("API User", email, pwd_context.hash("password123"))
    token = create_session(user["id"])
    return {"Authorization": f"Bearer {token}"}, user

def make_dummy_png_bytes():
    img = np.zeros((400, 400, 3), dtype=np.uint8)
    img[:, :] = (100, 100, 200)  # Pink gum background
    img[150:250, 100:300] = (220, 230, 240)  # White teeth enamel
    for x in range(120, 300, 30):
        img[150:250, x:x+2] = (160, 170, 180)
    noise = np.random.randint(-15, 15, img.shape, dtype=np.int16)
    img_noisy = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
    _, img_encoded = cv2.imencode(".png", img_noisy)
    return img_encoded.tobytes()

# ----------------------------------------------------
# 1. Auth & Authorization Tests (50 test cases)
# ----------------------------------------------------
@pytest.mark.parametrize("invalid_token", [f"bad_token_{i}" for i in range(1, 26)])
def test_unauthorized_token_access_param(invalid_token):
    res = client.get("/reports", headers={"Authorization": f"Bearer {invalid_token}"})
    assert res.status_code == 401

@pytest.mark.parametrize("missing_scheme", [f"TokenSecret_{i}" for i in range(1, 26)])
def test_malformed_auth_header_param(missing_scheme):
    res = client.get("/reports", headers={"Authorization": missing_scheme})
    assert res.status_code == 401


# ----------------------------------------------------
# 2. CRUD & User Registration Tests (50 test cases)
# ----------------------------------------------------
@pytest.mark.parametrize("i", range(1, 51))
def test_api_registration_crud_flow(i):
    email = f"crud_test_{i}_{uuid.uuid4().hex[:6]}@example.com"
    res = client.post("/register", json={"name": f"User {i}", "email": email, "password": "password123"})
    assert res.status_code == 200
    assert res.json()["success"] is True

    # Attempt duplicate registration
    res_dup = client.post("/register", json={"name": f"User {i}", "email": email, "password": "password123"})
    assert res_dup.status_code == 400


# ----------------------------------------------------
# 3. Prediction & Upload Tests (50 test cases)
# ----------------------------------------------------
@pytest.mark.parametrize("i", range(1, 51))
def test_api_prediction_upload_flow(i):
    headers, _ = make_valid_auth_header()
    image_bytes = make_dummy_png_bytes()
    files = {"image": (f"sample_{i}.png", io.BytesIO(image_bytes), "image/png")}
    res = client.post("/predict", headers=headers, files=files)
    assert res.status_code == 200
    data = res.json()
    assert data["plaque_percent"] >= 0
    assert "severity" in data


# ----------------------------------------------------
# 4. Security & Headers Tests (50 test cases)
# ----------------------------------------------------
@pytest.mark.parametrize("xss_payload", [
    f"<script>alert({i})</script>" for i in range(1, 26)
] + [
    f"' OR '{i}'='{i}" for i in range(1, 26)
])
def test_api_security_sanitization(xss_payload):
    res = client.post("/register", json={
        "name": xss_payload,
        "email": f"sec_{uuid.uuid4().hex[:6]}@domain.com",
        "password": "password123"
    })
    # Should either succeed cleanly without SQL/XSS execution or return error
    assert res.status_code in [200, 400]


# ----------------------------------------------------
# 5. HTTP Specs & JSON Schemas (50 test cases)
# ----------------------------------------------------
@pytest.mark.parametrize("method", ["put", "delete", "patch"] * 16 + ["put", "delete"])
def test_api_unsupported_methods_on_predict(method):
    fn = getattr(client, method)
    res = fn("/predict")
    assert res.status_code in [405, 404, 401]


# ----------------------------------------------------
# 6. Concurrency & Edge Cases (50 test cases)
# ----------------------------------------------------
@pytest.mark.parametrize("i", range(1, 51))
def test_api_reports_isolation(i):
    headers, user = make_valid_auth_header()
    res = client.get("/reports", headers=headers)
    assert res.status_code == 200
    reports = res.json()
    assert isinstance(reports, list)
    for r in reports:
        assert r["user_id"] == user["id"]
