# Project 1: One-Predictor Linear Regression

This folder contains two R workflows for a one-predictor regression case study using synthetic educational data.

## Part A: Missing data, imputation, and OLS

The Part A script:

1. Reads `117453_IV.csv` and `117453_DV.csv`.
2. Merges both files by `ID`.
3. Counts missingness.
4. Drops rows where both `IV` and `DV` are missing.
5. Uses MICE imputation with bootstrap linear regression (`norm.boot`).
6. Fits `DV ~ IV`.
7. Saves model summaries, ANOVA output, coefficients, confidence intervals, and diagnostic plots.

Reported course-result reference:

```text
DV = 51.4002 + 7.4831 * IV
Adjusted R-squared about 0.8589
```

MICE is stochastic, so rerun values can differ slightly. The script uses `set.seed(315)` for reproducibility.

## Part B: Transformations and lack-of-fit

The Part B script fits the report-selected transformed model:

```text
y^2 ~ 1/x
```

It also saves a transformation comparison table, residual plot, transformed regression plot, binned plot, and approximate lack-of-fit results using binned near-repeated transformed x-values.

Reported course-result reference:

```text
y^2 = 4.8492 + 3.4611 * (1/x)
Lack-of-fit p-value about 0.9938
R-squared about 0.6698
```

## Run

From the repository root:

```r
source("project1_simple_regression/scripts/01_project1_partA_imputation_regression.R")
source("project1_simple_regression/scripts/02_project1_partB_transformation_lof.R")
```

Generated files are saved under `project1_simple_regression/results/` and `project1_simple_regression/figures/`.
