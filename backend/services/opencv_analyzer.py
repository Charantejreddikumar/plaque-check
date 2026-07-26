from pathlib import Path

import cv2
import numpy as np

from services.analyzer import Analyzer
from services.image_validator import validate_teeth_image

PROCESSED_DIR = Path(__file__).resolve().parents[1] / "processed"


class OpenCVAnalyzer(Analyzer):
    def analyze(self, image_path: Path) -> dict:
        image = cv2.imread(str(image_path))
        if image is None:
            raise ValueError("Please upload a clear image showing human teeth.")

        # Perform strict teeth image validation
        validate_teeth_image(image)

        resized = _resize_for_analysis(image)
        hsv = cv2.cvtColor(resized, cv2.COLOR_BGR2HSV)

        tooth_mask = _estimate_tooth_regions(hsv)
        plaque_mask = _estimate_plaque_regions(hsv, tooth_mask)
        overlay_path = _save_visual_outputs(image_path, resized, plaque_mask)

        tooth_pixels = int(cv2.countNonZero(tooth_mask))
        plaque_pixels = int(cv2.countNonZero(plaque_mask))
        plaque_percent = (
            0 if tooth_pixels == 0 else round((plaque_pixels / tooth_pixels) * 100)
        )
        plaque_percent = int(np.clip(plaque_percent, 0, 100))

        # False positive reduction: if plaque coverage is less than 3%, report 0% plaque
        if plaque_percent < 3:
            plaque_percent = 0
            severity = "Low"
            recommendation = "No plaque detected."
        else:
            severity = _severity_for(plaque_percent)
            recommendation = _recommendation_for(severity)

        confidence = _confidence_for(tooth_pixels, resized.shape[0] * resized.shape[1])

        return {
            "image_path": _relative_path(image_path),
            "processed_image": _relative_path(overlay_path),
            "plaque_percent": plaque_percent,
            "severity": severity,
            "confidence": confidence,
            "recommendation": recommendation,
        }


def _resize_for_analysis(image: np.ndarray) -> np.ndarray:
    max_width = 900
    height, width = image.shape[:2]
    if width <= max_width:
        return image

    scale = max_width / width
    return cv2.resize(image, (max_width, int(height * scale)), interpolation=cv2.INTER_AREA)


def _estimate_tooth_regions(hsv: np.ndarray) -> np.ndarray:
    lower = np.array([0, 0, 105], dtype=np.uint8)
    upper = np.array([179, 95, 255], dtype=np.uint8)
    mask = cv2.inRange(hsv, lower, upper)
    kernel = np.ones((7, 7), np.uint8)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
    return cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)


def _estimate_plaque_regions(hsv: np.ndarray, tooth_mask: np.ndarray) -> np.ndarray:
    # Plaque biofilm color: yellow/orange hue with distinct saturation (>=55)
    yellow_lower = np.array([14, 55, 80], dtype=np.uint8)
    yellow_upper = np.array([40, 255, 255], dtype=np.uint8)
    plaque_color = cv2.inRange(hsv, yellow_lower, yellow_upper)

    saturation = hsv[:, :, 1]
    sat_mask = cv2.inRange(saturation, 55, 255)

    plaque_mask = cv2.bitwise_and(plaque_color, sat_mask)
    plaque_mask = cv2.bitwise_and(plaque_mask, tooth_mask)
    kernel = np.ones((5, 5), np.uint8)
    return cv2.morphologyEx(plaque_mask, cv2.MORPH_OPEN, kernel)


def _save_visual_outputs(
    image_path: Path,
    image: np.ndarray,
    plaque_mask: np.ndarray,
) -> Path:
    user_dir = image_path.parent.name
    processed_dir = PROCESSED_DIR / user_dir
    processed_dir.mkdir(parents=True, exist_ok=True)
    stem = image_path.stem
    original_path = processed_dir / f"{stem}_original.png"
    mask_path = processed_dir / f"{stem}_mask.png"
    overlay_path = processed_dir / f"{stem}_overlay.png"

    color_overlay = np.zeros_like(image)
    color_overlay[plaque_mask > 0] = (0, 72, 255)
    blended = cv2.addWeighted(image, 0.76, color_overlay, 0.42, 0)

    cv2.imwrite(str(original_path), image)
    cv2.imwrite(str(mask_path), plaque_mask)
    cv2.imwrite(str(overlay_path), blended)
    return overlay_path


def _severity_for(plaque_percent: int) -> str:
    if plaque_percent < 20:
        return "Low"
    if plaque_percent < 45:
        return "Moderate"
    return "High"


def _confidence_for(tooth_pixels: int, total_pixels: int) -> float:
    coverage = 0 if total_pixels == 0 else tooth_pixels / total_pixels
    return round(float(np.clip(0.58 + coverage, 0.62, 0.92)), 2)


def _recommendation_for(severity: str) -> str:
    if severity == "Low":
        return "Maintain brushing and continue monitoring."
    if severity == "Moderate":
        return "Improve brushing coverage and review plaque-prone areas closely."
    return "Prioritize thorough cleaning and consider professional dental advice."


def _relative_path(path: Path) -> str:
    return path.relative_to(Path(__file__).resolve().parents[1]).as_posix()
