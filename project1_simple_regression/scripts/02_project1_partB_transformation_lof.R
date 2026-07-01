# Project 1 Part B -----------------------------------------------------------
# Goal: explore transformations, fit y^2 ~ 1/x, and perform an approximate
# lack-of-fit test by binning near-repeated x-values.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
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

lack_of_fit_test <- function(data, x_col, y_col, bin_width = 0.1) {
  # Approximate lack-of-fit test:
  # 1. Bin near-repeated x values.
  # 2. Compare a linear model to a more flexible model with one mean per bin.
  # A high p-value suggests no significant lack of fit.
  dat <- data %>%
    mutate(
      x_for_bin = .data[[x_col]],
      y_for_model = .data[[y_col]],
      x_bin = round(x_for_bin / bin_width) * bin_width,
      x_bin_factor = factor(x_bin)
    )

  linear_model <- lm(y_for_model ~ x_for_bin, data = dat)
  saturated_bin_model <- lm(y_for_model ~ x_bin_factor, data = dat)

  anova(linear_model, saturated_bin_model)
}

repo_root <- find_repo_root()
project_dir <- file.path(repo_root, "project1_simple_regression")
fig_dir <- file.path(project_dir, "figures")
results_dir <- file.path(project_dir, "results")
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

data_path <- file.path(repo_root, "data", "raw", "project1", "117453_partB.csv")
partB_data <- read_csv(data_path, show_col_types = FALSE)

# Original scatterplot -------------------------------------------------------
scatter_original <- ggplot(partB_data, aes(x = x, y = y)) +
  geom_point(alpha = 0.65) +
  labs(
    title = "Project 1 Part B: Scatterplot Before Transformation",
    x = "x",
    y = "y"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(fig_dir, "partB_scatter_before_transformation.png"),
  plot = scatter_original,
  width = 8,
  height = 5,
  dpi = 300
)

# Transformation used in the report -----------------------------------------
transformed_data <- partB_data %>%
  mutate(
    x_trans = 1 / x,
    y_trans = y^2
  )

partB_model <- lm(y_trans ~ x_trans, data = transformed_data)

capture.output(summary(partB_model), file = file.path(results_dir, "partB_transformed_model_summary.txt"))
capture.output(anova(partB_model), file = file.path(results_dir, "partB_transformed_anova.txt"))
write_csv(glance(partB_model), file.path(results_dir, "partB_model_metrics.csv"))
write_csv(tidy(partB_model, conf.int = TRUE, conf.level = 0.95), file.path(results_dir, "partB_coefficients_95ci.csv"))
write_csv(tidy(partB_model, conf.int = TRUE, conf.level = 0.99), file.path(results_dir, "partB_coefficients_99ci.csv"))

# Lack-of-fit test -----------------------------------------------------------
lof_01 <- lack_of_fit_test(transformed_data, x_col = "x_trans", y_col = "y_trans", bin_width = 0.1)
lof_03 <- lack_of_fit_test(transformed_data, x_col = "x_trans", y_col = "y_trans", bin_width = 0.3)

capture.output(lof_01, file = file.path(results_dir, "partB_lack_of_fit_bin_0_1.txt"))
capture.output(lof_03, file = file.path(results_dir, "partB_lack_of_fit_bin_0_3.txt"))

# Optional comparison table for common transformations -----------------------
model_comparison <- tibble(
  model_name = c("original_y_x", "log_y_x", "sqrt_y_x", "y2_inv_x"),
  formula = c("y ~ x", "log(y) ~ x", "sqrt(y) ~ x", "I(y^2) ~ I(1/x)"),
  r_squared = c(
    summary(lm(y ~ x, data = partB_data))$r.squared,
    summary(lm(log(y) ~ x, data = partB_data))$r.squared,
    summary(lm(sqrt(y) ~ x, data = partB_data))$r.squared,
    summary(partB_model)$r.squared
  ),
  adj_r_squared = c(
    summary(lm(y ~ x, data = partB_data))$adj.r.squared,
    summary(lm(log(y) ~ x, data = partB_data))$adj.r.squared,
    summary(lm(sqrt(y) ~ x, data = partB_data))$adj.r.squared,
    summary(partB_model)$adj.r.squared
  ),
  bic = c(
    BIC(lm(y ~ x, data = partB_data)),
    BIC(lm(log(y) ~ x, data = partB_data)),
    BIC(lm(sqrt(y) ~ x, data = partB_data)),
    BIC(partB_model)
  )
)

write_csv(model_comparison, file.path(results_dir, "partB_transformation_comparison.csv"))

# Residual plot after transformation -----------------------------------------
residual_plot <- ggplot(
  data.frame(fitted = fitted(partB_model), residuals = resid(partB_model)),
  aes(x = fitted, y = residuals)
) +
  geom_point(alpha = 0.65) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title = "Project 1 Part B: Residual Plot After Transformation",
    x = "Fitted values",
    y = "Residuals"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(fig_dir, "partB_residual_after_transformation.png"),
  plot = residual_plot,
  width = 8,
  height = 5,
  dpi = 300
)

# Transformed regression plot ------------------------------------------------
transformed_plot <- ggplot(transformed_data, aes(x = x_trans, y = y_trans)) +
  geom_point(alpha = 0.65) +
  geom_smooth(method = "lm", se = FALSE, linetype = "dashed") +
  labs(
    title = "Project 1 Part B: Regression After Transformation",
    subtitle = "Model: y^2 ~ 1/x",
    x = "1 / x",
    y = "y^2"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(fig_dir, "partB_transformed_regression.png"),
  plot = transformed_plot,
  width = 8,
  height = 5,
  dpi = 300
)

# Binned data plot -----------------------------------------------------------
binned_data <- transformed_data %>%
  mutate(x_bin = round(x_trans / 0.1) * 0.1) %>%
  group_by(x_bin) %>%
  summarize(mean_y_trans = mean(y_trans), n = n(), .groups = "drop")

binned_plot <- ggplot(binned_data, aes(x = x_bin, y = mean_y_trans)) +
  geom_point(aes(size = n), alpha = 0.75) +
  geom_line() +
  labs(
    title = "Project 1 Part B: Binned Transformed Data",
    subtitle = "Point size shows number of observations per bin",
    x = "Binned 1/x",
    y = "Mean y^2"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(fig_dir, "partB_binned_transformed_data.png"),
  plot = binned_plot,
  width = 8,
  height = 5,
  dpi = 300
)

message("Project 1 Part B complete. Outputs saved to: ", results_dir)
