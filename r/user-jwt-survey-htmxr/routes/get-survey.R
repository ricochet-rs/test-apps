get_survey <- function(request, response, query) {
  user <- get_ricochet_user(request, pubkey, content_id)
  initials <- user$name |>
    trimws() |>
    strsplit("\\s+") |>
    unlist() |>
    head(2) |>
    substr(1, 1) |>
    paste(collapse = "") |>
    toupper()
  start_id <- get_question(query$q)$id
  input_scripts <- questions |>
    lapply(question_input, value = NULL) |>
    htmltools::findDependencies()

  page <- bc_page_navbar(
    div(
      class = "prose mx-auto flex w-full max-w-2xl flex-1 flex-col gap-6 p-10",
      div(
        id = "survey-body",
        class = "flex flex-col gap-6",
        `hx-target` = "#survey-body",
        hx_set(
          div(
            class = "flex flex-col gap-4",
            `aria-busy` = "true",
            div(
              class = "flex items-center gap-3",
              lapply(questions, function(question) {
                bc_skeleton(class = "h-4 w-16")
              })
            ),
            bc_skeleton(class = "h-2 w-full"),
            bc_card(
              bc_card_header(
                bc_skeleton(class = "h-6 w-3/4"),
                bc_skeleton(class = "h-4 w-1/2")
              ),
              bc_card_body(bc_skeleton(class = "h-24 w-full")),
              bc_card_footer(bc_skeleton(class = "h-9 w-24"))
            ),
            span(class = "sr-only", "Loading the survey")
          ),
          get = paste0("./survey/view?q=", start_id),
          trigger = "load"
        )
      )
    ),
    title = survey$title,
    href = "./survey",
    end = tagList(
      bc_theme_switcher(),
      bc_dropdown_menu(
        align = "end",
        trigger = tags$button(
          type = "button",
          class = "rounded-full",
          `aria-label` = "Your account",
          bc_avatar(fallback = initials, alt = user$name)
        ),
        bc_dropdown_group(
          user$name,
          bc_dropdown_item(
            user$email %||% "No email on file",
            disabled = TRUE
          ),
          bc_dropdown_item(paste("ID", user$sub), disabled = TRUE)
        )
      )
    ),
    tags$footer(
      class = "border-t py-2 text-center text-sm text-muted-foreground",
      "Hosted on ",
      a(href = "https://ricochet.rs", class = "font-medium", "ricochet.rs"),
      " 🐇"
    ),
    class = "flex flex-col"
  )

  page |>
    htmltools::attachDependencies(input_scripts) |>
    bc_page(
      title = survey$title,
      assets = "./basecoat/",
      theme = system.file("themes/ricochet.css", package = "basecoat"),
      head = tags$script(
        src = "./htmxr/assets/htmx/2.0.8/htmx.min.js",
        defer = NA
      )
    )
}
