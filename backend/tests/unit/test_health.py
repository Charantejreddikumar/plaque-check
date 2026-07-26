# pyrefly: ignore [missing-import]
import pytest
from fastapi.testclient import TestClient
from app import app

client = TestClient(app)

def test_health_check_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.text == '"PlaqueCheck backend running"'

def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    json_data = response.json()
    assert json_data == {"status": "backend healthy"}

def test_version_endpoint():
    response = client.get("/version")
    assert response.status_code == 200
    json_data = response.json()
    assert json_data["name"] == "PlaqueCheck Backend"
    assert "version" in json_data
