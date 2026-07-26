from abc import ABC, abstractmethod
from pathlib import Path

MODEL_PATH = Path(__file__).resolve().parents[1] / "models" / "plaque_model.onnx"


class Analyzer(ABC):
    @abstractmethod
    def analyze(self, image_path: Path) -> dict:
        raise NotImplementedError


def get_analyzer() -> Analyzer:
    if MODEL_PATH.exists():
        try:
            from services.dl_analyzer import DLAnalyzer
            return DLAnalyzer()
        except Exception:
            pass

    from services.opencv_analyzer import OpenCVAnalyzer
    return OpenCVAnalyzer()
