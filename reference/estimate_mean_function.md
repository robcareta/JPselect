# Estimate the Just-Pope mean production function with selectivity correction

Step 2 of Koundouri & Nauges (2005). Fits one of three functional forms
for the mean function \`f(x)\` plus extra shifters and the Inverse Mills
Ratio.

## Usage

``` r
estimate_mean_function(
  data,
  output_var,
  input_vars,
  shifter_vars,
  imr_var = "imr",
  form = c("linear_quadratic", "quadratic", "cobb_douglas"),
  mean_scale = TRUE
)
```

## Arguments

- data:

  Data frame of the selected subsample (\`D_l == 1\`) containing all
  variables listed below.

- output_var:

  Character. Name of the output / yield variable.

- input_vars:

  Character vector. Variable inputs.

- shifter_vars:

  Character vector. Extra production shifters that enter the mean
  function linearly (in all three forms).

- imr_var:

  Character. Name of the Mill's ratio column (default "imr").

- form:

  Functional form: \`"linear_quadratic"\` (default), \`"quadratic"\`, or
  \`"cobb_douglas"\`. See \*Details\*.

- mean_scale:

  Logical. If \`TRUE\` (default), mean-scale all variables before
  estimation, as in Table A1 of the paper. Ignored under \`form =
  "cobb_douglas"\`, where log-scaling makes the transformation
  meaningless.

## Value

A list with the fitted \`lm\` object, a coefficient table with
HC1-robust standard errors, the residuals, fitted values, adjusted
\\R^2\\, the formula used, the (possibly scaled) data frame, and the
functional form.

## Details

- \`"linear_quadratic"\` (default): linear, quadratic, and pairwise
  interaction terms in inputs. This is the form used in Koundouri &
  Nauges (2005). Compatible with additive interaction between the mean
  and variance functions, the key Just-Pope requirement.

- \`"quadratic"\`: linear and quadratic terms in inputs, no pairwise
  interactions. A more parsimonious version, useful when the sample is
  small.

- \`"cobb_douglas"\`: log-log specification, \\\log y = \beta_0 + \sum_j
  \beta_j \log x_j + \text{shifters} + \sigma M + w\\. Requires strictly
  positive output and inputs. Shankar & Nelson (1999) showed that the
  Cobb-Douglas mean + Cobb-Douglas variance specification is robust to
  input endogeneity in the JP framework.

Coefficients are obtained by OLS; with the regressors serving as their
own instruments, GMM point estimates coincide with OLS, and the paper's
heteroskedasticity-robust GMM standard errors are reproduced via HC1
sandwich variances.

If the Mill's ratio column is constant (e.g. all zero for the "without
selectivity" comparison), the term is dropped from the formula before
fitting.

## Examples

``` r
farms <- simulate_kiti_data(seed = 1)
sel   <- estimate_selection(farms, "vegetables",
                            c("rainfall","irrigated","dist_town",
                              "dist_coast","experience"))
farms$imr <- sel$imr
veg <- farms[farms$vegetables == 1, ]
mf  <- estimate_mean_function(
  data = veg, output_var = "revenue",
  input_vars   = c("fertilizers","pesticides","labor","water"),
  shifter_vars = c("machinery","rainfall","irrigated",
                   "dist_town","dist_coast","experience"))
head(mf$coefficients)
#>                  Coefficient   Std.Error t.Statistic      p.Value
#> (Intercept)      0.430540546 0.075148661   5.7291845 2.113282e-07
#> fertilizers      0.026561214 0.018828474   1.4106939 1.625822e-01
#> pesticides       0.073992857 0.011917726   6.2086389 2.939031e-08
#> labor            0.036699580 0.009318418   3.9383918 1.857306e-04
#> water            0.136547397 0.016804271   8.1257556 8.172466e-12
#> I(fertilizers^2) 0.001663074 0.002801760   0.5935821 5.546265e-01
```
