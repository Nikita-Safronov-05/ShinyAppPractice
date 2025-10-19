# Deploy Penguins-Analysis-App to shinyapps.io
if (!requireNamespace("rsconnect", quietly = TRUE)) install.packages("rsconnect", repos = "https://cloud.r-project.org")
library(rsconnect)
appDir <- normalizePath(".")
message("Deploying Penguins-Analysis-App from: ", appDir)
rsconnect::deployApp(appDir,
  appFiles = c("app.R"),
  appPrimaryDoc = "app.R",
  appName = "Penguins-Analysis-App",
  launch.browser = TRUE
)
