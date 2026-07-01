# Project 1 Part B -----------------------------------------------------------
# Fit the selected transformed model y^2 ~ 1/x and run an approximate
# lack-of-fit check by binning near-repeated transformed x-values.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
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
    stop(paste0(label, " is missing required column(s): ", paste(missing, collapse = ", ")), call. = FALSE)
  }
}

reset_output_dir <- function(path, prefix) {
  dir.create(path, showWarnings = FALSE, recursive = TRUE)
  old_files <- list.files(path, all.files = TRUE, full.names = TRUE, no.. = TRUE)
  old_files <- old_files[basename(old_files) != ".gitkeep" & startsWith(basename(old_files), prefix)]
  if (length(old_files) > 0) unlink(old_files, recursive = TRUE)
}

lack_of_fit_test <- function(data, x_col, y_col, bin_width) {
  dat <- data %>%
    filter(!is.na(.data[[x_col]]), !is.na(.data[[y_col]])) %>%
    mutate(
      x_for_bin = .data[[x_col]],
      y_for_model = .data[[y_col]],
      x_bin = round(x_for_bin / bin_width) * bin_width,
      x_bin_factor = factor(x_bin)
    )

  if (nlevels(dat$x_bin_factor) < 2) {
    stop("Lack-of-fit test needs at least two populated x bins.", call. = FALSE)
  }

  # Compare a straight-line trend across binned x-values with a model that
  # allows a separate mean for each bin.
  linear_model <- lm(y_for_model ~ x_bin, data = dat)
  binned_model <- lm(y_for_model ~ x_bin_factor, data = dat)
  anova(linear_model, binned_model)
}

safe_model_metrics <- function(model_name, formula_text, fit) {
  tibble(
    model_name = model_name,
    formula = formula_text,
    r_squared = summary(fit)$r.squared,
    adj_r_squared = summary(fit)$adj.r.squared,
    bic = BIC(fit),
    aic = AIC(fit)
  )
}

repo_root <- find_repo_root()
project_dir <- file.path(repo_root, "project1_simple_regression")
fig_dir <- file.path(project_dir, "figures")
results_dir <- file.path(project_dir, "results")
reset_output_dir(fig_dir, "partB_")
reset_output_dir(results_dir, "partB_")

data_path <- file.path(repo_root, "data", "raw", "project1", "117453_partB.csv")
require_files(data_path)

partB_data <- read_csv(data_path, na = c("", "NA", "NaN"), show_col_types = FALSE)
require_columns(partB_data, c("ID", "x", "y"), "Project 1 Part B file")
if (!is.numeric(partB_data$x) || !is.numeric(partB_data$y)) {
  stop("Project 1 Part B expects numeric x and y columns.", call. = FALSE)
}

missing_summary <- tibble(
  variable = names(partB_data),
  missing_count = sapply(partB_data, function(col) sum(is.na(col))),
  missing_fraction = sapply(partB_data, function(col) mean(is.na(col)))
)
write_csv(missing_summary, file.path(results_dir, "partB_missing_summary.csv"))

analysis_data <- partB_data %>% filter(!is.na(x), !is.na(y))
if (nrow(analysis_data) == 0) stop("No complete x/y rows are available for Project 1 Part B.", call. = FALSE)
if (any(analysis_data$x == 0)) stop("Project 1 Part B cannot use 1/x because at least one x value is zero.", call. = FALSE)
if (any(analysis_data$y <= 0)) stop("Project 1 Part B comparison models require positive y values.", call. = FALSE)

# Original scatterplot -------------------------------------------------------
scatter_original <- ggplot(analysis_data, aes(x = x, y = y)) +
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

# Report-selected transformation --------------------------------------------
transformed_data <- analysis_data %>%
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

lof_summary <- tibble(
  bin_width = c(0.1, 0.3),
  p_value = c(as.numeric(lof_01[2, "Pr(>F)"]), as.numeric(lof_03[2, "Pr(>F)"]))
)
write_csv(lof_summary, file.path(results_dir, "partB_lack_of_fit_summary.csv"))

# Comparison table for common transformations --------------------------------
fit_original <- lm(y ~ x, data = analysis_data)
fit_log <- lm(log(y) ~ x, data = analysis_data)
fit_sqrt <- lm(sqrt(y) ~ x, data = analysis_data)

model_comparison <- bind_rows(
  safe_model_metrics("original_y_x", "y ~ x", fit_original),
  safe_model_metrics("log_y_x", "log(y) ~ x", fit_log),
  safe_model_metrics("sqrt_y_x", "sqrt(y) ~ x", fit_sqrt),
  safe_model_metrics("y2_inv_x", "I(y^2) ~ I(1/x)", partB_model)
) %>% arrange(desc(adj_r_squared))

write_csv(model_comparison, file.path(results_dir, "partB_transformation_comparison.csv"))

writeLines(
  c(
    "Project 1 Part B notes",
    "Reported course result was approximately: y^2 = 4.8492 + 3.4611 * (1/x).",
    "Reported lack-of-fit p-value was about 0.9938 and R-squared was about 0.6698.",
    "The lack-of-fit test here is approximate because near-repeated x-values are created by binning transformed x."
  ),
  con = file.path(results_dir, "partB_reported_result_note.txt")
)

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
