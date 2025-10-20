library(shiny)

# Define reusable classes
card_class <- "bg-white border border-zinc-300 p-6"

ui <- tagList(
  suppressDependencies("bootstrap"),

  tags$head(
    tags$script(src = "https://cdn.jsdelivr.net/npm/@tailwindcss/browser@4"),
    tags$style(HTML(
      "
      @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');
      body { font-family: 'Inter', sans-serif; }
      
      /* Style the numeric inputs */
      .form-control {
        background-color: white !important;
        border: 2px solid #d4d4d8 !important;
        padding: 8px 12px !important;
        font-size: 16px !important;
        color: #18181b !important;
        width: 100% !important;
      }
      
      .form-control:focus {
        border-color: #3b82f6 !important;
        box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1) !important;
        outline: none !important;
      }
    "
    ))
  ),

  div(
    class = "min-h-screen bg-zinc-50 text-zinc-900",
    div(
      class = "flex flex-col lg:flex-row",
      # Sidebar
      div(
        class = "w-full lg:w-80 bg-white border-b lg:border-b-0 lg:border-r border-zinc-300 p-6 lg:min-h-screen",
        h1(
          span("ricochet", class = "font-bold font-mono"),
          " pricing calculator",
          class = "text-xl mb-8 text-zinc-900"
        ),

        # Configuration section
        div(
          class = "mb-8",
          h2("Configuration", class = "text-lg font-medium mb-4 text-zinc-900"),

          # Services
          div(
            class = "mb-4",
            tags$label(
              "Services",
              class = "block text-sm font-medium mb-2 text-zinc-900"
            ),
            numericInput(
              "services",
              NULL,
              value = 3,
              min = 0,
              max = 500,
              step = 1
            ),
            p(
              "Apps or APIs such as Shiny, Plumber, Ambiorix, or Quarto/R Markdown with Shiny runtime.",
              class = "text-xs text-zinc-600 mt-1"
            )
          ),

          # Tasks
          div(
            class = "mb-4",
            tags$label(
              "Tasks",
              class = "block text-sm font-medium mb-2 text-zinc-900"
            ),
            numericInput(
              "tasks",
              NULL,
              value = 5,
              min = 0,
              max = 1000,
              step = 1
            ),
            p(
              "Schedulable or invoked R/Julia scripts, R Markdown, or Quarto documents.",
              class = "text-xs text-zinc-600 mt-1"
            )
          ),

          # Staging Servers
          div(
            class = "mb-4",
            tags$label(
              "Staging Servers",
              class = "block text-sm font-medium mb-2 text-zinc-900"
            ),
            numericInput(
              "staging_servers",
              NULL,
              value = 0,
              min = 0,
              max = 20,
              step = 1
            )
          ),

          # Note about staging servers
          div(
            class = "mt-6 p-3 bg-zinc-100 border border-zinc-300",
            p(
              "Note: Staging servers only permit private access controls.",
              class = "text-sm text-zinc-700"
            )
          )
        )
      ),

      # Main content
      div(
        class = "flex-1 p-4 lg:p-8",

        # Cost breakdown (now includes total at top)
        conditionalPanel(
          condition = "output.is_unlimited != 'true'",
          div(
            class = paste(card_class, "mb-8"),
            h3(
              "Annual License Cost",
              class = "text-xl font-medium mb-4 border-b border-zinc-300 pb-2 text-zinc-900"
            ),
            # Total cost row
            div(
              class = "flex flex-col sm:grid sm:grid-cols-2 gap-6 mb-6 p-4 bg-zinc-50 border border-zinc-200",
              div(
                h4(
                  "Total Annual Cost",
                  class = "text-lg font-semibold text-zinc-900"
                ),
                div(
                  textOutput("total_cost"),
                  class = "text-3xl font-bold text-zinc-900 mt-1"
                )
              ),
              div(
                conditionalPanel(
                  condition = "output.is_unlimited == 'true'",
                  div(
                    class = "p-4 bg-emerald-50 border border-emerald-200",
                    h4(
                      "🎉 Enterprise Unlimited",
                      class = "text-lg font-semibold text-emerald-800 mb-2"
                    ),
                    p(
                      "Unrestricted access to everything.",
                      class = "text-emerald-700"
                    )
                  )
                )
              )
            ),
            # Breakdown rows
            div(
              class = "grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6",
              div(
                h4(
                  "Staging Servers",
                  class = "text-sm font-medium mb-2 text-zinc-900"
                ),
                div(
                  textOutput("staging_server_cost"),
                  class = "text-lg font-semibold text-zinc-900"
                )
              ),
              div(
                h4("Tasks", class = "text-sm font-medium mb-2 text-zinc-900"),
                div(
                  textOutput("task_cost"),
                  class = "text-lg font-semibold text-zinc-900"
                )
              ),
              div(
                h4(
                  "Services",
                  class = "text-sm font-medium mb-2 text-zinc-900"
                ),
                div(
                  textOutput("service_cost"),
                  class = "text-lg font-semibold text-zinc-900"
                )
              )
            ),
            div(
              class = "mt-6 pt-4 border-t border-zinc-300",
              div(
                textOutput("breakdown_details"),
                class = "text-sm text-zinc-600"
              )
            )
          )
        ),

        # Unlimited tier message
        conditionalPanel(
          condition = "output.is_unlimited == 'true'",
          div(
            class = paste(card_class, "mb-8 text-center"),
            div(
              class = "p-6 bg-emerald-50 border border-emerald-200",
              h2(
                "🎉 Enterprise Unlimited - $105,000",
                class = "text-3xl font-bold text-emerald-800 mb-4"
              ),
              p(
                "You've reached our unlimited tier! Unrestricted access to everything.",
                class = "text-emerald-700 text-lg"
              )
            )
          )
        ),

        # Pricing model explanation
        div(
          class = card_class,
          h3(
            "Volume-Based Pricing",
            class = "text-xl font-medium mb-4 border-b border-zinc-300 pb-2 text-zinc-900"
          ),
          div(
            class = "grid grid-cols-1 sm:grid-cols-2 gap-8 text-sm",
            div(
              h4("Services:", class = "font-medium mb-2 text-zinc-900"),
              tags$ul(
                class = "space-y-1 text-zinc-600",
                tags$li("• First 10: $1,000 each"),
                tags$li("• Next 10 (11-20): $750 each"),
                tags$li("• 21+: $500 each")
              )
            ),
            div(
              h4("Tasks:", class = "font-medium mb-2 text-zinc-900"),
              tags$ul(
                class = "space-y-1 text-zinc-600",
                tags$li("• First 25: $400 each"),
                tags$li("• Next 25 (26-50): $300 each"),
                tags$li("• 51+: $200 each")
              )
            ),
            div(
              h4("Servers:", class = "font-medium mb-2 text-zinc-900"),
              tags$ul(
                class = "space-y-1 text-zinc-600",
                tags$li("• Production: Included (no charge)"),
                tags$li("• Staging: $2,500 each")
              )
            ),
            div(
              h4("Unlimited Tier:", class = "font-medium mb-2 text-zinc-900"),
              p(
                "When total cost reaches $105,000, you get unrestricted access to everything.",
                class = "text-zinc-600"
              )
            )
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  # Calculate service cost with volume discounts
  service_cost_calc <- reactive({
    services <- input$services
    if (services == 0) {
      return(0)
    }

    cost <- 0
    # First 10 at $1,000 each
    tier1 <- min(services, 10)
    cost <- cost + (tier1 * 1000)

    if (services > 10) {
      # Next 10 (11-20) at $750 each
      tier2 <- min(services - 10, 10)
      cost <- cost + (tier2 * 750)
    }

    if (services > 20) {
      # Remaining (21+) at $500 each
      tier3 <- services - 20
      cost <- cost + (tier3 * 500)
    }

    cost
  })

  # Calculate task cost with volume discounts
  task_cost_calc <- reactive({
    tasks <- input$tasks
    if (tasks == 0) {
      return(0)
    }

    cost <- 0
    # First 25 at $400 each
    tier1 <- min(tasks, 25)
    cost <- cost + (tier1 * 400)

    if (tasks > 25) {
      # Next 25 (26-50) at $300 each
      tier2 <- min(tasks - 25, 25)
      cost <- cost + (tier2 * 300)
    }

    if (tasks > 50) {
      # Remaining (51+) at $200 each
      tier3 <- tasks - 50
      cost <- cost + (tier3 * 200)
    }

    cost
  })

  # Server costs (no base production server cost, only staging servers cost extra)
  prod_server_cost_calc <- reactive({
    0 # No cost for the included production server
  })

  staging_server_cost_calc <- reactive({
    input$staging_servers * 2500
  })

  # Total cost
  total_cost_calc <- reactive({
    total <- service_cost_calc() +
      task_cost_calc() +
      prod_server_cost_calc() +
      staging_server_cost_calc()
    if (total >= 105000) {
      return(105000)
    }
    total
  })

  # Check if unlimited
  is_unlimited <- reactive({
    total_without_cap <- service_cost_calc() +
      task_cost_calc() +
      prod_server_cost_calc() +
      staging_server_cost_calc()
    total_without_cap >= 105000
  })

  # Breakdown details
  breakdown_text <- reactive({
    if (is_unlimited()) {
      return("")
    }

    details <- c()

    # Services breakdown
    services <- input$services
    if (services > 0) {
      if (services <= 10) {
        details <- c(details, paste("Services:", services, "x $1,000"))
      } else if (services <= 20) {
        details <- c(
          details,
          paste("Services: 10 x $1,000 + ", services - 10, "x $750")
        )
      } else {
        details <- c(
          details,
          paste("Services: 10 x $1,000 + 10 x $750 + ", services - 20, "x $500")
        )
      }
    }

    # Tasks breakdown
    tasks <- input$tasks
    if (tasks > 0) {
      if (tasks <= 25) {
        details <- c(details, paste("Tasks:", tasks, "x $400"))
      } else if (tasks <= 50) {
        details <- c(
          details,
          paste("Tasks: 25 x $400 + ", tasks - 25, "x $300")
        )
      } else {
        details <- c(
          details,
          paste("Tasks: 25 x $400 + 25 x $300 + ", tasks - 50, "x $200")
        )
      }
    }

    paste(details, collapse = " | ")
  })

  # Outputs
  output$total_cost <- renderText({
    paste0("$", format(total_cost_calc(), big.mark = ","))
  })

  output$is_unlimited <- renderText({
    as.character(is_unlimited())
  })

  output$prod_server_cost <- renderText({
    paste0("$", format(prod_server_cost_calc(), big.mark = ","))
  })

  output$staging_server_cost <- renderText({
    paste0("$", format(staging_server_cost_calc(), big.mark = ","))
  })

  output$task_cost <- renderText({
    paste0("$", format(task_cost_calc(), big.mark = ","))
  })

  output$service_cost <- renderText({
    paste0("$", format(service_cost_calc(), big.mark = ","))
  })

  output$breakdown_details <- renderText({
    breakdown_text()
  })
}

shinyApp(ui = ui, server = server)
