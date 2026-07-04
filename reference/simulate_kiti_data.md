# Simulate a Kiti-Cyprus-like farm dataset

Generates a synthetic cross-section that mimics the structure of the
Koundouri & Nauges (2005) sample: 239 farms classified into vegetables
(95), cereals (89), and citrus (55) producers, with inputs and revenues
whose moments roughly match Table 1 of the paper. The crop-choice
process is driven by environmental and farmer characteristics so the
Heckman selection step has signal to recover.

## Usage

``` r
simulate_kiti_data(n_total = 239, n_veg = 95, n_cer = 89, n_cit = 55, seed = 1)
```

## Arguments

- n_total:

  Integer. Total number of farms (default 239).

- n_veg, n_cer, n_cit:

  Integer. Target counts per crop.

- seed:

  Optional integer seed.

## Value

A data frame with one row per farm and crop-choice dummies
\`vegetables\`, \`cereals\`, \`citrus\`.

## Details

This is for methodology demonstration only – it is not the original
Cyprus data and is not intended to reproduce the paper's exact point
estimates.

## Examples

``` r
farms <- simulate_kiti_data(seed = 1)
table(farms$crop)
#> 
#>    cereals     citrus vegetables 
#>         89         55         95 
```
