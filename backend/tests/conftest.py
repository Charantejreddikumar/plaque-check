import os
import sys
from pathlib import Path
import pytest

backend_dir = Path(__file__).resolve().parents[1]
if str(backend_dir) not in sys.path:
    sys.path.insert(0, str(backend_dir))

@pytest.fixture(autouse=True, scope="session")
def setup_test_environment():
    os.environ["TEST_DB_NAME"] = "test_plaquecheck.db"
    db_dir = backend_dir / "database"
    if db_dir.exists():
        for test_db in db_dir.glob("test_*.db"):
            try:
                test_db.unlink()
            except Exception:
                pass
