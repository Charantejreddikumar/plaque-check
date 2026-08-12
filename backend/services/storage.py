import os
import logging
from pathlib import Path

logger = logging.getLogger(__name__)

SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SUPABASE_KEY = os.getenv("SUPABASE_KEY") or os.getenv("SUPABASE_SERVICE_ROLE_KEY") or ""
BUCKET_NAME = os.getenv("SUPABASE_STORAGE_BUCKET", "plaquecheck-images")


def upload_image_to_storage(file_bytes: bytes, filename: str, content_type: str = "image/jpeg") -> str:
    """
    Uploads an image to Supabase Storage if configured, or stores it locally as fallback.
    Returns the public image URL or relative local server path.
    """
    if SUPABASE_URL and SUPABASE_KEY:
        try:
            from supabase import create_client
            supabase = create_client(SUPABASE_URL, SUPABASE_KEY)
            
            # Ensure bucket exists or handle upload
            res = supabase.storage.from_(BUCKET_NAME).upload(
                path=filename,
                file=file_bytes,
                file_options={"content-type": content_type, "upsert": "true"}
            )
            public_url = supabase.storage.from_(BUCKET_NAME).get_public_url(filename)
            logger.info("[SUPABASE STORAGE SUCCESS] Uploaded %s -> %s", filename, public_url)
            return public_url
        except Exception as exc:
            logger.warning("[SUPABASE STORAGE WARNING] Failed uploading to Supabase Storage (%s). Falling back to local storage.", exc)

    # Local storage fallback
    uploads_dir = Path(__file__).resolve().parent.parent / "uploads"
    uploads_dir.mkdir(parents=True, exist_ok=True)
    file_path = uploads_dir / filename
    with open(file_path, "wb") as f:
        f.write(file_bytes)
    
    logger.info("[LOCAL STORAGE] Saved image locally: %s", filename)
    return f"/uploads/{filename}"
