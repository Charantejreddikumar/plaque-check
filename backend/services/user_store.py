import sqlite3
from datetime import datetime, timezone
from pathlib import Path

DATABASE_DIR = Path(__file__).resolve().parents[1] / "database"
DATABASE_PATH = DATABASE_DIR / "users.db"


def init_user_database() -> None:
    DATABASE_DIR.mkdir(parents=True, exist_ok=True)
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT NOT NULL,
                email TEXT NOT NULL UNIQUE,
                password_hash TEXT NOT NULL,
                created_at TEXT NOT NULL
            )
            """
        )
        connection.commit()


def create_user(name: str, email: str, password_hash: str) -> dict:
    created_at = datetime.now(timezone.utc).isoformat()
    with sqlite3.connect(DATABASE_PATH) as connection:
        cursor = connection.execute(
            """
            INSERT INTO users (name, email, password_hash, created_at)
            VALUES (?, ?, ?, ?)
            """,
            (name, email, password_hash, created_at),
        )
        connection.commit()
        user_id = cursor.lastrowid

    return {
        "id": user_id,
        "name": name,
        "email": email,
        "created_at": created_at,
    }


def find_user_by_email(email: str) -> dict | None:
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.row_factory = sqlite3.Row
        row = connection.execute(
            """
            SELECT id, name, email, password_hash, created_at
            FROM users
            WHERE email = ?
            """,
            (email,),
        ).fetchone()

    return dict(row) if row else None
