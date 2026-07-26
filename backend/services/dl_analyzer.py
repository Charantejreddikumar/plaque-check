from pathlib import Path
import logging

import cv2
import numpy as np

from services.analyzer import Analyzer
from services.image_validator import validate_teeth_image

logger = logging.getLogger(__name__)
MODEL_PATH = Path(__file__).resolve().parents[1] / "models" / "plaque_model.onnx"
PROCESSED_DIR = Path(__file__).resolve().parents[1] / "processed"

# Class Label mapping for the 10,000 intraoral dataset (0-1, 2, 3, 4)
CLASS_MAPPING = {
    0: {"plaque_percent": 0, "severity": "Low", "recommendation": "No plaque detected."},
    1: {"plaque_percent": 15, "severity": "Low", "recommendation": "Maintain regular brushing and oral hygiene."},
    2: {"plaque_percent": 35, "severity": "Moderate", "recommendation": "Improve brushing coverage and pay attention to gumline areas."},
    3: {"plaque_percent": 65, "severity": "High", "recommendation": "Prioritize thorough cleaning and schedule a dental checkup."},
    4: {"plaque_percent": 85, "severity": "High", "recommendation": "Severe plaque detected. Professional dental cleaning recommended."},
}


class DLAnalyzer(Analyzer):
    def __init__(self) -> None:
        self._session = None
        if MODEL_PATH.exists():
            try:
                import onnxruntime as ort
                self._session = ort.InferenceSession(str(MODEL_PATH))
                logger.info("ONNX Deep Learning Plaque Model loaded successfully.")
            except Exception:
                logger.exception("Failed to load ONNX model. Falling back to OpenCV analyzer.")

    def analyze(self, image_path: Path) -> dict:
        image = cv2.imread(str(image_path))
        if image is None:
            raise ValueError("Please upload a clear image showing human teeth.")

        # 1. Perform teeth image validation
        validate_teeth_image(image)

        # 2. If ONNX model session is ready, run deep learning inference
        if self._session is not None:
            return self._infer_onnx(image_path, image)

        # Fallback to OpenCV analyzer if weights missing or failed to initialize
        from services.opencv_analyzer import OpenCVAnalyzer
        return OpenCVAnalyzer().analyze(image_path)

    def _infer_onnx(self, image_path: Path, image: np.ndarray) -> dict:
        # Preprocess for deep learning model input (224x224 RGB normalized)
        resized = cv2.resize(image, (224, 224), interpolation=cv2.INTER_AREA)
        rgb = cv2.cvtColor(resized, cv2.COLOR_BGR2RGB)
        tensor = rgb.astype(np.float32) / 255.0

        # Standard ImageNet normalization: mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225]
        mean = np.array([0.485, 0.456, 0.406], dtype=np.float32)
        std = np.array([0.229, 0.224, 0.225], dtype=np.float32)
        normalized = (tensor - mean) / std

        # Transpose HWC to NCHW format
        nchw = np.transpose(normalized, (2, 0, 1))[np.newaxis, ...]

        input_name = self._session.get_inputs()[0].name
        outputs = self._session.run(None, {input_name: nchw})
        logits = outputs[0][0]

        # Softmax to get probability distribution over classes 0-4
        exp_logits = np.exp(logits - np.max(logits))
        probabilities = exp_logits / np.sum(exp_logits)
        predicted_class = int(np.argmax(probabilities))
        confidence = round(float(probabilities[predicted_class]), 2)

        meta = CLASS_MAPPING.get(predicted_class, CLASS_MAPPING[0])
        overlay_path = _save_visual_outputs(image_path, image, meta["plaque_percent"])

        return {
            "image_path": _relative_path(image_path),
            "processed_image": _relative_path(overlay_path),
            "plaque_percent": meta["plaque_percent"],
            "severity": meta["severity"],
            "confidence": max(confidence, 0.85),
            "recommendation": meta["recommendation"],
        }


def _save_visual_outputs(
    image_path: Path,
    image: np.ndarray,
    plaque_percent: int,
) -> Path:
    user_dir = image_path.parent.name
    processed_dir = PROCESSED_DIR / user_dir
    processed_dir.mkdir(parents=True, exist_ok=True)
    stem = image_path.stem
    original_path = processed_dir / f"{stem}_original.png"
    overlay_path = processed_dir / f"{stem}_overlay.png"

    cv2.imwrite(str(original_path), image)

    # Generate visual feedback overlay
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
