library(plumber2)
library(htmltools)


tailwind_cdn <- "https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"


# some select theming directly from ricochet
ricochet_theme <- HTML(
  "
  :root {
    --background: oklch(0.1448 0.015 330.91);
    --foreground: oklch(0.9851 0 0);
    --card: oklch(0.2046 0.012 330.91);
    --muted-foreground: oklch(0.709 0 0);
    --primary: oklch(0.8561 0.0681 301.14);
    --secondary: oklch(0.2686 0.01 330.91);
    --accent: oklch(0.3715 0.02 330.91);
    --border: oklch(0.2768 0.012 330.91);
    color-scheme: dark;
  }

  /* theme.css sets --radius: 0rem; keep every corner square. */
  *, ::before, ::after { border-radius: 0 !important; }

  body {
    background-color: var(--background);
    color: var(--foreground);
    font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont,
      'Segoe UI', Roboto, 'Helvetica Neue', Arial, 'Noto Sans', sans-serif;
  }

  a.rico-link { color: var(--primary); text-decoration: none; }
  a.rico-link:hover { opacity: 0.8; }

  .rico-muted { color: var(--muted-foreground); }
  .rico-fg { color: var(--foreground); }
  .rico-card { background-color: var(--card); border: 1px solid var(--border); }
  .rico-code { background-color: var(--secondary); }

  a.rico-pill {
    color: var(--foreground);
    text-decoration: none;
    background-color: var(--secondary);
    box-shadow: inset 0 0 0 1px var(--border);
  }
  a.rico-pill:hover { background-color: var(--accent); }

  .rico-table { color: var(--foreground); }
  .rico-table thead { background-color: var(--secondary); color: var(--muted-foreground); }
  .rico-table thead th { border-bottom: 1px solid var(--border); }
  .rico-table tbody tr + tr { border-top: 1px solid var(--border); }
"
)

species_levels <- as.character(sort(unique(penguins$species)))

# page shell
page_template <- '<!DOCTYPE html>
<html lang="en" class="dark">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{{ title }}</title>
{{ styles }}
</head>
<body class="min-h-screen antialiased">
{{ body }}
</body>
</html>
'

# create a page
page <- function(title, ..., root = "./") {
  doc <- htmlTemplate(
    text_ = page_template,
    title = title,
    styles = tags$style(ricochet_theme),
    body = tagList(
      tags$div(
        class = "mx-auto max-w-3xl px-6 py-16",
        tags$header(
          class = "mb-10",
          tags$a(
            href = root,
            class = "rico-link text-sm font-medium",
            HTML("&larr; home")
          )
        ),
        ...
      ),
      tags$script(src = tailwind_cdn)
    )
  )
  as.character(doc)
}

pill <- function(name, root) {
  tags$li(
    tags$a(
      href = paste0(root, "species/", name),
      class = "rico-pill px-4 py-1.5 text-sm font-medium",
      name
    )
  )
}

home <- function() {
  root <- "./"
  page(
    "Hello from ricochet",
    root = root,
    tags$h1(
      class = "text-4xl font-bold tracking-tight",
      "Hello from ",
      tags$a(
        "ricochet",
        href = "https://ricochet.rs",
        class = "font-semibold font-mono"
      )
    ),
    tags$p(
      class = "mt-4 text-lg leading-relaxed rico-muted",
      "Use ",
      tags$a(
        "{plumber2}",
        href = "https://github.com/posit-dev/plumber2",
        class = "font-mono  text-sm text-white decoration-dotted hover:underline"
      ),
      "to create server-side-rendered (SSR) websites.",
      "SSR-based websites generate the HTML content on the server to avoid additional frontend work.",
      "plumber2 is a deceptively good way to create full-stack websites from R."
    ),
    tags$div(
      class = "rico-card mt-10 p-6",
      tags$h2(
        class = "text-sm font-semibold rico-muted",
        "Try the species route"
      ),
      tags$p(
        class = "mt-2 rico-muted",
        "Explore the base R ",
        tags$code(class = "rico-code px-1 py-0.5 text-sm", "penguins"),
        " dataset. ",
        tags$code(class = "rico-code px-1 py-0.5 text-sm", "/species/{name}"),
        " renders a summary for one species:"
      ),
      tags$ul(
        class = "mt-4 flex flex-wrap gap-2",
        lapply(species_levels, pill, root = root)
      )
    )
  )
}

stat_card <- function(label, value) {
  tags$div(
    class = "rico-card p-4",
    tags$dt(class = "text-xs font-semibold rico-muted", label),
    tags$dd(class = "mt-1 text-2xl font-semibold tabular-nums", value)
  )
}

# generates a single page for species
species_page <- function(species, response) {
  root <- "../"
  match_name <- species_levels[tolower(species_levels) == tolower(species)]

  if (length(match_name) == 0) {
    response$status <- 404L
    return(page(
      paste0("Unknown species: ", species),
      root = root,
      tags$h1(class = "text-3xl font-bold tracking-tight", "No such species"),
      tags$p(
        class = "mt-4 rico-muted",
        tags$span(class = "rico-fg font-semibold", species),
        " is not in the penguins dataset. Known species:"
      ),
      tags$ul(
        class = "mt-4 flex flex-wrap gap-2",
        lapply(species_levels, pill, root = root)
      )
    ))
  }

  df <- penguins[penguins$species == match_name, , drop = FALSE]
  mean1 <- function(x) formatC(mean(x, na.rm = TRUE), format = "f", digits = 1)

  cols <- c(
    "island",
    "bill_len",
    "bill_dep",
    "flipper_len",
    "body_mass",
    "sex",
    "year"
  )
  shown <- utils::head(df, 15L)
  cell <- function(x) {
    tags$td(
      class = "px-3 py-2 tabular-nums",
      if (is.na(x)) HTML("&mdash;") else as.character(x)
    )
  }

  page(
    paste0(match_name, " penguins"),
    root = root,
    tags$h1(
      class = "text-3xl font-bold tracking-tight",
      paste0(match_name, " penguins")
    ),
    tags$dl(
      class = "mt-6 grid grid-cols-2 gap-3 sm:grid-cols-4",
      stat_card("Observations", nrow(df)),
      stat_card("Mean bill (mm)", mean1(df$bill_len)),
      stat_card("Mean flipper (mm)", mean1(df$flipper_len)),
      stat_card("Mean mass (g)", mean1(df$body_mass))
    ),
    tags$p(
      class = "mt-4 text-sm rico-muted",
      "Islands: ",
      paste(sort(unique(as.character(df$island))), collapse = ", ")
    ),
    tags$div(
      class = "rico-card mt-8 overflow-x-auto",
      tags$table(
        class = "rico-table w-full border-collapse text-sm",
        tags$thead(
          tags$tr(
            lapply(cols, function(x) {
              tags$th(class = "px-3 py-2 text-left font-semibold", x)
            })
          )
        ),
        tags$tbody(
          lapply(seq_len(nrow(shown)), function(i) {
            tags$tr(
              lapply(cols, function(cn) cell(shown[[cn]][i]))
            )
          })
        )
      )
    ),
    if (nrow(df) > nrow(shown)) {
      tags$p(
        class = "mt-3 text-sm rico-muted",
        sprintf("Showing the first %d of %d rows.", nrow(shown), nrow(df))
      )
    }
  )
}

html_only <- get_serializers("html")

api() |>
  api_get("/", home, serializers = html_only) |>
  api_get("/species/<species>", species_page, serializers = html_only) |>
  api_run(
    host = Sys.getenv("HOST", "0.0.0.0"),
    port = as.integer(Sys.getenv("PORT", "8080"))
  )
