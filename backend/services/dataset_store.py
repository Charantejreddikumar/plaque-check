import os
import shutil
from datetime import datetime, timezone
from pathlib import Path

DATASET_DIR = Path(__file__).resolve().parents[1] / "dataset"


def dataset_mode_enabled() -> bool:
    return os.getenv("PLAQUECHECK_DATASET_MODE", "").lower() in {"1", "true", "yes"}


def store_dataset_sample(image_path: Path, processed_image: str) -> None:
    if not dataset_mode_enabled():
        return

    timestamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%S%fZ")
    raw_dir = DATASET_DIR / "raw"
    processed_dir = DATASET_DIR / "processed"
    raw_dir.mkdir(parents=True, exist_ok=True)
    processed_dir.mkdir(parents=True, exist_ok=True)

    raw_target = raw_dir / f"{timestamp}{image_path.suffix.lower()}"
    shutil.copy2(image_path, raw_target)

    backend_dir = Path(__file__).resolve().parents[1]
    processed_source = backend_dir / processed_image
    if processed_source.exists():
        shutil.copy2(processed_source, processed_dir / f"{timestamp}_overlay.png")
