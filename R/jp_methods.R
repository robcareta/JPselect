#' @export
print.jpfit <- function(x, digits = 3, alpha = 0.10, ...) {
  cfg <- x$config
  cat("Just-Pope production function with Heckman selection\n")
  cat("Koundouri & Nauges (2005) three-step procedure\n")
  cat(strrep("-", 55), "\n", sep = "")
  cat(sprintf("  Selection equation : %s ~ %s\n",
              cfg$selection_var,
              paste(cfg$selection_covariates, collapse = " + ")))
  cat(sprintf("  Output             : %s\n", cfg$output_var))
  cat(sprintf("  Inputs             : %s\n",
              paste(cfg$input_vars, collapse = ", ")))
  cat(sprintf("  Sample             : %d total, %d selected (%s == 1)\n",
              cfg$n_total, cfg$n_selected, cfg$selection_var))
  cat(sprintf("  Bootstrap reps     : %d\n", cfg$bootstrap_reps))
  cat("\nRisk function coefficients (variance elasticities):\n")
  tab <- .risk_compare_table(x, digits = digits)
  print(tab, row.names = FALSE)
  cat("\n")
  .print_jpfit_interpretation(x, alpha = alpha)
  invisible(x)
}

# Narrative interpretation of risk-function results: which inputs are
# risk-increasing/decreasing, where selectivity correction changes the
# conclusion, and whether the Mill's ratio in the mean function is
# significant. Designed to print under the risk-function table in
# print.jpfit().
.print_jpfit_interpretation <- function(x, alpha = 0.10) {
  cat(strrep("-", 55), "\n", sep = "")
  cat("Interpretation\n")
  cat(strrep("-", 55), "\n", sep = "")

  rw <- x$risk_with$coefficients
  ro <- x$risk_without$coefficients
  inputs <- setdiff(rownames(rw), "(Intercept)")
  inputs <- intersect(inputs, rownames(ro))

  coef_w <- rw[inputs, "Coefficient"]
  p_w    <- rw[inputs, "p.Value"]
  coef_o <- ro[inputs, "Coefficient"]
  p_o    <- ro[inputs, "p.Value"]

  sig_w     <- !is.na(p_w) & p_w < alpha
  decreasing <- inputs[sig_w & coef_w < 0]
  increasing <- inputs[sig_w & coef_w > 0]

  cat(sprintf("At p < %.2f, with selectivity correction:\n", alpha))
  cat(sprintf("  Risk-DECREASING inputs : %s\n",
              if (length(decreasing)) paste(decreasing, collapse = ", ")
              else "(none)"))
  cat(sprintf("  Risk-INCREASING inputs : %s\n",
              if (length(increasing)) paste(increasing, collapse = ", ")
              else "(none)"))

  # Where does selectivity correction change the inference?
  sig_o    <- !is.na(p_o) & p_o < alpha
  flips    <- inputs[sig_w & sig_o & sign(coef_w) != sign(coef_o)]
  lost_sig <- inputs[!sig_w & sig_o]
  gain_sig <- inputs[sig_w & !sig_o]

  cat("\nDoes selectivity correction change the conclusion?\n")
  if (!length(flips) && !length(lost_sig) && !length(gain_sig)) {
    cat("  No -- the two specifications agree on every input.\n")
  } else {
    for (inp in flips) {
      cat(sprintf("  %s : sign FLIPS (%+.3f without -> %+.3f with)\n",
                  inp, coef_o[inp == inputs], coef_w[inp == inputs]))
    }
    for (inp in lost_sig) {
      cat(sprintf("  %s : significant without correction (p=%.3f) but ",
                  inp, p_o[inp == inputs]))
      cat(sprintf("NOT significant once corrected (p=%.3f)\n",
                  p_w[inp == inputs]))
    }
    for (inp in gain_sig) {
      cat(sprintf("  %s : NOT significant without correction (p=%.3f) but ",
                  inp, p_o[inp == inputs]))
      cat(sprintf("significant once corrected (p=%.3f)\n",
                  p_w[inp == inputs]))
    }
  }

  # Mill's ratio significance in the mean function -- the direct test
  # for selection bias.
  mw <- x$mean_with$coefficients
  imr_row <- rownames(mw)[grepl("^imr", rownames(mw))]
  if (length(imr_row) > 0) {
    imr_p <- mw[imr_row[1], "p.Value"]
    imr_c <- mw[imr_row[1], "Coefficient"]
    cat("\nSelection-bias test (Mill's ratio in the mean function):\n")
    if (!is.na(imr_p) && imr_p < alpha) {
      cat(sprintf("  coef = %+.3f, p = %.3f -- selection bias DETECTED.\n",
                  imr_c, imr_p))
      cat("  Prefer the 'with correction' column above.\n")
    } else if (!is.na(imr_p)) {
      cat(sprintf("  coef = %+.3f, p = %.3f -- no selection bias detected ",
                  imr_c, imr_p))
      cat("at this level.\n")
      cat("  The two specifications should give similar conclusions.\n")
    }
  }
  invisible(NULL)
}

