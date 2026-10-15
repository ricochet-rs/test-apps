library(shiny)
library(basecoat)
library(htmltools)

source("coffees.R")

logo_lines <- readLines("www/logo.svg", warn = FALSE)
logo <- HTML(paste(
  grep("<title>", logo_lines, invert = TRUE, value = TRUE),
  collapse = "\n"
))

grass <- HTML(paste0(
  '<svg class="grass" viewBox="0 0 240 30" fill="currentColor" aria-hidden="true">',
  '<path d="M0 30L5 14L9 26L14 8L18 26L23 16L27 26L32 6L36 26L41 14L45 26L50 10',
  'L54 26L59 18L63 26L68 4L72 26L77 14L81 26L86 9L90 26L95 17L99 26L104 6L108 26',
  'L113 13L117 26L122 8L126 26L131 16L135 26L140 5L144 26L149 12L153 26L158 9',
  'L162 26L167 17L171 26L176 7L180 26L185 14L189 26L194 10L198 26L203 18L207 26',
  'L212 6L216 26L221 13L225 26L230 9L234 26L240 15L240 30Z"/></svg>'
))

# Every link sends the page it wants to the server as input$nav. The URL never
# changes, so a page cannot be bookmarked or shared.
go <- function(page) {
  sprintf(
    "Shiny.setInputValue('nav', '%s', {priority: 'event'}); window.scrollTo(0, 0); return false;",
    page
  )
}

nav_button <- function(label, page, variant = NULL) {
  tags$a(
    class = "btn",
    `data-variant` = variant,
    href = "#",
    onclick = go(page),
    label
  )
}

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
    href = "#",
    onclick = go(paste0("product:", coffee$slug)),
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

