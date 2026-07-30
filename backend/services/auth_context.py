from typing import Callable
from fastapi import Depends, Header, HTTPException, Query

from services.user_store import find_user_by_token


def current_user(
    authorization: str = Header(default=""),
    token: str = Query(default=None),
) -> dict:
    auth_token = token
    if not auth_token:
        scheme, _, bearer_token = authorization.partition(" ")
        if scheme.lower() == "bearer":
            auth_token = bearer_token.strip()

    if not auth_token:
        raise HTTPException(status_code=401, detail="Authentication required")

    user = find_user_by_token(auth_token)
    if user is None:
        raise HTTPException(status_code=401, detail="Invalid session")

    if user.get("status") == "deactivated":
        raise HTTPException(status_code=403, detail="Account is deactivated")

    return user


def require_role(allowed_roles: list[str]) -> Callable:
    def dependency(user: dict = Depends(current_user)) -> dict:
        user_role = user.get("role", "patient")
        if user_role not in allowed_roles:
            raise HTTPException(
                status_code=403,
                detail=f"Access denied. Requires one of roles: {allowed_roles} (Current role: {user_role})",
            )
        return user

    return dependency
