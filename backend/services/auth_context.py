from fastapi import Header, HTTPException

from services.user_store import find_user_by_token


def current_user(authorization: str = Header(default="")) -> dict:
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(status_code=401, detail="Authentication required")

    user = find_user_by_token(token.strip())
    if user is None:
        raise HTTPException(status_code=401, detail="Invalid session")

    return user
