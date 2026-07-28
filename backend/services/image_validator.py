import cv2
import numpy as np


def validate_teeth_image(image: np.ndarray) -> None:
    """
    Validates whether an uploaded image is a clear, properly lit close-up photo showing human teeth.
    Allows natural perioral skin and lips around the mouth while rejecting full-face portraits (with eyes/forehead), blurred images, or non-teeth photos.
    """
    if image is None or image.size == 0:
        raise ValueError("Please upload a clear image showing human teeth.")

    height, width = image.shape[:2]
    if height < 60 or width < 60:
        raise ValueError("Please upload a clear image showing human teeth.")

    # 1. Blur Detection using Variance of Laplacian
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    laplacian_var = cv2.Laplacian(gray, cv2.CV_64F).var()
    if laplacian_var < 50.0:
        raise ValueError("Please upload a clear image showing human teeth.")

    # 2. Lighting & Exposure Check
    mean_brightness = float(np.mean(gray))
    if mean_brightness < 30.0 or mean_brightness > 230.0:
        raise ValueError("Please upload a clear image showing human teeth.")

    # Overexposed clipped pixels check (>250)
    total_pixels = height * width
    overexposed_ratio = np.count_nonzero(gray > 250) / total_pixels
    if overexposed_ratio > 0.48:
        raise ValueError("Please upload a clear image showing human teeth.")

    # 3. Color & Structural Feature Analysis (Teeth Enamel + Oral Mucosa / Gum & Lip region)
    hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)

    # Tooth enamel region mask: Off-white/cream/neutral tones with low-to-moderate saturation
    tooth_lower = np.array([0, 0, 100], dtype=np.uint8)
    tooth_upper = np.array([179, 90, 255], dtype=np.uint8)
    tooth_mask = cv2.inRange(hsv, tooth_lower, tooth_upper)
    tooth_pixels = cv2.countNonZero(tooth_mask)
    tooth_ratio = tooth_pixels / total_pixels

    # Check for oral mucosa / gum / lip presence (pink/red tones bordering teeth)
    gum_mask_1 = cv2.inRange(hsv, np.array([0, 35, 30]), np.array([25, 255, 255]))
    gum_mask_2 = cv2.inRange(hsv, np.array([140, 35, 30]), np.array([180, 255, 255]))
    gum_mask = cv2.bitwise_or(gum_mask_1, gum_mask_2)
    gum_pixels = cv2.countNonZero(gum_mask)
    gum_ratio = gum_pixels / total_pixels

    # Mandatory Tooth Enamel Check: Photo must contain teeth enamel pixels (>= 3.0%)
    if tooth_ratio < 0.030:
        raise ValueError("Please upload a clear close-up image showing human teeth.")

    # 4. Full-Face Portrait Filter (Eyes + Forehead check)
    # ONLY reject as a full face portrait if eyes are clearly detected in the upper face region AND teeth ratio is low
    frontal_cascade_path = cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
    eye_cascade_path = cv2.data.haarcascades + 'haarcascade_eye.xml'
    
    if cv2.os.path.exists(frontal_cascade_path) and cv2.os.path.exists(eye_cascade_path):
        face_cascade = cv2.CascadeClassifier(frontal_cascade_path)
        eye_cascade = cv2.CascadeClassifier(eye_cascade_path)
        
        # Search for full face bounding boxes
        faces = face_cascade.detectMultiScale(gray, scaleFactor=1.1, minNeighbors=6, minSize=(int(width * 0.35), int(height * 0.35)))
        for (x, y, w, h) in faces:
            roi_gray = gray[y:y+int(h*0.6), x:x+w]
            eyes = eye_cascade.detectMultiScale(roi_gray, scaleFactor=1.1, minNeighbors=4)
            # If eyes are detected in the upper 60% of the face box AND teeth enamel is minor (< 6%), it's a full face portrait
            if len(eyes) >= 2 and tooth_ratio < 0.06:
                raise ValueError("Please upload a close-up photo focused on your teeth, not a full face portrait.")

    # 5. Non-Oral Background Check (Green/Blue landscapes, document paper)
    green_blue_mask = cv2.inRange(hsv, np.array([35, 30, 30]), np.array([140, 255, 255]))
    green_blue_ratio = cv2.countNonZero(green_blue_mask) / total_pixels
    if green_blue_ratio > 0.40:
        raise ValueError("Please upload a clear image showing human teeth.")

    white_background_mask = cv2.inRange(hsv, np.array([0, 0, 180]), np.array([179, 25, 255]))
    white_ratio = cv2.countNonZero(white_background_mask) / total_pixels
    if white_ratio > 0.82 and gum_ratio < 0.010:
        raise ValueError("Please upload a clear image showing human teeth.")

    # 6. Oral Cavity & Boundary Context Verification
    dark_oral_cavity_mask = cv2.inRange(hsv, np.array([0, 0, 0]), np.array([179, 255, 55]))
    dark_cavity_ratio = cv2.countNonZero(dark_oral_cavity_mask) / total_pixels

    if gum_ratio < 0.010 and dark_cavity_ratio < 0.008:
        raise ValueError("Please upload a clear image showing human teeth.")

    kernel = cv2.getStructuringElement(cv2.MORPH_RECT, (15, 15))
    dilated_teeth = cv2.dilate(tooth_mask, kernel)
    oral_context_mask = cv2.bitwise_or(gum_mask, dark_oral_cavity_mask)
    boundary_intersection = cv2.bitwise_and(dilated_teeth, oral_context_mask)
    boundary_ratio = cv2.countNonZero(boundary_intersection) / total_pixels

    if boundary_ratio < 0.004:
        raise ValueError("Please upload a clear image showing human teeth.")
