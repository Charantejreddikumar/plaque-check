import logging
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from services.auth_context import require_role
from services.report_store import get_report_by_id, list_all_reports, list_pending_reports, review_report
from services.user_store import (
    create_notification,
    get_patient_profile,
    list_users,
    log_audit_event,
)

router = APIRouter(prefix="/doctor", tags=["doctor"])
logger = logging.getLogger(__name__)


class ReviewPayload(BaseModel):
    status: str  # 'approved', 'modified', 'rejected'
    modified_plaque_percent: int | None = None
    doctor_notes: str = ""
    treatment_recommendations: str = ""
    follow_up_date: str = ""


@router.get("/dashboard")
def get_doctor_dashboard(user: dict = Depends(require_role(["doctor", "administrator"]))) -> dict:
    all_reports = list_all_reports()
    pending = [r for r in all_reports if r.get("review_status") == "pending_review"]
    completed = [r for r in all_reports if r.get("review_status") != "pending_review"]
    high_risk = [r for r in all_reports if r.get("plaque_percent", 0) >= 50]

    all_users = list_users()
    patients = [u for u in all_users if u.get("role") == "patient"]

    avg_score = 0
    if all_reports:
        avg_score = int(round(sum(r["plaque_percent"] for r in all_reports) / len(all_reports)))

    return {
        "total_patients": len(patients),
        "pending_reviews": len(pending),
        "completed_reviews": len(completed),
        "high_risk_patients": len(high_risk),
        "average_plaque_score": avg_score,
        "recent_patients": patients[:5],
        "pending_reports_list": pending[:10],
    }


@router.get("/patients")
def search_patients(
    query: str = "",
    user: dict = Depends(require_role(["doctor", "administrator"])),
) -> list[dict]:
    all_users = list_users()
    patients = [u for u in all_users if u.get("role") == "patient"]

    q = query.strip().lower()
    if not q:
        return [
            {
                **p,
                "details": get_patient_profile(p["id"]) or {},
            }
            for p in patients
        ]

    matched = []
    for p in patients:
        profile = get_patient_profile(p["id"]) or {}
        phone = str(profile.get("phone", "")).lower()
        pid = str(p["id"])
        if q in pid or q in p["name"].lower() or q in p["email"].lower() or q in phone:
            matched.append({**p, "details": profile})

    return matched


@router.get("/reports/pending")
def get_pending_reviews(user: dict = Depends(require_role(["doctor", "administrator"]))) -> list[dict]:
    return list_pending_reports()


@router.get("/reports")
def get_all_doctor_reports(user: dict = Depends(require_role(["doctor", "administrator"]))) -> list[dict]:
    return list_all_reports()


@router.get("/reports/{report_id}")
def get_report_details(
    report_id: int,
    user: dict = Depends(require_role(["doctor", "administrator"])),
) -> dict:
    report = get_report_by_id(report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    patient_profile = get_patient_profile(report["user_id"]) or {}
    return {
        "report": report,
        "patient": patient_profile,
    }


@router.post("/reports/{report_id}/review")
def submit_report_review(
    report_id: int,
    payload: ReviewPayload,
    user: dict = Depends(require_role(["doctor", "administrator"])),
) -> dict:
    report = get_report_by_id(report_id)
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")

    updated_report = review_report(
        report_id=report_id,
        doctor_id=user["id"],
        status=payload.status,
        modified_plaque=payload.modified_plaque_percent,
        notes=payload.doctor_notes,
        treatment=payload.treatment_recommendations,
        follow_up=payload.follow_up_date,
    )

    # Notify Patient
    create_notification(
        user_id=report["user_id"],
        title="Doctor Reviewed Your Plaque Report",
        message=f"Dr. {user['name']} has reviewed your plaque analysis report (Status: {payload.status.capitalize()}).",
        notif_type="doctor_review",
    )

    log_audit_event(
        user_id=user["id"],
        action="DOCTOR_REVIEW_REPORT",
        details=f"Doctor {user['name']} reviewed report #{report_id} -> {payload.status}",
    )

    return {
        "success": True,
        "message": f"Report #{report_id} has been successfully reviewed.",
        "report": updated_report,
    }
