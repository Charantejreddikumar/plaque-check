import io
import uuid
import numpy as np
import cv2
from locust import HttpUser, task, between

class PlaqueCheckUser(HttpUser):
    wait_time = between(1, 3)

    def on_start(self):
        """Register a user and log in to get a session token."""
        self.email = f"load_user_{uuid.uuid4().hex[:8]}@example.com"
        self.password = "password123"

        # Register
        self.client.post(
            "/register",
            json={"name": "Load Tester", "email": self.email, "password": self.password},
        )

        # Login
        res = self.client.post(
            "/login",
            json={"email": self.email, "password": self.password},
        )
        if res.status_code == 200:
            data = res.json()
            self.token = data.get("access_token", "")
            self.headers = {"Authorization": f"Bearer {self.token}"}
        else:
            self.token = ""
            self.headers = {}

    @task(3)
    def test_health_check(self):
        self.client.get("/health")

    @task(2)
    def test_reports_list(self):
        if self.token:
            self.client.get("/reports", headers=self.headers)

    @task(1)
    def test_predict_endpoint(self):
        if self.token:
            img = np.full((30, 30, 3), 220, dtype=np.uint8)
            _, img_encoded = cv2.imencode(".png", img)
            image_bytes = img_encoded.tobytes()
            files = {"image": ("load_test.png", io.BytesIO(image_bytes), "image/png")}
            self.client.post("/predict", headers=self.headers, files=files)
