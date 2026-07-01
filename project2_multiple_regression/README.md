# Project 2: Multiple Regression with Synthetic Indicators

This folder contains a multiple-regression workflow using a synthetic educational dataset. The dataset includes one response variable, four environmental variables, and synthetic gene-indicator variables. It is not real medical or genetic research data.

## Workflow

The script:

1. Checks missingness.
2. Fits an environmental baseline model.
3. Runs a Box-Cox transformation search.
4. Keeps the report-selected `Y^1.5` transformation.
5. Fits the final model `Y_15 ~ E1 + E3 + G14:G19`.
6. Saves final model summaries, ANOVA output, coefficients, candidate model comparisons, interaction scans, and diagnostic plots.

## Reported final model

Reported course-result reference:

```text
Y^1.5 = 23.035 + 1.730*E1 + 1.608*E3 + 1.803*(G14:G19) + error
Adjusted R-squared about 0.4241
```

The script saves interaction scans as diagnostic outputs but does not silently replace the report-selected model.

## Run

From the repository root:

```r
source("project2_multiple_regression/scripts/03_project2_multiple_regression.R")
```

Generated files are saved under `project2_multiple_regression/results/` and `project2_multiple_regression/figures/`.
