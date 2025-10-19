# Widgets included:
# 1) sliderInput: number of observations
# 2) selectInput: distribution type (Normal, Uniform, Exponential)
# 3) numericInput: a distribution parameter (mean / min / rate)
# 4) checkboxInput: whether to show density overlay
# 5) actionButton: resample data
# How to run:
# - In RStudio: open this file and click Run App
# - From an R console: install.packages('shiny') if needed, then run:
#     shiny::runApp('shinyapp1.R')

library(shiny)

ui <- fluidPage(
	titlePanel("Shiny app with 5 widgets"),
	sidebarLayout(
		sidebarPanel(
			sliderInput("n", "Number of observations:",
									min = 10, max = 5000, value = 500, step = 10),
			selectInput("dist", "Distribution:",
									choices = c("Normal", "Uniform", "Exponential"),
									selected = "Normal"),
					# static numeric input for the parameter (avoids startup race)
					numericInput("param", "Parameter:", value = 0, step = 0.1),
					# a short dynamic label explaining the parameter meaning
					htmlOutput("paramLabel"),
			checkboxInput("showDensity", "Show density curve", value = TRUE),
			actionButton("resample", "Resample")
		),
		mainPanel(
			plotOutput("histPlot"),
			br(),
			tableOutput("summaryTable")
		)
	)
)

server <- function(input, output, session) {

	# dynamic helper label explaining the meaning of `param` for the chosen distribution
output$paramLabel <- renderUI({
 	if (input$dist == "Normal") {
 		HTML("<small>Parameter = mean (Normal). Use any real number.</small>")
 	} else if (input$dist == "Uniform") {
 		HTML("<small>Parameter = minimum (Uniform). Maximum will be minimum + 1.</small>")
 	} else {
 		HTML("<small>Parameter = rate (Exponential). Use positive values; defaults to 1 if &le; 0.</small>")
 	}
})

	## Reactive sample generation: use reactiveVal + observeEvent so we
	## wait for the dynamic param input to exist and still react to the
	## Resample button. This avoids a race where eventReactive ran before
	## input$param was available.
	currentSample <- reactiveVal(NULL)

 	observeEvent(list(input$resample, input$param), {
		n <- input$n
		dist <- input$dist
		p <- input$param
		newSamp <- if (dist == "Normal") {
			rnorm(n, mean = p, sd = 1)
		} else if (dist == "Uniform") {
			runif(n, min = p, max = p + 1)
		} else {
			rate <- ifelse(p > 0, p, 1)
			rexp(n, rate = rate)
		}
		currentSample(newSamp)
	}, ignoreInit = FALSE)

	samp <- reactive({
		currentSample()
	})

	output$histPlot <- renderPlot({
		x <- samp()
		# plot histogram using counts (freq = TRUE) so y-axis shows pure counts
		h <- hist(x, breaks = 30, col = "#A6CEE3", border = "white", freq = TRUE,
			 main = paste("Histogram of", input$dist, "(n=", input$n, ")"),
			 xlab = "Value")
		if (input$showDensity) {
			# density gives probability density; scale to counts by multiplying
			# by number of observations and the bin width
			d <- density(x)
			binwidth <- diff(h$breaks)[1]
			lines(d$x, d$y * length(x) * binwidth, col = "#1F78B4", lwd = 2)
		}
	})

	output$summaryTable <- renderTable({
		x <- samp()
		s <- c(Mean = mean(x), SD = sd(x), Median = median(x), Min = min(x), Max = max(x))
		data.frame(Statistic = names(s), Value = as.numeric(s), row.names = NULL)
	})

	output$inputsText <- renderPrint({
		list(
			n = input$n,
			distribution = input$dist,
			parameter = input$param,
			showDensity = input$showDensity,
			lastResample = input$resample
		)
	})
}

shinyApp(ui, server)

