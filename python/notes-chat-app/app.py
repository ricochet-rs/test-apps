import os

import django
import uvicorn
from django.conf import settings
from django.core.management import call_command

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "notes_project.settings")

if __name__ == "__main__":
    django.setup()
    call_command("migrate", interactive=False)
    uvicorn.run(
        "notes_project.asgi:application",
        host="0.0.0.0",
        port=int(os.environ.get("PORT", "8001")),
        # Ricochet strips /app/<content-id>, so uvicorn adds it back to each request path.
        root_path=settings.FORCE_SCRIPT_NAME or "",
        proxy_headers=True,
        forwarded_allow_ips="*",
        lifespan="off",
    )
