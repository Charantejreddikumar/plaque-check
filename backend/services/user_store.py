import sqlite3
import hashlib
import secrets
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
        connection.execute(
            """
            CREATE TABLE IF NOT EXISTS sessions (
                token_hash TEXT PRIMARY KEY,
                user_id INTEGER NOT NULL,
                created_at TEXT NOT NULL,
                FOREIGN KEY (user_id) REFERENCES users(id)
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


def create_session(user_id: int) -> str:
    init_user_database()
    token = secrets.token_urlsafe(32)
    token_hash = _hash_token(token)
    created_at = datetime.now(timezone.utc).isoformat()
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.execute(
            """
            INSERT INTO sessions (token_hash, user_id, created_at)
            VALUES (?, ?, ?)
            """,
            (token_hash, user_id, created_at),
        )
        connection.commit()
    return token


def find_user_by_token(token: str) -> dict | None:
    if not token:
        return None

    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.row_factory = sqlite3.Row
        row = connection.execute(
            """
            SELECT users.id, users.name, users.email, users.created_at
            FROM sessions
            JOIN users ON users.id = sessions.user_id
            WHERE sessions.token_hash = ?
            """,
            (_hash_token(token),),
        ).fetchone()

    return dict(row) if row else None


def delete_session(token: str) -> None:
    if not token:
        return
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.execute(
            "DELETE FROM sessions WHERE token_hash = ?",
            (_hash_token(token),),
        )
        connection.commit()


def _hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()
