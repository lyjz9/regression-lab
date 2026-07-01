# Project 1: One-Predictor Linear Regression

This project contains two regression workflows using R.

## Part A: Merging, missing data, imputation, and OLS regression

The Part A data is split across two files: one file contains the independent variable (`IV`) and one file contains the dependent variable (`DV`). The script merges both files by `ID`, summarizes missingness, imputes missing values using the `mice` package, and fits an OLS model.

Reported result from the course report:

```text
DV = 51.4002 + 7.4831 * IV
Adjusted R-squared ≈ 0.8589
```

Because `mice` imputation is stochastic, the exact fitted values may change slightly unless the same seed and imputation settings are used.

## Part B: Transformation search and lack-of-fit testing

The Part B workflow explores transformations of the one-predictor relationship. The selected transformation in the original report was:

```text
y_trans = y^2
x_trans = 1 / x
model: y_trans ~ x_trans
```

Reported result from the course report:

```text
y^2 = 4.8492 + 3.4611 * (1/x)
Lack-of-fit p-value ≈ 0.9938
R-squared ≈ 0.6698
```

## Scripts

Run from the repository root:

```r
source("project1_simple_regression/scripts/01_project1_partA_imputation_regression.R")
source("project1_simple_regression/scripts/02_project1_partB_transformation_lof.R")
```

Generated figures and outputs will be saved in this project folder under `figures/` and `results/`.
