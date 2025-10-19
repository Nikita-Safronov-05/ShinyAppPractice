library(rsconnect)
appDir <- normalizePath(".")
message("Deploying Five-Widgets app from: ", appDir)
rsconnect::deployApp(appDir,
	appFiles = c("app.R"),
	appPrimaryDoc = "app.R",
	appName = "Five-Widgets",
	launch.browser = TRUE
)