try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

from fastapi import FastAPI, HTTPException as FastAPIHTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse


from routes.debug import router as debug_router
from routes.auth import router as auth_router
from routes.media import router as media_router
from routes.predict import router as predict_router
from routes.reports import router as reports_router
from routes.doctor import router as doctor_router
from routes.admin import router as admin_router
from routes.notifications import router as notifications_router
from database import init_all_tables, migrate_legacy_databases
from services.report_store import init_database
from services.user_store import init_user_database
from utils.logging_config import configure_logging

import logging
import os
import time
from pathlib import Path

BACKEND_DIR = Path(__file__).resolve().parent
for runtime_dir in ("uploads", "processed", "logs"):
    (BACKEND_DIR / runtime_dir).mkdir(parents=True, exist_ok=True)

configure_logging()
logger = logging.getLogger(__name__)

app = FastAPI(title="PlaqueCheck Backend", version="0.3.0")

cors_env = os.getenv("CORS_ALLOW_ORIGINS", "*")
allowed_origins = [
    origin.strip()
    for origin in cors_env.split(",")
    if origin.strip()
]
if not allowed_origins:
    allowed_origins = ["*"]
allow_origin_regex = r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"


@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.perf_counter()
    logger.info("Incoming request: %s %s", request.method, request.url)

    try:
        response = await call_next(request)
    except Exception:
        elapsed_ms = (time.perf_counter() - start_time) * 1000
        logger.exception(
            "Request failed: %s %s after %.2fms",
            request.method,
            request.url,
            elapsed_ms,
        )
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal server error"},
        )

    elapsed_ms = (time.perf_counter() - start_time) * 1000
    logger.info(
        "Response: %s %s -> %s in %.2fms",
        request.method,
        request.url,
        response.status_code,
        elapsed_ms,
    )
    return response


@app.exception_handler(FastAPIHTTPException)
async def http_exception_handler(request: Request, exc: FastAPIHTTPException):
    logger.warning(
        "HTTP error: %s %s -> %s %s",
        request.method,
        request.url,
        exc.status_code,
        exc.detail,
    )
    return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    logger.warning(
        "Validation error: %s %s -> %s",
        request.method,
        request.url,
        exc.errors(),
    )
    return JSONResponse(status_code=422, content={"detail": exc.errors()})

app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_origin_regex=allow_origin_regex,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(predict_router)
app.include_router(reports_router)
app.include_router(debug_router)
app.include_router(auth_router)
app.include_router(media_router)
app.include_router(doctor_router)
app.include_router(admin_router)
app.include_router(notifications_router)


@app.on_event("startup")
def startup() -> None:
    init_all_tables()
    migrate_legacy_databases()
    init_user_database(force=True)
    db_engine = get_db_type().upper()
    logger.info("[STARTUP] PlaqueCheck backend started with database engine: %s", db_engine)


@app.get("/")
def health_check() -> str:
    return "PlaqueCheck backend running"
