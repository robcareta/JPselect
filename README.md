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

### What `print(fit)` looks like

```
Just-Pope production function with Heckman selection
Koundouri & Nauges (2005) three-step procedure
-------------------------------------------------------
  Selection equation : vegetables ~ rainfall + irrigated + dist_town + dist_coast + experience
  Output             : revenue
  Inputs             : fertilizers, pesticides, labor, water
  Sample             : 239 total, 95 selected (vegetables == 1)
  Bootstrap reps     : 500

Risk function coefficients (variance elasticities):
       Input Coef_with SE_with t_with Coef_without SE_without t_without
 fertilizers     0.057   0.074  0.766        0.013      0.065     0.202
  pesticides     0.007   0.075  0.089       -0.018      0.072    -0.242
       labor    -0.107   0.067 -1.588       -0.154      0.066    -2.331
       water    -0.046   0.071 -0.648       -0.106      0.048    -2.206

-------------------------------------------------------
Interpretation
-------------------------------------------------------
At p < 0.10, with selectivity correction:
  Risk-DECREASING inputs : (none)
  Risk-INCREASING inputs : (none)

Does selectivity correction change the conclusion?
  labor : significant without correction (p=0.022) but NOT significant once corrected (p=0.116)
  water : significant without correction (p=0.030) but NOT significant once corrected (p=0.519)

Selection-bias test (Mill's ratio in the mean function):
  coef = +0.527, p = 0.036 -- selection bias DETECTED.
  Prefer the 'with correction' column above.
```

### What `summary(fit)` looks like

`summary(fit)` prints all three stages of the procedure end-to-end —
the probit selection equation (Step 1), the linear-quadratic mean
production function with the Mill's ratio (Step 2), and the
with/without selectivity comparison for the risk function (Step 3).

```
======================================================================
Just-Pope production function with Heckman selection
Koundouri & Nauges (2005) three-step procedure
======================================================================

Selection variable : vegetables
Sample             : 95 selected of 239 (39.7%)
Bootstrap reps     : 500

----- STEP 1. Probit selection equation -----
    Variable Coefficient Std.Error Statistic p.Value Sig
 (Intercept)       0.618     0.674     0.917   0.359
    rainfall      -0.032     0.022    -1.419   0.156
   irrigated       0.014     0.004     3.866   0.000 ***
   dist_town       0.024     0.018     1.362   0.173
  dist_coast      -0.057     0.023    -2.437   0.015  **
  experience      -0.019     0.007    -2.664   0.008 ***

----- STEP 2. Mean production function (WITH selectivity) -----
Adjusted R-squared: 0.964
               Variable Coefficient Std.Error Statistic p.Value Sig
            (Intercept)       0.137     0.124     1.103   0.274
            fertilizers       0.013     0.016     0.818   0.416
             pesticides       0.036     0.012     3.043   0.003 ***
                  labor       0.042     0.011     3.684   0.000 ***
                  water       0.130     0.009    14.048   0.000 ***
       I(fertilizers^2)       0.002     0.001     1.277   0.206
        I(pesticides^2)       0.005     0.002     3.314   0.001 ***
             I(labor^2)      -0.000     0.002    -0.060   0.952
             I(water^2)       0.002     0.001     1.782   0.079   *
              machinery       0.069     0.011     6.453   0.000 ***
               rainfall      -0.199     0.125    -1.590   0.116
              irrigated       0.467     0.103     4.555   0.000 ***
              dist_town       0.184     0.045     4.115   0.000 ***
             dist_coast      -0.176     0.060    -2.944   0.004 ***
             experience      -0.211     0.068    -3.081   0.003 ***
         imr_vegetables       0.527     0.247     2.135   0.036  **
 fertilizers:pesticides       0.020     0.007     2.848   0.006 ***
      fertilizers:labor      -0.003     0.001    -2.319   0.023  **
      fertilizers:water      -0.005     0.004    -1.479   0.144
       pesticides:labor       0.001     0.003     0.407   0.685
       pesticides:water      -0.004     0.001    -3.163   0.002 ***
            labor:water       0.004     0.004     0.986   0.327

----- STEP 3. Risk function: with vs without selectivity -----
       Input Coef_with SE_with t_with Coef_without SE_without t_without
 fertilizers     0.057   0.074  0.766        0.013      0.065     0.202
  pesticides     0.007   0.075  0.089       -0.018      0.072    -0.242
       labor    -0.107   0.067 -1.588       -0.154      0.066    -2.331
       water    -0.046   0.071 -0.648       -0.106      0.048    -2.206
```

