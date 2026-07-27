import io
import cv2
import numpy as np
import pytest
from fastapi.testclient import TestClient

from app import app
from services.user_store import create_session, create_user, init_user_database
from passlib.context import CryptContext

client = TestClient(app)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


@pytest.fixture(autouse=True)
def setup_db():
    init_user_database()


def create_test_user(name_prefix: str) -> tuple[dict, str]:
    email = f"{name_prefix}_{pytest.importorskip('uuid').uuid4().hex[:8]}@example.com"
    user = create_user(f"User {name_prefix}", email, pwd_context.hash("password123"))
    token = create_session(user["id"])
    return user, token


def create_synthetic_teeth_bytes() -> bytes:
    img = np.zeros((400, 400, 3), dtype=np.uint8)
    img[:, :] = (100, 100, 200)  # Pink gum background
    img[150:250, 100:300] = (220, 230, 240)  # White teeth enamel
    for x in range(120, 300, 30):
        img[150:250, x:x+2] = (160, 170, 180)
    noise = np.random.randint(-15, 15, img.shape, dtype=np.int16)
    img_noisy = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
    _, img_encoded = cv2.imencode(".png", img_noisy)
    return img_encoded.tobytes()


def test_user_reports_data_isolation():
    user_a, token_a = create_test_user("usera")
    user_b, token_b = create_test_user("userb")

    image_bytes = create_synthetic_teeth_bytes()

    # User A submits a scan
    headers_a = {"Authorization": f"Bearer {token_a}"}
    files = {"image": ("teeth_a.png", io.BytesIO(image_bytes), "image/png")}
    res_a = client.post("/predict", headers=headers_a, files=files)
    assert res_a.status_code == 200
    data_a = res_a.json()
    assert data_a["user_id"] == user_a["id"]

    # User A views their reports
    reports_a = client.get("/reports", headers=headers_a).json()
    assert len(reports_a) == 1
    assert reports_a[0]["user_id"] == user_a["id"]

    # User B views their reports -> Must be empty (0 reports)
    headers_b = {"Authorization": f"Bearer {token_b}"}
    reports_b = client.get("/reports", headers=headers_b).json()
    assert len(reports_b) == 0


def test_user_media_file_access_denied_for_other_user():
    user_a, token_a = create_test_user("usera_media")
    user_b, token_b = create_test_user("userb_media")

    image_bytes = create_synthetic_teeth_bytes()
    headers_a = {"Authorization": f"Bearer {token_a}"}
    files = {"image": ("teeth_a.png", io.BytesIO(image_bytes), "image/png")}
    res_a = client.post("/predict", headers=headers_a, files=files)
    assert res_a.status_code == 200
    processed_path = res_a.json()["processed_image"]

    # User B attempts to access User A's media file directly
    headers_b = {"Authorization": f"Bearer {token_b}"}
    res_media_b = client.get(f"/{processed_path}", headers=headers_b)
    # Must be 403 Forbidden
    assert res_media_b.status_code == 403
    assert res_media_b.json()["detail"] == "File access denied"


def test_user_media_file_access_with_query_param_token():
    user_a, token_a = create_test_user("usera_query_token")

    image_bytes = create_synthetic_teeth_bytes()
    headers_a = {"Authorization": f"Bearer {token_a}"}
    files = {"image": ("teeth_a.png", io.BytesIO(image_bytes), "image/png")}
    res_a = client.post("/predict", headers=headers_a, files=files)
    assert res_a.status_code == 200
    processed_path = res_a.json()["processed_image"]

    # User A accesses media file using URL query param ?token=... without Authorization header
    res_media_query = client.get(f"/{processed_path}?token={token_a}")
    assert res_media_query.status_code == 200
    assert len(res_media_query.content) > 0


def test_logout_session_invalidation():
    user, token = create_test_user("logout_user")
    headers = {"Authorization": f"Bearer {token}"}

    # Verify endpoint works with token
    res_reports = client.get("/reports", headers=headers)
    assert res_reports.status_code == 200

    # Perform logout
    res_logout = client.post("/logout", headers=headers)
    assert res_logout.status_code == 200
    assert res_logout.json()["success"] is True

    # Subsequent request using invalidated token must return 401
    res_invalid = client.get("/reports", headers=headers)
    assert res_invalid.status_code == 401
    assert res_invalid.json()["detail"] == "Invalid session"
