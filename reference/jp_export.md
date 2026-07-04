# Export a fitted \`jpfit\` object to Excel, LaTeX, or CSV

Writes the four publication-ready tables produced by \[jp_fit()\] – the
probit selection equation, the mean production function (with and
without selectivity correction), and the with/without risk-function
comparison – to a single Excel workbook (one sheet per table), one LaTeX
file (booktabs-style \`tabular\` environments), or a folder of CSV
files.

## Usage

``` r
jp_export(
  fit,
  file,
  format = c("auto", "xlsx", "tex", "csv"),
  digits = 3,
  caption_prefix = NULL,
  overwrite = TRUE
)
```

## Arguments

- fit:

  A \`jpfit\` object returned by \[jp_fit()\].

- file:

  Output destination. Format is autodetected from its extension
  (\`.xlsx\`, \`.tex\`, \`.csv\`) unless \`format\` is supplied. For
  \`format = "csv"\`, \`file\` is a directory and one CSV per table is
  written into it.

- format:

  One of "auto" (default), "xlsx", "tex", or "csv".

- digits:

  Number of digits to display in numeric cells (default 3).

- caption_prefix:

  Character. Inserted at the front of every table caption / sheet name
  to identify this fit (default uses the selection variable name).

- overwrite:

  Logical. Overwrite existing files (default \`TRUE\`).

## Value

Invisibly, the path(s) written.

## Details

Excel export requires the \`openxlsx\` package. If it is not installed,
install with \`install.packages("openxlsx")\`. LaTeX and CSV exports use
base R only.

## Examples

``` r
if (FALSE) { # \dontrun{
farms <- simulate_kiti_data(seed = 42)
fit <- jp_fit(
  data = farms, selection_var = "vegetables",
  selection_covariates = c("rainfall","irrigated","dist_town",
                           "dist_coast","experience"),
  output_var = "revenue",
  input_vars   = c("fertilizers","pesticides","labor","water"),
  shifter_vars = c("machinery","rainfall","irrigated",
                   "dist_town","dist_coast","experience"),
  bootstrap_reps = 100
)
jp_export(fit, "results_vegetables.xlsx")
jp_export(fit, "results_vegetables.tex")
jp_export(fit, "results_vegetables_csv/")
} # }
```
