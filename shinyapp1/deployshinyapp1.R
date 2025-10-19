## deployshinyapp1.R
## Robust deploy script for shinyapps.io using rsconnect.
## Usage (interactive):
##   Rscript deployshinyapp1.R
## Non-interactive: set these env vars before running: SHINYAPPS_NAME, SHINYAPPS_TOKEN, SHINYAPPS_SECRET

library(rsconnect)
appDir <- normalizePath(".")
message("Deploying app from: ", appDir)
# Explicitly set appPrimaryDoc to the Shiny file so rsconnect does not try to
# inspect the project for Quarto documents (which requires the 'quarto' CLI).
rsconnect::deployApp(appDir,
					 appFiles = c("shinyapp1.R"),
					 appPrimaryDoc = "shinyapp1.R",
					 appName = "shinyapp1",
					 launch.browser = TRUE)