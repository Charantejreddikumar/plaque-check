import numpy as np
from pathlib import Path
from uuid import uuid4
import logging

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile

from services.plaque_analyzer import analyze_image
from services.auth_context import current_user
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
async def predict(
    image: UploadFile = File(...),
    user: dict = Depends(current_user),
) -> dict:
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
    user_upload_dir = UPLOAD_DIR / str(user["id"])
    user_upload_dir.mkdir(parents=True, exist_ok=True)
    saved_path = user_upload_dir / f"{uuid4().hex}.{extension}"

    contents = await file.read()
    if not contents:
        logger.warning("Prediction request rejected: empty upload.")
        raise HTTPException(status_code=400, detail="Uploaded image is empty.")

    saved_path.write_bytes(contents)
    logger.info("Uploaded image saved: %s.", saved_path.name)

    try:
        prediction = analyze_image(saved_path)
        store_dataset_sample(saved_path, prediction["processed_image"])
        stored_prediction = save_report(user["id"], prediction)
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


@router.post("/predict/batch")
async def predict_batch(
    images: list[UploadFile] = File(...),
    user: dict = Depends(current_user),
) -> dict:
    if not images or len(images) == 0:
        raise HTTPException(status_code=400, detail="No images provided for analysis.")

    user_upload_dir = UPLOAD_DIR / str(user["id"])
    user_upload_dir.mkdir(parents=True, exist_ok=True)

    saved_paths = []
    # 1. Save and Audit Every Single Image
    for idx, file in enumerate(images, start=1):
        if not file.filename:
            raise HTTPException(status_code=400, detail=f"Image {idx} is missing a filename.")

        ext = file.filename.split(".")[-1].lower() if "." in file.filename else ""
        content_type = (file.content_type or "").lower()
        ext_ok = ext in ALLOWED_EXTENSIONS
        type_ok = content_type in ALLOWED_CONTENT_TYPES or content_type.startswith("image/")

        if not (ext_ok or type_ok):
            raise HTTPException(
                status_code=400,
                detail=f"Image {idx} ({file.filename}) is not a valid JPG, JPEG or PNG image.",
            )

        extension = ext if ext_ok else CONTENT_TYPE_EXTENSIONS.get(content_type, "jpg")
        saved_path = user_upload_dir / f"batch_{uuid4().hex}_{idx}.{extension}"

        contents = await file.read()
        if not contents:
            raise HTTPException(status_code=400, detail=f"Image {idx} ({file.filename}) is empty.")

        saved_path.write_bytes(contents)
        saved_paths.append((idx, file.filename, saved_path))

    # 2. Perform Mandatory Image Auditing & Plaque Analysis for Each Image
    individual_predictions = []
    for idx, orig_filename, saved_path in saved_paths:
        try:
            logger.info("Auditing image %d/%d: %s", idx, len(saved_paths), orig_filename)
            pred = analyze_image(saved_path)
            store_dataset_sample(saved_path, pred["processed_image"])
            individual_predictions.append(pred)
        except ValueError as exc:
            logger.warning("Batch validation failed on image %d (%s): %s", idx, orig_filename, exc)
            raise HTTPException(
                status_code=400,
                detail=f"Image {idx} failed auditing: {str(exc)}",
            ) from exc

    # 3. Calculate Average Plaque Percentage Across All Images
    plaque_scores = [p["plaque_percent"] for p in individual_predictions]
    avg_plaque = int(round(sum(plaque_scores) / len(plaque_scores)))

    confidences = [p.get("confidence", 0.85) for p in individual_predictions]
    avg_confidence = float(np.mean(confidences)) if confidences else 0.85

    # Derive overall severity and clinical recommendation based on 3-image average
    if avg_plaque < 3:
        severity = "Low"
        recommendation = "No plaque detected. Dental hygiene is excellent!"
    elif avg_plaque < 25:
        severity = "Low"
        recommendation = "Maintain regular brushing twice daily and gentle flossing."
    elif avg_plaque < 50:
        severity = "Moderate"
        recommendation = "Improve brushing coverage along the gumline areas."
    elif avg_plaque < 75:
        severity = "High"
        recommendation = "Prioritize thorough cleaning and consider a dental checkup."
    else:
        severity = "Severe"
        recommendation = "Severe plaque detected. Professional dental cleaning recommended."

    primary_prediction = {
        "image_path": individual_predictions[0]["image_path"],
        "processed_image": individual_predictions[0]["processed_image"],
        "plaque_percent": avg_plaque,
        "severity": severity,
        "confidence": avg_confidence,
        "recommendation": recommendation,
    }

    stored_prediction = save_report(user["id"], primary_prediction)
    stored_prediction["individual_results"] = individual_predictions
    stored_prediction["image_count"] = len(individual_predictions)

    logger.info(
        "Batch analysis complete for user %s: 3-image average plaque=%d%% severity=%s.",
        user["id"],
        avg_plaque,
        severity,
    )
    return stored_prediction

