# JPselect

**Just-Pope production functions with Heckman selectivity correction.**

Reproduces the three-step estimation procedure of Koundouri & Nauges
(2005, *Journal of Agricultural and Resource Economics* 30(3):597-608)
for Just-Pope (1978, 1979) stochastic production functions with
sample-selection bias from crop choice.

## Installation

```r
# install.packages("remotes")
remotes::install_github("robcareta/JPselect")
```

## Quick start

> **Note:** The example below uses `simulate_kiti_data()`, a **synthetic**
> 239-farm dataset whose marginals roughly match Table 1 of Koundouri &
> Nauges (2005). It is intended for demonstrating the methodology only —
> it is **not** the original Cyprus data and is not meant to reproduce
> the paper's exact point estimates. To use real data, pass any data
> frame with the appropriate columns to `jp_fit()`.

```r
library(JPselect)

# Synthetic 239-farm dataset mimicking the paper's Cyprus sample
farms <- simulate_kiti_data(seed = 42)

fit <- jp_fit(
  data                 = farms,
  selection_var        = "vegetables",
  selection_covariates = c("rainfall","irrigated","dist_town",
                           "dist_coast","experience"),
  output_var           = "revenue",
  input_vars           = c("fertilizers","pesticides","labor","water"),
  shifter_vars         = c("machinery","rainfall","irrigated",
                           "dist_town","dist_coast","experience"),
  bootstrap_reps       = 500
)

print(fit)     # risk-function table + plain-language interpretation
summary(fit)   # full Step 1, 2, 3 output
plot(fit)      # headline chart: risk function, with vs. without correction

# Export
jp_export(fit, "results.xlsx")    # one workbook, 5 sheets
jp_export(fit, "results.tex")     # booktabs tables for a paper
jp_export(fit, "results_csv/")    # one CSV per table
```

## What the package does

| Step | Function | Output |
|---|---|---|
| 1. Probit selection + Inverse Mills Ratio | `estimate_selection()` | probit model and IMR |
| 2. Linear-quadratic mean production function with IMR (OLS + HC1 SEs = just-identified GMM) | `estimate_mean_function()` | coefficient table, residuals |
| 3. Cobb-Douglas risk function: `log\|residuals\| ~ log(inputs)`, with full-pipeline bootstrap SEs | `estimate_risk_function()` | variance elasticities |
| End-to-end wrapper that also fits the "without selectivity" comparison | `jp_fit()` | `jpfit` S3 object with `print` / `summary` / `plot` / `coef` methods |
| Export the four resulting tables | `jp_export()` | one `.xlsx` with 5 sheets, one `.tex` with 4 booktabs tables, or a folder of CSVs |

The headline result of the paper is that variance elasticities estimated
*without* the Heckman correction can be biased in sign and magnitude.
`plot(fit)` shows this comparison side-by-side per input, and `print(fit)`
flags inputs whose conclusion actually changes between specifications.

## Standard errors

Step 3 SEs come from a 500-replication nonparametric bootstrap that
resamples the **full pipeline** — probit, IMR, mean function, residuals,
risk function — on every replication, so upstream parameter uncertainty
propagates correctly. Set `bootstrap_reps` lower for quicker runs.

## Reproducing the paper's tables

```r
source(system.file("examples", "replicate_koundouri_2005.R",
                   package = "JPselect"))
```

This runs the full pipeline for both vegetables and cereals groups and
saves coefficient plots to `./figures/`.

## Citation

If you use `JPselect` in published work, please cite the underlying
paper:

> Koundouri, P. and Nauges, C. (2005). On Production Function
> Estimation with Selectivity and Risk Considerations.
> *Journal of Agricultural and Resource Economics*, 30(3), 597-608.

and the package itself:

> Cardenas Retamal, R. (2026). *JPselect: Just-Pope Production
> Functions with Heckman Selectivity Correction.* R package version
> 0.1.0. https://github.com/robcareta/JPselect

In R, the canonical citation is also available via:

```r
citation("JPselect")
```

## References

- Heckman, J. (1979). Sample selection bias as a specification error.
  *Econometrica*, 47, 153-161.
- Just, R. E. and Pope, R. D. (1978). Stochastic representation of
  production functions and econometric implications.
  *Journal of Econometrics*, 7, 67-86.
- Koundouri, P. and Nauges, C. (2005). On Production Function
  Estimation with Selectivity and Risk Considerations.
  *Journal of Agricultural and Resource Economics*, 30(3), 597-608.

## License

MIT © 2026 Roberto Cardenas Retamal
