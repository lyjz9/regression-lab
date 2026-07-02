# Project 2 ------------------------------------------------------------------
# Multiple regression with synthetic educational variables. The analysis keeps
# the report-selected transformation Y^1.5 and final model:
# Y_15 ~ E1 + E3 + G14:G19.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
  library(ggplot2)
  library(MASS)
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
        "Expected raw data under data/raw/project2/.",
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

reset_output_dir <- function(path) {
  dir.create(path, showWarnings = FALSE, recursive = TRUE)
  old_files <- list.files(path, all.files = TRUE, full.names = TRUE, no.. = TRUE)
  old_files <- old_files[basename(old_files) != ".gitkeep"]
  if (length(old_files) > 0) unlink(old_files, recursive = TRUE)
}

scan_pair_interaction <- function(data, response_expr, base_terms, pair) {
  interaction_term <- paste(pair, collapse = ":")
  formula_text <- paste(response_expr, "~", paste(c(base_terms, interaction_term), collapse = " + "))
  model <- lm(as.formula(formula_text), data = data)
  coef_row <- tidy(model) %>% filter(term == interaction_term)

  if (nrow(coef_row) == 0) {
    return(tibble(
      interaction = interaction_term,
      estimate = NA_real_,
      p_value = NA_real_,
      adj_r_squared = summary(model)$adj.r.squared,
      bic = BIC(model)
    ))
  }

  tibble(
    interaction = interaction_term,
    estimate = coef_row$estimate,
    p_value = coef_row$p.value,
    adj_r_squared = summary(model)$adj.r.squared,
    bic = BIC(model)
  )
}

repo_root <- find_repo_root()
project_dir <- file.path(repo_root, "project2_multiple_regression")
fig_dir <- file.path(project_dir, "figures")
results_dir <- file.path(project_dir, "results")
reset_output_dir(fig_dir)
reset_output_dir(results_dir)

data_path <- file.path(repo_root, "data", "raw", "project2", "P2_117453.csv")
require_files(data_path)

Dat <- read_csv(data_path, na = c("", "NA", "NaN"), show_col_types = FALSE)
env_vars <- paste0("E", 1:4)
gene_vars <- paste0("G", 1:20)
required_cols <- c("Y", env_vars, gene_vars)
require_columns(Dat, required_cols, "Project 2 file")

non_numeric <- required_cols[!sapply(Dat[required_cols], is.numeric)]
if (length(non_numeric) > 0) {
  stop(paste0("Project 2 expects numeric columns: ", paste(non_numeric, collapse = ", ")), call. = FALSE)
}

set.seed(315)

# Missing-value check --------------------------------------------------------
missing_summary <- tibble(
  variable = names(Dat),
  missing_count = sapply(Dat, function(x) sum(is.na(x))),
  missing_fraction = sapply(Dat, function(x) mean(is.na(x)))
)
write_csv(missing_summary, file.path(results_dir, "project2_missing_summary.csv"))

analysis_data <- Dat[complete.cases(Dat[required_cols]), ]
row_summary <- tibble(
  metric = c("rows_original", "rows_after_complete_case_filter", "rows_removed_for_missing_required_values"),
  value = c(nrow(Dat), nrow(analysis_data), nrow(Dat) - nrow(analysis_data))
)
write_csv(row_summary, file.path(results_dir, "project2_row_summary.csv"))

if (nrow(analysis_data) == 0) stop("No complete Project 2 rows are available for modeling.", call. = FALSE)
if (any(analysis_data$Y <= 0)) stop("Box-Cox and Y^1.5 require positive Y values.", call. = FALSE)

# Baseline environmental model ----------------------------------------------
env_model <- lm(Y ~ E1 + E2 + E3 + E4, data = analysis_data)
capture.output(summary(env_model), file = file.path(results_dir, "project2_environmental_model_summary.txt"))
capture.output(anova(env_model), file = file.path(results_dir, "project2_environmental_model_anova.txt"))
write_csv(glance(env_model), file.path(results_dir, "project2_environmental_model_metrics.csv"))

# Box-Cox transformation search ---------------------------------------------
bc <- MASS::boxcox(env_model, lambda = seq(-2, 2, by = 0.05), plotit = FALSE)
best_lambda <- bc$x[which.max(bc$y)]
write_csv(tibble(best_lambda = best_lambda), file.path(results_dir, "project2_boxcox_best_lambda.csv"))

boxcox_df <- tibble(lambda = bc$x, log_likelihood = bc$y)
boxcox_plot <- ggplot(boxcox_df, aes(x = lambda, y = log_likelihood)) +
  geom_line() +
  geom_vline(xintercept = best_lambda, linetype = "dashed") +
  geom_vline(xintercept = 1.5, linetype = "dotted") +
  labs(
    title = "Project 2: Box-Cox Transformation Search",
    subtitle = paste("Best lambda on grid:", round(best_lambda, 3), "| report-selected lambda: 1.5"),
    x = "Lambda",
    y = "Log-likelihood"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(fig_dir, "project2_boxcox_plot.png"),
  plot = boxcox_plot,
  width = 8,
  height = 5,
  dpi = 300
)

# The original report selected lambda = 1.5.
analysis_data <- analysis_data %>% mutate(Y_15 = Y^1.5)

# Correlation screen ---------------------------------------------------------
independent_vars <- setdiff(names(analysis_data), c("Y", "Y_15"))
correlation_screen <- tibble(
  variable = independent_vars,
  cor_with_Y = sapply(independent_vars, function(v) cor(analysis_data[[v]], analysis_data$Y, use = "complete.obs")),
  cor_with_Y_15 = sapply(independent_vars, function(v) cor(analysis_data[[v]], analysis_data$Y_15, use = "complete.obs"))
) %>%
  arrange(desc(abs(cor_with_Y_15)))

