demo_user <- list(
  sub = "01M49CBB8EEHWHJ5XGQ6B89D95",
  name = "Ada Lovelace",
  email = "ada@example.com"
)

read_ricochet_pubkey <- function(ricochet_url) {
  rlang::try_fetch(
    {
      jwks <- file.path(ricochet_url, ".well-known", "jwks.json") |>
        yyjsonr::read_json_conn(arr_of_objs_to_df = FALSE)
      jose::read_jwk(jwks$keys[[1]])
    },
    error = function(cnd) NULL
  )
}

get_ricochet_user <- function(request, pubkey, content_id) {
  token <- request$get_header("x-ricochet-user")

  if (is.null(pubkey) || is.null(token) || !nzchar(token)) {
    return(demo_user)
  }

  claims <- rlang::try_fetch(
    jose::jwt_decode_sig(token, pubkey),
    error = function(cnd) NULL
  )

  if (is.null(claims) || !identical(claims$aud, content_id)) {
    return(demo_user)
  }

  list(
    sub = claims$sub,
    name = claims$name %||% claims$email %||% claims$sub,
    email = claims$email
  )
}
