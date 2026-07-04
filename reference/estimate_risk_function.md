# Estimate the Just-Pope variance (risk) function

Step 3 of Koundouri & Nauges (2005). Given mean-function residuals, fits
one of two functional forms for the variance function \`h(x)\`:

## Usage

``` r
estimate_risk_function(
  residuals,
  input_data,
  input_vars,
  form = c("cobb_douglas", "exponential"),
  positive_only = TRUE,
  bootstrap_reps = 500,
  full_data = NULL,
  selection_args = NULL,
  mean_args = NULL,
  seed = NULL
)
```

## Arguments

- residuals:

  Numeric vector of mean-function residuals (Step 2).

- input_data:

  Data frame aligned with \`residuals\`, holding input columns named in
  \`input_vars\`.

- input_vars:

  Character vector. Inputs to enter the risk function.

- form:

  Functional form: \`"cobb_douglas"\` (default) or \`"exponential"\`.
  See \*Details\*.

- positive_only:

  Logical. Drop rows with zero residuals before estimation (default
  \`TRUE\`). Under \`form = "cobb_douglas"\` also drops rows with
  non-positive inputs (needed for the log transformation).

- bootstrap_reps:

  Integer. Bootstrap replications (default 500; set 0 for OLS SEs only).

- full_data, selection_args, mean_args:

  Optional. When all three are supplied, the full pipeline is rerun on
  each bootstrap draw. See \[jp_fit()\] which wires this up for you.

- seed:

  Optional integer seed.

## Value

List with the fitted \`lm\` object, a coefficient table, the bootstrap
coefficient matrix, the post-filter sample size, and the functional form
actually used.

## Details

- \`"cobb_douglas"\` (default): \\h(x) = \xi_0 \prod_j x_j^{\xi_j}\\,
  estimated via \\\log\|\hat w\| = \xi_0 + \sum_j \xi_j \log x_j +
  \log\eta\\. Coefficients are \*\*variance elasticities\*\* (a 1
  changes output variance by \\\xi_j\\ inputs.

- \`"exponential"\`: \\h(x) = \exp(\xi_0 + \sum_j \xi_j x_j)\\,
  estimated via \\\log\|\hat w\| = \xi_0 + \sum_j \xi_j x_j +
  \log\eta\\. Coefficients are \*\*variance semi-elasticities\*\* (a
  1-unit rise in input \\j\\ changes log variance by \\\xi_j\\). Handles
  zero inputs because no log transformation is applied to \\x\\. See
  Saha, Havenner & Talpaz (1997), Tveterås (1999).

Standard errors default to a 500-replication nonparametric bootstrap,
matching the paper. If \`full_data\`, \`selection_args\`, and
\`mean_args\` are supplied, the bootstrap resamples the entire pipeline
(probit -\> IMR -\> mean function -\> residuals -\> risk function) on
each replication so upstream parameter uncertainty propagates into the
risk-function SEs.

## Examples

``` r
if (FALSE) { # \dontrun{
fit <- jp_fit(data = simulate_kiti_data(),
              selection_var = "vegetables",
              selection_covariates = c("rainfall","irrigated","dist_town",
                                       "dist_coast","experience"),
              output_var   = "revenue",
              input_vars   = c("fertilizers","pesticides","labor","water"),
              shifter_vars = c("machinery","rainfall","irrigated",
                               "dist_town","dist_coast","experience"),
              bootstrap_reps = 100,
              risk_form    = "exponential")
fit$risk_with$coefficients
} # }
```
