import os
import re
import sqlite3
import urllib.parse
from contextlib import contextmanager
from pathlib import Path

try:
    import psycopg2
    from psycopg2.extras import RealDictCursor
except ImportError:
    psycopg2 = None
    RealDictCursor = None
try:
    from dotenv import load_dotenv
    env_path = Path(__file__).resolve().parent.parent / ".env"
    load_dotenv(dotenv_path=env_path)
    load_dotenv()
except ImportError:
    pass

LOCAL_DB_DIR = Path(__file__).resolve().parents[1] / "database"


def _get_clean_database_url() -> str:
    use_supabase = os.getenv("USE_SUPABASE", "false").lower() in ("true", "1")
    if not use_supabase:
        return ""

    url = (
        os.getenv("SUPABASE_DATABASE_URL")
        or os.getenv("SUPABASE_DB_URL")
        or os.getenv("DATABASE_URL")
        or os.getenv("Database_URL")
        or os.getenv("database_url")
        or ""
    ).strip()
    if not url or "YOUR-PROJECT-REF" in url or "YOUR-PASSWORD" in url:
        return ""

    if url.startswith("postgres://"):
        url = url.replace("postgres://", "postgresql://", 1)

    # Remove literal brackets if password was entered as [your_password]
    url = re.sub(r":\[([^\]]+)\]@", r":\1@", url)

    # Parse scheme, user, password (which may contain '@' or '#'), and host
    pattern = r"^(postgresql://)([^:]+):(.*)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,}(?::\d+)?(?:/.*)?)$"
    match = re.match(pattern, url)
    if match:
        scheme, user, pwd, host_and_db = match.groups()
        if "@" in pwd or "#" in pwd:
            cleaned_pwd = urllib.parse.quote(pwd, safe="")
            url = f"{scheme}{user}:{cleaned_pwd}@{host_and_db}"

    return url



import logging
logger = logging.getLogger(__name__)


def get_db_type() -> str:
    url = _get_clean_database_url()
    return "postgres" if url else "sqlite"


@contextmanager
def get_db_connection(db_name: str = "plaquecheck.db"):
    url = _get_clean_database_url()
    conn = None
    if url:
        try:
            conn = psycopg2.connect(url, connect_timeout=10)
            conn.autocommit = False
            # Extract hostname for clean logging
            host_match = re.search(r"@([^:/]+)", url)
            host_str = host_match.group(1) if host_match else "Supabase PostgreSQL"
            logger.info("[SUPABASE CONNECT SUCCESS] Connected to PostgreSQL (%s)", host_str)
        except Exception as exc:
            logger.error("[SUPABASE CONNECT FAILURE] Failed to connect to PostgreSQL: %s", exc)
            raise RuntimeError(f"Database Connection Error: Unable to connect to Supabase PostgreSQL: {exc}") from exc

    if conn:
        try:
            yield ("postgres", conn)
            conn.commit()
        except Exception:
            try:
                conn.rollback()
            except Exception:
                pass
            raise
        finally:
            try:
                conn.close()
            except Exception:
                pass
        return

    LOCAL_DB_DIR.mkdir(parents=True, exist_ok=True)
    db_path = LOCAL_DB_DIR / db_name
    conn = sqlite3.connect(db_path)
    try:
        yield ("sqlite", conn)
        conn.commit()
    finally:
        conn.close()



