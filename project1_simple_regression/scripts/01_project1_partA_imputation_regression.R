# Project 1 Part A -----------------------------------------------------------
# Merge IV and DV by ID, summarize missingness, impute missing values with
# MICE, and fit the one-predictor regression model DV ~ IV.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(mice)
  library(broom)
})

find_repo_root <- function(start = getwd()) {
  current <- normalizePath(start, winslash = "/", mustWork = TRUE)
  repeat {
    if (file.exists(file.path(current, "run_all.R")) && dir.exists(file.path(current, "data"))) {
      return(current)
    }
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Could not find repository root. Run this script from the repo or a subfolder.", call. = FALSE)
    }
    current <- parent
  }
}

require_files <- function(paths) {
  missing <- paths[!file.exists(paths)]
  if (length(missing) > 0) {
    stop(
      paste(
        "Missing required data file(s):",
        paste(missing, collapse = "\n"),
        "Expected raw data under data/raw/project1/.",
        sep = "\n"
      ),
      call. = FALSE
    )
  }
}

require_columns <- function(dat, required, label) {
  missing <- setdiff(required, names(dat))
  if (length(missing) > 0) {
    stop(
      paste0(label, " is missing required column(s): ", paste(missing, collapse = ", ")),
      call. = FALSE
    )
  }
}

reset_output_dir <- function(path, prefix) {
  dir.create(path, showWarnings = FALSE, recursive = TRUE)
  old_files <- list.files(path, all.files = TRUE, full.names = TRUE, no.. = TRUE)
  old_files <- old_files[basename(old_files) != ".gitkeep" & startsWith(basename(old_files), prefix)]
  if (length(old_files) > 0) unlink(old_files, recursive = TRUE)
}

repo_root <- find_repo_root()
project_dir <- file.path(repo_root, "project1_simple_regression")
fig_dir <- file.path(project_dir, "figures")
results_dir <- file.path(project_dir, "results")
reset_output_dir(fig_dir, "partA_")
reset_output_dir(results_dir, "partA_")

iv_path <- file.path(repo_root, "data", "raw", "project1", "117453_IV.csv")
dv_path <- file.path(repo_root, "data", "raw", "project1", "117453_DV.csv")
require_files(c(iv_path, dv_path))

iv_data <- read_csv(iv_path, na = c("", "NA", "NaN"), show_col_types = FALSE)
dv_data <- read_csv(dv_path, na = c("", "NA", "NaN"), show_col_types = FALSE)
require_columns(iv_data, c("ID", "IV"), "Project 1 Part A IV file")
require_columns(dv_data, c("ID", "DV"), "Project 1 Part A DV file")

if (anyDuplicated(iv_data$ID) > 0 || anyDuplicated(dv_data$ID) > 0) {
  stop("Project 1 Part A expects one row per ID in each input file.", call. = FALSE)
}
if (!is.numeric(iv_data$IV) || !is.numeric(dv_data$DV)) {
  stop("Project 1 Part A expects numeric IV and DV columns.", call. = FALSE)
}

# Full join keeps every ID that appears in either file.
merged_data <- full_join(iv_data, dv_data, by = "ID") %>% arrange(ID)

missing_summary <- tibble(
  metric = c(
    "rows_after_merge",
    "complete_IV_and_DV",
    "missing_IV_only",
    "missing_DV_only",
    "missing_both_IV_and_DV",
    "rows_used_after_dropping_both_missing"
  ),
  value = c(
    nrow(merged_data),
    sum(!is.na(merged_data$IV) & !is.na(merged_data$DV)),
    sum(is.na(merged_data$IV) & !is.na(merged_data$DV)),
    sum(!is.na(merged_data$IV) & is.na(merged_data$DV)),
    sum(is.na(merged_data$IV) & is.na(merged_data$DV)),
    sum(!is.na(merged_data$IV) | !is.na(merged_data$DV))
  )
)
write_csv(missing_summary, file.path(results_dir, "partA_missing_summary.csv"))

