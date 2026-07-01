# Project 1 Part A -----------------------------------------------------------
# Goal: merge IV and DV files by subject ID, handle missing values with MICE,
# and fit a one-predictor linear regression model.

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
    if (dir.exists(file.path(current, "data", "raw"))) return(current)
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Could not find repository root. Please run this script from inside the repo.")
    }
    current <- parent
  }
}

repo_root <- find_repo_root()
project_dir <- file.path(repo_root, "project1_simple_regression")
fig_dir <- file.path(project_dir, "figures")
results_dir <- file.path(project_dir, "results")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

iv_path <- file.path(repo_root, "data", "raw", "project1", "117453_IV.csv")
dv_path <- file.path(repo_root, "data", "raw", "project1", "117453_DV.csv")

iv_data <- read_csv(iv_path, show_col_types = FALSE)
dv_data <- read_csv(dv_path, show_col_types = FALSE)

# Full join keeps all subject IDs that appear in either file.
merged_data <- full_join(iv_data, dv_data, by = "ID") %>% arrange(ID)

missing_summary <- tibble(
  metric = c(
    "rows_after_merge",
    "complete_IV_and_DV",
    "missing_IV_only",
    "missing_DV_only",
    "missing_both_IV_and_DV",
    "at_least_one_variable_present"
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

# Rows with both IV and DV missing do not contain information for regression.
analysis_data <- merged_data %>% filter(!(is.na(IV) & is.na(DV)))

# MICE imputation ------------------------------------------------------------
# The report used linear regression with bootstrap. In mice, this corresponds
# to method = "norm.boot" for continuous variables.
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
  m = 1,
  maxit = 5,
  method = methods,
  predictorMatrix = predictor_matrix,
  printFlag = FALSE
)

complete_data <- complete(imputed, action = 1)
write_csv(complete_data, file.path(results_dir, "partA_completed_data_after_mice.csv"))

# Linear regression ----------------------------------------------------------
partA_model <- lm(DV ~ IV, data = complete_data)

capture.output(summary(partA_model), file = file.path(results_dir, "partA_model_summary.txt"))
capture.output(anova(partA_model), file = file.path(results_dir, "partA_anova.txt"))

model_metrics <- glance(partA_model)
coef_table <- tidy(partA_model, conf.int = TRUE, conf.level = 0.95)
coef_table_99 <- tidy(partA_model, conf.int = TRUE, conf.level = 0.99)

write_csv(model_metrics, file.path(results_dir, "partA_model_metrics.csv"))
write_csv(coef_table, file.path(results_dir, "partA_coefficients_95ci.csv"))
write_csv(coef_table_99, file.path(results_dir, "partA_coefficients_99ci.csv"))

# Plot regression line -------------------------------------------------------
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
