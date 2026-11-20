import os
import sys
from pathlib import Path

if __name__ == "__main__":
    content_id = os.getenv("RICOCHET_CONTENT_ID")
    args = [
        sys.executable,
        "-m",
        "panel",
        "serve",
        str(Path(__file__).with_name("main.py")),
        "--index",
        "main",
        "--address",
        os.getenv("HOST", "127.0.0.1"),
        "--port",
        os.getenv("RICOCHET_PORT", os.getenv("PORT", "5006")),
        "--allow-websocket-origin",
        "*",
    ]
    if content_id:
        args += ["--root-path", f"/app/{content_id}"]
    os.execv(sys.executable, args)