# Rows with both IV and DV missing do not contain usable information for this
# regression workflow.
analysis_data <- merged_data %>% filter(!(is.na(IV) & is.na(DV)))
if (nrow(analysis_data) == 0) {
  stop("No usable Project 1 Part A rows remain after dropping rows with both IV and DV missing.", call. = FALSE)
}

# MICE imputation ------------------------------------------------------------
# The report used linear regression with bootstrap; in mice this is represented
# by method = "norm.boot" for continuous variables.
set.seed(315)
methods <- make.method(analysis_data)
methods["ID"] <- ""
methods["IV"] <- "norm.boot"
methods["DV"] <- "norm.boot"

predictor_matrix <- make.predictorMatrix(analysis_data)
predictor_matrix["ID", ] <- 0
predictor_matrix[, "ID"] <- 0

imputed <- mice(
  analysis_data,
  m = 5,
  maxit = 5,
  method = methods,
  predictorMatrix = predictor_matrix,
  printFlag = FALSE,
  seed = 315
)

complete_data <- complete(imputed, action = 1)
write_csv(complete_data, file.path(results_dir, "partA_completed_data_after_mice.csv"))

# Linear regression ----------------------------------------------------------
# The plotted/model-summary output uses the first completed dataset. A pooled
# coefficient table is also saved across all five imputations.
partA_model <- lm(DV ~ IV, data = complete_data)
pooled_model <- pool(with(imputed, lm(DV ~ IV)))

capture.output(summary(partA_model), file = file.path(results_dir, "partA_model_summary_first_imputation.txt"))
capture.output(anova(partA_model), file = file.path(results_dir, "partA_anova_first_imputation.txt"))
capture.output(summary(pooled_model), file = file.path(results_dir, "partA_pooled_model_summary.txt"))

write_csv(glance(partA_model), file.path(results_dir, "partA_model_metrics_first_imputation.csv"))
write_csv(tidy(partA_model, conf.int = TRUE, conf.level = 0.95), file.path(results_dir, "partA_coefficients_95ci_first_imputation.csv"))
write_csv(tidy(partA_model, conf.int = TRUE, conf.level = 0.99), file.path(results_dir, "partA_coefficients_99ci_first_imputation.csv"))
write_csv(summary(pooled_model, conf.int = TRUE), file.path(results_dir, "partA_pooled_coefficients.csv"))

writeLines(
  c(
    "Project 1 Part A notes",
    "Reported course result was approximately: DV = 51.4002 + 7.4831 * IV; adjusted R-squared about 0.8589.",
    "This script uses set.seed(315), MICE with norm.boot, and five imputations.",
    "MICE is stochastic, so rerun values can differ slightly from the original report."
  ),
  con = file.path(results_dir, "partA_reported_result_note.txt")
)

# Regression line ------------------------------------------------------------
plot_partA <- ggplot(complete_data, aes(x = IV, y = DV)) +
  geom_point(alpha = 0.65) +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed") +
  labs(
    title = "Project 1 Part A: Linear Regression After Imputation",
    subtitle = "Model: DV ~ IV",
    x = "Independent variable (IV)",
    y = "Dependent variable (DV)"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(fig_dir, "partA_regression_after_imputation.png"),
  plot = plot_partA,
  width = 8,
  height = 5,
  dpi = 300
)

# Residual plot --------------------------------------------------------------
residual_plot <- ggplot(
  data.frame(fitted = fitted(partA_model), residuals = resid(partA_model)),
  aes(x = fitted, y = residuals)
) +
  geom_point(alpha = 0.65) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title = "Project 1 Part A: Residual Plot",
    x = "Fitted values",
    y = "Residuals"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(fig_dir, "partA_residual_plot.png"),
  plot = residual_plot,
  width = 8,
  height = 5,
  dpi = 300
)

message("Project 1 Part A complete. Outputs saved to: ", results_dir)
