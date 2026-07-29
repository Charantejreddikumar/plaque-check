from abc import ABC, abstractmethod
from pathlib import Path
import logging

logger = logging.getLogger(__name__)
MODELS_DIR = Path(__file__).resolve().parents[1] / "models"
ONNX_PATH = MODELS_DIR / "plaque_model.onnx"
PT_PATH = MODELS_DIR / "plaque_model.pt"


class Analyzer(ABC):
    """
    Abstract base strategy interface for PlaqueCheck analysis engines.
    Enables seamless drop-in of future U-Net / DeepLabV3+ segmentation models
    without breaking FastAPI routes or Flutter application UI.
    """
    @abstractmethod
    def analyze(self, image_path: Path) -> dict:
        raise NotImplementedError


def get_analyzer() -> Analyzer:
    """
    Factory function returning the active plaque analysis engine strategy.
    """
    if ONNX_PATH.exists() or PT_PATH.exists():
        try:
            from services.dl_analyzer import DLAnalyzer
            logger.info("Initializing DLAnalyzer strategy.")
            return DLAnalyzer()
        except Exception:
            logger.exception("Failed to initialize DLAnalyzer strategy, falling back to OpenCVAnalyzer.")

    from services.opencv_analyzer import OpenCVAnalyzer
    logger.info("Initializing OpenCVAnalyzer strategy.")
    return OpenCVAnalyzer()
