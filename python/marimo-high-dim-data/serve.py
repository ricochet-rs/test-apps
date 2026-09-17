import os
from pathlib import Path

import marimo
import uvicorn

app = (
    marimo.create_asgi_app()
    .with_app(path="/", root=str(Path(__file__).with_name("main.py")))
    .build()
)

if __name__ == "__main__":
    content_id = os.getenv("RICOCHET_CONTENT_ID")
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=int(os.getenv("RICOCHET_PORT", os.getenv("PORT", "8000"))),
        root_path=f"/app/{content_id}" if content_id else "",
    )
