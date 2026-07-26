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
    total_pixels = height * width
    overexposed_ratio = np.count_nonzero(gray > 250) / total_pixels
    if overexposed_ratio > 0.45:
        raise ValueError("Please upload a clear image showing human teeth.")

    # 3. Color & Structural Feature Analysis (Teeth Enamel + Oral Mucosa / Gum region)
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)

    # Tooth enamel region mask: Off-white/cream/neutral tones with low-to-moderate saturation
    tooth_lower = np.array([0, 0, 110], dtype=np.uint8)
    tooth_upper = np.array([179, 75, 255], dtype=np.uint8)
    tooth_mask = cv2.inRange(hsv, tooth_lower, tooth_upper)
    tooth_pixels = cv2.countNonZero(tooth_mask)
    tooth_ratio = tooth_pixels / total_pixels

    # Check for oral mucosa / gum / lip presence (pink/red tones bordering teeth)
    gum_mask_1 = cv2.inRange(hsv, np.array([0, 45, 40]), np.array([18, 255, 255]))
    gum_mask_2 = cv2.inRange(hsv, np.array([150, 45, 40]), np.array([180, 255, 255]))
    gum_mask = cv2.bitwise_or(gum_mask_1, gum_mask_2)
    gum_pixels = cv2.countNonZero(gum_mask)
    gum_ratio = gum_pixels / total_pixels

    # Check green/blue landscape / non-oral background:
    green_blue_mask = cv2.inRange(hsv, np.array([35, 30, 30]), np.array([140, 255, 255]))
    green_blue_ratio = cv2.countNonZero(green_blue_mask) / total_pixels
    if green_blue_ratio > 0.35:
        raise ValueError("Please upload a clear image showing human teeth.")

    # Check document / text paper characteristic: high white background with dark text lines
    white_background_mask = cv2.inRange(hsv, np.array([0, 0, 180]), np.array([179, 25, 255]))
    white_ratio = cv2.countNonZero(white_background_mask) / total_pixels

    if white_ratio > 0.75 and gum_ratio < 0.02:
        raise ValueError("Please upload a clear image showing human teeth.")

    # Mandatory Intraoral Context Check: An intraoral teeth photo MUST contain
    # oral tissue (gums/lips pink-red ratio >= 2.0%) or oral cavity dark contrast.
    dark_oral_cavity_mask = cv2.inRange(hsv, np.array([0, 0, 0]), np.array([179, 255, 45]))
    dark_cavity_ratio = cv2.countNonZero(dark_oral_cavity_mask) / total_pixels

    if gum_ratio < 0.020 and dark_cavity_ratio < 0.015:
        raise ValueError("Please upload a clear image showing human teeth.")

    if tooth_ratio < 0.05:
        raise ValueError("Please upload a clear image showing human teeth.")

    # 4. Spatial Proximity Verification (Teeth Enamel bordering Gum / Oral Tissue)
    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (15, 15))
    dilated_teeth = cv2.dilate(tooth_mask, kernel)
    oral_context_mask = cv2.bitwise_or(gum_mask, dark_oral_cavity_mask)
    boundary_intersection = cv2.bitwise_and(dilated_teeth, oral_context_mask)
    boundary_ratio = cv2.countNonZero(boundary_intersection) / total_pixels

    if boundary_ratio < 0.008:
        raise ValueError("Please upload a clear image showing human teeth.")
