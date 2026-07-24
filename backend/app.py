from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from routes.debug import router as debug_router
from routes.auth import router as auth_router
from routes.predict import router as predict_router
from routes.reports import router as reports_router
from services.report_store import init_database
from services.user_store import init_user_database
from utils.logging_config import configure_logging

import logging
import os
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent
for runtime_dir in ("uploads", "processed", "logs"):
    (BACKEND_DIR / runtime_dir).mkdir(parents=True, exist_ok=True)

configure_logging()
logger = logging.getLogger(__name__)

app = FastAPI(title="PlaqueCheck Backend", version="0.2.0")

allowed_origins = [
    origin.strip()
    for origin in os.getenv("CORS_ALLOW_ORIGINS", "*").split(",")
    if origin.strip()
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials="*" not in allowed_origins,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(predict_router)
app.include_router(reports_router)
app.include_router(debug_router)
app.include_router(auth_router)

for static_dir in ("processed", "uploads"):
    app.mount(f"/{static_dir}", StaticFiles(directory=BACKEND_DIR / static_dir), name=static_dir)


@app.on_event("startup")
def startup() -> None:
    init_database()
    init_user_database()
    logger.info("PlaqueCheck backend started.")


@app.get("/")
def health_check() -> str:
    return "PlaqueCheck backend running"
