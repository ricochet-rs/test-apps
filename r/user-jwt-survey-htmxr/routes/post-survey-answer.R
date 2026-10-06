post_survey_answer <- function(request, response, body) {
  response$set_header("Cache-Control", "no-store")
  user <- get_ricochet_user(request, pubkey, content_id)

  view <- render_or_alert({
    question <- get_question(body$question)
    if (is.null(question)) {
      rlang::abort(paste("Unknown question", body$question %||% "(none)"))
    }

    value <- (body[[question$id]] %||% "") |>
      as.character() |>
      trimws() |>
      head(1)
    if (identical(question$type, "radio")) {
      value <- sub(paste0("^", question$id, "-"), "", value)
    }

    number <- value |>
      as.integer() |>
      suppressWarnings()
    option_values <- vapply(question$options, `[[`, character(1), "value")
    out_of_range <- question$type == "slider" &&
      (is.na(number) || number < question$min || number > question$max)

    error <- if (!nzchar(value) && !isFALSE(question$required)) {
      "Pick an answer to keep going."
    } else if (!nzchar(value)) {
      NULL
    } else if (out_of_range) {
      sprintf("Choose a number from %d to %d.", question$min, question$max)
    } else if (
      question$type == "textarea" && nchar(value) > question$max_length
    ) {
      sprintf("Keep it under %d characters.", question$max_length)
    } else if (!is.null(question$options) && !value %in% option_values) {
      "Pick one of the listed answers."
    }

    if (!is.null(error)) {
      question_view(
        question,
        get_user_answers(con, user$sub),
        value = value,
        error = error
      )
    } else {
      dbWithTransaction(con, {
        upsert_user(con, user)
        upsert_user_response(
          con,
          user$sub,
          question$id,
          value,
          survey$version
        )
      })

      upcoming <- get_next_question(get_user_answers(con, user$sub))

      if (is.null(upcoming)) {
        mark_user_complete(con, user$sub)
      }

      response$set_header("HX-Push-Url", paste0("./survey?q=", upcoming$id))
      survey_view(user)
    }
  })

  as.character(view)
}
