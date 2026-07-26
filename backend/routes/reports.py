from fastapi import APIRouter, Depends

from services.auth_context import current_user
from services.report_store import list_reports

router = APIRouter()


@router.get("/reports")
def reports(user: dict = Depends(current_user)) -> list[dict]:
    return list_reports(user["id"])
