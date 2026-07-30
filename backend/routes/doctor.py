import logging
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from services.auth_context import require_role
from services.report_store import get_report_by_id, list_all_reports, list_pending_reports, review_report
from services.user_store import (
    create_notification,
    get_patient_profile,
    get_user_notifications,
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
    all_users = list_users()
    users_by_id = {u["id"]: u for u in all_users}
    patients = [u for u in all_users if u.get("role") == "patient"]

    today_str = datetime.now().strftime("%Y-%m-%d")

    # Enrich reports with patient name and email
    enriched_reports = []
    for r in all_reports:
        patient_info = users_by_id.get(r.get("user_id"), {})
        enriched_reports.append({
            **r,
            "patient_name": patient_info.get("name", f"Patient #{r.get('user_id')}"),
            "patient_email": patient_info.get("email", ""),
        })

    # 1. Today's patients scans
    todays_patients = [
        r for r in enriched_reports
        if (r.get("timestamp") or "").startswith(today_str)
    ]

    # 2. Pending reviews queue: sorted by Highest Risk (plaque % desc), then Oldest Upload (timestamp asc)
    pending = [r for r in enriched_reports if r.get("review_status") == "pending_review"]
    pending.sort(key=lambda r: (-r.get("plaque_percent", 0), r.get("timestamp", "")))

    # 3. High risk cases (>= 50% plaque), sorted by plaque % desc
    high_risk = [r for r in enriched_reports if r.get("plaque_percent", 0) >= 50]
    high_risk.sort(key=lambda r: -r.get("plaque_percent", 0))

    completed = [r for r in enriched_reports if r.get("review_status") != "pending_review"]

    avg_score = 0
    if all_reports:
        avg_score = int(round(sum(r.get("plaque_percent", 0) for r in all_reports) / len(all_reports)))

    return {
        "total_patients": len(patients),
        "pending_reviews": len(pending),
        "completed_reviews": len(completed),
        "high_risk_patients": len(high_risk),
        "average_plaque_score": avg_score,
        "recent_patients": patients[:5],
        "pending_reports_list": pending,
        "todays_patients": todays_patients,
        "high_risk_cases": high_risk,
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


@router.get("/analytics")
def get_doctor_analytics(user: dict = Depends(require_role(["doctor", "administrator"]))) -> dict:
    all_reports = list_all_reports()
    pending = len([r for r in all_reports if r.get("review_status") == "pending_review"])
    reviewed = len([r for r in all_reports if r.get("review_status") != "pending_review"])
    total_count = pending + reviewed

    completion_rate = round((reviewed / total_count) * 100, 1) if total_count > 0 else 0.0

    low_risk = len([r for r in all_reports if r.get("plaque_percent", 0) < 20])
    mod_risk = len([r for r in all_reports if 20 <= r.get("plaque_percent", 0) < 50])
    high_risk = len([r for r in all_reports if r.get("plaque_percent", 0) >= 50])

    # Compute actual daily review counts from real database report timestamps
    day_counts = {"Mon": 0, "Tue": 0, "Wed": 0, "Thu": 0, "Fri": 0, "Sat": 0, "Sun": 0}
    days_map = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    for r in all_reports:
        ts_str = r.get("reviewed_at") or r.get("timestamp")
        if ts_str:
            try:
                dt = datetime.fromisoformat(ts_str.replace("Z", "+00:00"))
                day_name = days_map[dt.weekday()]
                day_counts[day_name] += 1
            except Exception:
                pass

    daily_reviews = [{"day": day, "count": day_counts[day]} for day in days_map]

    return {
        "review_completion_rate": completion_rate,
        "daily_reviews": daily_reviews,
        "plaque_distribution": [
            {"category": "Optimal (<20%)", "count": low_risk},
            {"category": "Moderate (20-49%)", "count": mod_risk},
            {"category": "High Risk (≥50%)", "count": high_risk},
        ],
        "total_reviews": reviewed,
        "pending_reviews": pending,
        "total_reports": total_count,
    }


@router.get("/patients/{patient_id}")
def get_patient_detail(
    patient_id: int,
    user: dict = Depends(require_role(["doctor", "administrator"])),
) -> dict:
    all_users = list_users()
    matched = next((u for u in all_users if u["id"] == patient_id and u.get("role") == "patient"), None)
    if not matched:
        raise HTTPException(status_code=404, detail="Patient not found")

    profile = get_patient_profile(patient_id) or {}
    all_reports = list_all_reports()
    patient_reports = [r for r in all_reports if r.get("user_id") == patient_id]

    return {
        "patient": matched,
        "profile": profile,
        "medical_history": profile.get("medical_history", ""),
        "scan_history": patient_reports,
    }


@router.get("/notifications")
def get_doctor_notifications(
    user: dict = Depends(require_role(["doctor", "administrator"])),
) -> list[dict]:
    return get_user_notifications(user["id"])
