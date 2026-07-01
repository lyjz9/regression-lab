# Project 2 ------------------------------------------------------------------
# Goal: estimate a multiple regression model from environmental variables,
# gene indicators, and interaction terms.

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
    if (dir.exists(file.path(current, "data", "raw"))) return(current)
    parent <- dirname(current)
    if (identical(parent, current)) {
      stop("Could not find repository root. Please run this script from inside the repo.")
    }
    current <- parent
  }
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
dir.create(fig_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

data_path <- file.path(repo_root, "data", "raw", "project2", "P2_117453.csv")
Dat <- read_csv(data_path, show_col_types = FALSE)

# Missing-value check --------------------------------------------------------
missing_summary <- tibble(
  variable = names(Dat),
  missing_count = sapply(Dat, function(x) sum(is.na(x))),
  missing_fraction = sapply(Dat, function(x) mean(is.na(x)))
)
write_csv(missing_summary, file.path(results_dir, "project2_missing_summary.csv"))

# Baseline environmental model ----------------------------------------------
env_model <- lm(Y ~ E1 + E2 + E3 + E4, data = Dat)
capture.output(summary(env_model), file = file.path(results_dir, "project2_environmental_model_summary.txt"))
capture.output(anova(env_model), file = file.path(results_dir, "project2_environmental_model_anova.txt"))

# Box-Cox transformation search ---------------------------------------------
# Box-Cox requires positive response values. This dataset has positive Y values.
bc <- MASS::boxcox(env_model, lambda = seq(-2, 2, by = 0.05), plotit = FALSE)
best_lambda <- bc$x[which.max(bc$y)]
write_csv(tibble(best_lambda = best_lambda), file.path(results_dir, "project2_boxcox_best_lambda.csv"))

boxcox_df <- tibble(lambda = bc$x, log_likelihood = bc$y)
boxcox_plot <- ggplot(boxcox_df, aes(x = lambda, y = log_likelihood)) +
  geom_line() +
  geom_vline(xintercept = best_lambda, linetype = "dashed") +
  labs(
    title = "Project 2: Box-Cox Transformation Search",
    subtitle = paste("Best lambda on grid:", round(best_lambda, 3)),
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
Dat <- Dat %>% mutate(Y_15 = Y^1.5)

# Correlation screen ---------------------------------------------------------
independent_vars <- setdiff(names(Dat), c("Y", "Y_15"))
correlation_screen <- tibble(
  variable = independent_vars,
  cor_with_Y = sapply(independent_vars, function(v) cor(Dat[[v]], Dat$Y)),
  cor_with_Y_15 = sapply(independent_vars, function(v) cor(Dat[[v]], Dat$Y_15))
) %>%
  arrange(desc(abs(cor_with_Y_15)))

write_csv(correlation_screen, file.path(results_dir, "project2_correlation_screen.csv"))

# Reported final model -------------------------------------------------------
final_model <- lm(Y_15 ~ E1 + E3 + G14:G19, data = Dat)
capture.output(summary(final_model), file = file.path(results_dir, "project2_final_model_summary.txt"))
capture.output(anova(final_model), file = file.path(results_dir, "project2_final_model_anova.txt"))
write_csv(tidy(final_model, conf.int = TRUE), file.path(results_dir, "project2_final_model_coefficients.csv"))
write_csv(glance(final_model), file.path(results_dir, "project2_final_model_metrics.csv"))

# Candidate model comparison -------------------------------------------------
model_candidates <- list(
  env_E1_E3 = lm(Y_15 ~ E1 + E3, data = Dat),
  env_plus_G14_G19_interaction = lm(Y_15 ~ E1 + E3 + G14:G19, data = Dat),
  env_plus_gene_main_effects = lm(Y_15 ~ E1 + E3 + G14 + G19, data = Dat),
  env_plus_gene_main_and_interaction = lm(Y_15 ~ E1 + E3 + G14 + G19 + G14:G19, data = Dat),
  full_environmental = lm(Y_15 ~ E1 + E2 + E3 + E4, data = Dat)
)

candidate_summary <- tibble(
  model_name = names(model_candidates),
  adj_r_squared = sapply(model_candidates, function(m) summary(m)$adj.r.squared),
  bic = sapply(model_candidates, BIC),
  aic = sapply(model_candidates, AIC)
) %>% arrange(desc(adj_r_squared))

write_csv(candidate_summary, file.path(results_dir, "project2_candidate_model_comparison.csv"))

# Interaction scans ----------------------------------------------------------
# These scans are intentionally saved as diagnostic tables. They help show how
# the selected G14:G19 interaction compares with other two-way interaction terms.
base_terms <- c("E1", "E3")
gene_vars <- paste0("G", 1:20)
env_vars <- paste0("E", 1:4)

gene_gene_pairs <- combn(gene_vars, 2, simplify = FALSE)
gene_gene_scan <- bind_rows(lapply(
  gene_gene_pairs,
  scan_pair_interaction,
  data = Dat,
  response_expr = "Y_15",
  base_terms = base_terms
)) %>% arrange(p_value)

write_csv(gene_gene_scan, file.path(results_dir, "project2_gene_gene_interaction_scan.csv"))

gene_environment_pairs <- unlist(lapply(env_vars, function(e) {
  lapply(gene_vars, function(g) c(e, g))
}), recursive = FALSE)

gene_environment_scan <- bind_rows(lapply(
  gene_environment_pairs,
  scan_pair_interaction,
  data = Dat,
  response_expr = "Y_15",
  base_terms = base_terms
)) %>% arrange(p_value)

write_csv(gene_environment_scan, file.path(results_dir, "project2_gene_environment_interaction_scan.csv"))

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

# Simple coefficient plot for final model -----------------------------------
coef_plot_data <- tidy(final_model, conf.int = TRUE) %>%
  filter(term != "(Intercept)")

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
