# Run all project scripts from the repository root.

project_scripts <- c(
  "project1_simple_regression/scripts/01_project1_partA_imputation_regression.R",
  "project1_simple_regression/scripts/02_project1_partB_transformation_lof.R",
  "project2_multiple_regression/scripts/03_project2_multiple_regression.R"
)

for (script in project_scripts) {
  source(script)
}
