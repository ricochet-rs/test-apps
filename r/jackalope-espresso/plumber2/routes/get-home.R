get_home <- function() {
  layout(
    title = NULL,
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
            link_button("Shop the coffee", "products"),
            link_button("Meet the farms", "#farms", "outline")
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
        link_button("See all coffees", "products", "outline")
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
