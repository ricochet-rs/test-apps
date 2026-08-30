import os

from fastapi import FastAPI
from fastapi.responses import RedirectResponse

content_id = os.getenv("RICOCHET_CONTENT_ID")
root_path = f"/app/{content_id}" if content_id else ""
app = FastAPI(root_path=root_path)


@app.get("/")
def root() -> RedirectResponse:
    return RedirectResponse(url="docs")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
