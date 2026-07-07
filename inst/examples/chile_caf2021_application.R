# Empirical application of JPselection to the Chilean Agricultural Census 2021
# (VIII Censo Nacional Agropecuario y Forestal). The folder structure
# expected by prepare_caf_data() is the one INE actually ships:
#
#   ChileCensusAg/
#     Actividad Silvoagropecuaria/seccion_*.csv
#     Hogar agricola/*.csv
#
# Workflow:
#   1. prepare_caf_data()  -- joins the section CSVs to one row per UPA
#   2. jp_fit()            -- 3-step Koundouri-Nauges pipeline
#   3. summary, plot, jp_export to Excel/LaTeX

library(JPselection)
library(ggplot2)

data_dir <- "ChileCensusAg/"
if (!dir.exists(data_dir)) {
  stop("Set `data_dir` to the folder containing 'Actividad Silvoagropecuaria/' ",
       "and 'Hogar agricola/' downloaded from INE.")
}

# ---------------------------------------------------------------------------
# 1. Prep: 175k farms aggregated to one row per UPA
# ---------------------------------------------------------------------------
# Cache to .rds so repeated runs don't re-read 360 MB of CSVs.
cache_path <- "caf_prepared.rds"
if (file.exists(cache_path)) {
  caf <- readRDS(cache_path)
} else {
  caf <- prepare_caf_data(data_dir)
  saveRDS(caf, cache_path)
}

# Focus on the extended questionnaire only -- the abbreviated questionnaire
# (Tipo_Cuest == 2) has only a handful of fields populated.
# Also drop suspicious surface values (>10,000 ha -- a handful of records
# appear to be in m^2 rather than ha; see surface_suspicious flag).
# Keep only commercial farms with machinery and crop specialisation.
caf <- caf[!is.na(caf$Tipo_Cuest) & caf$Tipo_Cuest == 1 &
             !is.na(caf$crop_group) &
             caf$surface_suspicious == 0 &
             caf$total_surface_ha > 0.1 &
             caf$machinery_count > 0, ]

cat("Sample size after filtering:", nrow(caf), "\n")
print(table(caf$crop_group))

# ---------------------------------------------------------------------------
# 2. Fit two crop-group models with the Koundouri-Nauges pipeline
# ---------------------------------------------------------------------------
selection_covariates <- c("CUT_REGION",
                          "irrigation_river","irrigation_well",
                          "irrigation_canal","has_tractor")
input_vars   <- c("total_surface_ha","machinery_count",
                  "infrastructure_count","irrigated_ha")
shifter_vars <- c("has_tractor","any_irrigation","CUT_REGION")

# Drop invalid machinery-value bands (sentinels coded as -1).
caf <- caf[!is.na(caf$machinery_value_band) & caf$machinery_value_band > 0, ]

# Capital-stock proxy: maximum machinery-value band (ordinal 1-10).
caf$output_proxy <- caf$machinery_value_band

# Ensure all input vars are strictly positive for the Cobb-Douglas
# risk function. Add 1 to count variables.
for (v in c("machinery_count","infrastructure_count")) caf[[v]] <- caf[[v]] + 1
caf$irrigated_ha <- caf$irrigated_ha + 0.01

fit_hortalizas <- jp_fit(
  data                 = caf,
  selection_var        = "hortalizas",
  selection_covariates = selection_covariates,
  output_var           = "output_proxy",
  input_vars           = input_vars,
  shifter_vars         = shifter_vars,
  bootstrap_reps       = 200,
  seed                 = 1
)

fit_frutales <- jp_fit(
  data                 = caf,
  selection_var        = "frutales",
  selection_covariates = selection_covariates,
  output_var           = "output_proxy",
  input_vars           = input_vars,
  shifter_vars         = shifter_vars,
  bootstrap_reps       = 200,
  seed                 = 2
)

cat("\n========== HORTALIZAS ==========\n"); summary(fit_hortalizas)
cat("\n========== FRUTALES ==========\n");   summary(fit_frutales)

# ---------------------------------------------------------------------------
# 3. Save figures and tables
# ---------------------------------------------------------------------------
dir.create("chile_results", showWarnings = FALSE)
ggsave("chile_results/fig_risk_hortalizas.png",
       plot(fit_hortalizas), width = 8, height = 4.5, dpi = 200, bg = "white")
ggsave("chile_results/fig_risk_frutales.png",
       plot(fit_frutales),   width = 8, height = 4.5, dpi = 200, bg = "white")
ggsave("chile_results/fig_probit_hortalizas.png",
       plot(fit_hortalizas, what = "probit"),
       width = 8, height = 4, dpi = 200, bg = "white")

jp_export(fit_hortalizas, "chile_results/hortalizas.xlsx")
jp_export(fit_hortalizas, "chile_results/hortalizas.tex")
jp_export(fit_frutales,   "chile_results/frutales.xlsx")
jp_export(fit_frutales,   "chile_results/frutales.tex")

cat("\nDone. Results in ./chile_results/\n")
