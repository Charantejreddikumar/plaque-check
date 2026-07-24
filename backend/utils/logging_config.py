import logging
from pathlib import Path

LOG_DIR = Path(__file__).resolve().parents[1] / "logs"
LOG_PATH = LOG_DIR / "app.log"


def configure_logging() -> None:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
        handlers=[
            logging.FileHandler(LOG_PATH),
            logging.StreamHandler(),
        ],
    )
