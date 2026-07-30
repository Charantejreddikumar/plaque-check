import logging
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException

from services.auth_context import require_role
from services.report_store import list_all_reports
from services.user_store import (
    approve_doctor,
    create_notification,
    deactivate_user,
    get_audit_logs,
    list_doctors,
    list_users,
    log_audit_event,
)

router = APIRouter(prefix="/admin", tags=["admin"])
logger = logging.getLogger(__name__)


@router.get("/dashboard")
def get_admin_dashboard(user: dict = Depends(require_role(["administrator"]))) -> dict:
    all_users = list_users()
    doctors = list_doctors()
    patients = [u for u in all_users if u.get("role") == "patient"]
    all_reports = list_all_reports()

    today_str = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    today_scans = [r for r in all_reports if str(r.get("timestamp", "")).startswith(today_str)]

    pending_docs = [d for d in doctors if d.get("approval_status") == "pending_approval"]

    return {
        "total_users": len(all_users),
        "total_doctors": len(doctors),
        "pending_doctor_approvals": len(pending_docs),
        "total_patients": len(patients),
        "today_scans": len(today_scans),
        "total_reports": len(all_reports),
        "model_version": "v1.4.0 (EfficientNet-B0 ONNX Engine)",
        "average_accuracy": "91.8%",
        "storage_usage": "1.24 GB",
        "pending_doctors_list": pending_docs,
        "recent_audit_logs": get_audit_logs()[:10],
    }


@router.get("/doctors")
def get_doctors_list(user: dict = Depends(require_role(["administrator"]))) -> list[dict]:
    return list_doctors()


@router.post("/doctors/{user_id}/approve")
def approve_doctor_account(
    user_id: int,
    user: dict = Depends(require_role(["administrator"])),
) -> dict:
    approve_doctor(user_id)
    create_notification(
        user_id=user_id,
        title="Doctor Account Approved",
        message="Your Doctor registration has been verified and approved by the Administrator. You may now access the Doctor Dashboard.",
        notif_type="approval",
    )
    log_audit_event(
        user_id=user["id"],
        action="ADMIN_APPROVE_DOCTOR",
        details=f"Admin approved doctor user #{user_id}",
    )
    return {"success": True, "message": f"Doctor account #{user_id} approved successfully."}


@router.post("/doctors/{user_id}/deactivate")
def deactivate_doctor_account(
    user_id: int,
    user: dict = Depends(require_role(["administrator"])),
) -> dict:
    deactivate_user(user_id)
    log_audit_event(
        user_id=user["id"],
        action="ADMIN_DEACTIVATE_DOCTOR",
        details=f"Admin deactivated doctor user #{user_id}",
    )
    return {"success": True, "message": f"Doctor account #{user_id} deactivated."}


@router.get("/patients")
def get_patients_list(user: dict = Depends(require_role(["administrator"]))) -> list[dict]:
    all_users = list_users()
    return [u for u in all_users if u.get("role") == "patient"]


@router.delete("/users/{user_id}")
def delete_user_account(
    user_id: int,
    user: dict = Depends(require_role(["administrator"])),
) -> dict:
    deactivate_user(user_id)
    log_audit_event(
        user_id=user["id"],
        action="ADMIN_DEACTIVATE_USER",
        details=f"Admin deactivated user #{user_id}",
    )
    return {"success": True, "message": f"User account #{user_id} deactivated."}


@router.get("/audit-logs")
def get_system_audit_logs(user: dict = Depends(require_role(["administrator"]))) -> list[dict]:
    return get_audit_logs()
