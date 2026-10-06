set_db_pragmas <- function(con) {
  dbGetQuery(con, "PRAGMA journal_mode = WAL")
  dbGetQuery(con, "PRAGMA busy_timeout = 5000")
  invisible(con)
}

create_tables <- function(con) {
  dbExecute(
    con,
    "CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT,
      email TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      completed_at TIMESTAMP
    )"
  )
  dbExecute(
    con,
    "CREATE TABLE IF NOT EXISTS responses (
      user_id TEXT NOT NULL REFERENCES users(id),
      question_id TEXT NOT NULL,
      value TEXT NOT NULL,
      survey_version TEXT NOT NULL,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (user_id, question_id)
    )"
  )
  invisible(con)
}

upsert_user <- function(con, user) {
  dbExecute(
    con,
    "INSERT INTO users (id, name, email) VALUES (?, ?, ?)
     ON CONFLICT (id) DO UPDATE SET name = excluded.name, email = excluded.email",
    list(user$sub, user$name, user$email %||% NA_character_)
  )
}

upsert_user_response <- function(con, user_id, question_id, value, version) {
  dbExecute(
    con,
    "INSERT INTO responses (user_id, question_id, value, survey_version)
     VALUES (?, ?, ?, ?)
     ON CONFLICT (user_id, question_id) DO UPDATE SET
       value = excluded.value,
       survey_version = excluded.survey_version,
       updated_at = CURRENT_TIMESTAMP",
    list(user_id, question_id, value, version)
  )
}

mark_user_complete <- function(con, user_id) {
  dbExecute(
    con,
    "UPDATE users SET completed_at = CURRENT_TIMESTAMP
     WHERE id = ? AND completed_at IS NULL",
    list(user_id)
  )
}

clear_user_complete <- function(con, user_id) {
  dbExecute(
    con,
    "UPDATE users SET completed_at = NULL WHERE id = ?",
    list(user_id)
  )
}

get_user_answers <- function(con, user_id) {
  rows <- dbGetQuery(
    con,
    "SELECT question_id, value FROM responses WHERE user_id = ?",
    list(user_id)
  )
  rows$value |> as.list() |> rlang::set_names(rows$question_id)
}

delete_user_responses <- function(con, user_id) {
  dbExecute(con, "DELETE FROM responses WHERE user_id = ?", list(user_id))
}

get_all_responses <- function(con) {
  dbGetQuery(con, "SELECT user_id, question_id, value FROM responses")
}
