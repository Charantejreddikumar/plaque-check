from abc import ABC, abstractmethod
from pathlib import Path


class Analyzer(ABC):
    @abstractmethod
    def analyze(self, image_path: Path) -> dict:
        raise NotImplementedError


def get_analyzer() -> Analyzer:
    from services.opencv_analyzer import OpenCVAnalyzer

    return OpenCVAnalyzer()
