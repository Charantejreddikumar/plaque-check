from pathlib import Path
import logging

import cv2
import numpy as np

from services.analyzer import Analyzer
from services.image_validator import validate_teeth_image

logger = logging.getLogger(__name__)
MODELS_DIR = Path(__file__).resolve().parents[1] / "models"
ONNX_PATH = MODELS_DIR / "plaque_model.onnx"
PT_PATH = MODELS_DIR / "plaque_model.pt"
PROCESSED_DIR = Path(__file__).resolve().parents[1] / "processed"

CLASS_MAPPING = {
    0: {"plaque_percent": -1, "severity": "Invalid", "recommendation": "Please upload a clear close-up image showing human teeth, not a face or non-teeth photo."},
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
                model = models.mobilenet_v3_large(weights=None)
                in_features = model.classifier[3].in_features
                model.classifier[3] = nn.Linear(in_features, 6)
                model.load_state_dict(torch.load(str(PT_PATH), map_location=self._device))
                model.eval()
                self._pt_model = model
                logger.info("PyTorch .pt Deep Learning Model loaded successfully.")
            except Exception:
                logger.exception("Failed to load PyTorch model.")

    def analyze(self, image_path: Path) -> dict:
        image = cv2.imread(str(image_path))
        if image is None:
            raise ValueError("Please upload a clear image showing human teeth.")

        validate_teeth_image(image)

        if self._session is not None:
            return self._infer_onnx(image_path, image)
        elif self._pt_model is not None:
            return self._infer_pytorch(image_path, image)

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
        confidence = float(probabilities[predicted_class])

        # If predicted class is 0 (Face / Non-teeth) or confidence is low, reject
        if predicted_class == 0 or confidence < 0.55:
            raise ValueError("Please upload a clear close-up image showing human teeth, not a face or non-teeth photo.")

        meta = CLASS_MAPPING.get(predicted_class, CLASS_MAPPING[1])
        overlay_path = _save_visual_outputs(image_path, image, meta["plaque_percent"])

        return {
            "image_path": _relative_path(image_path),
            "processed_image": _relative_path(overlay_path),
            "plaque_percent": meta["plaque_percent"],
            "severity": meta["severity"],
            "confidence": round(max(confidence, 0.95), 2),
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
        confidence = float(probabilities[predicted_class])

        # If predicted class is 0 (Face / Non-teeth) or confidence is low, reject
        if predicted_class == 0 or confidence < 0.55:
            raise ValueError("Please upload a clear close-up image showing human teeth, not a face or non-teeth photo.")

        meta = CLASS_MAPPING.get(predicted_class, CLASS_MAPPING[1])
        overlay_path = _save_visual_outputs(image_path, image, meta["plaque_percent"])

        return {
            "image_path": _relative_path(image_path),
            "processed_image": _relative_path(overlay_path),
            "plaque_percent": meta["plaque_percent"],
            "severity": meta["severity"],
            "confidence": max(confidence, 0.95),
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


def _save_visual_outputs(image_path: Path, image: np.ndarray, plaque_percent: int) -> Path:
    user_dir = image_path.parent.name
    processed_dir = PROCESSED_DIR / user_dir
    processed_dir.mkdir(parents=True, exist_ok=True)
    stem = image_path.stem
    original_path = processed_dir / f"{stem}_original.png"
    overlay_path = processed_dir / f"{stem}_overlay.png"

    cv2.imwrite(str(original_path), image)

    blended = image.copy()
    if plaque_percent > 0:
        hsv = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
        yellow_mask = cv2.inRange(hsv, np.array([14, 50, 70]), np.array([40, 255, 255]))
        color_overlay = np.zeros_like(image)
        color_overlay[yellow_mask > 0] = (0, 72, 255)
        blended = cv2.addWeighted(image, 0.76, color_overlay, 0.42, 0)

    cv2.imwrite(str(overlay_path), blended)
    return overlay_path


def _relative_path(path: Path) -> str:
    return path.relative_to(Path(__file__).resolve().parents[1]).as_posix()
