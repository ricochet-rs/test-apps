library(basecoat)
library(htmltools)
library(plumber2)

source("coffees.R")

for (route in list.files("routes", full.names = TRUE)) {
  source(route)
}

logo_lines <- readLines("public/logo.svg", warn = FALSE)
logo <- HTML(paste(
  grep("<title>", logo_lines, invert = TRUE, value = TRUE),
  collapse = "\n"
))

fonts <- tagList(
  tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
  tags$link(
    rel = "stylesheet",
    href = "https://fonts.googleapis.com/css2?family=Archivo:wdth,wght@62..125,400..900&family=Inter:wght@400;500;600;700&display=swap"
  ),
  tags$link(rel = "icon", type = "image/svg+xml", href = "/public/logo.svg"),
  tags$style(HTML(paste(readLines("site.css", warn = FALSE), collapse = "\n")))
)

layout <- function(..., title, current = NULL) {
  nav <- list(
    bc_nav_item(
      "Coffee",
      href = "/products",
      current = identical(current, "products")
    ),
    bc_nav_item("About", href = "/about", current = identical(current, "about"))
  )

  bc_page(
    title = paste(c(title, "Jackalope Coffee"), collapse = " · "),
    style = "lyra",
    theme = "theme.css",
    head = fonts,
    bc_page_navbar(
      title = tags$span(class = "brand", logo, "Jackalope"),
      href = "/",
      nav = nav,
      end = tagList(
        bc_theme_switcher(),
        link_button("Shop coffee", "/products")
      ),
      ...
    ),
    tags$footer(
      class = "site-footer",
      tags$div(
        class = "container",
        tags$span("Jackalope Coffee Roasters. Thumpin' good coffee."),
        tags$span(
          "A demo app built with R and deployed on",
          tags$a(href = "https://ricochet.rs", "ricochet.rs", .noWS = "after"),
          "."
        )
      )
    )
  )
}

link_button <- function(label, href, variant = NULL) {
  tags$a(class = "btn", `data-variant` = variant, href = href, label)
}

grass <- HTML(paste0(
  '<svg class="grass" viewBox="0 0 240 30" fill="currentColor" aria-hidden="true">',
  '<path d="M0 30L5 14L9 26L14 8L18 26L23 16L27 26L32 6L36 26L41 14L45 26L50 10',
  'L54 26L59 18L63 26L68 4L72 26L77 14L81 26L86 9L90 26L95 17L99 26L104 6L108 26',
  'L113 13L117 26L122 8L126 26L131 16L135 26L140 5L144 26L149 12L153 26L158 9',
  'L162 26L167 17L171 26L176 7L180 26L185 14L189 26L194 10L198 26L203 18L207 26',
  'L212 6L216 26L221 13L225 26L230 9L234 26L240 15L240 30Z"/></svg>'
))

label <- function(coffee) {
  tags$div(
    class = "label",
    style = paste0("background:", coffee$color),
    tags$span(class = "label-region", coffee$region),
    tags$span(
      class = "label-meta",
      paste(coffee$country, "·", coffee$roast, "roast")
    )
  )
}

farm_item <- function(coffee) {
  tags$div(
    class = "farm",
    tags$h3(coffee$region),
    tags$p(class = "text-sm text-muted-foreground", coffee$country),
    tags$p(class = "text-sm", paste(coffee$process, "·", coffee$elevation))
  )
}

product_card <- function(coffee) {
  tags$a(
    class = "product-card",
    href = paste0("/products/", coffee$slug),
    bc_card(
      label(coffee),
      bc_card_body(
        tags$p(class = "card-notes", coffee$notes_text),
        tags$p(class = "card-process", coffee$process)
      ),
      bc_card_footer(
        tags$p(
          tags$span(class = "card-price", paste0("$", coffee$price)),
          tags$span(class = "card-size", "/ 340 g")
        )
      )
    )
  )
}

html <- get_serializers("html")

api() |>
  api_statics("/public", "public") |>
  api_statics("/basecoat/", system.file("basecoat", package = "basecoat")) |>
  api_get("/", get_home, serializers = html) |>
  api_get("/products", get_products, serializers = html) |>
  api_get("/products/<slug>", get_product, serializers = html) |>
  api_get("/about", get_about, serializers = html) |>
  api_run(host = "0.0.0.0", port = as.integer(Sys.getenv("PORT", "8080")))
