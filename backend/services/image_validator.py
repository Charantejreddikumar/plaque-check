import cv2
import numpy as np


def validate_teeth_image(image: np.ndarray) -> None:
    """
    Basic sanity check for uploaded images (ensures valid non-empty image data).
    Removes restrictive skin/lip/face heuristics so all user photos can be analyzed smoothly.
    """
    if image is None or image.size == 0:
        raise ValueError("Please upload a clear image showing human teeth.")

    height, width = image.shape[:2]
    if height < 20 or width < 20:
        raise ValueError("Please upload a clear image showing human teeth.")

    # Check for completely black / dark corrupt non-photo images
    if float(np.mean(image)) < 15.0:
        raise ValueError("Please upload a clear image showing human teeth.")
