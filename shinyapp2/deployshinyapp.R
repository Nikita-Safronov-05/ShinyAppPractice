library(rsconnect)
appDir <- normalizePath(".")
message("Deploying app from: ", appDir)
rsconnect::deployApp(appDir,
					 appFiles = c("shinyapp2.R"),
					 appPrimaryDoc = "shinyapp2.R",
					 appName = "shinyapp2",
					 launch.browser = TRUE)