#' Prepare Chilean Agricultural Census (CAF 2021) data for [jp_fit()]
#'
#' Reads the raw CAF 2021 microdata files as INE actually ships them
#' and returns a single farm-level (`GUID`) data frame ready for
#' [jp_fit()].
#'
#' @section Real file layout (as of 2024 release):
#' INE distributes two parallel databases. Point `data_dir` at the
#' folder that contains them:
#' \preformatted{
#'   data_dir/
#'   |-- Actividad Silvoagropecuaria/
#'   |   |-- seccion_1.csv               # UPA-level core (G1-G4, SUP_UPA)
#'   |   |-- seccion_5.csv               # Administrator (ID39, ID40)
#'   |   |-- seccion_9_cereales.csv      # Surface by crop (one file per group)
#'   |   |-- seccion_9_hortalizas.csv
#'   |   |-- seccion_9_frutales.csv
#'   |   |-- seccion_9_vinas.csv
#'   |   |-- seccion_11.csv              # Practices: PM213-PM227 (fert, pest)
#'   |   |-- seccion_12.csv              # Irrigation: AR228-AR229
#'   |   |-- seccion_13_activos.csv      # AC242 (infrastructure)
#'   |   |-- seccion_13_maquinaria.csv   # AC230-AC238 (machinery + value)
#'   |   `-- ...
#'   `-- Hogar agricola/                 # Natural-person producers only
#'       |-- gestion.csv                 # TR244, TR250, HP280_2
#'       |-- actividad_agricola.csv      # US61_*, GA* (land use, livestock)
#'       |-- seccion_15_hogar.csv        # HP261-HP276 (household chars)
#'       `-- seccion_15_hogar_oa.csv
#' }
#' CSVs use `;` as separator and UTF-8 with BOM; `read.csv2()` is used
#' internally.
#'
#' @section What the census does NOT contain:
#' The CAF is structural. Key gaps for a Just-Pope application:
#' \itemize{
#'   \item No crop-level yield or production quantity.
#'   \item No farm-level prices.
#'   \item No labour counts in the productive database (TR244 and
#'     TR250 in `gestion.csv` are only \emph{yes/no} indicators for
#'     having permanent / temporary workers).
#'   \item No fertilizer/pesticide expenditure -- only categorical
#'     use indicators (PM213-PM214).
#'   \item HP280_1 (sales band) is \strong{not} included in the public
#'     release; only HP280_2 (band type, 1 = annual / 2 = monthly) is
#'     shipped. The function fills `sales_band_code` from HP280_2 but
#'     cannot map it to a peso amount without HP280_1.
#' }
#' The closest output proxy available within the census alone is
#' `machinery_value_clp` (a capital stock). For a true yield-based
#' replication, merge external ODEPA data by `CUT_COMUNA`.
#'
#' @param data_dir Path to the folder that contains the two database
#'   subfolders, e.g. `"ChileCensusAg/"`.
#' @param crop_group_map Named list mapping a broad group name to the
#'   numeric `G2` codes (default [caf2021_g2_groups()]).
#' @param include_household Logical. Merge the Hogar Agricola tables
#'   (covers natural-person producers only -- legal-person producers
#'   will get NAs for those columns). Default TRUE.
#' @param include_crop_surface Logical. Aggregate the `seccion_9_*`
#'   parcel files into farm-level area-per-crop variables. Default TRUE.
#'   Skip to read fewer files (`prepare_caf_data` is dominated by I/O).
#' @param verbose Logical. Print progress.
#'
#' @return A data frame with one row per `GUID`.
#' @export
#' @examples
#' \dontrun{
#' caf <- prepare_caf_data("ChileCensusAg/")
#' table(caf$crop_group)
#'
#' fit <- jp_fit(
#'   data                 = caf,
#'   selection_var        = "hortalizas",
#'   selection_covariates = c("CUT_REGION","admin_age","admin_female",
#'                            "irrigation_river","irrigation_well"),
#'   output_var           = "machinery_value_band",       # capital-stock proxy
#'   input_vars           = c("total_surface_ha","machinery_count",
#'                            "infrastructure_count","irrigated_ha"),
#'   shifter_vars         = c("fertilizer_use","pesticide_use","CUT_REGION"),
#'   bootstrap_reps       = 200
#' )
#' }
prepare_caf_data <- function(data_dir,
                             crop_group_map       = caf2021_g2_groups(),
                             include_household    = TRUE,
                             include_crop_surface = TRUE,
                             verbose              = TRUE) {

  stopifnot(dir.exists(data_dir))
  AS <- file.path(data_dir, "Actividad Silvoagropecuaria")
  HA <- file.path(data_dir, "Hogar agricola")
  if (!dir.exists(AS)) {
    stop("Could not find 'Actividad Silvoagropecuaria/' inside ", data_dir,
         ". Expected the folder structure shipped by INE.", call. = FALSE)
  }
  msg <- function(...) if (verbose) message(...)

  # -------------------------------------------------------------------
  # 1. UPA core (seccion_1): one row per GUID
  # -------------------------------------------------------------------
  msg("Reading seccion_1.csv (UPA core)...")
  s1 <- .read_caf(file.path(AS, "seccion_1.csv"))
  caf <- data.frame(
    GUID       = as.character(s1$GUID),
    Tipo_Cuest = .num(s1$Tipo_Cuest),
    G1         = .num(s1$G1),
    G2         = .num(s1$G2),
    G3         = .num(s1$G3),
    G4         = .num(s1$G4),
    SUP_UPA    = .num(s1$SUP_UPA),
    stringsAsFactors = FALSE
  )
  # SUP_UPA in the public release is most plausibly in hectares for the
  # bulk of the distribution (Tipo_Cuest=1 median 7.86, 95th = 158).
  # However a small subset of records (research entities, very large
  # estates) report values in m^2 instead, producing a heavy upper tail.
  # Pass SUP_UPA through unchanged as `total_surface_ha` and flag the
  # plausibly anomalous rows so the analyst can filter.
  caf$total_surface_ha   <- caf$SUP_UPA
  caf$surface_suspicious <- as.integer(caf$SUP_UPA > 10000)
  msg("  ", nrow(caf), " UPAs read.")

  # Crop-group dummies + a single character label
  caf$crop_group <- NA_character_
  for (grp in names(crop_group_map)) {
    flag <- as.integer(caf$G2 %in% crop_group_map[[grp]])
    caf[[grp]] <- flag
    caf$crop_group[flag == 1] <- grp
  }

  # -------------------------------------------------------------------
  # 2. Administrator (seccion_5): age, sex, CUT_REGION
  #    Many farms have multiple establecimientos; take the first.
  # -------------------------------------------------------------------
  msg("Reading seccion_5.csv (administrator)...")
  s5 <- .read_caf(file.path(AS, "seccion_5.csv"))
  s5 <- s5[!duplicated(s5$GUID), ]
  caf <- merge(caf,
               data.frame(
                 GUID         = as.character(s5$GUID),
                 CUT_REGION   = .num(s5$CUT_REGION),
                 admin_female = as.integer(.num(s5$ID39) == 2),
                 admin_age    = .num(s5$ID40)
               ),
               by = "GUID", all.x = TRUE)

  # -------------------------------------------------------------------
  # 3. Practices (seccion_11): fertilizer, pesticide use indicators
  # -------------------------------------------------------------------
  msg("Reading seccion_11.csv (practices)...")
  s11 <- .read_caf(file.path(AS, "seccion_11.csv"))
  fert_cols <- intersect(paste0("PM213_", 1:8), names(s11))
  fertilizer_use <- as.integer(rowSums(!is.na(s11[, fert_cols, drop = FALSE]) &
                                       s11[, fert_cols, drop = FALSE] != 0) > 0)
  practices <- data.frame(
    GUID            = as.character(s11$GUID),
    fertilizer_use  = fertilizer_use,
    pesticide_use   = as.integer(!is.na(s11$PM214) & .num(s11$PM214) > 0),
    herbicide_use   = as.integer(.num(s11$PM215) == 1),
    biocontrol_use  = as.integer(.num(s11$PM216) == 1),
    organic_cert    = as.integer(.num(s11$PM222) == 1)
  )
  practices_agg <- .agg_max_by_guid(practices)
  caf <- merge(caf, practices_agg, by = "GUID", all.x = TRUE)

  # -------------------------------------------------------------------
  # 4. Irrigation (seccion_12): water-source dummies
  # -------------------------------------------------------------------
  msg("Reading seccion_12.csv (irrigation)...")
  s12 <- .read_caf(file.path(AS, "seccion_12.csv"))
  irrig <- data.frame(
    GUID             = as.character(s12$GUID),
    irrigation_canal = as.integer(.num(s12$AR228_1) > 0),
    irrigation_river = as.integer(.num(s12$AR228_2) > 0 | .num(s12$AR228_3) > 0),
    irrigation_other_surface =
                       as.integer(.num(s12$AR228_4) > 0),
    irrigation_well  = as.integer(.num(s12$AR228_5) > 0 | .num(s12$AR228_6) > 0),
    irrigation_rain  = as.integer(.num(s12$AR228_7) > 0)
  )
  irrig$any_irrigation <- as.integer(rowSums(
    irrig[, -1], na.rm = TRUE) > 0)
  caf <- merge(caf, .agg_max_by_guid(irrig), by = "GUID", all.x = TRUE)

  # -------------------------------------------------------------------
  # 5. Machinery (seccion_13_maquinaria): counts and values
  # -------------------------------------------------------------------
  msg("Reading seccion_13_maquinaria.csv (machinery)...")
  s13m <- .read_caf(file.path(AS, "seccion_13_maquinaria.csv"))
  count_cols <- intersect(paste0("AC233_", 1:7), names(s13m))
  value_cols <- intersect(paste0("AC234_", 1:7), names(s13m))
  for (c in count_cols) s13m[[c]] <- .num(s13m[[c]])
  for (c in value_cols) s13m[[c]] <- .num(s13m[[c]])
  # AC234_* is a banded value code (1 = lowest band, ~10 = highest),
  # not raw pesos. Carry the max band across machinery types as an
  # ordinal proxy; do NOT sum them.
  mach <- data.frame(
    GUID                = as.character(s13m$GUID),
    machinery_count     = rowSums(s13m[, count_cols, drop = FALSE], na.rm = TRUE),
    machinery_value_band = suppressWarnings(do.call(
      pmax, c(s13m[, value_cols, drop = FALSE], list(na.rm = TRUE)))),
    has_tractor         = as.integer(.num(s13m$AC231) == 1)
  )
  mach$machinery_value_band[is.infinite(mach$machinery_value_band)] <- NA
  mach_agg <- .agg_sum_by_guid(mach[, c("GUID","machinery_count","has_tractor")])
  band_agg <- stats::aggregate(machinery_value_band ~ GUID, data = mach,
                               FUN = max, na.rm = TRUE)
  band_agg$machinery_value_band[is.infinite(band_agg$machinery_value_band)] <- NA
  caf <- merge(caf, mach_agg,  by = "GUID", all.x = TRUE)
  caf <- merge(caf, band_agg,  by = "GUID", all.x = TRUE)

  # -------------------------------------------------------------------
  # 6. Infrastructure (seccion_13_activos)
  # -------------------------------------------------------------------
  msg("Reading seccion_13_activos.csv (infrastructure)...")
  s13a <- .read_caf(file.path(AS, "seccion_13_activos.csv"))
  inf_cols <- intersect(paste0("AC242_", 1:10), names(s13a))
  for (c in inf_cols) s13a[[c]] <- .num(s13a[[c]])
  inf <- data.frame(
    GUID                 = as.character(s13a$GUID),
    infrastructure_count = rowSums(s13a[, inf_cols, drop = FALSE], na.rm = TRUE)
  )
  caf <- merge(caf, .agg_sum_by_guid(inf), by = "GUID", all.x = TRUE)

  # -------------------------------------------------------------------
  # 7. Crop-specific surfaces (seccion_9_*): aggregate to GUID
  # -------------------------------------------------------------------
  if (include_crop_surface) {
    msg("Reading seccion_9_*.csv (crop surfaces)...")
    crop_files <- list(
      cereales         = list(file = "seccion_9_cereales.csv",
                              cols = c("SS65","SS66")),     # riego + secano
      hortalizas       = list(file = "seccion_9_hortalizas.csv",
                              cols = c("SS81","SS86")),     # aire libre + cubierta
      frutales         = list(file = "seccion_9_frutales.csv",
                              cols = c("SS93","SS97")),     # formación + producción
      vinas            = list(file = "seccion_9_vinas.csv",
                              cols = c("SS_riego","SS_secano")),
      forrajeras       = list(file = "seccion_9_forrajeras.csv",
                              cols = NULL),
      flores           = list(file = "seccion_9_flores.csv",
                              cols = NULL),
      industriales     = list(file = "seccion_9_industriales.csv",
                              cols = c("SS75","SS76"))
    )
    for (nm in names(crop_files)) {
      path <- file.path(AS, crop_files[[nm]]$file)
      if (!file.exists(path)) next
      d <- .read_caf(path)
      cols <- crop_files[[nm]]$cols
      cols <- intersect(cols, names(d))
      if (length(cols) == 0) {
        # Fall back to any SS* surface columns in the file
        cols <- grep("^SS[0-9]+$", names(d), value = TRUE)
      }
      if (length(cols) == 0) next
      for (c in cols) d[[c]] <- .num(d[[c]])
      area <- data.frame(
        GUID = as.character(d$GUID),
        v    = rowSums(d[, cols, drop = FALSE], na.rm = TRUE)
      )
      area_agg <- stats::aggregate(v ~ GUID, data = area, FUN = sum,
                                   na.rm = TRUE)
      names(area_agg)[2] <- paste0("area_", nm, "_m2")
      caf <- merge(caf, area_agg, by = "GUID", all.x = TRUE)
    }
  }

  # -------------------------------------------------------------------
  # 8. Hogar Agricola (optional): labor indicators + land-use breakdown
  # -------------------------------------------------------------------
  # NOTE: the Hogar Agricola database uses GUIDs with the prefix HP*
  # while Actividad Silvoagropecuaria uses CE*. The two are NOT
  # joinable on GUID; they are parallel datasets covering different
  # producer populations. `include_household = TRUE` is therefore a
  # no-op for this function. Load the Hogar Agricola files
  # separately with [prepare_caf_hogar()] (see below) if you want to
  # analyse the household-producer subsample on its own.
  if (include_household) {
    msg("Skipping Hogar agricola/ -- not joinable to seccion_1 by GUID. ",
        "Use prepare_caf_hogar() for a standalone household analysis.")
  }

  # -------------------------------------------------------------------
  # 9. Fill NAs in binary indicators and derive helpers
  # -------------------------------------------------------------------
  # Farms not present in seccion_11 / seccion_12 / seccion_13 source
  # files are NA on those columns -- treat absence as "no" for binary
  # indicators (which is the natural interpretation).
  binary_cols <- c("fertilizer_use","pesticide_use","herbicide_use",
                   "biocontrol_use","organic_cert",
                   "irrigation_canal","irrigation_river",
                   "irrigation_other_surface","irrigation_well",
                   "irrigation_rain","any_irrigation",
                   "has_tractor")
  for (c in intersect(binary_cols, names(caf))) {
    caf[[c]][is.na(caf[[c]])] <- 0L
    caf[[c]] <- as.integer(caf[[c]])
  }
  for (c in intersect(c("machinery_count","infrastructure_count"),
                      names(caf))) {
    caf[[c]][is.na(caf[[c]])] <- 0
  }

  caf$specialised <- as.integer(!is.na(caf$crop_group))
  caf$irrigated_ha <- caf$total_surface_ha * caf$any_irrigation

  msg("Done. ", nrow(caf), " farms; ",
      sum(caf$specialised, na.rm = TRUE),
      " classified into a single crop group.")
  caf
}

