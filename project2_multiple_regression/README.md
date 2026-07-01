# Project 2: Multiple Regression with Environmental and Genetic Variables

This project uses a synthetic dataset containing:

- One response variable: `Y`
- Four environmental variables: `E1` to `E4`
- Twenty gene indicator variables: `G1` to `G20`
- Potential two-way interactions, including gene-environment and gene-gene interactions

The original analysis goal was to estimate the data-generating function and determine whether the response was associated with environmental variables, gene variables, gene-environment interactions, or gene-gene interactions.

## Reported final model

The original report selected a Box-Cox transformation with approximately `lambda = 1.5` and proposed:

```text
Y^1.5 = 23.035 + 1.730*E1 + 1.608*E3 + 1.803*(G14:G19) + error
```

Reported adjusted R-squared: about `0.4241`.

## Script

Run from the repository root:

```r
source("project2_multiple_regression/scripts/03_project2_multiple_regression.R")
```

The script:

1. Checks missing values.
2. Fits an environmental-variable baseline model.
3. Runs a Box-Cox transformation search.
4. Fits the reported final model using `Y^1.5`.
5. Scans selected gene-gene and gene-environment interactions.
6. Saves model summaries, comparison tables, and figures.

Generated outputs are saved under `figures/` and `results/`.
