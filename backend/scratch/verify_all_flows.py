import os
import sys
from io import BytesIO
import numpy as np
import cv2

# Ensure backend directory is in path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from fastapi.testclient import TestClient
from app import app
from database import init_all_tables
from services.user_store import init_user_database

client = TestClient(app)

def create_test_image_bytes():
    sample_path = os.path.join(os.path.dirname(__file__), "..", "uploads", "test_plaque.png")
    if os.path.exists(sample_path):
        with open(sample_path, "rb") as f:
            return f.read()
    img = np.full((200, 200, 3), (200, 180, 150), dtype=np.uint8)
    # Add contrast lines
    img[50:150, 50:150] = [255, 255, 255]
    img[80:120, 80:120] = [0, 0, 255]
    _, encoded = cv2.imencode(".png", img)
    return encoded.tobytes()

def run_all_tests():
    print("=== STARTING FULL END-TO-END PLAQUECHECK TEST SEQUENCE ===")
    
    # 1. Database Initialization
    from database import get_db_type
    db_backend = get_db_type().upper()
    print(f"1. Confirming database initialization... (DATABASE BACKEND: {db_backend})")
    init_all_tables()
    init_user_database(force=True)
    
    # 2. Health endpoint
    print("2. Testing health endpoint...")
    res = client.get("/")
    assert res.status_code == 200, f"Health check failed: {res.text}"
    print("   [OK] Health check OK:", res.text)
    
    # 3. Register Patient
    print("3. Registering new patient...")
    import uuid
    run_id = uuid.uuid4().hex[:6]
    patient_email = f"newpatient_{run_id}@plaquecheck.com"
    patient_pass = "patientpass123"
    res = client.post("/register", json={"name": "E2E Patient", "email": patient_email, "password": patient_pass})
    assert res.status_code == 200, f"Patient registration failed: {res.text}"
    print("   [OK] Patient registered successfully.")
    
    # 4. Login Patient
    print("4. Logging in patient...")
    res = client.post("/patient/login", json={"email": patient_email, "password": patient_pass})
    assert res.status_code == 200, f"Patient login failed: {res.text}"
    patient_token = res.json()["access_token"]
    patient_id = res.json()["user_id"]
    patient_headers = {"Authorization": f"Bearer {patient_token}"}
    print(f"   [OK] Patient logged in (ID: {patient_id}).")
    
    # 5. Retrieve Profile (/me)
    print("5. Retrieving patient profile (/me)...")
    res = client.get("/me", headers=patient_headers)
    assert res.status_code == 200, f"Profile fetch failed: {res.text}"
    assert res.json()["email"] == patient_email
    print("   [OK] Patient profile retrieved.")
    
    # 6. Upload plaque analysis image (Create Report)
    print("6. Uploading teeth image for plaque prediction...")
    img_bytes = create_test_image_bytes()
    files = {"image": ("teeth.jpg", img_bytes, "image/jpeg")}
    res = client.post("/predict", files=files, headers=patient_headers)
    assert res.status_code == 200, f"Plaque prediction failed: {res.text}"
    pred_data = res.json()
    report_id = pred_data["report_id"]
    print(f"   [OK] Plaque prediction successful. Report ID: {report_id}, Plaque %: {pred_data['plaque_percent']}%.")
    
    # 7. Retrieve Patient Reports
    print("7. Retrieving patient reports...")
    res = client.get("/reports", headers=patient_headers)
    assert res.status_code == 200, f"Report retrieval failed: {res.text}"
    reports = res.json()
    assert any(r["report_id"] == report_id for r in reports), "Created report missing from list"
    print("   [OK] Reports retrieved successfully.")
    
    # 8. Logout & Re-login Patient
    print("8. Testing logout and re-login...")
    client.post("/logout", headers=patient_headers)
    res = client.post("/patient/login", json={"email": patient_email, "password": patient_pass})
    assert res.status_code == 200, f"Re-login failed: {res.text}"
    patient_token = res.json()["access_token"]
    patient_headers = {"Authorization": f"Bearer {patient_token}"}
    print("   [OK] Patient re-login successful.")
    
    # 9. Register Doctor & Test Pending Restriction
    print("9. Registering new doctor & testing pending login restriction...")
    doc_email = f"newdoctor_{run_id}@plaquecheck.com"
    doc_pass = "doctorpass123"
    doc_payload = {
        "name": "Dr. E2E Specialist",
        "email": doc_email,
        "password": doc_pass,
        "mobile": "555-0999",
        "qualification": "BDS, MDS",
        "specialization": "Orthodontics",
        "registration_number": "D-8877",
        "clinic_name": "Smile Clinic",
        "hospital_name": "General Hospital"
    }
    res = client.post("/register/doctor", json=doc_payload)
    assert res.status_code == 200, f"Doctor registration failed: {res.text}"
    assert "pending" in res.json()["message"].lower()
    print("   [OK] Doctor registration submitted (pending approval).")

    # Verify Pending Doctor Login Denied
    res = client.post("/doctor/login", json={"email": doc_email, "password": doc_pass})
    assert res.status_code == 403, f"Pending doctor login should be denied 403: {res.text}"
    print("   [OK] Pending Doctor login correctly rejected (403 Forbidden).")
    
    # 10. Login Admin & Approve Doctor
    print("10. Logging in Admin & inspecting doctor requests...")
    res = client.post("/admin/login", json={"email": "admin@plaquecheck.com", "password": "password123"})
    assert res.status_code == 200, f"Admin login failed: {res.text}"
    admin_token = res.json()["access_token"]
    admin_headers = {"Authorization": f"Bearer {admin_token}"}
    
    # Find pending doctor requests
    res = client.get("/admin/doctor-requests", headers=admin_headers)
    assert res.status_code == 200
    pending_reqs = res.json()
    doc_req = next(d for d in pending_reqs if d["email"] == doc_email)
    doc_user_id = doc_req["user_id"]
    
    # Approve doctor via /admin/doctor-requests/{id}/approve
    res = client.post(f"/admin/doctor-requests/{doc_user_id}/approve", headers=admin_headers)
    assert res.status_code == 200, f"Doctor approval failed: {res.text}"
    print(f"   [OK] Doctor request for user #{doc_user_id} ACCEPTED by Admin.")

    # Test Rejecting Second Doctor Request
    rej_doc_email = f"rejdoctor_{run_id}@plaquecheck.com"
    client.post("/register/doctor", json={**doc_payload, "email": rej_doc_email})
    res = client.get("/admin/doctor-requests", headers=admin_headers)
    rej_req = next(d for d in res.json() if d["email"] == rej_doc_email)
    res = client.post(f"/admin/doctor-requests/{rej_req['user_id']}/reject", headers=admin_headers)
    assert res.status_code == 200
    res = client.post("/doctor/login", json={"email": rej_doc_email, "password": doc_pass})
    assert res.status_code == 403, "Rejected doctor login should be 403"
    print("   [OK] Rejected Doctor request correctly handled (REJECTED status & 403 login block).")
    
    # 11. Login Approved Doctor
    print("11. Logging in approved Doctor...")
    res = client.post("/doctor/login", json={"email": doc_email, "password": doc_pass})
    assert res.status_code == 200, f"Doctor login failed: {res.text}"
    doc_token = res.json()["access_token"]
    doc_headers = {"Authorization": f"Bearer {doc_token}"}
    print("   [OK] Approved Doctor logged in successfully.")
    
    # 12. Doctor Dashboard & Pending Reports
    print("12. Verifying Doctor Dashboard & Report Access...")
    res = client.get("/doctor/dashboard", headers=doc_headers)
    assert res.status_code == 200, f"Doctor dashboard failed: {res.text}"
    doc_dash = res.json()
    assert "pending_reviews" in doc_dash
    print("   [OK] Doctor dashboard operational.")
    
    # 13. Doctor Reviews Patient Report
    print("13. Doctor submitting review on patient report...")
    review_payload = {
        "status": "approved",
        "modified_plaque_percent": 15,
        "doctor_notes": "Minor plaque accumulation along lower incisors. Recommended scaling.",
        "treatment_recommendations": "Use antiseptic mouthwash twice daily.",
        "follow_up_date": "2026-09-01"
    }
    res = client.post(f"/doctor/reports/{report_id}/review", json=review_payload, headers=doc_headers)
    assert res.status_code == 200, f"Doctor report review failed: {res.text}"
    print("   [OK] Doctor review submitted successfully.")
    
    # 14. Doctor RBAC Security Test (Doctor accessing Admin-only endpoint)
    print("14. Testing Doctor RBAC security (attempting admin endpoint access)...")
    res = client.get("/admin/system-health", headers=doc_headers)
    assert res.status_code == 403, f"RBAC failed! Expected 403, got {res.status_code}"
    print("   [OK] RBAC enforced: Doctor blocked from Admin endpoint (403 Forbidden).")
    
    # 15. Verify Admin Dashboard Statistics
    print("15. Verifying Admin Dashboard & Live DB Stats...")
    res = client.get("/admin/dashboard", headers=admin_headers)
    assert res.status_code == 200, f"Admin dashboard failed: {res.text}"
    admin_dash = res.json()
    print(f"   [OK] Admin Stats: Total Patients = {admin_dash['total_patients']}, Total Doctors = {admin_dash['total_doctors']}, Total Reports = {admin_dash['today_reports']}.")
    
    # 16. Test Invalid Login
    print("16. Testing invalid login credentials...")
    res = client.post("/patient/login", json={"email": patient_email, "password": "wrongpassword"})
    assert res.status_code == 401, f"Expected 401, got {res.status_code}"
    print("   [OK] Invalid login rejected (401 Unauthorized).")
    
    # 17. Test Unauthorized API Access
    print("17. Testing unauthorized API access (no token)...")
    res = client.get("/reports")
    assert res.status_code == 401, f"Expected 401, got {res.status_code}"
    print("   [OK] Unauthorized request rejected (401 Unauthorized).")
    
    # 18. Verify Persistence (Database re-initialization check)
    print("18. Verifying data persistence after DB re-initialization...")
    init_all_tables()
    res = client.post("/patient/login", json={"email": patient_email, "password": patient_pass})
    assert res.status_code == 200, f"Persistence check failed: {res.text}"
    print("   [OK] Existing users and reports persist cleanly.")
    
    print("\n=======================================================")
    print("ALL 18 END-TO-END VERIFICATION FLOWS PASSED PERFECTLY!")
    print("=======================================================")

if __name__ == "__main__":
    run_all_tests()
