library(shiny)
library(DBI)
library(RSQLite)

db_path <- "persistent/app_data.sqlite3"

# Ensure table exists
con <- dbConnect(SQLite(), db_path)
dbExecute(
  con,
  "
  CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message TEXT,
    submission_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  )
"
)

dbDisconnect(con)

ui <- fluidPage(
  textInput("message", NULL, placeholder = "Enter your message"),
  actionButton("submit", "Save Message"),
  tableOutput("data_table")
)

server <- function(input, output, session) {
  refresh <- reactiveVal(FALSE)
  observeEvent(input$submit, {
    if (nzchar(input$message)) {
      con <- dbConnect(SQLite(), db_path)
      dbExecute(
        con,
        "INSERT INTO messages (message) VALUES (?)",
        list(input$message)
      )
      dbDisconnect(con)
      updateTextInput(session, "message", value = "")
      refresh(!refresh())
    }
  })

  df <- reactive({
    # Force reactivity when trigger changes
    refresh()
    con <- dbConnect(RSQLite::SQLite(), db_path)
    data <- dbGetQuery(
      con,
      "SELECT id, message, submission_time FROM messages ORDER BY id DESC"
    )
    dbDisconnect(con)
    data
  })
  output$data_table <- renderTable(df())
}

shinyApp(ui, server)
