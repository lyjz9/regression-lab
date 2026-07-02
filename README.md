# Regression Lab in R

Reproducible regression case studies using R, missing-data imputation, transformation testing, lack-of-fit checks, Box-Cox transformation, multiple regression, and interaction modeling.

## Overview

This repository contains two college regression case studies organized as a clean, runnable R portfolio project. The goal is to show an end-to-end statistical workflow: prepare data, handle missing values, fit models, compare transformations, diagnose assumptions, and save readable outputs.

The datasets are synthetic educational datasets assigned for coursework. They are not real medical, genetic, or patient data. Assignment PDFs, handouts, full class dataset archives, and other students' data are intentionally excluded.

## Skills demonstrated

- R project organization and reproducible analysis scripts
- Data cleaning, joins, missingness checks, and complete-case filtering
- Missing-data imputation with `mice`
- Ordinary least squares regression and model interpretation
- Transformation search and residual diagnostics
- Approximate lack-of-fit testing with binned near-repeated values
- Box-Cox transformation search with `MASS`
- Multiple regression with interaction terms
- Output management for result tables, text summaries, and diagnostic plots

## Case studies

### Project 1: One-predictor regression

Location: [`project1_simple_regression/`](project1_simple_regression/)

Part A merges independent-variable and dependent-variable files by `ID`, counts missingness, drops rows where both variables are missing, uses MICE imputation, and fits:

```text
DV ~ IV
```

Reported course-result reference:

```text
DV = 51.4002 + 7.4831 * IV
Adjusted R-squared about 0.8589
```

Because MICE is stochastic, rerun values may differ slightly even with a fixed seed.

Part B fits the report-selected transformed model:

```text
y^2 ~ 1/x
```

Reported course-result reference:

```text
y^2 = 4.8492 + 3.4611 * (1/x)
Lack-of-fit p-value about 0.9938
R-squared about 0.6698
```

The lack-of-fit test in the script is approximate because near-repeated transformed x-values are created through binning.

### Project 2: Multiple regression with synthetic indicators

Location: [`project2_multiple_regression/`](project2_multiple_regression/)

Project 2 uses a synthetic educational dataset with environmental variables and synthetic gene-indicator variables. The script checks missingness, fits an environmental baseline model, runs a Box-Cox search, keeps the report-selected `Y^1.5` transformation, scans interaction terms, and fits:

```text
Y_15 ~ E1 + E3 + G14:G19
```

Reported course-result reference:

```text
Y^1.5 = 23.035 + 1.730*E1 + 1.608*E3 + 1.803*(G14:G19) + error
Adjusted R-squared about 0.4241
```

The interaction scans are diagnostic outputs. They do not silently replace the report-selected model.

## How to run

Open R or RStudio from the repository root and run:

```r
source("install_packages.R")
source("run_all.R")
```

You can also run each case study separately:

```r
source("project1_simple_regression/scripts/01_project1_partA_imputation_regression.R")
source("project1_simple_regression/scripts/02_project1_partB_transformation_lof.R")
source("project2_multiple_regression/scripts/03_project2_multiple_regression.R")
```

## Outputs

Each script writes outputs to its project folder:

- `project1_simple_regression/results/`
- `project1_simple_regression/figures/`
- `project2_multiple_regression/results/`
- `project2_multiple_regression/figures/`

Outputs include model summaries, ANOVA tables, coefficient tables, confidence intervals, model comparison tables, missingness summaries, reported-result notes, regression plots, transformation plots, and residual diagnostics.

## Portfolio copy

Recruiter-friendly project-card and portfolio-page wording is available in [`docs/PORTFOLIO_COPY.md`](docs/PORTFOLIO_COPY.md).

## Data note

The raw files expected by the scripts are:

```text
data/raw/project1/117453_IV.csv
data/raw/project1/117453_DV.csv
data/raw/project1/117453_partB.csv
data/raw/project2/P2_117453.csv
```

Only the synthetic datasets needed to reproduce this portfolio project are included.
