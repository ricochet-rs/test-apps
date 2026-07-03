library(plumber)
library(jose)

# The proxy that launched this app serves its verification key as a JWKS.
ricochet_url <- Sys.getenv("RICOCHET_URL", "http://localhost:6188")
jwks <- yyjsonr::read_json_conn(
  file.path(ricochet_url, ".well-known", "jwks.json"),
  arr_of_objs_to_df = FALSE
)

# theres only one key in jwks at the moment
pubkey <- jose::read_jwk(jwks$keys[[1]])

# this app's own content id. the token's aud must match it
content_id <- Sys.getenv("RICOCHET_CONTENT_ID")

#* Echo the raw identity header, unverified
#* @get /headers
function(req) {
  list(
    x_ricochet_user = req$HTTP_X_RICOCHET_USER,
    user_agent = req$HTTP_USER_AGENT
  )
}

#* Verify the signed identity token and return the caller's claims
#* @get /whoami
function(req, res) {
  token <- req$HTTP_X_RICOCHET_USER
  if (is.null(token) || !nzchar(token)) {
    res$status <- 401
    return(list(error = "no X-Ricochet-User header"))
  }

  # verifies signature and expiry
  claims <- tryCatch(
    jose::jwt_decode_sig(token, pubkey),
    error = function(e) NULL
  )
  if (is.null(claims)) {
    res$status <- 401
    return(list(error = "invalid or expired token"))
  }

  # reject a token minted for different content
  if (!identical(claims$aud, content_id)) {
    res$status <- 403
    return(list(error = "token audience does not match this content"))
  }

  claims
}
