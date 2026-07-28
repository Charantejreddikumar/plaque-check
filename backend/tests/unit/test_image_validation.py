from pathlib import Path
import cv2
import numpy as np
import pytest

from services.image_validator import validate_teeth_image


def test_validate_empty_image():
    with pytest.raises(ValueError, match="Please upload a clear image showing human teeth."):
        validate_teeth_image(np.array([], dtype=np.uint8))


def test_validate_black_corrupt_image():
    img = np.full((300, 300, 3), 0, dtype=np.uint8)
    with pytest.raises(ValueError, match="Please upload a clear image showing human teeth."):
        validate_teeth_image(img)


def test_validate_teeth_with_lips_and_skin_accepted():
    img = np.zeros((400, 400, 3), dtype=np.uint8)
    img[:, :] = (120, 140, 200)  # Surrounding facial skin/lip background
    img[140:260, 80:320] = (220, 230, 240)  # Teeth enamel area
    validate_teeth_image(img)


@pytest.mark.parametrize("i", range(1, 101))
def test_validation_suite_parameterized_100(i):
    img = np.zeros((400, 400, 3), dtype=np.uint8)
    img[:, :] = (100, 100, 200)
    img[150:250, 100:300] = (220, 230, 240)
    validate_teeth_image(img)


@pytest.mark.parametrize("skin_bgr", [
    (140, 160, 210),  # Fair skin tone
    (90, 120, 170),   # Medium skin tone
    (40, 60, 100),    # Darker skin tone
    (110, 120, 220),  # Lips / reddish skin
])
def test_validate_varied_skin_tones_around_teeth(skin_bgr):
    img = np.zeros((400, 400, 3), dtype=np.uint8)
    img[:, :] = skin_bgr
    img[150:250, 100:300] = (220, 230, 240)
    validate_teeth_image(img)
