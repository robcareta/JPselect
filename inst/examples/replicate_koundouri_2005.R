# Replication of Koundouri & Nauges (2005, JARE 30(3):597-608) using JPselection.
#
# This script fits the with/without selectivity comparison for both crop
# groups (vegetables and cereals), prints the same tables shown in the
# paper, and saves the three diagnostic plots.
#
# Run from the package root with:
#   Rscript inst/examples/replicate_koundouri_2005.R
# or interactively after devtools::load_all().

if (!exists("BOOTSTRAP_REPS")) BOOTSTRAP_REPS <- 500
if (!exists("SEED"))           SEED           <- 42

library(JPselection)
library(ggplot2)

dir.create("figures", showWarnings = FALSE)
dir.create("tables",  showWarnings = FALSE)

farms <- simulate_kiti_data(seed = SEED)
cat("Sample composition:\n"); print(table(farms$crop))

selection_covariates <- c("rainfall","irrigated",
                          "dist_town","dist_coast","experience")
input_vars   <- c("fertilizers","pesticides","labor","water")
shifter_vars <- c("machinery","rainfall","irrigated",
                  "dist_town","dist_coast","experience")

# ---------- Vegetables ------------------------------------------------------
fit_veg <- jp_fit(
  data                 = farms,
  selection_var        = "vegetables",
  selection_covariates = selection_covariates,
  output_var           = "revenue",
  input_vars           = input_vars,
  shifter_vars         = shifter_vars,
  bootstrap_reps       = BOOTSTRAP_REPS,
  seed                 = SEED
)

# ---------- Cereals --------------------------------------------------------
fit_cer <- jp_fit(
  data                 = farms,
  selection_var        = "cereals",
  selection_covariates = selection_covariates,
  output_var           = "revenue",
  input_vars           = input_vars,
  shifter_vars         = shifter_vars,
  bootstrap_reps       = BOOTSTRAP_REPS,
  seed                 = SEED + 100
)

cat("\n========== VEGETABLES ==========\n")
summary(fit_veg)

cat("\n========== CEREALS ==========\n")
summary(fit_cer)

# Plots: one risk-function chart per crop, side by side via patchwork
# (or saved individually if patchwork is not available).
ggsave("figures/fig1_probit_vegetables.png",
       plot(fit_veg, what = "probit"),
       width = 8, height = 4, dpi = 200, bg = "white")
ggsave("figures/fig1_probit_cereals.png",
       plot(fit_cer, what = "probit"),
       width = 8, height = 4, dpi = 200, bg = "white")
ggsave("figures/fig2_risk_vegetables.png",
       plot(fit_veg, what = "risk"),
       width = 8, height = 4.5, dpi = 200, bg = "white")
ggsave("figures/fig2_risk_cereals.png",
       plot(fit_cer, what = "risk"),
       width = 8, height = 4.5, dpi = 200, bg = "white")
ggsave("figures/fig3_mean_vegetables.png",
       plot(fit_veg, what = "mean"),
       width = 8, height = 5, dpi = 200, bg = "white")
ggsave("figures/fig3_mean_cereals.png",
       plot(fit_cer, what = "mean"),
       width = 8, height = 5, dpi = 200, bg = "white")

# Export every table to Excel, LaTeX, and CSV for both crop groups.
jp_export(fit_veg, "tables/results_vegetables.xlsx")
jp_export(fit_veg, "tables/results_vegetables.tex")
jp_export(fit_veg, "tables/csv_vegetables/")
jp_export(fit_cer, "tables/results_cereals.xlsx")
jp_export(fit_cer, "tables/results_cereals.tex")
jp_export(fit_cer, "tables/csv_cereals/")

cat("\nSaved figures to ./figures/ and tables to ./tables/\n")
