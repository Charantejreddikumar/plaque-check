from datetime import datetime, timezone
import sqlite3
try:
    from psycopg2.extras import RealDictCursor
except ImportError:
    RealDictCursor = None

from services.db import get_db_connection


def init_database() -> None:
    from database import init_all_tables
    init_all_tables()


def save_report(user_id: int, prediction: dict) -> dict:
    init_database()
    timestamp = datetime.now(timezone.utc).isoformat()
    with get_db_connection() as (db_type, conn):
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
                    timestamp,
                    review_status
                )
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, 'pending_review')
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
                    timestamp,
                    review_status
                )
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending_review')
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
        "review_status": "pending_review",
    }


def list_reports(user_id: int) -> list[dict]:
    init_database()
    with get_db_connection() as (db_type, conn):
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
                    timestamp,
                    doctor_id,
                    review_status,
                    doctor_notes,
                    treatment_recommendations,
                    follow_up_date,
                    reviewed_at
                FROM reports
                WHERE user_id = %s
                ORDER BY timestamp DESC, id DESC
                """,
                (user_id,),
            )
            rows = cursor.fetchall()
            return [_row_to_dict(row) for row in rows]
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
                    timestamp,
                    doctor_id,
                    review_status,
                    doctor_notes,
                    treatment_recommendations,
                    follow_up_date,
                    reviewed_at
                FROM reports
                WHERE user_id = ?
                ORDER BY datetime(timestamp) DESC, id DESC
                """,
                (user_id,),
            ).fetchall()
            return [_row_to_dict(row) for row in rows]


def get_report_by_id(report_id: int) -> dict | None:
    init_database()
    with get_db_connection() as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute("SELECT * FROM reports WHERE id = %s", (report_id,))
            row = cursor.fetchone()
            return _row_to_dict(row) if row else None
        else:
            conn.row_factory = sqlite3.Row
            row = conn.execute("SELECT * FROM reports WHERE id = ?", (report_id,)).fetchone()
            return _row_to_dict(row) if row else None


def list_pending_reports() -> list[dict]:
    init_database()
    with get_db_connection() as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
                "SELECT * FROM reports WHERE review_status = 'pending_review' ORDER BY timestamp DESC"
            )
            rows = cursor.fetchall()
            return [_row_to_dict(row) for row in rows]
        else:
            conn.row_factory = sqlite3.Row
            rows = conn.execute(
                "SELECT * FROM reports WHERE review_status = 'pending_review' ORDER BY datetime(timestamp) DESC"
            ).fetchall()
            return [_row_to_dict(row) for row in rows]


def list_all_reports() -> list[dict]:
    init_database()
    with get_db_connection() as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute("SELECT * FROM reports ORDER BY timestamp DESC")
            rows = cursor.fetchall()
            return [_row_to_dict(row) for row in rows]
        else:
            conn.row_factory = sqlite3.Row
            rows = conn.execute("SELECT * FROM reports ORDER BY datetime(timestamp) DESC").fetchall()
            return [_row_to_dict(row) for row in rows]


def review_report(
    report_id: int,
    doctor_id: int,
    status: str,
    modified_plaque: int | None = None,
    notes: str = "",
    treatment: str = "",
    follow_up: str = "",
) -> dict | None:
    init_database()
    reviewed_at = datetime.now(timezone.utc).isoformat()
    with get_db_connection() as (db_type, conn):
        cursor = conn.cursor()
        report = get_report_by_id(report_id)
        if not report:
            return None

        plaque = modified_plaque if modified_plaque is not None else report["plaque_percent"]
        if plaque < 3:
            severity = "Low"
        elif plaque < 25:
            severity = "Low"
        elif plaque < 50:
            severity = "Moderate"
        elif plaque < 75:
            severity = "High"
        else:
            severity = "Severe"

        if db_type == "postgres":
            cursor.execute(
                """
                UPDATE reports
                SET doctor_id = %s,
                    review_status = %s,
                    plaque_percent = %s,
                    severity = %s,
                    doctor_notes = %s,
                    treatment_recommendations = %s,
                    follow_up_date = %s,
                    reviewed_at = %s
                WHERE id = %s
                """,
                (doctor_id, status, plaque, severity, notes, treatment, follow_up, reviewed_at, report_id),
            )
        else:
            cursor.execute(
                """
                UPDATE reports
                SET doctor_id = ?,
                    review_status = ?,
                    plaque_percent = ?,
                    severity = ?,
                    doctor_notes = ?,
                    treatment_recommendations = ?,
                    follow_up_date = ?,
                    reviewed_at = ?
                WHERE id = ?
                """,
                (doctor_id, status, plaque, severity, notes, treatment, follow_up, reviewed_at, report_id),
            )
    return get_report_by_id(report_id)


def _row_to_dict(row) -> dict:
    d = dict(row)
    return {
        "report_id": d["id"],
        "user_id": d["user_id"],
        "image_path": d["image_path"],
        "processed_image": d["processed_image"],
        "plaque_percent": d["plaque_percent"],
        "severity": d["severity"],
        "confidence": float(d["confidence"]) if d.get("confidence") is not None else 0.85,
        "recommendation": d.get("recommendation", ""),
        "timestamp": d["timestamp"],
        "doctor_id": d.get("doctor_id"),
        "review_status": d.get("review_status") or "pending_review",
        "doctor_notes": d.get("doctor_notes") or "",
        "treatment_recommendations": d.get("treatment_recommendations") or "",
        "follow_up_date": d.get("follow_up_date") or "",
        "reviewed_at": d.get("reviewed_at") or "",
    }
