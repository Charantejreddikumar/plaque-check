import hashlib
import secrets
from datetime import datetime, timezone
import sqlite3
from psycopg2.extras import RealDictCursor

from services.db import get_db_connection


def init_user_database() -> None:
    with get_db_connection("users.db") as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS users (
                    id SERIAL PRIMARY KEY,
                    name TEXT NOT NULL,
                    email TEXT NOT NULL UNIQUE,
                    password_hash TEXT NOT NULL,
                    created_at TEXT NOT NULL
                )
                """
            )
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS sessions (
                    token_hash TEXT PRIMARY KEY,
                    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                    created_at TEXT NOT NULL
                )
                """
            )
        else:
            cursor.execute(
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
            cursor.execute(
                """
                CREATE TABLE IF NOT EXISTS sessions (
                    token_hash TEXT PRIMARY KEY,
                    user_id INTEGER NOT NULL,
                    created_at TEXT NOT NULL,
                    FOREIGN KEY (user_id) REFERENCES users(id)
                )
                """
            )


def create_user(name: str, email: str, password_hash: str) -> dict:
    init_user_database()
    created_at = datetime.now(timezone.utc).isoformat()
    with get_db_connection("users.db") as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute(
                """
                INSERT INTO users (name, email, password_hash, created_at)
                VALUES (%s, %s, %s, %s)
                RETURNING id
                """,
                (name, email, password_hash, created_at),
            )
            user_id = cursor.fetchone()[0]
        else:
            cursor.execute(
                """
                INSERT INTO users (name, email, password_hash, created_at)
                VALUES (?, ?, ?, ?)
                """,
                (name, email, password_hash, created_at),
            )
            user_id = cursor.lastrowid

    return {
        "id": user_id,
        "name": name,
        "email": email,
        "created_at": created_at,
    }


def find_user_by_email(email: str) -> dict | None:
    init_user_database()
    with get_db_connection("users.db") as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
                """
                SELECT id, name, email, password_hash, created_at
                FROM users
                WHERE email = %s
                """,
                (email,),
            )
            row = cursor.fetchone()
            return dict(row) if row else None
        else:
            conn.row_factory = sqlite3.Row
            row = conn.execute(
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
    with get_db_connection("users.db") as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute(
                """
                INSERT INTO sessions (token_hash, user_id, created_at)
                VALUES (%s, %s, %s)
                ON CONFLICT (token_hash) DO NOTHING
                """,
                (token_hash, user_id, created_at),
            )
        else:
            cursor.execute(
                """
                INSERT INTO sessions (token_hash, user_id, created_at)
                VALUES (?, ?, ?)
                """,
                (token_hash, user_id, created_at),
            )
    return token


def find_user_by_token(token: str) -> dict | None:
    if not token:
        return None

    init_user_database()
    token_hash = _hash_token(token)
    with get_db_connection("users.db") as (db_type, conn):
        if db_type == "postgres":
            cursor = conn.cursor(cursor_factory=RealDictCursor)
            cursor.execute(
                """
                SELECT users.id, users.name, users.email, users.created_at
                FROM sessions
                JOIN users ON users.id = sessions.user_id
                WHERE sessions.token_hash = %s
                """,
                (token_hash,),
            )
            row = cursor.fetchone()
            return dict(row) if row else None
        else:
            conn.row_factory = sqlite3.Row
            row = conn.execute(
                """
                SELECT users.id, users.name, users.email, users.created_at
                FROM sessions
                JOIN users ON users.id = sessions.user_id
                WHERE sessions.token_hash = ?
                """,
                (token_hash,),
            ).fetchone()
            return dict(row) if row else None


def delete_session(token: str) -> None:
    if not token:
        return
    token_hash = _hash_token(token)
    with get_db_connection("users.db") as (db_type, conn):
        cursor = conn.cursor()
        if db_type == "postgres":
            cursor.execute("DELETE FROM sessions WHERE token_hash = %s", (token_hash,))
        else:
            cursor.execute("DELETE FROM sessions WHERE token_hash = ?", (token_hash,))


def _hash_token(token: str) -> str:
    return hashlib.sha256(token.encode("utf-8")).hexdigest()
