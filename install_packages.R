# Install the R packages needed for the analysis scripts.
# Run from the repository root with:
# source("install_packages.R")

if (is.null(getOption("repos")) || identical(getOption("repos")[["CRAN"]], "@CRAN@")) {
  options(repos = c(CRAN = "https://cloud.r-project.org"))
}

packages <- c(
  "dplyr",
  "readr",
  "ggplot2",
  "mice",
  "MASS",
  "broom",
  "knitr"
)

installed <- rownames(installed.packages())
missing_packages <- setdiff(packages, installed)

if (length(missing_packages) > 0) {
  message("Installing missing package(s): ", paste(missing_packages, collapse = ", "))
  install.packages(missing_packages, dependencies = TRUE)
} else {
  message("All required packages are already installed.")
}

invisible(lapply(packages, library, character.only = TRUE))
message("Packages loaded successfully.")
