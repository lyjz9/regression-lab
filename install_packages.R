# Install the R packages needed for the analysis scripts.
# Run from the repository root with:
# source("install_packages.R")

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
  install.packages(missing_packages, dependencies = TRUE)
}

invisible(lapply(packages, library, character.only = TRUE))
