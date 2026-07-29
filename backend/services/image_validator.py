import logging
import cv2
import numpy as np

logger = logging.getLogger(__name__)


def validate_teeth_image(image: np.ndarray) -> None:
    """
    Validates uploaded dental images for basic clarity and readability.
    Accepts all normal dental photographs containing perioral lips, gums, and skin context.
    Rejects only corrupt, dark (mean < 15.0), unreadable, or undersized images.
    """
    logger.info("[Stage 1/11] Starting image validation check...")

    if image is None or image.size == 0:
        logger.warning("[Validation Failed] Empty or invalid image data received.")
        raise ValueError("Please upload a clear image showing human teeth.")

    height, width = image.shape[:2]
    if height < 20 or width < 20:
        logger.warning("[Validation Failed] Image resolution too small: %dx%d.", width, height)
        raise ValueError("Please upload a clear image showing human teeth.")

    # Check for completely black / dark corrupt non-photo images
    mean_val = float(np.mean(image))
    if mean_val < 15.0:
        logger.warning("[Validation Failed] Image is corrupted or too dark (mean pixel intensity: %.2f).", mean_val)
        raise ValueError("Please upload a clear image showing human teeth.")

    logger.info("[Stage 1/11 PASSED] Image is valid for analysis (dimensions: %dx%d, mean intensity: %.1f).", width, height, mean_val)