layout <- function(..., current = NULL) {
  tagList(
    bc_page_navbar(
      title = tags$a(
        class = "brand",
        href = "#",
        onclick = go("home"),
        logo,
        "Jackalope"
      ),
      nav = list(
        bc_nav_item(
          "Coffee",
          href = "#",
          onclick = go("products"),
          current = identical(current, "products")
        ),
        bc_nav_item(
          "About",
          href = "#",
          onclick = go("about"),
          current = identical(current, "about")
        )
      ),
      end = tagList(
        bc_theme_switcher(),
        nav_button("Shop coffee", "products")
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

home_page <- function() {
  layout(
    tags$section(
      class = "hero",
      tags$div(
        class = "container",
        tags$div(
          class = "space-y-6",
          tags$h1("Thumpin' good coffee."),
          tags$p(
            "Single-origin coffees for espresso and filter, from six farms",
            "we buy from every harvest."
          ),
          tags$p(class = "promise", "Roasted to order. Shipped within a day."),
          tags$div(
            class = "flex flex-wrap gap-3",
            nav_button("Shop the coffee", "products"),
            tags$a(
              class = "btn",
              `data-variant` = "outline",
              href = "#farms",
              "Meet the farms"
            )
          )
        ),
        tags$div(class = "hero-mark", logo, grass)
      )
    ),
    tags$section(
      class = "section container",
      tags$h2(class = "title mb-4", "This week's coffees"),
      tags$div(class = "product-grid", lapply(coffees[1:3], product_card)),
      tags$div(
        style = "margin-top: 2rem",
        nav_button("See all coffees", "products", "outline")
      )
    ),
    tags$section(
      id = "farms",
      class = "section farms",
      tags$div(
        class = "container",
        tags$h2(class = "title", "Six farms, every harvest"),
        tags$p(
          class = "text-muted-foreground mb-4",
          "We buy from the same six producers each year, so every coffee on",
          "the menu comes from a farm we know."
        ),
        tags$div(class = "farm-grid", lapply(coffees, farm_item))
      )
    )
  )
}

products_page <- function() {
  layout(
    current = "products",
    tags$section(
      class = "section container",
      tags$h1(class = "title", "Our coffees"),
      tags$p(
        class = "text-muted-foreground mb-4",
        "Every bag is roasted to order and shipped within a day."
      ),
      tags$div(class = "product-grid", lapply(coffees, product_card))
    )
  )
}

product_page <- function(coffee) {
  layout(
    current = "products",
    tags$section(
      class = "section container space-y-6",
      nav_button("All coffees", "products", "outline"),
      tags$div(
        class = "detail",
        label(coffee),
        tags$div(
          class = "space-y-6",
          tags$h1(class = "title", coffee$name),
          tags$p(class = "text-lg", coffee$blurb),
          tags$div(
            class = "flex flex-wrap gap-2",
            lapply(coffee$notes, bc_badge, variant = "outline")
          ),
          tags$dl(
            class = "facts",
            tags$dt("Roast"),
            tags$dd(coffee$roast),
            tags$dt("Process"),
            tags$dd(coffee$process),
            tags$dt("Elevation"),
            tags$dd(coffee$elevation),
            tags$dt("Bag"),
            tags$dd("340 g, whole bean")
          ),
          tags$div(
            class = "flex items-center gap-4",
            tags$span(
              class = "text-2xl font-semibold",
              paste0("$", coffee$price)
            ),
            bc_button("Add to bag", id = "add_to_bag")
          )
        )
      )
    )
  )
}

about_page <- function() {
  layout(
    current = "about",
    tags$section(
      class = "section container narrow prose",
      tags$h1("About"),
      tags$p(
        "My first coffee job was in high school, at the kids' cafe in the Bay",
        "Area Discovery Museum, just under the Golden Gate Bridge.",
        "We poured",
        tags$a(
          href = "https://www.equatorcoffees.com/",
          "Equator Coffees",
          .noWS = "after"
        ),
        ", and it is still my favorite roaster.",
        "I am wearing their hat right now."
      ),
      tags$p(
        "In college, I walked half a mile through the snow to open",
        tags$a(href = "https://montealto.com/", "Cafe Monte Alto"),
        "in Plymouth, New Hampshire, by 5:30 in the morning.",
        "Eddie and Micky, the zestiest couple I know, ran it as a cafe and a",
        "roaster, and I served Jay Moskowitz (may he rest in peace) across",
        "its counter.",
        "That is where I fell for espresso drinks and learned latte art."
      ),
      tags$p(
        "For my 27th birthday, I bought a Rancilio Silvia Pro X.",
        "I make at least one cortado on it every day."
      ),
      tags$p(
        "Jackalope is not a real roaster.",
        "It is a demo application to demonstrate the difference between Shiny",
        "and server-side rendering with plumber2."
      ),
      tags$p(nav_button("Taste the lineup", "products"))
    )
  )
}

ui <- tagList(
  bc_shiny_deps(style = "lyra", theme = "theme.css"),
  tags$head(
    tags$title("Jackalope Coffee"),
    tags$link(rel = "preconnect", href = "https://fonts.googleapis.com"),
    tags$link(
      rel = "stylesheet",
      href = "https://fonts.googleapis.com/css2?family=Archivo:wdth,wght@62..125,400..900&family=Inter:wght@400;500;600;700&display=swap"
    ),
    tags$link(rel = "icon", type = "image/svg+xml", href = "logo.svg"),
    includeCSS("site.css")
  ),
  uiOutput("page"),
  bc_toaster()
)

server <- function(input, output, session) {
  page <- reactiveVal("home")

  observeEvent(input$nav, page(input$nav))

  output$page <- renderUI({
    current <- page()

    if (startsWith(current, "product:")) {
      return(product_page(coffees[[sub(
        "product:",
        "",
        current,
        fixed = TRUE
      )]]))
    }

    switch(
      current,
      products = products_page(),
      about = about_page(),
      home_page()
    )
  })

  observeEvent(input$add_to_bag, {
    bc_show_toast(bc_toast("Added to your bag", category = "success"))
  })
}

shinyApp(ui, server)
