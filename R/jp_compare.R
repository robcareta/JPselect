#' Compare jp_fit specifications across functional forms
#'
#' Runs [jp_fit()] under every combination of `mean_forms` x `risk_forms`
#' supplied and returns a side-by-side comparison so the analyst can see
#' how sensitive the risk-function conclusions are to the choice of form.
#'
#' All arguments other than `mean_forms` and `risk_forms` are passed
#' verbatim to [jp_fit()]; `mean_form` and `risk_form` set on the call
#' are vectorised over the two grids.
#'
#' @param ... Arguments forwarded to [jp_fit()] (e.g., `data`,
#'   `selection_var`, `input_vars`, `bootstrap_reps`).
#' @param mean_forms Character vector of mean-function forms to compare.
#'   Subset of `c("linear_quadratic","quadratic","cobb_douglas")`.
#' @param risk_forms Character vector of risk-function forms to compare.
#'   Subset of `c("cobb_douglas","exponential")`.
#' @param verbose Logical. Print progress messages.
#'
#' @return A list with two data frames:
#' \describe{
#'   \item{`summary`}{One row per spec combination, with adjusted R^2 of
#'     the mean function, Mill's ratio coefficient and p-value, and a
#'     flag for whether selection bias was detected at p < 0.10.}
#'   \item{`coefficients`}{Long-format risk-function coefficients: one
#'     row per (combination, input), with the with-correction estimate,
#'     SE, t-stat, p-value, and significance stars.}
#' }
#' @export
#' @examples
#' \dontrun{
#' farms <- simulate_kiti_data(seed = 42)
#' cmp <- jp_compare(
#'   data                 = farms,
#'   selection_var        = "vegetables",
#'   selection_covariates = c("rainfall","irrigated","dist_town",
#'                            "dist_coast","experience"),
#'   output_var           = "revenue",
#'   input_vars           = c("fertilizers","pesticides","labor","water"),
#'   shifter_vars         = c("machinery","rainfall","irrigated",
#'                            "dist_town","dist_coast","experience"),
#'   bootstrap_reps       = 0,
#'   mean_forms           = c("linear_quadratic","quadratic"),
#'   risk_forms           = c("cobb_douglas","exponential")
#' )
#' cmp$summary
#' cmp$coefficients
#' }
jp_compare <- function(...,
                       mean_forms = c("linear_quadratic", "quadratic",
                                      "cobb_douglas"),
                       risk_forms = c("cobb_douglas", "exponential"),
                       verbose    = TRUE) {

  args <- list(...)
  combos <- expand.grid(mean_form = mean_forms,
                        risk_form = risk_forms,
                        stringsAsFactors = FALSE)

  summary_rows <- list()
  coef_rows    <- list()

  for (i in seq_len(nrow(combos))) {
    mf <- combos$mean_form[i]
    rf <- combos$risk_form[i]
    combo_label <- paste0(.short_form(mf), "/", .short_form(rf))
    if (verbose) message("[", i, "/", nrow(combos), "] Fitting ",
                         combo_label, "...")

    fit <- tryCatch(
      do.call(jp_fit, c(args, list(mean_form = mf, risk_form = rf))),
      error = function(e) {
        message("    Failed: ", conditionMessage(e))
        NULL
      })
    if (is.null(fit)) next

    # Mill's ratio diagnostics from Step 2
    mw <- fit$mean_with$coefficients
    imr_row <- rownames(mw)[grepl("^imr", rownames(mw))]
    if (length(imr_row) > 0) {
      imr_c <- mw[imr_row[1], "Coefficient"]
      imr_p <- mw[imr_row[1], "p.Value"]
    } else {
      imr_c <- NA_real_; imr_p <- NA_real_
    }

    summary_rows[[length(summary_rows) + 1]] <- data.frame(
      combo       = combo_label,
      mean_form   = mf,
      risk_form   = rf,
      mean_adj_r2 = round(fit$mean_with$adj_r2, 3),
      imr_coef    = round(imr_c, 3),
      imr_p       = round(imr_p, 3),
      bias_detected = !is.na(imr_p) & imr_p < 0.10,
      n_selected  = fit$config$n_selected,
      stringsAsFactors = FALSE
    )

    # Risk-function coefficients (with selectivity correction)
    rc <- fit$risk_with$coefficients
    inputs <- setdiff(rownames(rc), "(Intercept)")
    for (inp in inputs) {
      coef_rows[[length(coef_rows) + 1]] <- data.frame(
        combo = combo_label,
        mean_form = mf,
        risk_form = rf,
        input = inp,
        coef  = round(rc[inp, "Coefficient"], 3),
        se    = round(rc[inp, "Std.Error"],   3),
        t     = round(rc[inp, "t.Statistic"], 3),
        p     = round(rc[inp, "p.Value"],     3),
        sig   = .compare_stars(rc[inp, "p.Value"]),
        stringsAsFactors = FALSE
      )
    }
  }

  structure(
    list(
      summary      = do.call(rbind, summary_rows),
      coefficients = do.call(rbind, coef_rows)
    ),
    class = "jpcompare"
  )
}

.short_form <- function(form) {
  switch(form,
    linear_quadratic = "LQ",
    quadratic        = "Q",
    cobb_douglas     = "CD",
    exponential      = "Exp",
    form)
}

.compare_stars <- function(p) {
  if (is.na(p)) return("")
  if (p < 0.01) "***" else if (p < 0.05) "**" else if (p < 0.10) "*" else ""
}