#' @export
summary.jpfit <- function(object, digits = 3, ...) {
  cfg <- object$config

  cat("\n", strrep("=", 70), "\n",
      "Just-Pope production function with Heckman selection\n",
      "Koundouri & Nauges (2005) three-step procedure\n",
      strrep("=", 70), "\n\n", sep = "")

  cat(sprintf("Selection variable : %s\n", cfg$selection_var))
  cat(sprintf("Sample             : %d selected of %d (%.1f%%)\n",
              cfg$n_selected, cfg$n_total,
              100 * cfg$n_selected / cfg$n_total))
  cat(sprintf("Bootstrap reps     : %d\n", cfg$bootstrap_reps))

  cat("\n----- STEP 1. Probit selection equation -----\n")
  sel_tab <- summary(object$selection$model)$coefficients
  print(.format_coef_table(sel_tab, digits = digits), row.names = FALSE)

  cat("\n----- STEP 2. Mean production function (WITH selectivity) -----\n")
  cat(sprintf("Adjusted R-squared: %.3f\n", object$mean_with$adj_r2))
  print(.format_coef_table(object$mean_with$coefficients, digits = digits),
        row.names = FALSE)

  cat("\n----- STEP 3. Risk function: with vs without selectivity -----\n")
  print(.risk_compare_table(object, digits = digits), row.names = FALSE)

  cat("\n")
  .print_jpfit_interpretation(object, alpha = 0.10)

  invisible(object)
}

#' Plot the risk-function coefficients of a fitted `jpfit` object
#'
#' Produces the headline coefficient plot from Koundouri & Nauges (2005):
#' variance elasticities of each input under the with- and without-
#' selectivity-correction specifications, side by side.
#'
#' @param x A `jpfit` object.
#' @param ci Coverage for the displayed interval (default 0.95).
#' @param ... Unused; for S3 consistency.
#'
#' @return A ggplot object.
#' @importFrom ggplot2 ggplot aes geom_vline geom_errorbarh geom_point
#'   labs theme_minimal position_dodge
#' @export
plot.jpfit <- function(x, ci = 0.95, ...) {
  z <- stats::qnorm(0.5 + ci / 2)
  .plot_risk(x, z)
}

