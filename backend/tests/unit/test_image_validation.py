from pathlib import Path
import time
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


def test_validate_overexposed_image():
    img = np.full((300, 300, 3), 250, dtype=np.uint8)
    with pytest.raises(ValueError, match="Please upload a clear image showing human teeth."):
        validate_teeth_image(img)


def test_validate_severely_blurry_image():
    # Smooth uniform gradient image with zero high frequency details
    img = np.full((300, 300, 3), 128, dtype=np.uint8)
    with pytest.raises(ValueError, match="Please upload a clear image showing human teeth."):
        validate_teeth_image(img)


def test_validate_document_image_rejected():
    # White background with black text lines (no tooth enamel structure)
    img = np.full((400, 400, 3), 245, dtype=np.uint8)
    for y in range(50, 350, 20):
        img[y:y+3, 40:360] = (20, 20, 20)
    with pytest.raises(ValueError, match="Please upload a clear image showing human teeth."):
        validate_teeth_image(img)


def test_validate_unrelated_food_object_rejected():
    # Green apple image (no teeth)
    img = np.zeros((400, 400, 3), dtype=np.uint8)
    img[:, :] = (30, 30, 30)
    cv2.circle(img, (200, 200), 120, (40, 180, 50), -1)
    with pytest.raises(ValueError, match="Please upload a clear image showing human teeth."):
        validate_teeth_image(img)


def test_validate_teeth_with_lips_and_skin_accepted():
    img = np.zeros((400, 400, 3), dtype=np.uint8)
    img[:, :] = (120, 140, 200)  # Surrounding facial skin/lip background
    img[140:260, 80:320] = (220, 230, 240)  # Teeth enamel area
    # Add teeth gaps for sharpness
    for x in range(110, 300, 30):
        img[140:260, x:x+3] = (80, 90, 110)
    validate_teeth_image(img)


def test_validate_teeth_with_braces_accepted():
    img = np.zeros((400, 400, 3), dtype=np.uint8)
    img[:, :] = (100, 110, 190)  # Lips / gums background
    img[140:260, 80:320] = (220, 230, 240)  # Teeth enamel
    # Add metallic braces brackets
    for x in range(110, 300, 30):
        img[190:210, x:x+12] = (180, 180, 180)
        img[140:260, x:x+2] = (60, 60, 60)
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
    for x in range(120, 290, 25):
        img[150:250, x:x+2] = (70, 80, 100)
    validate_teeth_image(img)


@pytest.mark.parametrize("lighting_bgr", [
    (180, 220, 250),  # Bright warm light
    (240, 220, 190),  # Cool blue light
    (140, 140, 140),  # Dim interior lighting
])
def test_validate_different_lighting_conditions(lighting_bgr):
    img = np.zeros((400, 400, 3), dtype=np.uint8)
    img[:, :] = (80, 90, 160)
    img[140:260, 80:320] = lighting_bgr
    for x in range(110, 300, 30):
        img[140:260, x:x+2] = (40, 40, 40)
    validate_teeth_image(img)


def test_validator_execution_time_under_100ms():
    img = np.zeros((1080, 1920, 3), dtype=np.uint8)
    img[:, :] = (100, 120, 190)
    img[350:750, 400:1520] = (220, 230, 240)
    for x in range(500, 1450, 100):
        img[350:750, x:x+10] = (60, 70, 90)

    t0 = time.perf_counter()
    validate_teeth_image(img)
    elapsed_ms = (time.perf_counter() - t0) * 1000.0
    print(f"\n1080p Image Validation Execution Time: {elapsed_ms:.2f} ms")
    assert elapsed_ms < 100.0
