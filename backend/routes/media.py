from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse

from services.auth_context import current_user

router = APIRouter()

BACKEND_DIR = Path(__file__).resolve().parents[1]
MEDIA_ROOTS = {
    "uploads": BACKEND_DIR / "uploads",
    "processed": BACKEND_DIR / "processed",
}


@router.get("/{media_type}/{user_id}/{filename}")
def media_file(
    media_type: str,
    user_id: int,
    filename: str,
    user: dict = Depends(current_user),
) -> FileResponse:
    if media_type not in MEDIA_ROOTS:
        raise HTTPException(status_code=404, detail="File not found")
    if user_id != user["id"]:
        raise HTTPException(status_code=403, detail="File access denied")
    if Path(filename).name != filename:
        raise HTTPException(status_code=400, detail="Invalid file name")

    path = MEDIA_ROOTS[media_type] / str(user_id) / filename
    if not path.is_file():
        raise HTTPException(status_code=404, detail="File not found")

    return FileResponse(path)
