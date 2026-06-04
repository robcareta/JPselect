#' Simulate a Kiti-Cyprus-like farm dataset
#'
#' Generates a synthetic cross-section that mimics the structure of the
#' Koundouri & Nauges (2005) sample: 239 farms classified into vegetables
#' (95), cereals (89), and citrus (55) producers, with inputs and revenues
#' whose moments roughly match Table 1 of the paper. The crop-choice
#' process is driven by environmental and farmer characteristics so the
#' Heckman selection step has signal to recover.
#'
#' This is for methodology demonstration only -- it is not the original
#' Cyprus data and is not intended to reproduce the paper's exact point
#' estimates.
#'
#' @param n_total Integer. Total number of farms (default 239).
#' @param n_veg,n_cer,n_cit Integer. Target counts per crop.
#' @param seed Optional integer seed.
#'
#' @return A data frame with one row per farm and crop-choice dummies
#'   `vegetables`, `cereals`, `citrus`.
#' @importFrom stats rnorm rgamma sd
#' @export
#' @examples
#' farms <- simulate_kiti_data(seed = 1)
#' table(farms$crop)
simulate_kiti_data <- function(n_total = 239,
                               n_veg = 95, n_cer = 89, n_cit = 55,
                               seed = 1) {
  if (!is.null(seed)) set.seed(seed)
  stopifnot(n_veg + n_cer + n_cit == n_total)

  rainfall   <- stats::rnorm(n_total, mean = 25, sd = 4)
  irrigated  <- pmax(0, stats::rnorm(n_total, mean = 40, sd = 25))
  dist_town  <- pmax(0.5, stats::rnorm(n_total, mean = 10, sd = 5))
  dist_coast <- pmax(0.5, stats::rnorm(n_total, mean = 8, sd = 4))
  experience <- pmax(1, stats::rnorm(n_total, mean = 25, sd = 12))
  machinery  <- pmax(0, stats::rnorm(n_total, mean = 5, sd = 3))

  u_veg <- 1.3 + 0.012 * irrigated + 0.035 * dist_town -
           0.080 * dist_coast - 0.030 * experience -
           0.030 * rainfall + stats::rnorm(n_total, 0, 1.2)
  u_cer <- -1.5 - 0.012 * irrigated - 0.070 * dist_town +
           0.100 * dist_coast + 0.037 * experience +
           0.020 * rainfall + stats::rnorm(n_total, 0, 1.2)
  # Keep this draw to preserve RNG-state reproducibility with the original
  # script-based version of simulate_kiti_data (assignment is by exclusion,
  # so u_cit is never actually consulted, but its draw must still happen).
  invisible(stats::rnorm(n_total, 0, 1.2))

  rank_veg <- order(u_veg, decreasing = TRUE)
  veg_idx  <- rank_veg[seq_len(n_veg)]
  remain   <- setdiff(seq_len(n_total), veg_idx)
  rank_cer <- remain[order(u_cer[remain], decreasing = TRUE)]
  cer_idx  <- rank_cer[seq_len(n_cer)]
  cit_idx  <- setdiff(remain, cer_idx)

  crop <- character(n_total)
  crop[veg_idx] <- "vegetables"
  crop[cer_idx] <- "cereals"
  crop[cit_idx] <- "citrus"

  surface <- pmax(0.2, stats::rgamma(n_total, shape = 0.6, scale = 7))

  draw_input <- function(mean_veg, mean_cer, mean_cit,
                         sd_veg, sd_cer, sd_cit) {
    m <- ifelse(crop == "vegetables", mean_veg,
         ifelse(crop == "cereals",    mean_cer, mean_cit))
    s <- ifelse(crop == "vegetables", sd_veg,
         ifelse(crop == "cereals",    sd_cer, sd_cit))
    shape <- pmax(0.3, (m / s)^2)
    scale <- s^2 / pmax(m, 1e-6)
    pmax(1, stats::rgamma(n_total, shape = shape, scale = scale))
  }

  fertilizers <- draw_input(243, 120, 180, 444, 325, 350)
  pesticides  <- draw_input(152,  51, 100, 419, 151, 250)
  labor       <- draw_input(230, 105, 160, 714, 212, 400)
  water       <- draw_input(118,  50,  90, 600, 194, 300)

  base_rev <- ifelse(crop == "vegetables", 2800,
              ifelse(crop == "cereals",     750, 1800))
  mean_y <- base_rev +
    0.8 * fertilizers + 1.5 * pesticides +
    0.4 * labor + 1.2 * water +
    35 * irrigated - 50 * dist_coast + 60 * dist_town -
    20 * experience + 80 * machinery
  sigma_y <- exp(
    6 +
    0.45 * .scale_log(fertilizers) +
    0.20 * .scale_log(pesticides) -
    0.35 * .scale_log(labor) -
    0.10 * .scale_log(water)
  )
  revenue <- pmax(50, mean_y + sigma_y * stats::rnorm(n_total))

  data.frame(
    farm_id     = seq_len(n_total),
    crop        = crop,
    vegetables  = as.integer(crop == "vegetables"),
    cereals     = as.integer(crop == "cereals"),
    citrus      = as.integer(crop == "citrus"),
    surface     = surface,
    revenue     = revenue,
    fertilizers = fertilizers,
    pesticides  = pesticides,
    labor       = labor,
    water       = water,
    machinery   = machinery,
    rainfall    = rainfall,
    irrigated   = irrigated,
    dist_town   = dist_town,
    dist_coast  = dist_coast,
    experience  = experience,
    stringsAsFactors = FALSE
  )
}

.scale_log <- function(x) {
  l <- log(pmax(x, 1))
  (l - mean(l)) / stats::sd(l)
}
