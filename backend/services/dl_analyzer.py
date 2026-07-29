from pathlib import Path
import logging

import cv2
import numpy as np

from services.analyzer import Analyzer
from services.image_validator import validate_teeth_image
from services.roi_cropper import extract_teeth_roi

logger = logging.getLogger(__name__)
MODELS_DIR = Path(__file__).resolve().parents[1] / "models"
ONNX_PATH = MODELS_DIR / "plaque_model.onnx"
PT_PATH = MODELS_DIR / "plaque_model.pt"
PROCESSED_DIR = Path(__file__).resolve().parents[1] / "processed"

CLASS_MAPPING = {
    0: {"plaque_percent": 0, "severity": "Low", "recommendation": "No plaque detected. Dental hygiene is excellent!"},
    1: {"plaque_percent": 0, "severity": "Low", "recommendation": "No plaque detected. Dental hygiene is excellent!"},
    2: {"plaque_percent": 15, "severity": "Low", "recommendation": "Maintain regular brushing twice daily and gentle flossing."},
    3: {"plaque_percent": 35, "severity": "Moderate", "recommendation": "Improve brushing coverage along the gumline areas."},
    4: {"plaque_percent": 65, "severity": "High", "recommendation": "Prioritize thorough cleaning and consider dental checkup."},
    5: {"plaque_percent": 85, "severity": "High", "recommendation": "Severe plaque detected. Professional dental cleaning recommended."},
}


class DLAnalyzer(Analyzer):
    def __init__(self) -> None:
        self._session = None
        self._pt_model = None
        self._device = None

        # 1. Try loading ONNX session if available
        if ONNX_PATH.exists():
            try:
                import onnxruntime as ort
                self._session = ort.InferenceSession(str(ONNX_PATH))
                logger.info("ONNX Deep Learning Plaque Model loaded successfully.")
                return
            except Exception:
                logger.warning("Failed to load ONNX session, attempting PyTorch fallback.")

        # 2. Try loading PyTorch .pt model directly
        if PT_PATH.exists():
            try:
                import torch
                from torchvision import models
                import torch.nn as nn

                self._device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
                state_dict = torch.load(str(PT_PATH), map_location=self._device)
                num_classes = 6
                if "classifier.3.weight" in state_dict:
                    num_classes = state_dict["classifier.3.weight"].shape[0]

                model = models.mobilenet_v3_large(weights=None)
                in_features = model.classifier[3].in_features
                model.classifier[3] = nn.Linear(in_features, num_classes)
                model.load_state_dict(state_dict)
                model.eval()
                self._pt_model = model
                logger.info("PyTorch .pt Deep Learning Model loaded successfully with %d classes.", num_classes)
            except Exception:
                logger.exception("Failed to load PyTorch model.")

    def analyze(self, image_path: Path) -> dict:
        image = cv2.imread(str(image_path))
        if image is None:
            raise ValueError("Please upload a clear image showing human teeth.")

        validate_teeth_image(image)
        teeth_roi, _ = extract_teeth_roi(image)

        if self._session is not None:
            return self._infer_onnx(image_path, teeth_roi)
        elif self._pt_model is not None:
            return self._infer_pytorch(image_path, teeth_roi)

        from services.opencv_analyzer import OpenCVAnalyzer
        return OpenCVAnalyzer().analyze(image_path)

    def _infer_onnx(self, image_path: Path, image: np.ndarray) -> dict:
        nchw = _preprocess_image(image)
        input_name = self._session.get_inputs()[0].name
        outputs = self._session.run(None, {input_name: nchw})
        logits = outputs[0][0]

        exp_logits = np.exp(logits - np.max(logits))
        probabilities = exp_logits / np.sum(exp_logits)
        predicted_class = int(np.argmax(probabilities))
        raw_confidence = float(probabilities[predicted_class])

        meta = CLASS_MAPPING.get(predicted_class, CLASS_MAPPING[1])
        overlay_path, seg_percent = _save_visual_outputs(image_path, image, meta["plaque_percent"])

        plaque_percent = seg_percent if seg_percent > 0 else meta["plaque_percent"]
        severity = _severity_for(plaque_percent)
        dynamic_confidence = round(float(np.clip(raw_confidence, 0.65, 0.97)), 2)

        return {
            "image_path": _relative_path(image_path),
            "processed_image": _relative_path(overlay_path),
            "plaque_percent": plaque_percent,
            "severity": severity,
            "confidence": dynamic_confidence,
            "recommendation": meta["recommendation"],
        }

    def _infer_pytorch(self, image_path: Path, image: np.ndarray) -> dict:
        import torch

        nchw = _preprocess_image(image)
        tensor_in = torch.from_numpy(nchw).to(self._device)

        with torch.no_grad():
            logits = self._pt_model(tensor_in)[0].cpu().numpy()

        exp_logits = np.exp(logits - np.max(logits))
        probabilities = exp_logits / np.sum(exp_logits)
        predicted_class = int(np.argmax(probabilities))
        raw_confidence = float(probabilities[predicted_class])

        meta = CLASS_MAPPING.get(predicted_class, CLASS_MAPPING[1])
        overlay_path, seg_percent = _save_visual_outputs(image_path, image, meta["plaque_percent"])

        plaque_percent = seg_percent if seg_percent > 0 else meta["plaque_percent"]
        severity = _severity_for(plaque_percent)
        dynamic_confidence = round(float(np.clip(raw_confidence, 0.65, 0.97)), 2)

        return {
            "image_path": _relative_path(image_path),
            "processed_image": _relative_path(overlay_path),
            "plaque_percent": plaque_percent,
            "severity": severity,
            "confidence": dynamic_confidence,
            "recommendation": meta["recommendation"],
        }


