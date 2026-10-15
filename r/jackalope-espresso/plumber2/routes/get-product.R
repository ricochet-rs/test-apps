get_product <- function(slug, response) {
  coffee <- coffees[[slug]]

  if (is.null(coffee)) {
    response$status <- 404L
    return(layout(
      title = "Not found",
      current = "products",
      tags$section(
        class = "section container narrow space-y-6",
        tags$h1(class = "title", "That coffee hopped away."),
        tags$p(
          class = "text-muted-foreground",
          "There is no coffee called ",
          tags$code(slug),
          "."
        ),
        link_button("Back to all coffees", "/products")
      )
    ))
  }

  layout(
    title = coffee$name,
    current = "products",
    tags$section(
      class = "section container space-y-6",
      bc_breadcrumb(
        bc_breadcrumb_item("Home", href = "/"),
        bc_breadcrumb_item("Coffee", href = "/products"),
        bc_breadcrumb_item(coffee$name, current = TRUE)
      ),
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
            bc_button("Add to bag")
          )
        )
      )
    )
  )
}
