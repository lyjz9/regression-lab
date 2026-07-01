# Regression Lab in R

This repository contains two reproducible R case studies from AMS 315 Data Analysis coursework. Both projects use synthetic datasets and focus on building, diagnosing, and interpreting regression models.

## Projects

### 1. One-Predictor Linear Regression
Location: [`project1_simple_regression/`](project1_simple_regression/)

This project has two parts:

- **Part A:** Merge independent-variable and dependent-variable files by subject ID, count missingness, impute missing values, and fit an ordinary least squares model.
- **Part B:** Explore transformations of the independent and dependent variables, fit a transformed regression model, and run an approximate lack-of-fit test using binned repeated/near-repeated x-values.

Reported course-result highlights:

- Part A fitted model: `DV = 51.4002 + 7.4831 * IV`
- Part A adjusted R-squared: about `0.8589`
- Part B selected transformed model: `y^2 ~ 1/x`
- Part B lack-of-fit p-value: about `0.9938`

### 2. Multiple Regression with Environmental and Genetic Variables
Location: [`project2_multiple_regression/`](project2_multiple_regression/)

This project estimates a data-generating function from a synthetic dataset with environmental variables, gene indicator variables, and interaction terms.

Reported course-result highlights:

- Box-Cox suggested transforming `Y` with approximately `lambda = 1.5`
- Final reported model: `Y^1.5 = 23.035 + 1.730*E1 + 1.608*E3 + 1.803*(G14:G19) + error`
- Adjusted R-squared: about `0.4241`
- Main conclusion: evidence for environmental effects (`E1`, `E3`) and a gene-gene interaction (`G14:G19`), but no selected gene-environment interaction.

## Repository structure

```text
.
├── data/
│   └── raw/
│       ├── project1/
│       └── project2/
├── project1_simple_regression/
│   ├── scripts/
│   ├── figures/
│   ├── results/
│   └── README.md
├── project2_multiple_regression/
│   ├── scripts/
│   ├── figures/
│   ├── results/
│   └── README.md
├── docs/
│   └── CODEX_PROMPT.md
├── install_packages.R
├── run_all.R
└── README.md
```

## How to run

From the repository root:

```r
source("install_packages.R")
source("run_all.R")
```

Or run each script separately:

```r
source("project1_simple_regression/scripts/01_project1_partA_imputation_regression.R")
source("project1_simple_regression/scripts/02_project1_partB_transformation_lof.R")
source("project2_multiple_regression/scripts/03_project2_multiple_regression.R")
```

## Skills demonstrated

- Data cleaning and merging
- Missing-data imputation with `mice`
- Ordinary least squares regression
- Transformation search and model diagnostics
- Approximate lack-of-fit testing
- Box-Cox transformation
- Multiple regression and interaction modeling
- Model comparison using adjusted R-squared and BIC
- Reproducible project organization in R

## Notes

The datasets included here are synthetic course datasets assigned to the author. The original assignment handouts and full class dataset archives are intentionally not included.
