from pathlib import Path
import logging

import cv2
import numpy as np

from services.analyzer import Analyzer
from services.image_validator import validate_teeth_image
from services.roi_cropper import extract_teeth_roi

logger = logging.getLogger(__name__)
PROCESSED_DIR = Path(__file__).resolve().parents[1] / "processed"


class OpenCVAnalyzer(Analyzer):
    def analyze(self, image_path: Path) -> dict:
        logger.info("=== Starting OpenCV Fallback Pipeline Execution for %s ===", image_path.name)
        image = cv2.imread(str(image_path))
        if image is None:
            logger.error("[Stage 1 Failed] Unable to read image file: %s", image_path)
            raise ValueError("Please upload a clear image showing human teeth.")

        validate_teeth_image(image)
        teeth_roi, roi_rect = extract_teeth_roi(image)
        logger.info("[Stage 2/11 PASSED] Teeth ROI extracted: rect=%s, shape=%s", roi_rect, teeth_roi.shape)

        resized = _resize_for_analysis(teeth_roi)
        logger.info("[Stage 3/11 PASSED] Resized image shape: %s", resized.shape)

        lab = cv2.cvtColor(resized, cv2.COLOR_BGR2LAB)
        clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
        lab[:, :, 0] = clahe.apply(lab[:, :, 0])
        enhanced_bgr = cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)
        hsv = cv2.cvtColor(enhanced_bgr, cv2.COLOR_BGR2HSV)

        tooth_mask = _estimate_tooth_regions(hsv)
        gum_mask = _estimate_gum_regions(hsv)

        plaque_mask = _estimate_plaque_regions_hybrid(lab, hsv, tooth_mask, gum_mask)
        logger.info("[Stage 8/11 PASSED] OpenCV Plaque Mask generated: plaque_pixels=%d", cv2.countNonZero(plaque_mask))

        overlay_path = _save_visual_outputs(image_path, resized, plaque_mask)

        tooth_pixels = int(cv2.countNonZero(tooth_mask))
        plaque_pixels = int(cv2.countNonZero(plaque_mask))
        plaque_percent = (
            0 if tooth_pixels == 0 else round((plaque_pixels / tooth_pixels) * 100)
        )
        plaque_percent = int(np.clip(plaque_percent, 0, 100))
        logger.info("[Stage 9/11 PASSED] Plaque Percentage calculated from pixel ratio: %d%%", plaque_percent)

        if plaque_percent < 3:
            plaque_percent = 0
            severity = "Low"
            recommendation = "No plaque detected."
        else:
            severity = _severity_for(plaque_percent)
            recommendation = _recommendation_for(severity)

        confidence = _confidence_for(tooth_pixels, resized.shape[0] * resized.shape[1])
        logger.info("[Stage 11/11 PASSED] Final Prediction: Plaque=%d%%, Severity=%s, Confidence=%.2f", plaque_percent, severity, confidence)

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
    # Teeth enamel: Bright, low-to-moderate saturation
    lower = np.array([0, 0, 105], dtype=np.uint8)
    upper = np.array([179, 95, 255], dtype=np.uint8)
    mask = cv2.inRange(hsv, lower, upper)
    kernel = np.ones((7, 7), np.uint8)
    mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
    return cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel)


def _estimate_gum_regions(hsv: np.ndarray) -> np.ndarray:
    # Pink/Red oral mucosa / gum region
    gum_1 = cv2.inRange(hsv, np.array([0, 50, 40]), np.array([16, 255, 255]))
    gum_2 = cv2.inRange(hsv, np.array([155, 50, 40]), np.array([180, 255, 255]))
    gum_mask = cv2.bitwise_or(gum_1, gum_2)
    kernel = np.ones((9, 9), np.uint8)
    return cv2.morphologyEx(gum_mask, cv2.MORPH_CLOSE, kernel)


def _estimate_plaque_regions_hybrid(
    lab: np.ndarray,
    hsv: np.ndarray,
    tooth_mask: np.ndarray,
    gum_mask: np.ndarray,
) -> np.ndarray:
    # 1. CIELAB b* channel yellowing threshold (b* > 131 in OpenCV 8-bit scale)
    b_channel = lab[:, :, 2]
    lab_yellow_mask = cv2.inRange(b_channel, 131, 255)

    # 2. HSV Biofilm color range (Yellow/Orange hue 10-45, saturation >= 22)
    yellow_lower = np.array([10, 22, 60], dtype=np.uint8)
    yellow_upper = np.array([45, 255, 255], dtype=np.uint8)
    hsv_yellow_mask = cv2.inRange(hsv, yellow_lower, yellow_upper)

    # Combine color evidence
    combined_color = cv2.bitwise_and(lab_yellow_mask, hsv_yellow_mask)

    # 3. Gingival Margin Proximity (plaque accumulates near gumline / interdental edges)
    dilated_gum = cv2.dilate(gum_mask, np.ones((25, 25), np.uint8))
    
    # Interdental edges using Laplacian on teeth
    edges = cv2.Canny(hsv[:, :, 2], 50, 150)
    dilated_edges = cv2.dilate(edges, np.ones((7, 7), np.uint8))

    proximity_mask = cv2.bitwise_or(dilated_gum, dilated_edges)

    # Plaque must be on teeth AND (near gumline OR along interdental edges)
    plaque_mask = cv2.bitwise_and(combined_color, tooth_mask)
    plaque_mask = cv2.bitwise_and(plaque_mask, proximity_mask)

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
    overlay = image.copy()
    if cv2.countNonZero(plaque_mask) > 0:
        # Bright Yellow-Orange plaque bacteria overlay (B=0, G=180, R=255)
        color_overlay[plaque_mask > 0] = (0, 180, 255)

        # Highlight plaque edge contours in vivid neon yellow (B=0, G=240, R=255)
        contours, _ = cv2.findContours(plaque_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        cv2.drawContours(color_overlay, contours, -1, (0, 240, 255), 2)

        mask_bool = plaque_mask > 0
        overlay[mask_bool] = cv2.addWeighted(image[mask_bool], 0.35, color_overlay[mask_bool], 0.65, 0)

    cv2.imwrite(str(original_path), image)
    cv2.imwrite(str(mask_path), plaque_mask)
    cv2.imwrite(str(overlay_path), overlay)
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
        return (
            "• Brush twice daily for 2 minutes using fluoride toothpaste.\n"
            "• Floss daily to clean interdental spaces.\n"
            "• Schedule routine dental checkups every 6 months."
        )
    if severity == "Moderate":
        return (
            "• Focus on posterior molars and gingival margins where plaque accumulates.\n"
            "• Use an electric toothbrush and interdental cleaning brushes.\n"
            "• Rinse daily with an antibacterial mouthwash."
        )
    return (
        "• Perform thorough 2-minute brushing twice daily with soft bristles.\n"
        "• Dedicated flossing and gumline cleaning required to prevent tartar formation.\n"
        "• Schedule professional dental scaling and consultation promptly."
    )


def _relative_path(path: Path) -> str:
    resolved_path = path.resolve()
    base_path = Path(__file__).resolve().parents[1]
    try:
        return resolved_path.relative_to(base_path).as_posix()
    except ValueError:
        return resolved_path.as_posix()
