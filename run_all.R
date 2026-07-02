# Run all project scripts from the repository root.
# Usage:
# source("install_packages.R")
# source("run_all.R")

project_scripts <- c(
  "project1_simple_regression/scripts/01_project1_partA_imputation_regression.R",
  "project1_simple_regression/scripts/02_project1_partB_transformation_lof.R",
  "project2_multiple_regression/scripts/03_project2_multiple_regression.R"
)

missing_scripts <- project_scripts[!file.exists(project_scripts)]
if (length(missing_scripts) > 0) {
  stop(
    paste("Missing analysis script(s):", paste(missing_scripts, collapse = "\n"), sep = "\n"),
    call. = FALSE
  )
}

for (script in project_scripts) {
  message("\nRunning: ", script)
  source(script)
}

message("\nAll regression lab scripts completed.")
