# Package index

## Package overview

- [`JPselection-package`](https://robcareta.github.io/JPselection/reference/JPselection-package.md)
  [`JPselection`](https://robcareta.github.io/JPselection/reference/JPselection-package.md)
  : JPselection: Just-Pope Production Functions with Heckman Selectivity
  Correction

## Full pipeline

Wrappers for the complete three-step procedure with vs. without
selectivity correction.

- [`jp_fit()`](https://robcareta.github.io/JPselection/reference/jp_fit.md)
  : Fit the full Koundouri-Nauges (2005) three-step pipeline
- [`jp_compare()`](https://robcareta.github.io/JPselection/reference/jp_compare.md)
  : Compare jp_fit specifications across functional forms

## S3 methods

Extracting coefficients and plotting fitted objects.

- [`plot(`*`<jpfit>`*`)`](https://robcareta.github.io/JPselection/reference/plot.jpfit.md)
  : Plot the risk-function coefficients of a fitted \`jpfit\` object
- [`coef(`*`<jpfit>`*`)`](https://robcareta.github.io/JPselection/reference/coef.jpfit.md)
  : Extract risk-function coefficients

## Individual stages

The estimation steps exposed for finer control.

- [`estimate_selection()`](https://robcareta.github.io/JPselection/reference/estimate_selection.md)
  : Estimate the crop-choice selection equation and compute the Inverse
  Mills Ratio
- [`estimate_mean_function()`](https://robcareta.github.io/JPselection/reference/estimate_mean_function.md)
  : Estimate the Just-Pope mean production function with selectivity
  correction
- [`estimate_risk_function()`](https://robcareta.github.io/JPselection/reference/estimate_risk_function.md)
  : Estimate the Just-Pope variance (risk) function

## Export

Write results to Excel, LaTeX, or CSV for papers and slides.

- [`jp_export()`](https://robcareta.github.io/JPselection/reference/jp_export.md)
  : Export a fitted \`jpfit\` object to Excel, LaTeX, or CSV

## Example and reference data

Synthetic and packaged datasets used for demonstration.

- [`simulate_kiti_data()`](https://robcareta.github.io/JPselection/reference/simulate_kiti_data.md)
  : Simulate a Kiti-Cyprus-like farm dataset
- [`prepare_caf_data()`](https://robcareta.github.io/JPselection/reference/prepare_caf_data.md)
  : Prepare Chilean Agricultural Census (CAF 2021) data for \[jp_fit()\]
- [`caf2021_docs()`](https://robcareta.github.io/JPselection/reference/caf2021_docs.md)
  : Open the CAF 2021 documentation bundled with the package
- [`caf2021_g2_groups()`](https://robcareta.github.io/JPselection/reference/caf2021_g2_groups.md)
  : Default mapping of G2 codes to broad activity groups
