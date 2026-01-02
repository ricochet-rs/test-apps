library(shiny)

# Define UI for application that draws a histogram
ui <- fluidPage(
  # Application title
  titlePanel(sample(letters, 1)),

  # Sidebar with a slider input for number of bins
  sidebarLayout(
    sidebarPanel(
      sliderInput("bins", "Number of bins:", min = 1, max = 50, value = 30)
    ),

    # Show a plot of the generated distribution
    mainPanel(
      plotOutput("distPlot")
    )
  )
)

server <- function(input, output, session) {
  # Print lorem ipsum every second
  observe({
    invalidateLater(1000, session)
    message(unlist(lorem::ipsum()))
  })

  # Print message whenever slider changes
  observeEvent(input$bins, {
    message("Slider moved! New bin count: ", input$bins)
  })

  output$distPlot <- renderPlot({
    # generate bins based on input$bins from ui.R
    x <- faithful[, 2]
    bins <- seq(min(x), max(x), length.out = input$bins + 1)

    # draw the histogram with the specified number of bins
    hist(
      x,
      breaks = bins,
      col = "darkgray",
      border = "white",
      xlab = "Waiting time to next eruption (in mins)",
      main = "Histogram of waiting times"
    )
  })
}

shiny::shinyApp(ui, server)
