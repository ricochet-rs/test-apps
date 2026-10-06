# Survey

A five-question survey that knows who is answering and saves every answer as it goes.

Run `ricochet deploy r/user-jwt-survey-htmxr` from the repository root to deploy it.

## How it works

- `survey.json` drives the whole UI. Edit a question there and the page follows.
- Each answer is saved in `persistent/survey.sqlite3`, so a respondent can leave and resume on any device.
- The signed-in user comes from the `X-Ricochet-User` token. With no token, the app shows a demo user, Ada Lovelace.
- The breadcrumb at the top shows progress. Select any answered step to change it.

## Question types

Each question has a `type` that picks its control:

| Type       | Control                     |
| ---------- | --------------------------- |
| `slider`   | A range from `min` to `max` |
| `select`   | A dropdown of `options`     |
| `combobox` | A searchable, grouped list  |
| `radio`    | One choice with a blurb     |
| `textarea` | Free text, optional         |

Never reuse a question `id` for a different question.
Bump `version` when you change one, since each answer records the version it was given against.
