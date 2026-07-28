from fastapi import APIRouter

router = APIRouter()

BACKEND_VERSION = "0.2.0"


@router.get("/health")
def health() -> dict:
    return {"status": "backend healthy"}


@router.get("/version")
def version() -> dict:
    return {"name": "PlaqueCheck Backend", "version": BACKEND_VERSION}


@router.get("/db-status")
def db_status() -> dict:
    from services.db import get_db_type
    return {"db_type": get_db_type()}

