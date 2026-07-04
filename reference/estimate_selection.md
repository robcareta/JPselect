# Estimate the crop-choice selection equation and compute the Inverse Mills Ratio

Step 1 of Koundouri & Nauges (2005). Fits a probit on a binary selection
indicator (e.g., 1 = farmer grew vegetables, 0 = otherwise) and returns
the Inverse Mills Ratio (IMR) for every observation in \`data\`, ready
to be plugged into the Step-2 mean function.

## Usage

``` r
estimate_selection(data, selection_var, covariates)
```

## Arguments

- data:

  A data frame containing the selection indicator and the covariates
  listed in \`covariates\`.

- selection_var:

  Character. Name of the binary 0/1 selection variable.

- covariates:

  Character vector of explanatory variable names.

## Value

A list with:

- model:

  The fitted probit (a \`glm\` object).

- imr:

  Inverse Mills Ratio \\\phi(x'\beta)/\Phi(x'\beta)\\ per row.

- probabilities:

  Predicted probability of selection per row.

## Examples

``` r
farms <- simulate_kiti_data(seed = 1)
sel <- estimate_selection(farms, "vegetables",
                          c("rainfall","irrigated","dist_town",
                            "dist_coast","experience"))
head(sel$imr)
#>         1         2         3         4         5         6 
#> 1.6969300 0.9725054 0.8323618 0.6767589 0.9008406 1.0675290 
```
