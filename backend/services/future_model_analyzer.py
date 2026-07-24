from pathlib import Path

from services.analyzer import Analyzer


class FutureModelAnalyzer(Analyzer):
    def analyze(self, image_path: Path) -> dict:
        raise NotImplementedError(
            "Deep learning analyzers such as YOLO, CNN, or U-Net can be plugged in here."
        )
