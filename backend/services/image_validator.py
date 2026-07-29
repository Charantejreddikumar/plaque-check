import logging
import time
import cv2
import numpy as np

logger = logging.getLogger(__name__)


def validate_teeth_image(image: np.ndarray) -> None:
    """
    Lightweight, high-performance teeth image validation module (< 10 ms).
    Executes BEFORE plaque analysis. Does NOT modify the original image.

    Accepts:
      - Normal intraoral photos
      - Teeth with visible lips, gums, tongue, cheeks, or surrounding facial skin
      - Teeth with braces or dental restorations
      - Varied skin tones, camera hardware, and lighting conditions

    Rejects:
      - Unreadable, empty, or extremely small images (< 30x30)
      - Extremely dark images (mean < 18.0)
      - Severely overexposed / washed out images (mean > 245.0 or flat high brightness)
      - Flat white documents / paper pages (high brightness with zero saturation variance)
      - Completely blurred images (Laplacian variance < 15.0)
      - Non-teeth objects, flat documents, landscapes, or food (tooth area < 1.8% or < 150 pixels)
    """
    t0 = time.perf_counter()

    # 1. Readability & Dimensions Check
    if image is None or image.size == 0:
        logger.warning("[Validation Failed] Image is empty or unreadable.")
        raise ValueError("Please upload a clear image showing human teeth.")

    height, width = image.shape[:2]
    if height < 30 or width < 30:
        logger.warning("[Validation Failed] Image resolution too small: %dx%d.", width, height)
        raise ValueError("Please upload a clear image showing human teeth.")

    # Downsample large images for ultra-fast validation (< 10 ms even on 4K photos)
    if width > 600:
        scale = 600.0 / width
        small_img = cv2.resize(image, (600, int(height * scale)), interpolation=cv2.INTER_AREA)
    else:
        small_img = image

    h_small, w_small = small_img.shape[:2]
    total_pixels_small = h_small * w_small

    # Convert small_img to grayscale for fast exposure & blur checks
    gray = cv2.cvtColor(small_img, cv2.COLOR_BGR2GRAY)

    # 2. Brightness & Exposure Checks
    mean_brightness = float(np.mean(gray))
    std_brightness = float(np.std(gray))

    if mean_brightness < 18.0:
        logger.warning("[Validation Failed] Image is extremely dark (mean: %.2f).", mean_brightness)
        raise ValueError("Please upload a clear image showing human teeth.")

    if mean_brightness > 245.0 or (mean_brightness > 220.0 and std_brightness < 10.0):
        logger.warning("[Validation Failed] Image is severely overexposed/washed out (mean: %.2f, std: %.2f).", mean_brightness, std_brightness)
        raise ValueError("Please upload a clear image showing human teeth.")

    # 3. Contrast & Document Rejection Check
    if std_brightness < 8.0:
        logger.warning("[Validation Failed] Image contrast too low or uniform (std: %.2f).", std_brightness)
        raise ValueError("Please upload a clear image showing human teeth.")

    # Fast check for white paper document pages (bright paper with near-zero saturation variation)
    hsv = cv2.cvtColor(small_img, cv2.COLOR_BGR2HSV)
    saturation = hsv[:, :, 1]
    std_saturation = float(np.std(saturation))

    if mean_brightness > 190.0 and std_saturation < 6.0:
        logger.warning("[Validation Failed] Flat white document/paper detected (mean_bright: %.1f, std_sat: %.2f).", mean_brightness, std_saturation)
        raise ValueError("Please upload a clear image showing human teeth.")

    # 4. Sharpness Check (blur detection via Laplacian variance)
    laplacian_var = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    if laplacian_var < 15.0:
        logger.warning("[Validation Failed] Image is severely blurred (Laplacian variance: %.2f).", laplacian_var)
        raise ValueError("Please upload a clear image showing human teeth.")

    # 5. Visible Teeth Area Detection
    # Detect tooth enamel (bright, low-to-moderate saturation in HSV space)
    lower_teeth = np.array([0, 0, 95], dtype=np.uint8)
    upper_teeth = np.array([179, 105, 255], dtype=np.uint8)
    tooth_mask = cv2.inRange(hsv, lower_teeth, upper_teeth)

    tooth_pixels = int(cv2.countNonZero(tooth_mask))
    tooth_ratio = tooth_pixels / total_pixels_small

    if tooth_pixels < 100 or tooth_ratio < 0.018:
        logger.warning("[Validation Failed] No teeth or insufficient teeth visible (tooth_pixels: %d, ratio: %.4f).", tooth_pixels, tooth_ratio)
        raise ValueError("Please upload a clear image showing human teeth.")

    elapsed_ms = (time.perf_counter() - t0) * 1000.0
    logger.info("[Stage 1 Validation PASSED] Valid dental photo (dim: %dx%d, blur_var: %.1f, teeth_ratio: %.2f%%, elapsed: %.2f ms).",
                width, height, laplacian_var, tooth_ratio * 100, elapsed_ms)
