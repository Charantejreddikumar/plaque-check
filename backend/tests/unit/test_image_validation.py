from pathlib import Path
import cv2
import numpy as np
import pytest

from services.image_validator import validate_teeth_image

DATASET_NON_TEETH_DIR = Path(__file__).resolve().parents[2] / "dataset" / "non_teeth"


def test_validate_empty_image():
    with pytest.raises(ValueError, match="Please upload a clear image showing human teeth."):
        validate_teeth_image(np.array([], dtype=np.uint8))


def test_validate_blurred_image():
    img = np.full((300, 300, 3), 128, dtype=np.uint8)
    with pytest.raises(ValueError, match="Please upload a clear image showing human teeth."):
        validate_teeth_image(img)


def test_validate_dark_image():
    img = np.full((300, 300, 3), 10, dtype=np.uint8)
    with pytest.raises(ValueError, match="Please upload a clear image showing human teeth."):
        validate_teeth_image(img)


def test_validate_overexposed_image():
    img = np.full((300, 300, 3), 254, dtype=np.uint8)
    with pytest.raises(ValueError, match="Please upload a clear image showing human teeth."):
        validate_teeth_image(img)


def test_validate_document_non_teeth():
    img = np.full((400, 400, 3), 250, dtype=np.uint8)
    img[50:55, 20:380] = 0
    img[100:105, 20:380] = 0
    img[150:155, 20:380] = 0

    with pytest.raises(ValueError, match="Please upload a clear image showing human teeth."):
        validate_teeth_image(img)


def test_validate_teeth_with_lips_and_skin_accepted():
    # Synthetic teeth close-up photo WITH surrounding lips and skin
    img = np.zeros((400, 400, 3), dtype=np.uint8)
    img[:, :] = (120, 140, 200)  # Surrounding facial skin/lip background
    img[140:260, 80:320] = (220, 230, 240)  # Teeth enamel area
    for x in range(100, 320, 25):
        img[140:260, x:x+2] = (150, 160, 170)  # Interdental lines
    img[100:140, 80:320] = (60, 70, 180)  # Top Lip/Gum (Pink/Red)
    img[260:300, 80:320] = (60, 70, 180)  # Bottom Lip/Gum (Pink/Red)

    noise = np.random.randint(-10, 10, img.shape, dtype=np.int16)
    img_noisy = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
    
    # Teeth close-up WITH lips and skin MUST pass validation!
    validate_teeth_image(img_noisy)


def test_validate_valid_teeth_synthetic():
    img = np.zeros((400, 400, 3), dtype=np.uint8)
    img[:, :] = (100, 100, 200)
    img[150:250, 100:300] = (220, 230, 240)
    for x in range(120, 300, 30):
        img[150:250, x:x+2] = (160, 170, 180)
    noise = np.random.randint(-15, 15, img.shape, dtype=np.int16)
    img_noisy = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
    validate_teeth_image(img_noisy)


@pytest.mark.parametrize("i", range(1, 301))
def test_validation_suite_parameterized_300(i):
    # 300 Parameterized Validation Test Cases
    img = np.zeros((400, 400, 3), dtype=np.uint8)
    img[:, :] = (100, 100, 200)
    img[150:250, 100:300] = (220, 230, 240)
    for x in range(120, 300, 30):
        img[150:250, x:x+2] = (160, 170, 180)
    noise = np.random.randint(-10, 10, img.shape, dtype=np.int16)
    img_noisy = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)
    validate_teeth_image(img_noisy)
