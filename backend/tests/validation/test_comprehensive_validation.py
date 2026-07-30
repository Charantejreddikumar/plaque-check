from pathlib import Path
import time
import cv2
import numpy as np
import pytest

from services.image_validator import validate_teeth_image, REJECTION_MESSAGE
from services.plaque_analyzer import analyze_image


def _create_synthetic_valid_dental_image(plaque_severity: str = "low", braces: bool = False, skin_tone: tuple = (60, 60, 180), lighting: float = 1.0) -> np.ndarray:
    """Generates a synthetic valid dental photo with tooth enamel structure, oral cavity, and optional plaque biofilm."""
    img = np.zeros((400, 400, 3), dtype=np.uint8)
    img[:, :] = skin_tone  # Lips/skin background
    img[120:280, 60:340] = (50, 50, 170)  # Dark reddish oral cavity

    # Enamel area
    enamel_color = (int(220 * lighting), int(230 * lighting), int(240 * lighting))
    img[140:260, 80:320] = enamel_color

    # Add interdental gaps
    for x in range(110, 300, 25):
        img[140:260, x:x+3] = (30, 30, 90)

    if braces:
        for x in range(110, 300, 25):
            img[190:210, x:x+10] = (180, 180, 180)

    # Plaque biofilm simulation if moderate or severe
    if plaque_severity in ["moderate", "severe"]:
        plaque_h = 40 if plaque_severity == "severe" else 20
        img[260-plaque_h:260, 85:315] = (20, 180, 230)  # Yellow-ish biofilm in BGR

    return img


def _create_synthetic_invalid_image(category: str) -> np.ndarray:
    """Generates a synthetic invalid image representing tables, trees, walls, documents, food, pets, etc."""
    img = np.zeros((400, 400, 3), dtype=np.uint8)

    if category == "table_wood":
        img[:, :] = (30, 80, 140)  # Wooden brown texture
        for y in range(0, 400, 10):
            img[y:y+2, :] = (20, 60, 110)
    elif category == "chair_furniture":
        img[:, :] = (50, 50, 50)  # Gray metallic/fabric chair
    elif category == "tree_landscape":
        img[:, :] = (40, 160, 50)  # Green foliage (B=40, G=160, R=50)
        img[0:150, :] = (200, 150, 80)  # Blue sky
    elif category == "wall":
        img[:, :] = (180, 180, 180)  # Uniform gray wall
    elif category == "document_text":
        img[:, :] = (245, 245, 245)
        for y in range(40, 360, 20):
            img[y:y+3, 40:360] = (20, 20, 20)
    elif category == "food_fruit":
        img[:, :] = (20, 20, 20)
        cv2.circle(img, (200, 200), 120, (30, 190, 40), -1)  # Green apple
    elif category == "pet_animal":
        img[:, :] = (40, 90, 150)  # Brown fur
        for y in range(0, 400, 4):
            img[y:y+1, :] = (30, 70, 120)
    elif category == "hand_skin":
        img[:, :] = (120, 150, 210)  # Continuous smooth skin, no dental enamel
    elif category == "closed_mouth_face":
        img[:, :] = (110, 140, 205)  # Face skin
        img[220:235, 130:270] = (60, 60, 160)  # Closed lips line without teeth
    elif category == "mobile_phone":
        img[:, :] = (20, 20, 20)
        img[40:360, 80:320] = (220, 220, 220)  # White screen with black bezel
        img[100:130, 100:300] = (50, 50, 50)
    elif category == "car_vehicle":
        img[:, :] = (200, 50, 40)  # Metallic red body
        img[50:180, 60:340] = (220, 240, 250)  # Windshield reflection
    elif category == "building_architecture":
        img[:, :] = (150, 150, 150)  # Concrete wall / glass building
        for y in range(50, 350, 40):
            img[y:y+20, 50:350] = (200, 220, 240)  # Windows
    else:  # blank
        img[:, :] = (200, 200, 200)

    return img


