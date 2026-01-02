library(sf)
library(shiny)
library(bslib)
library(dplyr)
library(leaflet)
library(ggplot2)

svi_wa <- st_read(
  "data/SVI2022_WASHINGTON_tract.gdb",
  layer = "SVI2022_WASHINGTON_tract"
)
svi_wa <- st_transform(svi_wa, crs = 4326)

svi_wa_col_select <- select(svi_wa, where(is.numeric)) |>
  slice(1)

ui <- page_sidebar(
  title = "WA SVI Dashboard",
  sidebar = sidebar(
    varSelectInput(
      inputId = "var_select",
      "Select a variable to visualize",
      svi_wa_col_select
    ),
    tags$div(
      tags$a(
        href = "https://svi.cdc.gov/map25/data/docs/SVI2022Documentation_ZCTA.pdf",
        "Open Documentation",
        target = "_blank",
        style = "font-size: 14px;"
      )
    )
  ),
  layout_columns(
    list(
      card(leafletOutput("map")),
      card(plotOutput("myplot"))
    ),
    card(
      card_header("County Summary"),
      tableOutput("table_output")
    )
  )
)


server <- function(input, output) {
  observeEvent(input$var_select, {
    output$myplot <- renderPlot({
      var_name <- input$var_select
      ggplot(svi_wa, aes(x = .data[[var_name]], fill = after_stat(count))) +
        geom_histogram() +
        scale_fill_viridis_c(option = "mako") +
        theme_minimal()
    })

    output$map <- renderLeaflet({
      var_name <- input$var_select
      pal <- colorBin(
        "BuGn",
        domain = svi_wa[[var_name]],
        bins = 5,
        pretty = TRUE
      )
      leaflet() |>
        addTiles() |>
        # polygons
        addPolygons(
          data = svi_wa,
          fillColor = ~ pal(get(var_name)),
          fillOpacity = 0.7,
          color = "black",
          weight = 1,
          group = "SVI Layer",
          label = ~ paste("FIPS:", FIPS, "\n", var_name, ":", get(var_name)),
          highlightOptions = highlightOptions(
            weight = 2,
            color = "#666",
            fillOpacity = 0.9,
            bringToFront = TRUE
          )
        ) |>
        #legend
        addLegend(
          position = "topright",
          pal = pal,
          values = svi_wa[[var_name]],
          title = as.character(var_name)
        ) |>

        #layers
        addLayersControl(
          overlayGroups = c("SVI Layer"),
          options = layersControlOptions(collapsed = FALSE)
        )
    })
    output$table_output <- renderTable({
      svi_wa |>
        sf::st_drop_geometry() |>
        select(COUNTY, input$var_select) |>
        group_by(COUNTY) |>
        summarise(
          mean = mean(.data[[input$var_select]], na.rm = TRUE),
          min = min(.data[[input$var_select]], na.rm = TRUE),
          max = max(.data[[input$var_select]], na.rm = TRUE),
        )
    })
  })
}

shinyApp(ui, server)
