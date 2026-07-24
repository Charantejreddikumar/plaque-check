from pathlib import Path

from services.analyzer import get_analyzer


def analyze_image(image_path: Path) -> dict:
    return get_analyzer().analyze(image_path)
