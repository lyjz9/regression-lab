# Codex Prompt for This Repo

You are helping me polish a GitHub portfolio repository called `regression-lab`.

## Context

This repo contains two R-based regression projects from AMS 315 Data Analysis. The goal is to turn my coursework into a clean, reproducible, recruiter-friendly GitHub project without changing the statistical story.

The original code was not saved, so the current scripts were reconstructed from my final reports, datasets, and class handout workflow. Please improve the repo carefully and keep the analysis faithful to the reports.

## Data

Only use these included synthetic datasets:

- `data/raw/project1/117453_IV.csv`
- `data/raw/project1/117453_DV.csv`
- `data/raw/project1/117453_partB.csv`
- `data/raw/project2/P2_117453.csv`

Do not add full class dataset archives, assignment PDFs, handouts, or other students' data.

## Current statistical goals

### Project 1 Part A

- Merge IV and DV files by `ID`.
- Count missingness.
- Drop rows where both IV and DV are missing.
- Impute missing values using MICE linear regression with bootstrap (`norm.boot`).
- Fit `DV ~ IV`.
- Save model summary, ANOVA table, coefficients, confidence intervals, and figures.

Reported original result:

```text
DV = 51.4002 + 7.4831 * IV
Adjusted R-squared ≈ 0.8589
```

Because MICE is stochastic, do not force exact values unless you can identify the original imputation seed/method. Add a clear note if rerun values differ slightly.

### Project 1 Part B

- Explore the one-predictor regression relationship.
- Fit the selected transformed model: `y^2 ~ 1/x`.
- Run approximate lack-of-fit tests using binned near-repeated x-values.
- Save summaries and figures.

Reported original result:

```text
y^2 = 4.8492 + 3.4611 * (1/x)
LOF p-value ≈ 0.9938
R-squared ≈ 0.6698
```

### Project 2

- Check missingness.
- Fit environmental baseline model.
- Use Box-Cox to evaluate response transformation.
- Use the report-selected transformation `Y^1.5`.
- Fit final model: `Y_15 ~ E1 + E3 + G14:G19`.
- Save model summary, ANOVA, coefficient table, candidate comparison, interaction scans, and diagnostic plots.

Reported original result:

```text
Y^1.5 = 23.035 + 1.730*E1 + 1.608*E3 + 1.803*(G14:G19) + error
Adjusted R-squared ≈ 0.4241
```

## What I want you to do

Please inspect the repo and improve it like a real portfolio project:

1. Make sure all R scripts run from the repo root on Windows.
2. Fix any R syntax or package issues.
3. Improve comments and function names where helpful.
4. Avoid overengineering.
5. Keep the output folder structure clean.
6. Improve README wording so it sounds professional but still entry-level friendly.
7. Add a short “What this project demonstrates” section if it helps.
8. Do not publish course assignment PDFs, full dataset zips, or handouts.
9. Do not change the main reported models unless the data clearly proves the report had a mistake; if so, explain the difference in the README rather than silently changing it.
10. Add a note that these are synthetic educational datasets and not medical/genetic research data.

## Preferred style

- R-first.
- Clean, readable scripts.
- Minimal dependencies.
- Good folder organization.
- Clear outputs saved to `figures/` and `results/`.
- Good README for recruiters looking at data analyst / data science projects.

## Final deliverable

After your changes, give me:

- A summary of what you changed.
- Any scripts I should run.
- Any issues or warnings.
- Suggested GitHub repo description and topics.