`summary()` also appends the same interpretation block that
`print(fit)` shows at the bottom.

### What `plot(fit)` looks like

![Risk-function coefficients: with vs. without selectivity correction](man/figures/README-risk-plot.png)

Each input appears twice — once estimated with the Heckman correction
(red) and once without (teal). When the two estimates disagree the
selectivity bias is visible at a glance: here, `labor` and `water` look
significantly risk-decreasing only in the uncorrected (teal) spec,
matching the headline finding of the paper.

## Methodology

`JPselect` estimates production functions in two interlocking pieces —
a *mean* and a *variance* — while correcting for the bias that arises
when farmers choose what to produce.

### The Just-Pope production function

Just and Pope (1978) decompose output into a deterministic mean plus a
stochastic component whose **magnitude itself depends on inputs**:

$$y_l = f(\mathbf{x}, \boldsymbol{\beta}_l) + h(\mathbf{x}, \boldsymbol{\xi}_l)\,\eta_l, \qquad \eta_l \sim N(0, 1).$$

- $f(\cdot)$ is the **mean function** — how inputs map to expected
  output.
- $h(\cdot)$ is the **risk** (variance) **function** — how inputs map
  to output variability. Negative coefficients in $h$ mean an input is
  *risk-decreasing*; positive ones mean *risk-increasing*.

The risk function is the headline output: it tells whether labour,
water, fertiliser, etc. *reduce* or *amplify* yield uncertainty.

### Why crop choice creates a selectivity problem

Producers choose among $L$ candidate crops by comparing expected
profits. Whether a farm specialises in vegetables vs. cereals depends
partly on observables (soil, climate, water access) and partly on
**unobservables** correlated with productivity. Estimating the
production function $f$ on the chosen sub-sample alone therefore biases
the estimates — a textbook Heckman problem.

### The Heckman correction

For each candidate crop, a probit predicts the choice indicator $D_l$:

$$D_l = \mathbf{1}\big[g(\mathbf{z}, \boldsymbol{\lambda}_l) + v_l > 0\big],$$

and the **Inverse Mills Ratio** is computed as

$$M_l = \frac{\phi(g(\mathbf{z}, \hat{\boldsymbol{\lambda}}_l))}{\Phi(g(\mathbf{z}, \hat{\boldsymbol{\lambda}}_l))},$$

where $\phi$ and $\Phi$ are the standard-normal pdf and cdf. Adding
$M_l$ as a regressor in the production function absorbs the average
unobserved "productivity" of the selected sample, making the remaining
coefficients consistent.

### The three estimation steps

| Step | What is estimated | Function |
|---|---|---|
| 1 | Probit on $D_l$, then compute $M_l$ | `estimate_selection()` |
| 2 | Mean fn: $y_l = f(\mathbf{x},\boldsymbol{\beta}_l) + \sigma_l M_l + w_l$ with $f$ linear-quadratic | `estimate_mean_function()` |
| 3 | Risk fn via $\log\|\hat w_l\| = \xi_0 + \sum_j \xi_j \log x_j + \log\eta_l$ (Cobb-Douglas $h$) | `estimate_risk_function()` |

Step 2 fits the **linear-quadratic mean function**

$$f(\mathbf{x}) = \beta_0 + \sum_j \beta_j x_j + \sum_j \beta_{2j} x_j^2 + \sum_{j < k} \beta_{jk} x_j x_k.$$

Step 3 fits the **Cobb-Douglas risk function** $h(\mathbf{x}) = \xi_0
\prod_j x_j^{\xi_j}$, so each coefficient $\xi_j$ is the **variance
elasticity** of input $j$: a 1% rise in the input changes output
variance by $\xi_j$%. Negative $\xi_j$ → risk-decreasing input;
positive $\xi_j$ → risk-increasing.

### Why the with-vs-without comparison matters

If selectivity bias is present ($\sigma_l \neq 0$ in Step 2), the
Step-3 risk-function coefficients estimated **without** the Mill's
ratio are biased. Koundouri & Nauges' main finding is that ignoring
selectivity can flip the sign or kill the significance of
risk-function coefficients — exactly the gap that `print(fit)` and
`plot(fit)` make visible side by side. The Mill's ratio coefficient
$\sigma_l$ in Step 2 is itself a direct test for selection bias: if
it's significant, the corrected column is the one you should report.

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
