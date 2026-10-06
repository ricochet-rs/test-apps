library(DBI)
library(htmxr)
library(RSQLite)
library(basecoat)
library(plumber2)

source("db-utils.R")
source("jose-utils.R")

for (route in list.files("routes", full.names = TRUE)) {
  source(route)
}

survey <- yyjsonr::read_json_file("survey.json", arr_of_objs_to_df = FALSE)
questions <- survey$questions
question_ids <- vapply(questions, `[[`, character(1), "id")

dir.create("persistent", showWarnings = FALSE)
con <- dbConnect("persistent/survey.sqlite3", drv = SQLite())
set_db_pragmas(con)
create_tables(con)

pubkey <- Sys.getenv("RICOCHET_URL", "http://localhost:6188") |>
  read_ricochet_pubkey()
content_id <- Sys.getenv("RICOCHET_CONTENT_ID")

get_question <- function(question_id) {
  if (is.null(question_id) || !question_id %in% question_ids) {
    return(NULL)
  }
  questions[[match(question_id, question_ids)]]
}

get_next_question <- function(answers) {
  unanswered <- setdiff(question_ids, names(answers))
  if (length(unanswered)) get_question(unanswered[[1]])
}

get_option_label <- function(question, value) {
  for (option in question$options) {
    if (identical(option$value, value)) {
      return(option$label)
    }
  }
  value
}

link_to_question <- function(tag, question_id) {
  tag |>
    hx_set(get = paste0("./survey/view?q=", question_id)) |>
    htmltools::tagAppendAttributes(
      `hx-push-url` = paste0("./survey?q=", question_id)
    )
}

render_or_alert <- function(expr) {
  rlang::try_fetch(expr, error = function(cnd) {
    message("survey: ", conditionMessage(cnd))
    bc_alert(
      title = "That did not load",
      description = "Something went wrong reading the survey. Try again in a moment.",
      action = bc_button("Try again", variant = "outline", size = "sm") |>
        hx_set(get = "./survey/view"),
      variant = "destructive"
    )
  })
}

progress_breadcrumb <- function(answers, current_id = NULL) {
  crumbs <- lapply(questions, function(question) {
    if (identical(question$id, current_id)) {
      return(bc_breadcrumb_item(question$short, current = TRUE))
    }
    if (!is.null(answers[[question$id]])) {
      return(
        a(href = paste0("./survey?q=", question$id), question$short) |>
          link_to_question(question$id) |>
          tags$li()
      )
    }
    tags$li(span(class = "text-muted-foreground", question$short))
  })

  if (is.null(current_id)) {
    crumbs <- c(crumbs, list(bc_breadcrumb_item("Done", current = TRUE)))
  }

  answered <- sum(question_ids %in% names(answers))

  div(
    class = "flex flex-col gap-3",
    rlang::inject(bc_breadcrumb(!!!crumbs, label = "Survey progress")),
    div(
      class = "flex items-center gap-3",
      bc_progress(
        answered / length(questions) * 100,
        label = "Questions answered",
        class = "flex-1"
      ),
      span(
        class = "text-sm tabular-nums text-muted-foreground",
        sprintf("%d of %d", answered, length(questions))
      )
    )
  )
}

question_input <- function(question, value) {
  input_id <- paste0(question$id, "-input")

  switch(
    question$type,
    slider = {
      value <- (value %||% question$default) |> as.integer()
      output_id <- paste0(question$id, "-output")
      div(
        class = "flex flex-col gap-4",
        div(
          class = "flex items-baseline gap-2",
          tags$output(
            id = output_id,
            `for` = input_id,
            class = "text-5xl font-semibold tabular-nums",
            value
          ),
          span(class = "text-muted-foreground", question$unit)
        ),
        bc_slider(
          min = question$min,
          max = question$max,
          value = value,
          id = input_id,
          name = question$id,
          aria_label = question$prompt,
          oninput = sprintf(
            "document.getElementById('%s').value = this.value",
            output_id
          )
        ),
        div(
          class = "flex justify-between text-xs text-muted-foreground",
          span(question$min),
          span(paste0(question$max, "+"))
        )
      )
    },
    select = bc_select(
      lapply(question$options, function(option) {
        bc_select_option(option$value, option$label)
      }),
      placeholder = question$placeholder,
      name = question$id,
      id = input_id,
      selected = value,
      class = "w-full",
      aria_label = question$prompt
    ),
    combobox = {
      groups <- vapply(question$options, `[[`, character(1), "group")
      bc_combobox(
        input_id,
        lapply(unique(groups), function(group) {
          options <- lapply(
            question$options[groups == group],
            function(option) {
              bc_combobox_option(option$value, label = option$label)
            }
          )
          rlang::inject(bc_combobox_group(group, !!!options))
        }),
        placeholder = question$placeholder,
        name = question$id,
        selected = value %||% "",
        class = "w-full",
        aria_label = question$prompt
      )
    },
    radio = {
      radios <- lapply(question$options, function(option) {
        bc_radio(
          paste0(question$id, "-", option$value),
          option$label,
          checked = identical(value, option$value),
          description = option$description
        )
      })
      rlang::inject(bc_radio_group(
        !!!radios,
        name = question$id,
        label = question$prompt,
        id = input_id
      ))
    },
    textarea = bc_textarea(
      id = input_id,
      name = question$id,
      placeholder = question$placeholder,
      value = value,
      rows = 4,
      aria_label = question$prompt
    )
  )
}

