# Extract risk-function coefficients

Extract risk-function coefficients

## Usage

``` r
# S3 method for class 'jpfit'
coef(object, which = c("risk", "mean", "selection"), correction = TRUE, ...)
```

## Arguments

- object:

  A \`jpfit\` object.

- which:

  One of "risk" (default), "mean", "selection". For "risk" and "mean",
  choose \`correction = TRUE/FALSE\` to pick the with- or without-IMR
  version.

- correction:

  Logical. Pick the corrected version when \`TRUE\`.

- ...:

  Unused.
