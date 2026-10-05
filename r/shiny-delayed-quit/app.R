library(shiny)

ui <- fluidPage(
  titlePanel("Self-terminating test app"),
  p("This app quits its own R process ~1 second after a session connects.")
)

server <- function(input, output, session) {
  # Bind healthy first, then kill the whole R process mid-life.
  # This is the "app calls quit()" scenario: the process exits after it was Running.
  later::later(
    function() {
      message("test app: terminating R process now")
      quit(save = "no")
    },
    delay = 1
  )
}

shinyApp(ui, server)
