# Notes Chat App

Run the [notes_chat_app](https://github.com/NikoriakViktor/notes_chat_app) Django project with SQLite on persistent storage.

Scope: Python app; Django ASGI; Django Channels WebSocket chat; Django login; SQLite in `persistent/`.

The code comes from the upstream repository under its MIT license.
Without `DATABASE_URL`, `notes_project/settings.py` stores the database at `persistent/db.sqlite3`, and `app.py` applies migrations at startup.
Chat messages pass between users in memory, so `_ricochet.toml` keeps the app to one instance.

See the [app catalog](../../README.md#app-catalog) for deployment instructions.
