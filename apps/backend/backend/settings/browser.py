"""Disposable local demo/browser settings. Start through scripts/browser-backend.py."""

import os
from pathlib import Path

from .test import *

# The launcher owns this temporary directory; missing configuration fails closed.
BROWSER_DATA_DIR = Path(os.environ["ALIENCOMMONS_BROWSER_DATA_DIR"])
DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BROWSER_DATA_DIR / "db.sqlite3",
    }
}
MEDIA_ROOT = BROWSER_DATA_DIR / "media"
ALLOWED_HOSTS = ["127.0.0.1", "localhost", "testserver"]
CSRF_TRUSTED_ORIGINS = ["http://127.0.0.1:43100"]
SITE_URL = "http://127.0.0.1:43100"
ALLOW_DEMO_DATA = True
ASGI_APPLICATION = "backend.asgi.application"
