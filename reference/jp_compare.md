# Compare jp_fit specifications across functional forms

Runs \[jp_fit()\] under every combination of \`mean_forms\` x
\`risk_forms\` supplied and returns a side-by-side comparison so the
analyst can see how sensitive the risk-function conclusions are to the
choice of form.

## Usage

``` r
jp_compare(
  ...,
  mean_forms = c("linear_quadratic", "quadratic", "cobb_douglas"),
  risk_forms = c("cobb_douglas", "exponential"),
  verbose = TRUE
)
```

## Arguments

- ...:

  Arguments forwarded to \[jp_fit()\] (e.g., \`data\`,
  \`selection_var\`, \`input_vars\`, \`bootstrap_reps\`).

- mean_forms:

  Character vector of mean-function forms to compare. Subset of
  \`c("linear_quadratic","quadratic","cobb_douglas")\`.

- risk_forms:

  Character vector of risk-function forms to compare. Subset of
  \`c("cobb_douglas","exponential")\`.

- verbose:

  Logical. Print progress messages.

## Value

A list with two data frames:

- \`summary\`:

  One row per spec combination, with adjusted R^2 of the mean function,
  Mill's ratio coefficient and p-value, and a flag for whether selection
  bias was detected at p \< 0.10.

- \`coefficients\`:

  Long-format risk-function coefficients: one row per (combination,
  input), with the with-correction estimate, SE, t-stat, p-value, and
  significance stars.

## Details

All arguments other than \`mean_forms\` and \`risk_forms\` are passed
verbatim to \[jp_fit()\]; \`mean_form\` and \`risk_form\` set on the
call are vectorised over the two grids.

## Examples

``` r
if (FALSE) { # \dontrun{
farms <- simulate_kiti_data(seed = 42)
cmp <- jp_compare(
  data                 = farms,
  selection_var        = "vegetables",
  selection_covariates = c("rainfall","irrigated","dist_town",
                           "dist_coast","experience"),
  output_var           = "revenue",
  input_vars           = c("fertilizers","pesticides","labor","water"),
  shifter_vars         = c("machinery","rainfall","irrigated",
                           "dist_town","dist_coast","experience"),
  bootstrap_reps       = 0,
  mean_forms           = c("linear_quadratic","quadratic"),
  risk_forms           = c("cobb_douglas","exponential")
)
cmp$summary
cmp$coefficients
} # }
```
