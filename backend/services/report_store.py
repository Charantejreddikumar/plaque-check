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
                user_id INTEGER,
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
        columns = {
            row[1]
            for row in connection.execute("PRAGMA table_info(reports)").fetchall()
        }
        if "user_id" not in columns:
            connection.execute("ALTER TABLE reports ADD COLUMN user_id INTEGER")
        connection.execute(
            "CREATE INDEX IF NOT EXISTS idx_reports_user_id ON reports(user_id)"
        )
        connection.commit()


def save_report(user_id: int, prediction: dict) -> dict:
    init_database()
    timestamp = datetime.now(timezone.utc).isoformat()
    with sqlite3.connect(DATABASE_PATH) as connection:
        cursor = connection.execute(
            """
            INSERT INTO reports (
                user_id,
                image_path,
                processed_image,
                plaque_percent,
                severity,
                confidence,
                recommendation,
                timestamp
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                user_id,
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
        "user_id": user_id,
        "timestamp": timestamp,
    }


def list_reports(user_id: int) -> list[dict]:
    init_database()
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.row_factory = sqlite3.Row
        rows = connection.execute(
            """
            SELECT
                id,
                user_id,
                image_path,
                processed_image,
                plaque_percent,
                severity,
                confidence,
                recommendation,
                timestamp
            FROM reports
            WHERE user_id = ?
            ORDER BY datetime(timestamp) DESC, id DESC
            """,
            (user_id,),
        ).fetchall()

    return [
        {
            "report_id": row["id"],
            "user_id": row["user_id"],
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
