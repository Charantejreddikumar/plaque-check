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
    find_admin_user_by_email,
    find_doctor_user_by_email,
    find_patient_user_by_email,
    find_user_by_email,
    get_doctor_profile,
    get_patient_profile,
    log_audit_event,
    verify_password_hash,
)
from services.auth_context import current_user
from passlib.context import CryptContext

router = APIRouter()
logger = logging.getLogger(__name__)
password_context = CryptContext(schemes=["bcrypt", "pbkdf2_sha256", "sha256_crypt"], deprecated="auto")

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
    logger.info("[REGISTER REQUEST] Patient registration request for: %s", email)

    if not name:
        raise HTTPException(status_code=400, detail="Name is required")
    if not EMAIL_PATTERN.match(email):
        raise HTTPException(status_code=400, detail="Invalid email")
    if len(payload.password) < 6:
        raise HTTPException(
            status_code=400,
            detail="Password must be at least 6 characters",
        )

    # Check cross-role collision
    if find_user_by_email(email):
        logger.warning("[AUTH FAILURE] Registration failed: Email %s already registered across roles", email)
        raise HTTPException(status_code=400, detail="Email already registered")

    password_hash = password_context.hash(payload.password)

    try:
        user = create_user(name, email, password_hash, role="patient", status="active")
        log_audit_event(user["id"], "REGISTER_PATIENT", f"Patient registered: {email}")
    except (sqlite3.IntegrityError, *PSYCOPG2_ERRORS) as exc:
        logger.warning("[AUTH FAILURE] Registration integrity error for %s: %s", email, exc)
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
            detail=f"Registration failed: {str(exc)}",
        ) from exc

    logger.info("[AUTH SUCCESS] Patient registration success for email: %s (User ID: %s)", email, user["id"])
    return {"success": True, "message": "Account created"}


