library(shiny)
library(jose)

# this app is deployed on localhost
# you may set the RICCOHET_URL as well
ricochet_url <- Sys.getenv("RICOCHET_URL", "http://localhost:6188")
jwks <- yyjsonr::read_json_conn(
  file.path(ricochet_url, ".well-known", "jwks.json"),
  arr_of_objs_to_df = FALSE
)

# theres only one key in jwks at the moment
pubkey <- jose::read_jwk(jwks$keys[[1]])

# this app's own content id. the token's aud must match it
content_id <- Sys.getenv("RICOCHET_CONTENT_ID")

ui <- fluidPage(
  titlePanel("Ricochet identity w/ Shiny"),
  h4("Raw X-Ricochet-User header"),
  verbatimTextOutput("raw_header"),
  h4("Verified claims"),
  verbatimTextOutput("claims")
)

server <- function(input, output, session) {
  # ricochet adds the X-Ricochet-User header
  token <- session$request$HTTP_X_RICOCHET_USER

  # capture the raw header if found
  output$raw_header <- renderText(token %||% "(no header present)")

  output$claims <- renderPrint({
    if (is.null(token)) {
      return("no X-Ricochet-User header")
    }

    # verifies signature and expiry
    claims <- jose::jwt_decode_sig(token, pubkey)

    # reject a token if the audience claim doesn't match the content ID
    if (!identical(claims$aud, content_id)) {
      return("token audience does not match this content")
    }
    claims
  })
}

shinyApp(ui, server)
