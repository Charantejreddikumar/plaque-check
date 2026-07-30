import logging
import re
import sqlite3
try:
    import psycopg2
    PSYCOPG2_ERRORS = (psycopg2.IntegrityError,)
except ImportError:
    PSYCOPG2_ERRORS = ()

from fastapi import APIRouter, Depends, Header, HTTPException
from pydantic import BaseModel

from services.user_store import (
    create_doctor,
    create_session,
    create_user,
    delete_session,
    find_user_by_email,
    get_doctor_profile,
    get_patient_profile,
    log_audit_event,
)
from services.auth_context import current_user
from passlib.context import CryptContext

router = APIRouter()
logger = logging.getLogger(__name__)
password_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str


class DoctorRegisterRequest(BaseModel):
    name: str
    email: str
    password: str
    mobile: str
    qualification: str
    specialization: str
    registration_number: str
    clinic_name: str
    hospital_name: str


class LoginRequest(BaseModel):
    email: str
    password: str
    role: str = ""


@router.post("/register")
def register(payload: RegisterRequest) -> dict:
    email = payload.email.strip().lower()
    name = payload.name.strip()

    if not name:
        raise HTTPException(status_code=400, detail="Name is required")
    if not EMAIL_PATTERN.match(email):
        raise HTTPException(status_code=400, detail="Invalid email")
    if len(payload.password) < 6:
        raise HTTPException(
            status_code=400,
            detail="Password must be at least 6 characters",
        )

    password_hash = password_context.hash(payload.password)

    try:
        user = create_user(name, email, password_hash, role="patient", status="active")
        log_audit_event(user["id"], "REGISTER_PATIENT", f"Patient registered: {email}")
    except (sqlite3.IntegrityError, *PSYCOPG2_ERRORS) as exc:
        raise HTTPException(
            status_code=400,
            detail="Email already registered",
        ) from exc
    except Exception as exc:
        err_str = str(exc).lower()
        if "unique" in err_str or "duplicate" in err_str or "already exists" in err_str:
            raise HTTPException(
                status_code=400,
                detail="Email already registered",
            ) from exc
        logger.exception("Registration failed for %s.", email)
        raise HTTPException(
            status_code=500,
            detail="Registration failed. Please try again.",
        ) from exc

    logger.info("Patient registration success: %s.", email)
    return {"success": True, "message": "Account created successfully"}


@router.post("/register/doctor")
def register_doctor(payload: DoctorRegisterRequest) -> dict:
    email = payload.email.strip().lower()
    name = payload.name.strip()

    if not name:
        raise HTTPException(status_code=400, detail="Name is required")
    if not EMAIL_PATTERN.match(email):
        raise HTTPException(status_code=400, detail="Invalid email")
    if len(payload.password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    if not payload.registration_number.strip():
        raise HTTPException(status_code=400, detail="Medical Registration Number is required")

    password_hash = password_context.hash(payload.password)

    try:
        user = create_user(name, email, password_hash, role="doctor", status="pending_approval")
        create_doctor(
            user_id=user["id"],
            mobile=payload.mobile.strip(),
            qualification=payload.qualification.strip(),
            specialization=payload.specialization.strip(),
            registration_number=payload.registration_number.strip(),
            clinic_name=payload.clinic_name.strip(),
            hospital_name=payload.hospital_name.strip(),
        )
        log_audit_event(user["id"], "REGISTER_DOCTOR", f"Doctor registration submitted (pending approval): {email}")
    except (sqlite3.IntegrityError, *PSYCOPG2_ERRORS) as exc:
        raise HTTPException(status_code=400, detail="Email already registered") from exc
    except Exception as exc:
        err_str = str(exc).lower()
        if "unique" in err_str or "duplicate" in err_str:
            raise HTTPException(status_code=400, detail="Email already registered") from exc
        raise HTTPException(status_code=500, detail="Doctor registration failed.") from exc

    logger.info("Doctor registration submitted: %s (Pending Approval)", email)
    return {
        "success": True,
        "message": "Doctor registration submitted successfully! Your account is pending Administrator approval.",
    }


@router.post("/login")
def login(payload: LoginRequest) -> dict:
    email = payload.email.strip().lower()
    user = find_user_by_email(email)

    if user is None or not password_context.verify(payload.password, user["password_hash"]):
        logger.info("Login failed: %s.", email)
        raise HTTPException(status_code=401, detail="Invalid email or password")

    if user["status"] == "deactivated":
        raise HTTPException(status_code=403, detail="Account deactivated. Please contact Administrator.")

    if user["role"] == "doctor" and user["status"] == "pending_approval":
        raise HTTPException(
            status_code=403,
            detail="Your Doctor account registration is pending Administrator approval. You will receive access once verified.",
        )

    token = create_session(user["id"])
    log_audit_event(user["id"], "LOGIN", f"User logged in as {user['role']}: {email}")

    logger.info("Login success: %s (Role: %s).", email, user["role"])
    return {
        "success": True,
        "user_id": user["id"],
        "name": user["name"],
        "email": user["email"],
        "role": user["role"],
        "status": user["status"],
        "access_token": token,
        "token_type": "bearer",
    }


@router.post("/patient/login")
def patient_login(payload: LoginRequest) -> dict:
    res = login(payload)
    if res["role"] != "patient":
        raise HTTPException(status_code=403, detail="This account is not registered as a Patient.")
    return res


@router.post("/doctor/login")
def doctor_login(payload: LoginRequest) -> dict:
    res = login(payload)
    if res["role"] != "doctor":
        raise HTTPException(status_code=403, detail="This account is not registered as a Doctor.")
    return res


@router.post("/admin/login")
def admin_login(payload: LoginRequest) -> dict:
    res = login(payload)
    if res["role"] != "administrator":
        raise HTTPException(status_code=403, detail="This account is not authorized as an Administrator.")
    return res


@router.post("/doctor/register")
def doctor_register_alias(payload: DoctorRegisterRequest) -> dict:
    return register_doctor(payload)


@router.get("/me")
def get_current_user_profile(user: dict = Depends(current_user)) -> dict:
    role = user.get("role", "patient")
    profile = {}
    if role == "patient":
        profile = get_patient_profile(user["id"]) or {}
    elif role == "doctor":
        profile = get_doctor_profile(user["id"]) or {}

    return {
        **user,
        "details": profile,
    }


@router.post("/logout")
def logout(authorization: str = Header(default="")) -> dict:
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() == "bearer" and token:
        delete_session(token.strip())
    return {"success": True, "message": "Logged out successfully"}
