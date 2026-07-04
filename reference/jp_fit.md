# Fit the full Koundouri-Nauges (2005) three-step pipeline

High-level wrapper that runs the entire Just-Pope-with-Heckman procedure
in a single call:

1.  Probit selection on \`selection_var\` against
    \`selection_covariates\`; compute the Inverse Mills Ratio.

2.  Linear-quadratic mean production function with IMR, fit on the
    selected subsample (\`selection_var == 1\`).

3.  Cobb-Douglas risk function on \`log\|residuals\|\`, with bootstrap
    standard errors that resample the full pipeline.

For comparison purposes the function also fits the parallel "without
selectivity correction" path by zeroing the IMR before Step 2. This is
the with/without contrast displayed in Tables 4 and 5 of the paper and
on \[plot.jpfit()\].

## Usage

``` r
jp_fit(
  data,
  selection_var,
  selection_covariates,
  output_var,
  input_vars,
  shifter_vars,
  bootstrap_reps = 500,
  mean_scale = TRUE,
  mean_form = c("linear_quadratic", "quadratic", "cobb_douglas"),
  risk_form = c("cobb_douglas", "exponential"),
  seed = NULL
)
```

## Arguments

- data:

  Data frame with one row per farmer covering both the selected and
  non-selected groups (Step 1 needs both).

- selection_var:

  Character. Name of the 0/1 selection indicator.

- selection_covariates:

  Character vector of probit covariates.

- output_var:

  Character. Output / yield variable.

- input_vars:

  Character vector of variable inputs.

- shifter_vars:

  Character vector of extra production shifters.

- bootstrap_reps:

  Integer. Bootstrap replications for Step 3 SEs (default 500, as in the
  paper).

- mean_scale:

  Logical. Mean-scale all variables before Step 2.

- seed:

  Optional integer seed.

## Value

An object of class \`jpfit\` with elements \`selection\`, \`mean_with\`,
\`mean_without\`, \`risk_with\`, \`risk_without\`, \`config\`, and
\`call\`. See \[print.jpfit()\], \[summary.jpfit()\], \[plot.jpfit()\].

## Examples

``` r
if (FALSE) { # \dontrun{
farms <- simulate_kiti_data(seed = 1)
fit <- jp_fit(
  data         = farms,
  selection_var = "vegetables",
  selection_covariates = c("rainfall","irrigated","dist_town",
                           "dist_coast","experience"),
  output_var   = "revenue",
  input_vars   = c("fertilizers","pesticides","labor","water"),
  shifter_vars = c("machinery","rainfall","irrigated",
                   "dist_town","dist_coast","experience"),
  bootstrap_reps = 100
)
print(fit)
summary(fit)
plot(fit)
} # }
```
