import numpy as np
import pytest

from services.image_validator import validate_teeth_image


def test_validate_empty_image():
    with pytest.raises(ValueError, match="Please upload a clear image showing human teeth."):
        validate_teeth_image(np.array([], dtype=np.uint8))


def test_validate_blurred_image():
    # Synthetic flat/blurred low variance image
    img = np.full((300, 300, 3), 128, dtype=np.uint8)
    with pytest.raises(ValueError, match="Please upload a clear image showing human teeth."):
        validate_teeth_image(img)


def test_validate_dark_image():
    # Extremely dark image
    img = np.full((300, 300, 3), 10, dtype=np.uint8)
    with pytest.raises(ValueError, match="Please upload a clear image showing human teeth."):
        validate_teeth_image(img)


def test_validate_overexposed_image():
    # Overexposed image
    img = np.full((300, 300, 3), 254, dtype=np.uint8)
    with pytest.raises(ValueError, match="Please upload a clear image showing human teeth."):
        validate_teeth_image(img)


def test_validate_document_non_teeth():
    # White background with black text lines (document simulation)
    img = np.full((400, 400, 3), 250, dtype=np.uint8)
    # Add horizontal dark lines (simulating text lines)
    img[50:55, 20:380] = 0
    img[100:105, 20:380] = 0
    img[150:155, 20:380] = 0

    with pytest.raises(ValueError, match="Please upload a clear image showing human teeth."):
        validate_teeth_image(img)


def test_validate_valid_teeth_synthetic():
    # Create a synthetic valid dental photo (teeth white/neutral + surrounding gum pink tones)
    img = np.zeros((400, 400, 3), dtype=np.uint8)

    # Oral cavity / gums background (Pink/Red: BGR = (100, 100, 200))
    img[:, :] = (100, 100, 200)

    # Teeth row (White/off-white enamel: BGR = (220, 230, 240))
    # Draw teeth pixels in the central region
    img[150:250, 100:300] = (220, 230, 240)

    # Add teeth separation lines (edges)
    for x in range(120, 300, 30):
        img[150:250, x:x+2] = (160, 170, 180)

    # Add slight random texture so Laplacian variance is sharp (>55)
    noise = np.random.randint(-15, 15, img.shape, dtype=np.int16)
    img_noisy = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)

    # Should pass validation cleanly without raising ValueError
    validate_teeth_image(img_noisy)