write_csv(correlation_screen, file.path(results_dir, "project2_correlation_screen.csv"))

# Report-selected final model ------------------------------------------------
final_model <- lm(Y_15 ~ E1 + E3 + G14:G19, data = analysis_data)
capture.output(summary(final_model), file = file.path(results_dir, "project2_final_model_summary.txt"))
capture.output(anova(final_model), file = file.path(results_dir, "project2_final_model_anova.txt"))
write_csv(tidy(final_model, conf.int = TRUE), file.path(results_dir, "project2_final_model_coefficients.csv"))
write_csv(glance(final_model), file.path(results_dir, "project2_final_model_metrics.csv"))

# Candidate model comparison -------------------------------------------------
model_candidates <- list(
  env_E1_E3 = lm(Y_15 ~ E1 + E3, data = analysis_data),
  env_plus_G14_G19_interaction = lm(Y_15 ~ E1 + E3 + G14:G19, data = analysis_data),
  env_plus_gene_main_effects = lm(Y_15 ~ E1 + E3 + G14 + G19, data = analysis_data),
  env_plus_gene_main_and_interaction = lm(Y_15 ~ E1 + E3 + G14 + G19 + G14:G19, data = analysis_data),
  full_environmental = lm(Y_15 ~ E1 + E2 + E3 + E4, data = analysis_data)
)

candidate_summary <- tibble(
  model_name = names(model_candidates),
  formula = sapply(model_candidates, function(m) paste(deparse(formula(m)), collapse = " ")),
  adj_r_squared = sapply(model_candidates, function(m) summary(m)$adj.r.squared),
  bic = sapply(model_candidates, BIC),
  aic = sapply(model_candidates, AIC)
) %>%
  arrange(desc(adj_r_squared))

write_csv(candidate_summary, file.path(results_dir, "project2_candidate_model_comparison.csv"))

# Interaction scans ----------------------------------------------------------
# These diagnostic scans show how the selected G14:G19 interaction compares
# with other two-way interaction terms. They do not silently replace the
# report-selected model.
base_terms <- c("E1", "E3")

gene_gene_pairs <- combn(gene_vars, 2, simplify = FALSE)
gene_gene_scan <- bind_rows(lapply(
  gene_gene_pairs,
  scan_pair_interaction,
  data = analysis_data,
  response_expr = "Y_15",
  base_terms = base_terms
)) %>%
  arrange(p_value)

write_csv(gene_gene_scan, file.path(results_dir, "project2_gene_gene_interaction_scan.csv"))

gene_environment_pairs <- unlist(lapply(env_vars, function(e) {
  lapply(gene_vars, function(g) c(e, g))
}), recursive = FALSE)

gene_environment_scan <- bind_rows(lapply(
  gene_environment_pairs,
  scan_pair_interaction,
  data = analysis_data,
  response_expr = "Y_15",
  base_terms = base_terms
)) %>%
  arrange(p_value)

write_csv(gene_environment_scan, file.path(results_dir, "project2_gene_environment_interaction_scan.csv"))

writeLines(
  c(
    "Project 2 notes",
    "This is a synthetic educational dataset, not real medical or genetic research data.",
    "Reported course result was approximately: Y^1.5 = 23.035 + 1.730*E1 + 1.608*E3 + 1.803*(G14:G19) + error.",
    "Reported adjusted R-squared was about 0.4241.",
    "The script reports Box-Cox search output but keeps the report-selected Y^1.5 transformation and final model."
  ),
  con = file.path(results_dir, "project2_reported_result_note.txt")
)

# Diagnostic plots -----------------------------------------------------------
original_residual_plot <- ggplot(
  data.frame(fitted = fitted(env_model), residuals = resid(env_model)),
  aes(x = fitted, y = residuals)
) +
  geom_point(alpha = 0.65) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title = "Project 2: Residual Plot Before Transformation",
    x = "Fitted values",
    y = "Residuals"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(fig_dir, "project2_residual_before_transformation.png"),
  plot = original_residual_plot,
  width = 8,
  height = 5,
  dpi = 300
)

final_residual_plot <- ggplot(
  data.frame(fitted = fitted(final_model), residuals = resid(final_model)),
  aes(x = fitted, y = residuals)
) +
  geom_point(alpha = 0.65) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  labs(
    title = "Project 2: Residual Plot After Y^1.5 Transformation",
    subtitle = "Final model: Y^1.5 ~ E1 + E3 + G14:G19",
    x = "Fitted values",
    y = "Residuals"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(fig_dir, "project2_residual_after_transformation.png"),
  plot = final_residual_plot,
  width = 8,
  height = 5,
  dpi = 300
)

coef_plot_data <- tidy(final_model, conf.int = TRUE) %>% filter(term != "(Intercept)")

coef_plot <- ggplot(coef_plot_data, aes(x = reorder(term, estimate), y = estimate)) +
  geom_point() +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.15) +
  coord_flip() +
  labs(
    title = "Project 2: Final Model Coefficients",
    x = "Term",
    y = "Estimate with 95% confidence interval"
  ) +
  theme_minimal()

ggsave(
  filename = file.path(fig_dir, "project2_final_model_coefficients.png"),
  plot = coef_plot,
  width = 8,
  height = 5,
  dpi = 300
)

message("Project 2 complete. Outputs saved to: ", results_dir)
