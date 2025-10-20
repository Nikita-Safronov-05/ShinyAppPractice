# Weather-Time-Series/app.R
# Interactive time series plot for MacLeish weather data with station/date selectors.

library(shiny)
library(dplyr)
library(ggplot2)
library(plotly)
library(lubridate)

# Helper to fetch and combine station data by name
load_station_from_rds <- function(name) {
  p <- file.path("data", paste0(name, ".rds"))
  if (file.exists(p)) readRDS(p) else NULL
}

get_station_df <- function(station) {
  # Only use vendored RDS data to keep deployment free of geospatial deps
  vendored <- load_station_from_rds(station)
  if (!is.null(vendored)) return(vendored)
  stop(
    "Required data file not found: ",
    file.path("data", paste0(station, ".rds")),
    ". Please create it locally with:\n",
    "dir.create('Weather-Time-Series/data', showWarnings=FALSE); ",
    "saveRDS(macleish::", station, ", 'Weather-Time-Series/data/", station, ".rds')"
  )
}

# Detect a reasonable time column name in the data frame
time_col_name <- function(df) {
  if ("date" %in% names(df)) return("date")
  if ("when" %in% names(df)) return("when")
  if ("time" %in% names(df)) return("time")
  if ("datetime" %in% names(df)) return("datetime")
  NULL
}

variables <- c(
  "temperature" = "temperature",
  "wind_speed" = "wind_speed",
  "wind_dir" = "wind_dir",
  "pressure" = "pressure",
  "precipitation" = "precipitation"
)

ui <- fluidPage(
  titlePanel("MacLeish Weather: Time Series"),
  sidebarLayout(
    sidebarPanel(
      selectInput("station", "Weather station:", choices = c("whately_2015", "orchard_2015"), selected = "whately_2015"),
      dateRangeInput("dates", "Date range:", start = as.Date("2015-01-01"), end = as.Date("2015-12-31"),
                     min = as.Date("2015-01-01"), max = as.Date("2015-12-31")),
      # Choices will be populated dynamically based on the selected dataset
      selectInput("variable", "Variable:", choices = NULL)
    ),
    mainPanel(
      plotlyOutput("tsPlot", height = "520px")
    )
  )
)

server <- function(input, output, session) {
  # Update variable choices whenever station changes
  observeEvent(input$station, {
    df <- get_station_df(input$station)
    tcol <- time_col_name(df)
    # All numeric columns except the time column
    num_cols <- names(df)[vapply(df, is.numeric, logical(1))]
    if (!is.null(tcol)) num_cols <- setdiff(num_cols, tcol)
    # Fallback: if nothing detected, offer all columns except time
    choices <- if (length(num_cols)) num_cols else setdiff(names(df), tcol)
    # Prefer some common variables if available
    preferred <- c("temperature", "wind_speed", "wind_dir", "pressure", "precipitation")
    sel <- intersect(preferred, choices)
    selected <- if (length(sel)) sel[[1]] else choices[[1]]
    updateSelectInput(session, "variable", choices = choices, selected = selected)
  }, ignoreInit = FALSE)

  data_sel <- reactive({
    df <- get_station_df(input$station)
    tcol <- time_col_name(df)
    validate(need(!is.null(tcol), "Can't find a time column (date/when/time) in this dataset."))
    # Ensure comparison works: convert input dates to POSIXct bounds
    start_dt <- as.POSIXct(input$dates[1], tz = attr(df[[tcol]], "tzone", exact = TRUE))
    end_dt <- as.POSIXct(input$dates[2] + 1, tz = attr(df[[tcol]], "tzone", exact = TRUE)) - seconds(1)
    df <- df %>% filter(.data[[tcol]] >= start_dt, .data[[tcol]] <= end_dt)
    validate(need(nrow(df) > 0, "No rows in the selected date range."))
    df
  })

  output$tsPlot <- renderPlotly({
    df <- data_sel()
    var <- req(input$variable)
    validate(need(var %in% names(df), sprintf("Variable '%s' not found in data.", var)))
    tcol <- time_col_name(df)
    p <- ggplot(df, aes(x = .data[[tcol]], y = .data[[var]])) +
      theme_minimal(base_size = 14) +
      labs(x = "Date", y = var, title = paste(input$station, var))
    if (isTRUE(input$showPoints)) {
      p <- p + geom_point(size = 0.8, alpha = 0.7, na.rm = TRUE)
    }
    p <- p + geom_line(na.rm = TRUE, color = "#2c7fb8")
    ggplotly(p) %>% layout(legend = list(orientation = "h", x = 0, y = -0.2))
  })

}

shinyApp(ui, server)
