import logging
import re
import sqlite3

from fastapi import APIRouter, Header, HTTPException
from pydantic import BaseModel
from passlib.context import CryptContext

from services.user_store import create_session, create_user, delete_session, find_user_by_email

router = APIRouter()
logger = logging.getLogger(__name__)
password_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

EMAIL_PATTERN = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str


class LoginRequest(BaseModel):
    email: str
    password: str


@router.post("/register")
def register(payload: RegisterRequest) -> dict:
    print("REGISTER REQUEST")
    email = payload.email.strip().lower()
    name = payload.name.strip()
    print("EMAIL", email)

    if not name:
        print("FAIL")
        raise HTTPException(status_code=400, detail="Name is required")
    if not EMAIL_PATTERN.match(email):
        print("FAIL")
        raise HTTPException(status_code=400, detail="Invalid email")
    if len(payload.password) < 6:
        print("FAIL")
        raise HTTPException(
            status_code=400,
            detail="Password must be at least 6 characters",
        )

    password_hash = password_context.hash(payload.password)

    try:
        create_user(name, email, password_hash)
    except sqlite3.IntegrityError as exc:
        logger.info("Registration failed: duplicate email %s.", email)
        print("FAIL")
        raise HTTPException(
            status_code=400,
            detail="Email already registered",
        ) from exc
    except Exception as exc:
        logger.exception("Registration failed unexpectedly for %s.", email)
        print("FAIL")
        raise HTTPException(
            status_code=500,
            detail="Registration failed. Please try again.",
        ) from exc

    logger.info("Registration success: %s.", email)
    print("SUCCESS")
    return {"success": True, "message": "Account created"}


@router.post("/login")
def login(payload: LoginRequest) -> dict:
    print("LOGIN REQUEST")
    email = payload.email.strip().lower()
    print("EMAIL", email)

    user = find_user_by_email(email)
    if user is None or not password_context.verify(
        payload.password,
        user["password_hash"],
    ):
        logger.info("Login failed: %s.", email)
        print("FAIL")
        raise HTTPException(status_code=401, detail="Invalid credentials")

    logger.info("Login success: %s.", email)
    print("SUCCESS")
    token = create_session(user["id"])
    return {
        "success": True,
        "user_id": user["id"],
        "name": user["name"],
        "email": user["email"],
        "access_token": token,
        "token_type": "bearer",
    }


@router.post("/logout")
def logout(authorization: str = Header(default="")) -> dict:
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() == "bearer" and token:
        delete_session(token.strip())
    return {"success": True, "message": "Logged out successfully"}