def _preprocess_image(image: np.ndarray) -> np.ndarray:
    resized = cv2.resize(image, (224, 224), interpolation=cv2.INTER_AREA)
    rgb = cv2.cvtColor(resized, cv2.COLOR_BGR2RGB)
    tensor = rgb.astype(np.float32) / 255.0

    mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
    std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
    normalized = (tensor - mean) / std

    return np.transpose(normalized, (2, 0, 1))[np.newaxis, ...]


def _save_visual_outputs(image_path: Path, image: np.ndarray, plaque_percent: int) -> tuple[Path, int]:
    user_dir = image_path.parent.name
    processed_dir = PROCESSED_DIR / user_dir
    processed_dir.mkdir(parents=True, exist_ok=True)
    stem = image_path.stem
    original_path = processed_dir / f"{stem}_original.png"
    overlay_path = processed_dir / f"{stem}_overlay.png"

    cv2.imwrite(str(original_path), image)

    lab = cv2.cvtColor(image, cv2.COLOR_BGR2LAB)
    clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
    lab[:, :, 0] = clahe.apply(lab[:, :, 0])
    enhanced_bgr = cv2.cvtColor(lab, cv2.COLOR_LAB2BGR)
    hsv = cv2.cvtColor(enhanced_bgr, cv2.COLOR_BGR2HSV)

    # 1. Tooth enamel region mask (bright, low-to-moderate saturation)
    tooth_lower = np.array([0, 0, 100], dtype=np.uint8)
    tooth_upper = np.array([179, 100, 255], dtype=np.uint8)
    tooth_mask = cv2.inRange(hsv, tooth_lower, tooth_upper)

    # 2. Oral mucosa / gum mask
    gum_1 = cv2.inRange(hsv, np.array([0, 40, 30]), np.array([25, 255, 255]))
    gum_2 = cv2.inRange(hsv, np.array([155, 40, 30]), np.array([180, 255, 255]))
    gum_mask = cv2.bitwise_or(gum_1, gum_2)

    # 3. Plaque biofilm detection (b* > 138 in LAB + yellow/orange hue 10-45 in HSV)
    b_channel = lab[:, :, 2]
    lab_yellow = cv2.inRange(b_channel, 138, 255)
    hsv_yellow = cv2.inRange(hsv, np.array([10, 30, 50]), np.array([45, 255, 255]))
    combined_color = cv2.bitwise_and(lab_yellow, hsv_yellow)

    dilated_gum = cv2.dilate(gum_mask, np.ones((25, 25), np.uint8))
    edges = cv2.Canny(hsv[:, :, 2], 50, 150)
    dilated_edges = cv2.dilate(edges, np.ones((7, 7), np.uint8))
    proximity_mask = cv2.bitwise_or(dilated_gum, dilated_edges)

    plaque_mask = cv2.bitwise_and(combined_color, tooth_mask)
    plaque_mask = cv2.bitwise_and(plaque_mask, proximity_mask)

    tooth_pixels = int(cv2.countNonZero(tooth_mask))
    plaque_pixels = int(cv2.countNonZero(plaque_mask))
    seg_percent = (
        0 if tooth_pixels == 0 else round((plaque_pixels / tooth_pixels) * 100)
    )
    seg_percent = int(np.clip(seg_percent, 0, 100))

    color_overlay = np.zeros_like(image)
    if cv2.countNonZero(plaque_mask) > 0:
        # Bright Yellow-Orange plaque bacteria overlay (B=0, G=180, R=255)
        color_overlay[plaque_mask > 0] = (0, 180, 255)
        contours, _ = cv2.findContours(plaque_mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        cv2.drawContours(color_overlay, contours, -1, (0, 240, 255), 2)
    elif plaque_percent > 0:
        # Fallback yellow/orange overlay if percentage > 0
        simple_yellow = cv2.inRange(hsv, np.array([10, 25, 50]), np.array([45, 255, 255]))
        color_overlay[simple_yellow > 0] = (0, 180, 255)

    blended = cv2.addWeighted(image, 0.65, color_overlay, 0.75, 0)
    cv2.imwrite(str(overlay_path), blended)
    return overlay_path, seg_percent


def _severity_for(plaque_percent: int) -> str:
    if plaque_percent < 20:
        return "Low"
    if plaque_percent < 45:
        return "Moderate"
    return "High"


def _relative_path(path: Path) -> str:
    resolved_path = path.resolve()
    base_path = Path(__file__).resolve().parents[1]
    try:
        return resolved_path.relative_to(base_path).as_posix()
    except ValueError:
        return resolved_path.as_posix()
