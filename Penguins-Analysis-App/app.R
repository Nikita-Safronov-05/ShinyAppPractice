# Penguins-Analysis-App

library(shiny)
library(palmerpenguins)
library(dplyr)
library(ggplot2)

attrs <- c("bill_length_mm", "bill_depth_mm", "flipper_length_mm", "body_mass_g")

ui <- fluidPage(
  titlePanel("Penguins Analysis App"),
  sidebarLayout(
    sidebarPanel(
      selectInput("filterBy", "Filter by:", choices = c("All", "Species", "Sex"), selected = "All"),
      uiOutput("filterUI"),
      hr(),
      selectInput("xvar", "X variable:", choices = attrs, selected = "bill_length_mm"),
      selectInput("yvar", "Y variable:", choices = attrs, selected = "flipper_length_mm"),
      checkboxInput("addLM", "Add linear fit", value = FALSE),
      uiOutput("colorUI")
    ),
    mainPanel(
      plotOutput("scatterPlot", height = "500px"),
      br(),
      tableOutput("summaryTable")
    )
  )
)

server <- function(input, output, session) {
  output$filterUI <- renderUI({
    if (input$filterBy == "Species") {
      selectInput("species", "Species:", choices = unique(na.omit(penguins$species)), selected = unique(na.omit(penguins$species))[1])
    } else if (input$filterBy == "Sex") {
      selectInput("sex", "Sex:", choices = unique(na.omit(penguins$sex)), selected = unique(na.omit(penguins$sex))[1])
    } else {
      tags$div("No filter applied")
    }
  })

  output$colorUI <- renderUI({
    if (input$filterBy %in% c("Sex", "Species")) return(NULL)
    selectInput("colorBy", "Color by:", choices = c("Species" = "species", "Sex" = "sex", "None" = "none"), selected = "species")
  })

  colorVar <- reactive({
    if (input$filterBy == "Sex") {
      "species"
    } else if (input$filterBy == "Species") {
      "sex"
    } else {
      if (is.null(input$colorBy)) "species" else input$colorBy
    }
  })

  filtered <- reactive({
    df <- penguins %>% filter(!is.na(.data[[input$xvar]]), !is.na(.data[[input$yvar]]))
    if (input$filterBy == "Species" && !is.null(input$species)) {
      df <- df %>% filter(species == input$species)
    }
    if (input$filterBy == "Sex" && !is.null(input$sex)) {
      df <- df %>% filter(sex == input$sex)
    }
    df
  })

  output$scatterPlot <- renderPlot({
    df <- filtered()
    cv <- colorVar()
    p <- ggplot(df, aes_string(x = input$xvar, y = input$yvar)) + theme_minimal()
    if (cv == "none") {
      p <- p + geom_point(size = 2, alpha = 0.8)
    } else {
      p <- p + geom_point(aes(color = .data[[cv]]), size = 2, alpha = 0.8) +
        labs(color = if (cv == "species") "Species" else "Sex")
    }
    if (input$addLM) p <- p + geom_smooth(method = 'lm', se = FALSE, color = 'black')
    p <- p + theme(
      axis.title = element_text(size = 16),
      axis.text  = element_text(size = 12),
      legend.title = element_text(size = 14),
      legend.text  = element_text(size = 12)
    )
    p
  })

  output$summaryTable <- renderTable({
    df <- filtered()
    if (nrow(df) == 0) return(data.frame(Message = "No rows match the filter"))
    df %>% summarise(
      N = n(),
      across(all_of(c(input$xvar, input$yvar)), list(mean = ~mean(. , na.rm = TRUE), sd = ~sd(. , na.rm = TRUE)))
    ) %>% rename_with(~ gsub("_1", "", .x))
  })
}

shinyApp(ui, server)