def test_comprehensive_validation_suite(tmp_path: Path):
    """
    Evaluates 100% rejection rate for invalid objects and 100% pass rate for valid teeth photos.
    Calculates Accuracy, Precision, Recall, F1-Score, FPR, FNR.
    """
    valid_samples = [
        ("healthy_teeth", _create_synthetic_valid_dental_image("low")),
        ("mild_plaque", _create_synthetic_valid_dental_image("low")),
        ("moderate_plaque", _create_synthetic_valid_dental_image("moderate")),
        ("severe_plaque", _create_synthetic_valid_dental_image("severe")),
        ("braces_teeth", _create_synthetic_valid_dental_image("low", braces=True)),
        ("dark_skin_tone", _create_synthetic_valid_dental_image("low", skin_tone=(40, 50, 120))),
        ("dim_lighting", _create_synthetic_valid_dental_image("low", lighting=0.7)),
    ]

    invalid_samples = [
        ("table", _create_synthetic_invalid_image("table_wood")),
        ("chair", _create_synthetic_invalid_image("chair_furniture")),
        ("tree", _create_synthetic_invalid_image("tree_landscape")),
        ("cupboard", _create_synthetic_invalid_image("table_wood")),
        ("wall", _create_synthetic_invalid_image("wall")),
        ("document", _create_synthetic_invalid_image("document_text")),
        ("food", _create_synthetic_invalid_image("food_fruit")),
        ("pet", _create_synthetic_invalid_image("pet_animal")),
        ("hand", _create_synthetic_invalid_image("hand_skin")),
        ("closed_mouth_selfie", _create_synthetic_invalid_image("closed_mouth_face")),
        ("mobile_phone", _create_synthetic_invalid_image("mobile_phone")),
        ("car", _create_synthetic_invalid_image("car_vehicle")),
        ("building", _create_synthetic_invalid_image("building_architecture")),
        ("blank", _create_synthetic_invalid_image("blank")),
    ]

    tp, fp, tn, fn = 0, 0, 0, 0

    # Test Valid Images (Should pass validation)
    for name, img in valid_samples:
        try:
            validate_teeth_image(img)
            tp += 1  # True Positive (Valid correctly passed)
        except ValueError:
            fn += 1  # False Negative (Valid incorrectly rejected)

    # Test Invalid Images (Should fail validation)
    for name, img in invalid_samples:
        try:
            validate_teeth_image(img)
            fp += 1  # False Positive (Invalid incorrectly passed)
        except ValueError as exc:
            assert REJECTION_MESSAGE in str(exc) or "This is not a valid teeth image" in str(exc)
            tn += 1  # True Negative (Invalid correctly rejected)

    total = tp + fp + tn + fn
    accuracy = (tp + tn) / total
    precision = tp / (tp + fp) if (tp + fp) > 0 else 1.0
    recall = tp / (tp + fn) if (tp + fn) > 0 else 1.0
    f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 1.0
    fpr = fp / (fp + tn) if (fp + tn) > 0 else 0.0
    fnr = fn / (fn + tp) if (fn + tp) > 0 else 0.0

    print("\n" + "=" * 60)
    print("PLAGUECHECK COMPREHENSIVE VALIDATION EVALUATION METRICS")
    print("=" * 60)
    print(f"Total Samples Evaluated : {total}")
    print(f"True Positives (TP)     : {tp}")
    print(f"True Negatives (TN)     : {tn}")
    print(f"False Positives (FP)    : {fp}")
    print(f"False Negatives (FN)    : {fn}")
    print("-" * 60)
    print(f"Accuracy                : {accuracy * 100:.2f}%")
    print(f"Precision               : {precision * 100:.2f}%")
    print(f"Recall                  : {recall * 100:.2f}%")
    print(f"F1-Score                : {f1 * 100:.2f}%")
    print(f"False Positive Rate     : {fpr * 100:.2f}%")
    print(f"False Negative Rate     : {fnr * 100:.2f}%")
    print("=" * 60)

    assert fp == 0, f"Validation passed {fp} invalid non-teeth images!"
    assert fn == 0, f"Validation rejected {fn} valid teeth images!"
    assert accuracy == 1.0
