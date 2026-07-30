import uuid
import pytest
from fastapi.testclient import TestClient

from app import app
from services.user_store import init_user_database
from services.report_store import init_database

client = TestClient(app)


@pytest.fixture(autouse=True)
def setup_databases():
    init_user_database()
    init_database()


def test_patient_registration_and_login_flow():
    email = f"patient_{uuid.uuid4().hex[:8]}@example.com"
    # 1. Register Patient
    res = client.post("/register", json={"name": "Test Patient", "email": email, "password": "password123"})
    assert res.status_code == 200
    assert res.json()["success"] is True

    # 2. Login Patient
    res_login = client.post("/login", json={"email": email, "password": "password123"})
    assert res_login.status_code == 200
    data = res_login.json()
    assert data["role"] == "patient"
    assert "access_token" in data
    patient_token = data["access_token"]

    # 3. Patient RBAC Security Check (Must fail on Doctor/Admin endpoints)
    res_doc_dash = client.get("/doctor/dashboard", headers={"Authorization": f"Bearer {patient_token}"})
    assert res_doc_dash.status_code == 403

    res_admin_dash = client.get("/admin/dashboard", headers={"Authorization": f"Bearer {patient_token}"})
    assert res_admin_dash.status_code == 403


def test_doctor_onboarding_approval_and_dashboard_flow():
    email = f"doctor_{uuid.uuid4().hex[:8]}@example.com"
    # 1. Register Doctor
    res_reg = client.post(
        "/register/doctor",
        json={
            "name": "Dr. Sarah Jenkins",
            "email": email,
            "password": "password123",
            "mobile": "+1555019283",
            "qualification": "MDS Periodontics",
            "specialization": "Dental Surgeon",
            "registration_number": "DENT-99182",
            "clinic_name": "Smile Care Clinic",
            "hospital_name": "City General Hospital",
        },
    )
    assert res_reg.status_code == 200

    # 2. Unapproved Doctor Login Attempt (Must fail with 403 Pending Approval)
    res_unapproved = client.post("/login", json={"email": email, "password": "password123"})
    assert res_unapproved.status_code == 403
    assert "pending administrator approval" in res_unapproved.json()["detail"].lower()

    # 3. Admin Login & Doctor Approval
    res_admin_login = client.post("/login", json={"email": "admin@plaquecheck.com", "password": "password123"})
    assert res_admin_login.status_code == 200
    admin_token = res_admin_login.json()["access_token"]

    res_doc_list = client.get("/admin/doctors", headers={"Authorization": f"Bearer {admin_token}"})
    assert res_doc_list.status_code == 200
    doctors = res_doc_list.json()

    target_doc = next(d for d in doctors if d["email"].lower() == email.lower())
    doc_user_id = target_doc["user_id"]

    # Approve Doctor
    res_approve = client.post(f"/admin/doctors/{doc_user_id}/approve", headers={"Authorization": f"Bearer {admin_token}"})
    assert res_approve.status_code == 200

    # 4. Approved Doctor Login Attempt (Must succeed now)
    res_doc_login = client.post("/login", json={"email": email, "password": "password123"})
    assert res_doc_login.status_code == 200
    doc_token = res_doc_login.json()["access_token"]
    assert res_doc_login.json()["role"] == "doctor"

    # 5. Doctor Dashboard Access
    res_dash = client.get("/doctor/dashboard", headers={"Authorization": f"Bearer {doc_token}"})
    assert res_dash.status_code == 200
    dash_data = res_dash.json()
    assert "total_patients" in dash_data
    assert "pending_reviews" in dash_data


def test_admin_dashboard_and_audit_logs():
    res_admin_login = client.post("/login", json={"email": "admin@plaquecheck.com", "password": "password123"})
    assert res_admin_login.status_code == 200
    admin_token = res_admin_login.json()["access_token"]

    res_dash = client.get("/admin/dashboard", headers={"Authorization": f"Bearer {admin_token}"})
    assert res_dash.status_code == 200
    data = res_dash.json()
    assert "total_users" in data
    assert "model_version" in data
    assert "average_accuracy" in data

    res_logs = client.get("/admin/audit-logs", headers={"Authorization": f"Bearer {admin_token}"})
    assert res_logs.status_code == 200
    assert isinstance(res_logs.json(), list)
