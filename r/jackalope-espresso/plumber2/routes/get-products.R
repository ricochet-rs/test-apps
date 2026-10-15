get_products <- function() {
  layout(
    title = "Coffee",
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
