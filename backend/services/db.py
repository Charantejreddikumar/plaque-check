import os
import re
import sqlite3
import urllib.parse
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


def _get_clean_database_url() -> str:
    url = (
        os.getenv("DATABASE_URL")
        or os.getenv("Database_URL")
        or os.getenv("database_url")
        or ""
    ).strip()
    if not url:
        return ""

    if url.startswith("postgres://"):
        url = url.replace("postgres://", "postgresql://", 1)

    # Remove literal brackets if password was entered as [your_password]
    url = re.sub(r":\[([^\]]+)\]@", r":\1@", url)

    # Encode special characters in password (like '#') if not already encoded
    match = re.match(r"^(postgresql://)([^:]+):([^@]+)@([^:/]+)(:\d+)?/(.+)$", url)
    if match:
        scheme, user, pwd, host, port, dbname = match.groups()
        port_str = port if port else ""
        if "#" in pwd and "%23" not in pwd:
            pwd = urllib.parse.quote(pwd, safe="")
        url = f"{scheme}{user}:{pwd}@{host}{port_str}/{dbname}"

    return url


def get_db_type() -> str:
    url = _get_clean_database_url()
    return "postgres" if url else "sqlite"


@contextmanager
def get_db_connection(db_name: str = "plaquecheck.db"):
    url = _get_clean_database_url()
    if url:
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


