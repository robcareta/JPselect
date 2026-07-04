# Prepare Chilean Agricultural Census (CAF 2021) data for \[jp_fit()\]

Reads the raw CAF 2021 microdata files as INE actually ships them and
returns a single farm-level (\`GUID\`) data frame ready for
\[jp_fit()\].

## Usage

``` r
prepare_caf_data(
  data_dir,
  crop_group_map = caf2021_g2_groups(),
  include_household = TRUE,
  include_crop_surface = TRUE,
  verbose = TRUE
)
```

## Arguments

- data_dir:

  Path to the folder that contains the two database subfolders, e.g.
  \`"ChileCensusAg/"\`.

- crop_group_map:

  Named list mapping a broad group name to the numeric \`G2\` codes
  (default \[caf2021_g2_groups()\]).

- include_household:

  Logical. Merge the Hogar Agricola tables (covers natural-person
  producers only – legal-person producers will get NAs for those
  columns). Default TRUE.

- include_crop_surface:

  Logical. Aggregate the \`seccion_9\_\*\` parcel files into farm-level
  area-per-crop variables. Default TRUE. Skip to read fewer files
  (\`prepare_caf_data\` is dominated by I/O).

- verbose:

  Logical. Print progress.

## Value

A data frame with one row per \`GUID\`.

## Real file layout (as of 2024 release)

INE distributes two parallel databases. Point \`data_dir\` at the folder
that contains them:


      data_dir/
      |-- Actividad Silvoagropecuaria/
      |   |-- seccion_1.csv               # UPA-level core (G1-G4, SUP_UPA)
      |   |-- seccion_5.csv               # Administrator (ID39, ID40)
      |   |-- seccion_9_cereales.csv      # Surface by crop (one file per group)
      |   |-- seccion_9_hortalizas.csv
      |   |-- seccion_9_frutales.csv
      |   |-- seccion_9_vinas.csv
      |   |-- seccion_11.csv              # Practices: PM213-PM227 (fert, pest)
      |   |-- seccion_12.csv              # Irrigation: AR228-AR229
      |   |-- seccion_13_activos.csv      # AC242 (infrastructure)
      |   |-- seccion_13_maquinaria.csv   # AC230-AC238 (machinery + value)
      |   `-- ...
      `-- Hogar agricola/                 # Natural-person producers only
          |-- gestion.csv                 # TR244, TR250, HP280_2
          |-- actividad_agricola.csv      # US61_*, GA* (land use, livestock)
          |-- seccion_15_hogar.csv        # HP261-HP276 (household chars)
          `-- seccion_15_hogar_oa.csv

CSVs use \`;\` as separator and UTF-8 with BOM; \`read.csv2()\` is used
internally.

## What the census does NOT contain

The CAF is structural. Key gaps for a Just-Pope application:

- No crop-level yield or production quantity.

- No farm-level prices.

- No labour counts in the productive database (TR244 and TR250 in
  \`gestion.csv\` are only *yes/no* indicators for having permanent /
  temporary workers).

- No fertilizer/pesticide expenditure – only categorical use indicators
  (PM213-PM214).

- HP280_1 (sales band) is **not** included in the public release; only
  HP280_2 (band type, 1 = annual / 2 = monthly) is shipped. The function
  fills \`sales_band_code\` from HP280_2 but cannot map it to a peso
  amount without HP280_1.

The closest output proxy available within the census alone is
\`machinery_value_clp\` (a capital stock). For a true yield-based
replication, merge external ODEPA data by \`CUT_COMUNA\`.

## Examples

``` r
if (FALSE) { # \dontrun{
caf <- prepare_caf_data("ChileCensusAg/")
table(caf$crop_group)

fit <- jp_fit(
  data                 = caf,
  selection_var        = "hortalizas",
  selection_covariates = c("CUT_REGION","admin_age","admin_female",
                           "irrigation_river","irrigation_well"),
  output_var           = "machinery_value_band",       # capital-stock proxy
  input_vars           = c("total_surface_ha","machinery_count",
                           "infrastructure_count","irrigated_ha"),
  shifter_vars         = c("fertilizer_use","pesticide_use","CUT_REGION"),
  bootstrap_reps       = 200
)
} # }
```
