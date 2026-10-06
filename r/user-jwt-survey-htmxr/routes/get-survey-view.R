get_survey_view <- function(request, response, query) {
  response$set_header("Cache-Control", "no-store")
  user <- get_ricochet_user(request, pubkey, content_id)
  survey_view(user, query$q) |>
    render_or_alert() |>
    as.character()
}
