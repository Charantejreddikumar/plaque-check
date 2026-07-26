from datetime import datetime, timezone
import sqlite3
from psycopg2.extras import RealDictCursor

from services.db import get_db_connection


def init_database() -> None:
    with get_db_connection("reports.db") as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS reports (
                    id SERIAL PRIMARY KEY,
                    user_id INTEGER NOT NULL,
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
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_reports_user_id ON reports(user_id)")
        else:
            cursor.execute(
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
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_reports_user_id ON reports(user_id)")


def save_report(user_id: int, prediction: dict) -> dict:
    init_database()
    timestamp = datetime.now(timezone.utc).isoformat()
    with get_db_connection("reports.db") as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute(
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
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id
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
            report_id = cursor.fetchone()[0]
        else:
            cursor.execute(
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
            report_id = cursor.lastrowid

    return {
        **prediction,
        "report_id": report_id,
        "user_id": user_id,
        "timestamp": timestamp,
    }


def list_reports(user_id: int) -> list[dict]:
    init_database()
    with get_db_connection("reports.db") as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
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
                WHERE user_id = %s
                ORDER BY timestamp DESC, id DESC
                """,
                (user_id,),
            )
            rows = cursor.fetchall()
            return [
                {
                    "report_id": row["id"],
                    "user_id": row["user_id"],
                    "image_path": row["image_path"],
                    "processed_image": row["processed_image"],
                    "plaque_percent": row["plaque_percent"],
                    "severity": row["severity"],
                    "confidence": float(row["confidence"]),
                    "recommendation": row["recommendation"],
                    "timestamp": row["timestamp"],
                }
                for row in rows
            ]
        else:
            conn.row_factory = sqlite3.Row
            rows = conn.execute(
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
