post_survey_reset <- function(request, response) {
  response$set_header("Cache-Control", "no-store")
  user <- get_ricochet_user(request, pubkey, content_id)

  as.character(render_or_alert({
    dbWithTransaction(con, {
      delete_user_responses(con, user$sub)
      clear_user_complete(con, user$sub)
    })
    survey_view(user)
  }))
}
