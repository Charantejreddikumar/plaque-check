from fastapi import Header, HTTPException, Query

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

    return user

