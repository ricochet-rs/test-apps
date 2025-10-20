library(shiny)
wd <- normalizePath(getwd())
ui <- fluidPage(
  titlePanel("List Files in Path"),

  sidebarLayout(
    sidebarPanel(
      textInput("path", "Enter file path:", value = "~"),
      actionButton("go", "List Files"),

      tags$hr(),
      tags$details(
        tags$p(sprintf("Current working directory: %s", wd)),
        tags$summary("Suggested Paths to Explore (for testing)"),
        tags$p(
          "Use these paths to test access control and security isolation."
        ),
        tags$strong("Linux:"),
        tags$ul(
          tags$li("/etc"),
          tags$li("/var/log"),
          tags$li("/root"),
          tags$li("/home"),
          tags$li("/proc"),
          tags$li("/srv"),
          tags$li("/boot")
        ),
        tags$strong("macOS:"),
        tags$ul(
          tags$li("/Users"),
          tags$li("/Library"),
          tags$li("/System"),
          tags$li("/private"),
          tags$li("/var/log"),
          tags$li("/etc"),
          tags$li("/Volumes")
        )
      )
    ),
    mainPanel(
      verbatimTextOutput("file_list")
    )
  )
)

server <- function(input, output) {
  files <- eventReactive(input$go, {
    req(input$path)
    tryCatch(
      {
        list.files(
          input$path,
          all.files = TRUE,
          full.names = TRUE,
          include.dirs = TRUE
        )
      },
      error = function(e) {
        paste("Error:", e$message)
      }
    )
  })

  output$file_list <- renderPrint({
    files()
  })
}

shinyApp(ui, server)
