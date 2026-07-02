# Regression Lab in R

## Tagline

Reproducible regression case studies using R, missing-data imputation, transformation testing, and multiple regression.

## Project Summary

This project turns two AMS 315 regression case studies into a clean, portfolio-ready R workflow. It shows how I organize raw data, write reproducible scripts, handle missing values, test transformations, fit regression models, and save readable outputs for review.

Project 2 uses synthetic educational variables, including simulated environmental and gene-indicator columns. It should be read as a statistics and modeling exercise, not as real medical or genetic research.

## Longer Portfolio Description

Regression Lab in R is a reproducible statistics project built from two course regression case studies. The repository is organized so the analysis can be run from the root folder, with raw data stored in a clear `data/raw/` structure and results saved into project-specific output folders.

In Project 1, I merge independent-variable and dependent-variable files by ID, summarize missingness, use MICE imputation for missing values, and fit a simple linear regression model. I also compare transformations and run an approximate lack-of-fit check for the selected transformed model.

In Project 2, I work with a synthetic educational dataset to practice multiple regression. The workflow checks missingness, fits an environmental baseline model, runs a Box-Cox transformation search, keeps the report-selected `Y^1.5` transformation, evaluates interaction terms, and saves final model outputs and diagnostic plots.

## Tech Stack

R, dplyr, readr, ggplot2, mice, MASS, broom

## Key Skills Demonstrated

- Data cleaning and project organization
- Missing-data checks and MICE imputation
- Ordinary least squares regression
- Transformation testing and Box-Cox search
- Approximate lack-of-fit testing
- Multiple regression and interaction terms
- Model diagnostics and statistical reporting
- Reproducible analysis scripting

## Resume-Style Bullets

- Organized two regression case studies into a reproducible R project with clear raw-data paths, run scripts, documentation, saved outputs, and diagnostic figures.
- Applied MICE imputation, OLS regression, transformation testing, and model diagnostics to evaluate simple and multiple regression models.
- Built output workflows that save model summaries, ANOVA tables, coefficient tables, confidence intervals, comparison tables, and plots for review.
- Used Box-Cox transformation search and interaction scans to support a report-selected multiple regression model on a synthetic educational dataset.
- Documented the project for a recruiter-facing GitHub portfolio while clearly separating statistical practice from real medical or genetic research.

## What I Learned

This project helped me connect classroom regression concepts to a more practical workflow: checking data first, making scripts reusable, saving outputs clearly, and documenting modeling choices. I also learned how important it is to explain statistical results in plain language so another person can understand what was done and why it matters.

## GitHub Project Card Blurb

Built a reproducible R project from two statistical modeling case studies, including data cleaning, MICE imputation, OLS regression, transformation search, lack-of-fit testing, Box-Cox transformation, and interaction modeling. Organized the project into a GitHub-ready structure with scripts, outputs, documentation, and clear run instructions.

## Suggested Portfolio Tags

R, Regression, Data Cleaning, Missing Data, MICE, ggplot2, Box-Cox, Model Diagnostics, Statistical Modeling

## Website Copy

### Short Project Card Version

Reproducible R regression lab with missing-data imputation, transformation testing, multiple regression, interaction terms, and model diagnostics.

### Longer Project Detail Version

This project organizes two AMS 315 regression case studies into a clean, runnable R portfolio repository. I used R to prepare synthetic course datasets, check missingness, apply MICE imputation, fit simple and multiple regression models, compare transformations, run an approximate lack-of-fit test, evaluate a Box-Cox transformation, and save model outputs and diagnostic plots. The result is a recruiter-friendly project that shows both statistical modeling fundamentals and reproducible analysis habits.

### Impact / Skills Bullets

- Cleaned and structured synthetic course datasets into a reproducible R workflow.
- Saved model summaries, ANOVA tables, coefficient tables, confidence intervals, and diagnostic plots for transparent reporting.
- Practiced regression modeling skills used in analyst work: imputation, transformations, interactions, and model diagnostics.

### Suggested Buttons

- View GitHub
- View README
