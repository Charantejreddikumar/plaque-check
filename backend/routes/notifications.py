import logging
from fastapi import APIRouter, Depends, HTTPException

from services.auth_context import current_user
from services.user_store import get_user_notifications

router = APIRouter(prefix="/notifications", tags=["notifications"])
logger = logging.getLogger(__name__)


@router.get("")
def fetch_notifications(user: dict = Depends(current_user)) -> list[dict]:
    return get_user_notifications(user["id"])
