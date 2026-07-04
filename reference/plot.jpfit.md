# Plot the risk-function coefficients of a fitted \`jpfit\` object

Produces the headline coefficient plot from Koundouri & Nauges (2005):
variance elasticities of each input under the with- and without-
selectivity-correction specifications, side by side.

## Usage

``` r
# S3 method for class 'jpfit'
plot(x, ci = 0.95, ...)
```

## Arguments

- x:

  A \`jpfit\` object.

- ci:

  Coverage for the displayed interval (default 0.95).

- ...:

  Unused; for S3 consistency.

## Value

A ggplot object.
