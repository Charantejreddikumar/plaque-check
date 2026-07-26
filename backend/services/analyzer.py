from abc import ABC, abstractmethod
from pathlib import Path

MODELS_DIR = Path(__file__).resolve().parents[1] / "models"
ONNX_PATH = MODELS_DIR / "plaque_model.onnx"
PT_PATH = MODELS_DIR / "plaque_model.pt"


class Analyzer(ABC):
    @abstractmethod
    def analyze(self, image_path: Path) -> dict:
        raise NotImplementedError


def get_analyzer() -> Analyzer:
    if ONNX_PATH.exists() or PT_PATH.exists():
        try:
            from services.dl_analyzer import DLAnalyzer
            return DLAnalyzer()
        except Exception:
            pass

    from services.opencv_analyzer import OpenCVAnalyzer
    return OpenCVAnalyzer()
