from fastapi import APIRouter

from services.report_store import list_reports

router = APIRouter()


@router.get("/reports")
def reports() -> list[dict]:
    return list_reports()
