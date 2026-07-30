import logging
import time
import cv2
import numpy as np

logger = logging.getLogger(__name__)

REJECTION_MESSAGE = (
    "This is not a valid teeth image.\n"
    "Plaque analysis cannot be performed.\n"
    "Please scan your teeth again."
)


def validate_teeth_image(image: np.ndarray) -> None:
    """
    Dedicated Image Validation Module executing BEFORE plaque detection.
    Independent from the plaque detection model.

    Accepts:
      - Human teeth clearly visible (healthy, mild/moderate/severe plaque, braces)
      - Dental arch visible
      - Teeth occupying meaningful portion of image
      - Sufficient quality for analysis
      - Partial lips, partial gums, skin around mouth, varied skin tones, varied lighting

    Rejects:
      - Tables, chairs, trees, cupboards, food, screens, documents, pets,
        cars, buildings, landscapes, faces without visible teeth, random household objects.
    """
    t0 = time.perf_counter()

    # 1. Readability & Resolution Check
    if image is None or image.size == 0:
        logger.warning("[Validation Failed] Image is empty or unreadable.")
        raise ValueError(REJECTION_MESSAGE)

    height, width = image.shape[:2]
    if height < 40 or width < 40:
        logger.warning("[Validation Failed] Image resolution too small: %dx%d.", width, height)
        raise ValueError(REJECTION_MESSAGE)

    # Downsample large images for fast validation (< 15 ms)
    if width > 600:
        scale = 600.0 / width
        small_img = cv2.resize(image, (600, int(height * scale)), interpolation=cv2.INTER_AREA)
    else:
        small_img = image

    h_small, w_small = small_img.shape[:2]
    total_pixels_small = h_small * w_small

    gray = cv2.cvtColor(small_img, cv2.COLOR_BGR2GRAY)

    # 2. Brightness, Contrast & Blur Checks
    mean_brightness = float(np.mean(gray))
    std_brightness = float(np.std(gray))

    if mean_brightness < 18.0:
        logger.warning("[Validation Failed] Image too dark (mean: %.2f).", mean_brightness)
        raise ValueError(REJECTION_MESSAGE)

    if mean_brightness > 242.0 or (mean_brightness > 215.0 and std_brightness < 12.0):
        logger.warning("[Validation Failed] Image overexposed/washed out (mean: %.2f, std: %.2f).", mean_brightness, std_brightness)
        raise ValueError(REJECTION_MESSAGE)

    if std_brightness < 8.0:
        logger.warning("[Validation Failed] Image contrast too low (std: %.2f).", std_brightness)
        raise ValueError(REJECTION_MESSAGE)

    # Blur detection via Laplacian variance
    laplacian_var = float(cv2.Laplacian(gray, cv2.CV_64F).var())
    if laplacian_var < 15.0:
        logger.warning("[Validation Failed] Image too blurry (Laplacian var: %.2f).", laplacian_var)
        raise ValueError(REJECTION_MESSAGE)

    hsv = cv2.cvtColor(small_img, cv2.COLOR_BGR2HSV)
    lab = cv2.cvtColor(small_img, cv2.COLOR_BGR2LAB)

    # 3. Flat Document / Paper Page Rejection
    saturation = hsv[:, :, 1]
    std_saturation = float(np.std(saturation))
    if mean_brightness > 185.0 and std_saturation < 6.5:
        logger.warning("[Validation Failed] Flat white document/paper detected (mean_bright: %.1f, std_sat: %.2f).", mean_brightness, std_saturation)
        raise ValueError(REJECTION_MESSAGE)

    # 4. Nature / Outdoor / Landscape Rejection (Trees, Sky, Grass)
    green_mask = cv2.inRange(hsv, np.array([35, 35, 35]), np.array([85, 255, 255]))
    sky_mask = cv2.inRange(hsv, np.array([90, 40, 60]), np.array([130, 255, 255]))
    outdoor_pixels = int(cv2.countNonZero(green_mask)) + int(cv2.countNonZero(sky_mask))
    outdoor_ratio = outdoor_pixels / total_pixels_small
    if outdoor_ratio > 0.18:
        logger.warning("[Validation Failed] Landscape/nature background detected (outdoor_ratio: %.2f%%).", outdoor_ratio * 100)
        raise ValueError(REJECTION_MESSAGE)

    # 5. Furniture / Wood Grain / Household Object Rejection (Tables, Chairs, Cupboards, Doors)
    wood_mask = cv2.inRange(hsv, np.array([8, 25, 30]), np.array([26, 180, 220]))
    wood_pixels = int(cv2.countNonZero(wood_mask))
    wood_ratio = wood_pixels / total_pixels_small

    # 6. Oral Mucosa / Gum / Lip Tissue Mask (Context check)
    gum_1 = cv2.inRange(hsv, np.array([0, 18, 20]), np.array([25, 255, 255]))
    gum_2 = cv2.inRange(hsv, np.array([150, 18, 20]), np.array([180, 255, 255]))
    oral_mucosa_mask = cv2.bitwise_or(gum_1, gum_2)
    oral_mucosa_pixels = int(cv2.countNonZero(oral_mucosa_mask))
    oral_mucosa_ratio = oral_mucosa_pixels / total_pixels_small

    if wood_ratio > 0.35 and oral_mucosa_ratio < 0.02:
        logger.warning("[Validation Failed] Wooden furniture/table/cupboard detected (wood_ratio: %.2f%%, oral_ratio: %.2f%%).", wood_ratio * 100, oral_mucosa_ratio * 100)
        raise ValueError(REJECTION_MESSAGE)

    # 7. Tooth Enamel & Structural Arch Detection
    hsv_enamel = cv2.inRange(hsv, np.array([0, 0, 90]), np.array([179, 85, 255]))
    lab_enamel = cv2.inRange(lab, np.array([120, 110, 100]), np.array([255, 145, 175]))
    enamel_candidate_mask = cv2.bitwise_and(hsv_enamel, lab_enamel)

    dilated_oral = cv2.dilate(oral_mucosa_mask, cv2.getStructuringElement(cv2.MORPH_RECT, (15, 15)))
    bounded_enamel = cv2.bitwise_and(enamel_candidate_mask, dilated_oral)

    enamel_pixels = int(cv2.countNonZero(enamel_candidate_mask))
    bounded_pixels = int(cv2.countNonZero(bounded_enamel))

    enamel_ratio = enamel_pixels / total_pixels_small
    bounded_ratio = bounded_pixels / total_pixels_small

    if enamel_pixels < 120 or enamel_ratio < 0.012:
        logger.warning("[Validation Failed] Insufficient tooth enamel pixels detected (enamel_pixels: %d, ratio: %.4f).", enamel_pixels, enamel_ratio)
        raise ValueError(REJECTION_MESSAGE)

    # 8. Interdental Edge Gradient & Arch Contour Structure Check
    sobel_x = cv2.Sobel(gray, cv2.CV_32F, 1, 0, ksize=3)
    abs_sobel_x = np.abs(sobel_x)
    enamel_edges = (abs_sobel_x > 25.0).astype(np.uint8) * enamel_candidate_mask
    edge_count = int(cv2.countNonZero(enamel_edges))
    edge_density = edge_count / float(max(enamel_pixels, 1))

    # 9. Oral Context Mandate & Closed Mouth / Face without visible teeth / Skin-only Rejection
    skin_mask = cv2.inRange(hsv, np.array([0, 20, 50]), np.array([25, 160, 255]))
    skin_pixels = int(cv2.countNonZero(skin_mask))
    skin_ratio = skin_pixels / total_pixels_small

    if oral_mucosa_ratio < 0.005 and bounded_ratio < 0.003:
        logger.warning("[Validation Failed] Non-dental object detected: missing oral mucosa context (oral_mucosa_ratio: %.4f, bounded_ratio: %.4f).",
                       oral_mucosa_ratio, bounded_ratio)
        raise ValueError(REJECTION_MESSAGE)

    if skin_ratio > 0.35 and (bounded_ratio < 0.008 or edge_density < 0.035):
        logger.warning("[Validation Failed] Face without visible teeth or skin photo detected (skin_ratio: %.2f%%, bounded_enamel: %.2f%%, edge_density: %.4f).",
                       skin_ratio * 100, bounded_ratio * 100, edge_density)
        raise ValueError(REJECTION_MESSAGE)

    # 10. General Object / Non-Dental Image Rejection
    is_dental_arch = (
        (bounded_ratio >= 0.005 and edge_density >= 0.025)
        or (enamel_ratio >= 0.035 and bounded_ratio >= 0.003 and edge_density >= 0.025)
    )

    if not is_dental_arch:
        logger.warning("[Validation Failed] Image lacks characteristic dental arch edge structure / oral context (bounded_ratio: %.4f, enamel_ratio: %.4f, edge_density: %.4f).",
                       bounded_ratio, enamel_ratio, edge_density)
        raise ValueError(REJECTION_MESSAGE)

    elapsed_ms = (time.perf_counter() - t0) * 1000.0
    logger.info("[Validation PASSED] Valid dental photo verified (dim: %dx%d, blur: %.1f, enamel_ratio: %.2f%%, bounded_ratio: %.2f%%, edge_density: %.4f, elapsed: %.2f ms).",
                width, height, laplacian_var, enamel_ratio * 100, bounded_ratio * 100, edge_density, elapsed_ms)

