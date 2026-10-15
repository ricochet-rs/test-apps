roast_colors <- c(
  "Light" = "oklch(0.52 0.2 27)",
  "Medium" = "oklch(0.44 0.17 25)",
  "Medium-dark" = "oklch(0.35 0.12 22)",
  "Dark" = "oklch(0.24 0.05 20)"
)

coffees <- list(
  list(
    slug = "colombia-huila",
    country = "Colombia",
    region = "Huila",
    roast = "Medium",
    process = "Washed",
    elevation = "1,600 to 1,900 m",
    notes = c("Milk chocolate", "Red apple", "Panela"),
    price = 18,
    blurb = "Our house espresso. Sweet and round, and just as good with milk as without."
  ),
  list(
    slug = "ethiopia-yirgacheffe",
    country = "Ethiopia",
    region = "Yirgacheffe",
    roast = "Light",
    process = "Natural",
    elevation = "1,900 to 2,200 m",
    notes = c("Blueberry", "Jasmine", "Lemon curd"),
    price = 21,
    blurb = "Bright, floral, and fruity. Our favorite coffee for pour-over."
  ),
  list(
    slug = "guatemala-antigua",
    country = "Guatemala",
    region = "Antigua",
    roast = "Medium",
    process = "Washed",
    elevation = "1,500 to 1,700 m",
    notes = c("Toffee", "Orange zest", "Baking spice"),
    price = 19,
    blurb = "Silky and balanced, with a little spice on the finish."
  ),
  list(
    slug = "brazil-cerrado",
    country = "Brazil",
    region = "Cerrado",
    roast = "Medium-dark",
    process = "Pulped natural",
    elevation = "900 to 1,200 m",
    notes = c("Roasted peanut", "Caramel", "Brown sugar"),
    price = 16,
    blurb = "A low and nutty everyday coffee that holds up to milk."
  ),
  list(
    slug = "sumatra-aceh",
    country = "Sumatra",
    region = "Aceh",
    roast = "Dark",
    process = "Wet-hulled",
    elevation = "1,300 to 1,600 m",
    notes = c("Cedar", "Dark cocoa", "Molasses"),
    price = 17,
    blurb = "Heavy body and low acidity for anyone who likes a dark roast."
  ),
  list(
    slug = "mexico-chiapas-decaf",
    country = "Mexico",
    region = "Chiapas Decaf",
    roast = "Medium-dark",
    process = "Swiss Water decaf",
    elevation = "1,200 to 1,600 m",
    notes = c("Fudge", "Almond", "Dried cherry"),
    price = 18,
    blurb = "All of the flavor of a late-night shot without the caffeine."
  )
)

coffees <- lapply(coffees, function(x) {
  x$name <- paste(x$country, x$region)
  x$color <- roast_colors[[x$roast]]
  x$notes_text <- paste(c(x$notes[1], tolower(x$notes[-1])), collapse = ", ")
  x
})

names(coffees) <- vapply(coffees, `[[`, character(1), "slug")