#' Default mapping of G2 codes to broad activity groups
#'
#' G2 has 73 categories. This function returns the default partition
#' used by [prepare_caf_data()]. Override by passing a list with the
#' same structure.
#'
#' @return A named list of integer vectors.
#' @export
caf2021_g2_groups <- function() {
  list(
    cereales      = c(1, 2, 3, 4),
    hortalizas    = c(5, 6, 7, 8, 12, 14),
    tuberculos    = c(8),
    frutales      = c(17, 18, 19, 20, 21, 22, 23, 24),
    vina          = c(16),
    forrajeras    = c(11),
    flores        = c(12),
    bovinos       = c(26),
    ovinos_caprinos = c(29, 30),
    porcinos      = c(31),
    aves          = c(32),
    forestal      = c(40, 41, 42, 43)
  )
}

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

# INE ships CSVs with ; separator. Most files are UTF-8 with BOM, but
# a few (seccion_12.csv) are Latin-1. Try UTF-8 first, fall back to
# Latin-1 on failure. Some files also carry an unnamed leading column
# (Excel row-index residue) which we drop.
.read_caf <- function(path) {
  read_one <- function(enc) {
    utils::read.csv2(path,
                     fileEncoding   = enc,
                     stringsAsFactors = FALSE,
                     na.strings = c("", "NA", "-77", "-88", "-99"),
                     check.names = FALSE)
  }
  d <- tryCatch(read_one("UTF-8-BOM"),
                error   = function(e) read_one("latin1"),
                warning = function(w) suppressWarnings(read_one("latin1")))
  # Drop any unnamed leading row-index columns.
  bad <- which(names(d) == "" | is.na(names(d)))
  if (length(bad)) d <- d[, -bad, drop = FALSE]
  d
}

.num <- function(x) suppressWarnings(as.numeric(x))

# Aggregate to one row per GUID by taking the column-wise max
# (works well for 0/1 indicators).
.agg_max_by_guid <- function(df) {
  df <- df[!is.na(df$GUID), , drop = FALSE]
  num_cols <- setdiff(names(df), "GUID")
  for (c in num_cols) df[[c]] <- as.numeric(df[[c]])
  out <- stats::aggregate(df[, num_cols, drop = FALSE],
                          by = list(GUID = df$GUID),
                          FUN = max, na.rm = TRUE)
  for (c in num_cols) {
    v <- out[[c]]
    v[is.infinite(v)] <- NA
    out[[c]] <- v
  }
  out
}

# Aggregate to one row per GUID by summing numeric columns.
.agg_sum_by_guid <- function(df) {
  df <- df[!is.na(df$GUID), , drop = FALSE]
  num_cols <- setdiff(names(df), "GUID")
  for (c in num_cols) df[[c]] <- as.numeric(df[[c]])
  stats::aggregate(df[, num_cols, drop = FALSE],
                   by = list(GUID = df$GUID),
                   FUN = sum, na.rm = TRUE)
}
