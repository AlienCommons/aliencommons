"""Run a real Django API with disposable demo data and no external services."""

import os
import signal
import sys
from pathlib import Path
from tempfile import TemporaryDirectory


def main():
    sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "apps/backend"))
    # Override inherited deployment configuration rather than accepting a database URL.
    os.environ["DJANGO_SETTINGS_MODULE"] = "backend.settings.browser"
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    with TemporaryDirectory(prefix="aliencommons-browser-") as directory:
        os.environ["ALIENCOMMONS_BROWSER_DATA_DIR"] = directory
        import django
        from django.core.management import call_command
        from django.db import connections

        django.setup()
        try:
            call_command("migrate", interactive=False, verbosity=0)
            call_command("seed_demo")
            call_command("runserver", "127.0.0.1:43101", use_reloader=False)
        finally:
            connections.close_all()


if __name__ == "__main__":
    main()
