import logging
import cv2
import numpy as np

logger = logging.getLogger(__name__)


def extract_teeth_roi(image: np.ndarray) -> tuple[np.ndarray, tuple[int, int, int, int]]:
    """
    Locates and crops the teeth & mouth region of interest (ROI) from a lower-face photo (nose to chin).
    Returns (cropped_roi, (x, y, w, h)). If teeth ROI is not distinctly isolated, returns the full image.
    """
    logger.info("[Stage 2/11] Extracting teeth & oral cavity Region of Interest (ROI)...")
    if image is None or image.size == 0:
        return image, (0, 0, 0, 0)

    height, width = image.shape[:2]
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)

    # 1. Tooth enamel region mask (bright, low-to-moderate saturation)
    tooth_lower = np.array([0, 0, 100], dtype=np.uint8)
    tooth_upper = np.array([179, 90, 255], dtype=np.uint8)
    tooth_mask = cv2.inRange(hsv, tooth_lower, tooth_upper)

    # 2. Oral mucosa / gum / lip mask
    gum_mask_1 = cv2.inRange(hsv, np.array([0, 15, 30]), np.array([32, 255, 255]))
    gum_mask_2 = cv2.inRange(hsv, np.array([135, 15, 30]), np.array([180, 255, 255]))
    gum_mask = cv2.bitwise_or(gum_mask_1, gum_mask_2)

    # Combine tooth enamel and oral cavity context
    combined_mask = cv2.bitwise_or(tooth_mask, gum_mask)

    # Morphological closing to join teeth boundaries
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (15, 15))
    cleaned_mask = cv2.morphologyEx(combined_mask, cv2.MORPH_CLOSE, kernel)

    contours, _ = cv2.findContours(cleaned_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    min_area = (width * height) * 0.005  # minimum 0.5% area of image
    valid_rects = []

    for cnt in contours:
        area = cv2.contourArea(cnt)
        if area >= min_area:
            x, y, w, h = cv2.boundingRect(cnt)
            # Check aspect ratio (teeth/mouth region is horizontally wide or balanced)
            aspect_ratio = w / float(h)
            if 0.4 <= aspect_ratio <= 4.5:
                valid_rects.append((x, y, w, h, area))

    if not valid_rects:
        return image, (0, 0, width, height)

    # Select the largest valid tooth/mouth contour bounding box
    valid_rects.sort(key=lambda r: r[4], reverse=True)
    x, y, w, h, _ = valid_rects[0]

    # Add 15% margin around the teeth region
    margin_x = int(w * 0.15)
    margin_y = int(h * 0.15)

    crop_x1 = max(0, x - margin_x)
    crop_y1 = max(0, y - margin_y)
    crop_x2 = min(width, x + w + margin_x)
    crop_y2 = min(height, y + h + margin_y)

    crop_w = crop_x2 - crop_x1
    crop_h = crop_y2 - crop_y1

    # Only crop if the cropped ROI is at least 80x80 pixels
    if crop_w >= 80 and crop_h >= 80:
        cropped_roi = image[crop_y1:crop_y2, crop_x1:crop_x2]
        return cropped_roi, (crop_x1, crop_y1, crop_w, crop_h)

    return image, (0, 0, width, height)
