library(rsconnect)

# Resolve the app directory so this works from the repo root or this folder
cwd <- normalizePath(".")
appDir <- if (file.exists(file.path(cwd, "app.R"))) cwd else normalizePath(file.path(cwd, "Weather-Time-Series"), mustWork = TRUE)

# Collect vendored data files if present
data_files <- c(
    file.path("data", "whately_2015.rds"),
    file.path("data", "orchard_2015.rds")
)
data_files <- data_files[file.exists(file.path(appDir, data_files))]

bundle_files <- c("app.R", data_files)

message("Working directory: ", cwd)
message("Deploying from appDir: ", appDir)
message("Bundling files: ", paste(bundle_files, collapse = ", "))

rsconnect::deployApp(
    appDir = appDir,
    appFiles = bundle_files,
    appPrimaryDoc = "app.R",
    appName = "Weather-Time-Series",
    launch.browser = TRUE
)
library(rsconnect)
appDir <- paste0(normalizePath("."), '/Weather-Time-Series')
message("Deploying Weather-Time-Series app from: ", appDir)
rsconnect::deployApp(appDir,
    appFiles = c("app.R"),
    appPrimaryDoc = "app.R",
    appName = "Weather-Time-Series",
    launch.browser = TRUE
)