@router.post("/register/doctor")
def register_doctor(payload: DoctorRegisterRequest) -> dict:
    email = payload.email.strip().lower()
    name = payload.name.strip()
    logger.info("[REGISTER REQUEST] Doctor registration request for: %s", email)

    if not name:
        raise HTTPException(status_code=400, detail="Name is required")
    if not EMAIL_PATTERN.match(email):
        raise HTTPException(status_code=400, detail="Invalid email")
    if len(payload.password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters")
    if not payload.registration_number.strip():
        raise HTTPException(status_code=400, detail="Medical Registration Number is required")

    # Check cross-role collision
    if find_user_by_email(email):
        logger.warning("[AUTH FAILURE] Doctor registration failed: Email %s already registered across roles", email)
        raise HTTPException(status_code=400, detail="Email already registered")

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
        logger.exception("Doctor registration failed for %s.", email)
        raise HTTPException(status_code=500, detail=f"Doctor registration failed: {str(exc)}") from exc

    logger.info("[AUTH SUCCESS] Doctor registration submitted for email: %s (User ID: %s, Pending Approval)", email, user["id"])
    return {
        "success": True,
        "message": "Doctor registration submitted successfully! Your account is pending Administrator approval.",
    }


@router.post("/login")
def login(payload: LoginRequest) -> dict:
    email = payload.email.strip().lower()

    if payload.role == "doctor":
        return doctor_login(payload)
    elif payload.role in ("administrator", "admin"):
        return admin_login(payload)
    elif payload.role == "patient":
        return patient_login(payload)

    user = find_user_by_email(email)
    if user:
        if user["role"] == "doctor":
            return doctor_login(payload)
        elif user["role"] in ("administrator", "admin"):
            return admin_login(payload)

    return patient_login(payload)


@router.post("/patient/login")
def patient_login(payload: LoginRequest) -> dict:
    email = payload.email.strip().lower()
    logger.info("[LOGIN REQUEST] Patient login attempt for email: %s", email)
    user = find_patient_user_by_email(email)

    if user is None:
        if find_doctor_user_by_email(email) or find_admin_user_by_email(email):
            logger.warning("[AUTH FAILURE] Patient login rejected: Email %s belongs to a different role", email)
            raise HTTPException(status_code=403, detail="This account is not registered as a patient.")
        logger.warning("[AUTH FAILURE] Patient login failed: Email %s not found in patient_users", email)
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if not verify_password_hash(payload.password, user["password_hash"]):
        logger.warning("[AUTH FAILURE] Patient login failed: Invalid password for email %s", email)
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if user["status"] == "deactivated":
        logger.warning("[AUTH FAILURE] Patient login rejected: Account %s is deactivated", email)
        raise HTTPException(status_code=403, detail="Account deactivated. Please contact Administrator.")

    token = create_session(user["id"], role="patient")
    log_audit_event(user["id"], "LOGIN", f"Patient logged in: {email}")
    logger.info("[AUTH SUCCESS] Patient authenticated successfully: %s (User ID: %s)", email, user["id"])

    return {
        "success": True,
        "user_id": user["id"],
        "name": user["name"],
        "email": user["email"],
        "role": "patient",
        "status": user["status"],
        "access_token": token,
        "token_type": "bearer",
    }


@router.post("/doctor/login")
def doctor_login(payload: LoginRequest) -> dict:
    email = payload.email.strip().lower()
    logger.info("[LOGIN REQUEST] Doctor login attempt for email: %s", email)
    user = find_doctor_user_by_email(email)

    if user is None:
        if find_patient_user_by_email(email) or find_admin_user_by_email(email):
            logger.warning("[AUTH FAILURE] Doctor login rejected: Email %s belongs to a different role", email)
            raise HTTPException(status_code=403, detail="This account is not registered as a doctor.")
        logger.warning("[AUTH FAILURE] Doctor login failed: Email %s not found in doctor_users", email)
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if not verify_password_hash(payload.password, user["password_hash"]):
        logger.warning("[AUTH FAILURE] Doctor login failed: Invalid password for email %s", email)
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if user["status"] in ("deactivated", "rejected"):
        logger.warning("[AUTH FAILURE] Doctor login rejected: Account %s is %s", email, user["status"])
        raise HTTPException(
            status_code=403,
            detail=f"Your Doctor account registration was {user['status']}. Please contact Administrator.",
        )

    if user["status"] == "pending_approval":
        logger.warning("[AUTH FAILURE] Doctor login rejected: Account %s is pending administrator approval", email)
        raise HTTPException(
            status_code=403,
            detail="Your Doctor account registration is pending Administrator approval. You will receive access once verified.",
        )

    token = create_session(user["id"], role="doctor")
    log_audit_event(user["id"], "LOGIN", f"Doctor logged in: {email}")
    logger.info("[AUTH SUCCESS] Doctor authenticated successfully: %s (User ID: %s)", email, user["id"])

    return {
        "success": True,
        "user_id": user["id"],
        "name": user["name"],
        "email": user["email"],
        "role": "doctor",
        "status": user["status"],
        "access_token": token,
        "token_type": "bearer",
    }


@router.post("/admin/login")
def admin_login(payload: LoginRequest) -> dict:
    email = payload.email.strip().lower()
    logger.info("[LOGIN REQUEST] Admin login attempt for email: %s", email)
    user = find_admin_user_by_email(email)

    if user is None:
        logger.warning("[AUTH FAILURE] Admin login failed: Email %s not found in admin_users", email)
        raise HTTPException(status_code=403, detail="This account is not authorized as an Administrator.")

    if not verify_password_hash(payload.password, user["password_hash"]):
        logger.warning("[AUTH FAILURE] Admin login failed: Invalid password for email %s", email)
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_session(user["id"], role="administrator")
    log_audit_event(user["id"], "LOGIN", f"Admin logged in: {email}")
    logger.info("[AUTH SUCCESS] Admin authenticated successfully: %s (User ID: %s)", email, user["id"])

    return {
        "success": True,
        "user_id": user["id"],
        "name": user["name"],
        "email": user["email"],
        "role": "administrator",
        "status": user["status"],
        "access_token": token,
        "token_type": "bearer",
    }


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
