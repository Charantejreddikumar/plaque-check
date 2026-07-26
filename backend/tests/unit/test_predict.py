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

def test_predict_valid_teeth_image():
    headers = get_auth_header()
    # pyrefly: ignore [missing-import]
    import cv2
    # pyrefly: ignore [missing-import]
    import numpy as np
    
    # Create a synthetic valid dental photo
    img = np.zeros((400, 400, 3), dtype=np.uint8)
    img[:, :] = (100, 100, 200)  # Pink gum background
    img[150:250, 100:300] = (220, 230, 240)  # White teeth enamel
    for x in range(120, 300, 30):
        img[150:250, x:x+2] = (160, 170, 180)
    noise = np.random.randint(-15, 15, img.shape, dtype=np.int16)
    img_noisy = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
    
    _, img_encoded = cv2.imencode(".png", img_noisy)
    image_bytes = img_encoded.tobytes()

    files = {"image": ("test_teeth.png", io.BytesIO(image_bytes), "image/png")}
    res = client.post("/predict", headers=headers, files=files)
    assert res.status_code == 200
    data = res.json()
    assert "plaque_percent" in data
    assert "severity" in data
    assert "report_id" in data
    assert data["plaque_percent"] == 0
    assert data["recommendation"] == "No plaque detected."

def test_predict_non_teeth_image_rejected():
    headers = get_auth_header()
    # pyrefly: ignore [missing-import]
    import cv2
    # pyrefly: ignore [missing-import]
    import numpy as np
    # Solid black image or document simulation
    img = np.full((300, 300, 3), 10, dtype=np.uint8)
    _, img_encoded = cv2.imencode(".png", img)
    files = {"image": ("dark_photo.png", io.BytesIO(img_encoded.tobytes()), "image/png")}
    res = client.post("/predict", headers=headers, files=files)
    assert res.status_code == 400
    assert res.json()["detail"] == "Please upload a clear image showing human teeth."

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
