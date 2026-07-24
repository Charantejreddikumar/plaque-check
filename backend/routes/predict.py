from pathlib import Path
from uuid import uuid4
import logging

from fastapi import APIRouter, File, HTTPException, UploadFile

from services.plaque_analyzer import analyze_image
from services.dataset_store import store_dataset_sample
from services.report_store import save_report

router = APIRouter()
logger = logging.getLogger(__name__)

UPLOAD_DIR = Path(__file__).resolve().parents[1] / "uploads"
ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png"}
ALLOWED_CONTENT_TYPES = {"image/jpeg", "image/jpg", "image/png"}
CONTENT_TYPE_EXTENSIONS = {
    "image/jpeg": "jpg",
    "image/jpg": "jpg",
    "image/png": "png",
}


@router.post("/predict")
async def predict(image: UploadFile = File(...)) -> dict:
    file = image

    print("===== UPLOAD DEBUG =====")
    print("filename:", file.filename)
    print("content_type:", file.content_type)
    if file.filename and "." in file.filename:
        ext = file.filename.split(".")[-1].lower()
        print("extension:", ext)
    else:
        ext = ""
    print("validation started")

    if not file.filename:
        logger.warning("Prediction request rejected: missing image filename.")
        raise HTTPException(status_code=400, detail="Missing image file.")

    content_type = (file.content_type or "").lower()
    ext_ok = ext in ALLOWED_EXTENSIONS
    type_ok = content_type in ALLOWED_CONTENT_TYPES or content_type.startswith(
        "image/"
    )

    if not (ext_ok or type_ok):
        logger.warning(
            "Prediction request rejected: filename=%s content_type=%s extension=%s.",
            file.filename,
            file.content_type,
            ext,
        )
        raise HTTPException(
            status_code=400,
            detail="Upload JPG, JPEG or PNG image.",
        )

    extension = ext if ext_ok else CONTENT_TYPE_EXTENSIONS.get(content_type, "jpg")
    UPLOAD_DIR.mkdir(parents=True, exist_ok=True)
    saved_path = UPLOAD_DIR / f"{uuid4().hex}.{extension}"

    contents = await file.read()
    if not contents:
        logger.warning("Prediction request rejected: empty upload.")
        raise HTTPException(status_code=400, detail="Uploaded image is empty.")

    saved_path.write_bytes(contents)
    logger.info("Uploaded image saved: %s.", saved_path.name)

    try:
        prediction = analyze_image(saved_path)
        store_dataset_sample(saved_path, prediction["processed_image"])
        stored_prediction = save_report(prediction)
        logger.info(
            "Analysis complete: report_id=%s plaque=%s severity=%s.",
            stored_prediction["report_id"],
            stored_prediction["plaque_percent"],
            stored_prediction["severity"],
        )
        return stored_prediction
    except ValueError as exc:
        logger.exception("Analysis failed for %s.", saved_path.name)
        raise HTTPException(status_code=400, detail=str(exc)) from exc