#' Extract risk-function coefficients
#'
#' @param object A `jpfit` object.
#' @param which One of "risk" (default), "mean", "selection". For "risk"
#'   and "mean", choose `correction = TRUE/FALSE` to pick the with- or
#'   without-IMR version.
#' @param correction Logical. Pick the corrected version when `TRUE`.
#' @param ... Unused.
#' @export
coef.jpfit <- function(object, which = c("risk","mean","selection"),
                       correction = TRUE, ...) {
  which <- match.arg(which)
  switch(which,
    selection = stats::coef(object$selection$model),
    mean      = if (correction) stats::coef(object$mean_with$model)
                else             stats::coef(object$mean_without$model),
    risk      = if (correction) stats::coef(object$risk_with$model)
                else             stats::coef(object$risk_without$model)
  )
}

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------
.format_coef_table <- function(tab, digits = 3) {
  tab <- as.data.frame(tab)
  est_col <- intersect(c("Estimate","Coefficient"), names(tab))[1]
  se_col  <- intersect(c("Std. Error","Std.Error"), names(tab))[1]
  z_col   <- intersect(c("z value","t.Statistic","t value"), names(tab))[1]
  p_col   <- intersect(c("Pr(>|z|)","p.Value","Pr(>|t|)"), names(tab))[1]
  stars <- ifelse(tab[[p_col]] < 0.01, "***",
           ifelse(tab[[p_col]] < 0.05, "**",
           ifelse(tab[[p_col]] < 0.10, "*", "")))
  data.frame(
    Variable    = rownames(tab),
    Coefficient = sprintf(paste0("%.", digits, "f"), tab[[est_col]]),
    Std.Error   = sprintf(paste0("%.", digits, "f"), tab[[se_col]]),
    Statistic   = sprintf(paste0("%.", digits, "f"), tab[[z_col]]),
    p.Value     = sprintf("%.3f", tab[[p_col]]),
    Sig         = stars,
    stringsAsFactors = FALSE,
    row.names   = NULL
  )
}

.risk_compare_table <- function(x, digits = 3) {
  rw <- x$risk_with$coefficients
  ro <- x$risk_without$coefficients
  keep <- setdiff(rownames(rw), "(Intercept)")
  data.frame(
    Input         = keep,
    Coef_with     = round(rw[keep, "Coefficient"], digits),
    SE_with       = round(rw[keep, "Std.Error"],   digits),
    t_with        = round(rw[keep, "t.Statistic"], digits),
    Coef_without  = round(ro[keep, "Coefficient"], digits),
    SE_without    = round(ro[keep, "Std.Error"],   digits),
    t_without     = round(ro[keep, "t.Statistic"], digits),
    row.names     = NULL
  )
}

# Risk-function plot: with vs without selectivity correction.
# Uses theme_minimal() and ggplot's default discrete palette so users
# can override with their own theme/scale via the `+` operator.
.plot_risk <- function(x, z) {
  build_one <- function(rf, spec) {
    tab <- rf$coefficients
    keep <- setdiff(rownames(tab), "(Intercept)")
    data.frame(
      Input    = keep,
      Estimate = tab[keep, "Coefficient"],
      SE       = tab[keep, "Std.Error"],
      Spec     = spec,
      row.names = NULL
    )
  }
  df <- rbind(
    build_one(x$risk_with,    "With selectivity correction"),
    build_one(x$risk_without, "Without selectivity correction")
  )
  df$Input <- factor(df$Input, levels = x$config$input_vars)
  df$Spec  <- factor(df$Spec,
                     levels = c("With selectivity correction",
                                "Without selectivity correction"))
  df$lo <- df$Estimate - z * df$SE
  df$hi <- df$Estimate + z * df$SE

  ggplot2::ggplot(df, ggplot2::aes(x = .data$Estimate, y = .data$Input,
                                   colour = .data$Spec)) +
    ggplot2::geom_vline(xintercept = 0, linetype = "dashed") +
    ggplot2::geom_errorbarh(ggplot2::aes(xmin = .data$lo, xmax = .data$hi),
                            height = 0.2,
                            position = ggplot2::position_dodge(width = 0.5)) +
    ggplot2::geom_point(position = ggplot2::position_dodge(width = 0.5)) +
    ggplot2::labs(
      title    = "Risk function: with vs. without selectivity correction",
      subtitle = sprintf("Selected group: %s == 1 (n = %d)",
                         x$config$selection_var, x$config$n_selected),
      x        = "Variance elasticity",
      y        = NULL,
      colour   = NULL,
      caption  = sprintf("Bars are %.0f%% bootstrap CIs (%d reps).",
                         100 * (2 * stats::pnorm(z) - 1),
                         x$config$bootstrap_reps)
    ) +
    ggplot2::theme_minimal()
}

# Avoid R CMD check note about ".data" being undefined.
utils::globalVariables(".data")
