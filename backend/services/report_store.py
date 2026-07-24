import sqlite3
from datetime import datetime, timezone
from pathlib import Path

DATABASE_DIR = Path(__file__).resolve().parents[1] / "database"
DATABASE_PATH = DATABASE_DIR / "reports.db"


def init_database() -> None:
    DATABASE_DIR.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS reports (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                image_path TEXT NOT NULL,
                processed_image TEXT NOT NULL,
                plaque_percent INTEGER NOT NULL,
                severity TEXT NOT NULL,
                confidence REAL NOT NULL,
                recommendation TEXT NOT NULL,
                timestamp TEXT NOT NULL
            )
            """
        )


def save_report(prediction: dict) -> dict:
    init_database()
    timestamp = datetime.now(timezone.utc).isoformat()
    with sqlite3.connect(DATABASE_PATH) as connection:
        cursor = connection.execute(
            """
            INSERT INTO reports (
                image_path,
                processed_image,
                plaque_percent,
                severity,
                confidence,
                recommendation,
                timestamp
            )
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                prediction["image_path"],
                prediction["processed_image"],
                prediction["plaque_percent"],
                prediction["severity"],
                prediction["confidence"],
                prediction["recommendation"],
                timestamp,
            ),
        )

    return {
        **prediction,
        "report_id": cursor.lastrowid,
        "timestamp": timestamp,
    }


def list_reports() -> list[dict]:
    init_database()
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.row_factory = sqlite3.Row
        rows = connection.execute(
            """
            SELECT
                id,
                image_path,
                processed_image,
                plaque_percent,
                severity,
                confidence,
                recommendation,
                timestamp
            FROM reports
            ORDER BY datetime(timestamp) DESC, id DESC
            """
        ).fetchall()

    return [
        {
            "report_id": row["id"],
            "image_path": row["image_path"],
            "processed_image": row["processed_image"],
            "plaque_percent": row["plaque_percent"],
            "severity": row["severity"],
            "confidence": row["confidence"],
            "recommendation": row["recommendation"],
            "timestamp": row["timestamp"],
        }
        for row in rows
    ]
