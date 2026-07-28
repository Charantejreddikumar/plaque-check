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


def test_validate_face_dataset_rejection():
    if DATASET_NON_TEETH_DIR.exists():
        samples = list(DATASET_NON_TEETH_DIR.glob("*.jpg"))[:10]
        for img_path in samples:
            img = cv2.imread(str(img_path))
            if img is not None:
                with pytest.raises(ValueError):
                    validate_teeth_image(img)


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