question_view <- function(question, answers, value = NULL, error = NULL) {
  position <- match(question$id, question_ids)
  previous <- if (position > 1) question_ids[[position - 1]]

  tagList(
    progress_breadcrumb(answers, question$id),
    tags$form(
      class = "flex flex-col",
      tags$input(type = "hidden", name = "question", value = question$id),
      bc_card(
        style = "overflow: visible",
        bc_card_header(
          tags$h2(question$prompt),
          tags$p(question$help),
          sprintf("%d of %d", position, length(questions)) |>
            bc_badge(variant = "outline") |>
            bc_card_action()
        ),
        bc_card_body(
          class = "flex flex-col gap-4",
          if (!is.null(error)) {
            bc_alert(title = error, variant = "destructive")
          },
          question_input(question, value %||% answers[[question$id]])
        ),
        bc_card_footer(
          class = "flex items-center justify-between gap-2",
          if (is.null(previous)) {
            span()
          } else {
            bc_button("Back", variant = "outline") |>
              link_to_question(previous)
          },
          bc_button(
            if (position == length(questions)) "Finish" else "Next",
            type = "submit"
          )
        )
      )
    ) |>
      hx_set(post = "./survey/answer")
  )
}

survey_view <- function(user, question_id = NULL) {
  answers <- get_user_answers(con, user$sub)
  question <- get_question(question_id) %||% get_next_question(answers)

  if (!is.null(question)) {
    return(question_view(question, answers))
  }

  responses <- get_all_responses(con)
  respondents <- responses$user_id |> unique() |> length()

  summaries <- lapply(questions, function(question) {
    values <- responses$value[responses$question_id == question$id]
    if (!length(values) || identical(question$type, "textarea")) {
      return(NULL)
    }

    if (identical(question$type, "slider")) {
      return(bc_item(
        title = question$short,
        description = values |>
          as.integer() |>
          median() |>
          sprintf(fmt = "Typical team ships %s %s.", question$unit),
        variant = "outline"
      ))
    }

    counts <- values |> table() |> sort(decreasing = TRUE) |> head(3)
    bc_item(
      title = question$short,
      div(
        class = "flex w-full flex-col gap-2",
        lapply(names(counts), function(value) {
          share <- (counts[[value]] / length(values) * 100) |> round()
          div(
            class = "flex items-center gap-3",
            span(
              class = "w-36 truncate text-sm",
              get_option_label(question, value)
            ),
            bc_progress(
              share,
              label = get_option_label(question, value),
              class = "flex-1"
            ),
            span(class = "text-sm tabular-nums", paste0(share, "%"))
          )
        })
      ),
      variant = "outline"
    )
  })

  answer_items <- lapply(questions, function(question) {
    value <- answers[[question$id]] %||% ""
    bc_item(
      title = question$short,
      description = if (!nzchar(value)) {
        "Skipped"
      } else {
        switch(
          question$type,
          slider = paste(value, question$unit),
          textarea = value,
          get_option_label(question, value)
        )
      },
      actions = bc_button("Edit", variant = "ghost", size = "sm") |>
        link_to_question(question$id),
      variant = "outline"
    )
  })

  tagList(
    progress_breadcrumb(answers),
    bc_card(
      bc_card_header(
        user$name |>
          trimws() |>
          strsplit("\\s+") |>
          unlist() |>
          head(1) |>
          sprintf(fmt = "Thanks, %s 🎉") |>
          tags$h2(),
        tags$p("Your answers are saved. Change any of them below.")
      ),
      bc_card_body(rlang::inject(bc_item_group(!!!answer_items))),
      bc_card_footer(
        class = "flex",
        bc_button("Start over", variant = "outline") |>
          hx_set(
            post = "./survey/reset",
            confirm = "Clear every answer and start again?"
          ) |>
          htmltools::tagAppendAttributes(`hx-push-url` = "./survey")
      )
    ),
    bc_card(
      bc_card_header(
        tags$h2("Everyone so far"),
        tags$p(sprintf(
          "%d %s answered.",
          respondents,
          if (respondents == 1) "person has" else "people have"
        ))
      ),
      bc_card_body(rlang::inject(bc_item_group(!!!summaries)))
    )
  )
}

html <- get_serializers("html")

api(doc_type = NULL) |>
  hx_serve_assets() |>
  api_logger(logger_console()) |>
  api_statics("/basecoat/", system.file("basecoat", package = "basecoat")) |>
  api_get("/", get_root) |>
  api_get("/survey", get_survey, serializers = html) |>
  api_get("/survey/view", get_survey_view, serializers = html) |>
  api_post("/survey/answer", post_survey_answer, serializers = html) |>
  api_post("/survey/reset", post_survey_reset, serializers = html) |>
  api_run(
    host = Sys.getenv("HOST", "0.0.0.0"),
    port = as.integer(Sys.getenv("PORT", "8080")),
    showcase = FALSE
  )
