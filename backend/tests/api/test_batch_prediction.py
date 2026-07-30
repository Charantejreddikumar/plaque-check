import io
import uuid
import pytest
import numpy as np
import cv2
from fastapi.testclient import TestClient

from app import app
from services.user_store import init_user_database, create_user, create_session
from services.report_store import init_database
from passlib.context import CryptContext

client = TestClient(app)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


@pytest.fixture(autouse=True)
def setup_databases():
    init_user_database()
    init_database()


def make_valid_auth_header():
    email = f"batch_user_{uuid.uuid4().hex[:8]}@example.com"
    user = create_user("Batch User", email, pwd_context.hash("password123"))
    token = create_session(user["id"])
    return {"Authorization": f"Bearer {token}"}, user


def make_dummy_teeth_png_bytes():
    img = np.zeros((400, 400, 3), dtype=np.uint8)
    img[:, :] = (100, 100, 200)  # Pink gum/lip background
    img[150:250, 100:300] = (220, 230, 240)  # White teeth enamel
    for x in range(120, 300, 30):
        img[150:250, x:x+2] = (160, 170, 180)  # Tooth gaps
    noise = np.random.randint(-15, 15, img.shape, dtype=np.int16)
    img_noisy = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
    _, img_encoded = cv2.imencode(".png", img_noisy)
    return img_encoded.tobytes()


def make_non_teeth_png_bytes():
    # Completely black image (fails resolution/darkness/teeth enamel validation)
    img = np.zeros((100, 100, 3), dtype=np.uint8)
    _, img_encoded = cv2.imencode(".png", img)
    return img_encoded.tobytes()


def test_batch_prediction_three_images_success():
    headers, _ = make_valid_auth_header()
    files = [
        ("images", ("teeth_front.png", io.BytesIO(make_dummy_teeth_png_bytes()), "image/png")),
        ("images", ("teeth_left.png", io.BytesIO(make_dummy_teeth_png_bytes()), "image/png")),
        ("images", ("teeth_right.png", io.BytesIO(make_dummy_teeth_png_bytes()), "image/png")),
    ]
    res = client.post("/predict/batch", headers=headers, files=files)
    assert res.status_code == 200
    data = res.json()

    assert "plaque_percent" in data
    assert "severity" in data
    assert "individual_results" in data
    assert len(data["individual_results"]) == 3
    assert data["image_count"] == 3

    # Check that average plaque calculation is correct
    scores = [item["plaque_percent"] for item in data["individual_results"]]
    expected_avg = int(round(sum(scores) / 3))
    assert data["plaque_percent"] == expected_avg


def test_batch_prediction_auditing_rejection_on_invalid_image():
    headers, _ = make_valid_auth_header()
    files = [
        ("images", ("teeth_front.png", io.BytesIO(make_dummy_teeth_png_bytes()), "image/png")),
        ("images", ("invalid_photo.png", io.BytesIO(make_non_teeth_png_bytes()), "image/png")),
        ("images", ("teeth_right.png", io.BytesIO(make_dummy_teeth_png_bytes()), "image/png")),
    ]
    res = client.post("/predict/batch", headers=headers, files=files)
    assert res.status_code == 400
    data = res.json()
    assert "detail" in data
    assert "failed auditing" in data["detail"].lower() or "not a valid teeth image" in data["detail"].lower()
