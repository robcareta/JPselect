# Open the CAF 2021 documentation bundled with the package

Three documents from INE Chile are shipped inside this package's
\`inst/extdata/\` folder for offline reference:

- dictionary:

  Variable dictionary (\`.xlsx\`) – the authoritative codebook for the
  UPA, ESTABLECIMIENTO, PREDIO, and HOGAR tables.

- methodology:

  Methodological document (\`.pdf\`) describing sample design,
  definitions, and operative procedures.

- questionnaire:

  Census questionnaire facsimile (\`.pdf\`).

## Usage

``` r
caf2021_docs(which = c("all", "dictionary", "methodology", "questionnaire"))
```

## Arguments

- which:

  One of "dictionary", "methodology", "questionnaire", or "all"
  (default). With "all", returns a named character vector of the three
  file paths.

## Value

A file path (or named vector of paths) to the bundled document(s).

## Details

These are the only CAF 2021 documents accessible by direct URL from INE;
the \*\*microdata files themselves are served through an interactive
SharePoint widget and must be downloaded manually\*\* from
<https://www.ine.gob.cl/estadisticas-por-tema/agricultura-y-medio-ambiente/censo-agropecuario>
(section \*Bases de datos\*).

## Examples

``` r
caf2021_docs("dictionary")
#> Warning: Some bundled docs are missing: methodology, questionnaire
#> [1] "/home/runner/work/_temp/Library/JPselection/extdata/caf2021_dictionary.xlsx"
if (FALSE) { # \dontrun{
# Open the variable dictionary in Excel
shell.exec(caf2021_docs("dictionary"))
} # }
```
