import os
import sqlite3
from contextlib import contextmanager
from pathlib import Path

import psycopg2
from psycopg2.extras import RealDictCursor
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

LOCAL_DB_DIR = Path(__file__).resolve().parents[1] / "database"


def get_db_type() -> str:
    url = os.getenv("DATABASE_URL", "").strip()
    return "postgres" if url else "sqlite"


@contextmanager
def get_db_connection(db_name: str = "plaquecheck.db"):
    url = os.getenv("DATABASE_URL", "").strip()
    if url:
        # Fix Render/Supabase postgres:// schema if present -> postgresql://
        if url.startswith("postgres://"):
            url = url.replace("postgres://", "postgresql://", 1)

        conn = psycopg2.connect(url)
        try:
            yield ("postgres", conn)
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()
    else:
        LOCAL_DB_DIR.mkdir(parents=True, exist_ok=True)
        db_path = LOCAL_DB_DIR / db_name
        conn = sqlite3.connect(db_path)
        try:
            yield ("sqlite", conn)
            conn.commit()
        finally:
            conn.close()

