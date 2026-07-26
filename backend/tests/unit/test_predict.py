import io
# pyrefly: ignore [missing-import]
import pytest
from fastapi.testclient import TestClient
from app import app
from services.user_store import create_user, create_session, init_user_database
# pyrefly: ignore [missing-import]
from passlib.context import CryptContext

client = TestClient(app)
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

@pytest.fixture(autouse=True)
def setup_db():
    init_user_database()

def get_auth_header():
    email = f"predict_user_{pytest.importorskip('uuid').uuid4().hex[:8]}@example.com"
    user = create_user("Predict User", email, pwd_context.hash("password123"))
    token = create_session(user["id"])
    return {"Authorization": f"Bearer {token}"}

def test_predict_unauthorized():
    res = client.post("/predict")
    assert res.status_code == 401

def test_predict_valid_image():
    headers = get_auth_header()
    # Create a tiny 10x10 white PNG image
    # pyrefly: ignore [missing-import]
    import cv2
    import numpy as np
    img = np.full((10, 10, 3), 255, dtype=np.uint8)
    _, img_encoded = cv2.imencode(".png", img)
    image_bytes = img_encoded.tobytes()

    files = {"image": ("test_teeth.png", io.BytesIO(image_bytes), "image/png")}
    res = client.post("/predict", headers=headers, files=files)
    assert res.status_code == 200
    data = res.json()
    assert "plaque_percent" in data
    assert "severity" in data
    assert "report_id" in data

def test_predict_invalid_extension():
    headers = get_auth_header()
    files = {"image": ("test.txt", io.BytesIO(b"not an image"), "text/plain")}
    res = client.post("/predict", headers=headers, files=files)
    assert res.status_code == 400

def test_predict_empty_file():
    headers = get_auth_header()
    files = {"image": ("test.png", io.BytesIO(b""), "image/png")}
    res = client.post("/predict", headers=headers, files=files)
    assert res.status_code == 400
