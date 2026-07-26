import cv2
import numpy as np


def validate_teeth_image(image: np.ndarray) -> None:
    """
    Validates whether an uploaded image is a clear, properly lit photo showing human teeth.
    Raises ValueError with a user-friendly message if the image is invalid.
    """
    if image is None or image.size == 0:
        raise ValueError("Please upload a clear image showing human teeth.")

    height, width = image.shape[:2]
    if height < 60 or width < 60:
        raise ValueError("Please upload a clear image showing human teeth.")

    # 1. Blur Detection using Variance of Laplacian
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
    if laplacian_var < 55.0:
        raise ValueError("Please upload a clear image showing human teeth.")

    # 2. Lighting & Exposure Check
    mean_brightness = float(np.mean(gray))
    if mean_brightness < 35.0 or mean_brightness > 225.0:
        raise ValueError("Please upload a clear image showing human teeth.")

    # Overexposed clipped pixels check (>250)
    overexposed_ratio = np.count_nonzero(gray > 250) / (height * width)
    if overexposed_ratio > 0.45:
        raise ValueError("Please upload a clear image showing human teeth.")

    # 3. Color & Structural Feature Analysis (Teeth + Oral Mucosa / Gum region)
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
    hue = hsv[:, :, 0]
    sat = hsv[:, :, 1]
    val = hsv[:, :, 2]

    # Tooth region mask: Bright, low-to-moderate saturation
    tooth_lower = np.array([0, 0, 105], dtype=np.uint8)
    tooth_upper = np.array([179, 95, 255], dtype=np.uint8)
    tooth_mask = cv2.inRange(hsv, tooth_lower, tooth_upper)

    total_pixels = height * width
    tooth_pixels = cv2.countNonZero(tooth_mask)
    tooth_ratio = tooth_pixels / total_pixels

    # Teeth must occupy a reasonable portion of the photo (between 5% and 80%)
    if tooth_ratio < 0.05 or tooth_ratio > 0.85:
        raise ValueError("Please upload a clear image showing human teeth.")

    # Check for oral mucosa / gum / lip presence (pink/red tones bordering teeth)
    # Red/Pink Hue range in HSV: 0-15 and 155-180 with moderate-to-high saturation
    gum_mask_1 = cv2.inRange(hsv, np.array([0, 50, 40]), np.array([16, 255, 255]))
    gum_mask_2 = cv2.inRange(hsv, np.array([155, 50, 40]), np.array([180, 255, 255]))
    gum_mask = cv2.bitwise_or(gum_mask_1, gum_mask_2)
    gum_pixels = cv2.countNonZero(gum_mask)
    gum_ratio = gum_pixels / total_pixels

    # Non-teeth images (e.g. paper documents, solid objects, landscapes, blue sky/foliage, pets)
    # will lack the oral environment combination (teeth structure + oral tissue/gums or high contrast oral cavity).
    # Check green/blue landscape foliage:
    green_blue_mask = cv2.inRange(hsv, np.array([35, 40, 40]), np.array([140, 255, 255]))
    green_blue_ratio = cv2.countNonZero(green_blue_mask) / total_pixels
    if green_blue_ratio > 0.40:
        raise ValueError("Please upload a clear image showing human teeth.")

    # Check document / text paper characteristic: extremely high white background (>85%) with dark text edges
    white_background_mask = cv2.inRange(hsv, np.array([0, 0, 180]), np.array([179, 30, 255]))
    white_ratio = cv2.countNonZero(white_background_mask) / total_pixels
    edges = cv2.Canny(gray, 100, 200)
    edge_ratio = cv2.countNonZero(edges) / total_pixels

    if white_ratio > 0.82 and gum_ratio < 0.02:
        raise ValueError("Please upload a clear image showing human teeth.")

    # Final check: Teeth ratio combined with oral context (gums or contrast)
    if tooth_ratio < 0.08 and gum_ratio < 0.03:
        raise ValueError("Please upload a clear image showing human teeth.")
