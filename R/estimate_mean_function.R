#' Estimate the Just-Pope mean production function with selectivity correction
#'
#' Step 2 of Koundouri & Nauges (2005). Fits a linear-quadratic mean
#' function in variable inputs (linear, quadratic, and pairwise interaction
#' terms) plus extra shifters and the Inverse Mills Ratio. Coefficients are
#' obtained by OLS; with the regressors serving as their own instruments,
#' GMM point estimates coincide with OLS, and the paper's heteroskedasticity-
#' robust GMM standard errors are reproduced via HC1 sandwich variances.
#'
#' If the Mill's ratio column is constant (e.g. all zero for the
#' "without selectivity" comparison), the term is dropped from the formula
#' before fitting -- otherwise `lm()` would return an NA coefficient and the
#' robust vcov dimensions would not match `coef()`.
#'
#' @param data Data frame of the selected subsample (`D_l == 1`) containing
#'   all variables listed below.
#' @param output_var Character. Name of the output / yield variable.
#' @param input_vars Character vector. Variable inputs entering linearly,
#'   quadratically, and via pairwise interactions.
#' @param shifter_vars Character vector. Extra production shifters entering
#'   the mean function linearly only.
#' @param imr_var Character. Name of the Mill's ratio column (default
#'   "imr").
#' @param mean_scale Logical. If `TRUE` (default), mean-scale all variables
#'   before estimation, as in Table A1 of the paper.
#'
#' @return A list with the fitted `lm` object, a coefficient table with
#'   HC1-robust standard errors, the residuals, fitted values, adjusted
#'   \eqn{R^2}, the formula used, and the (possibly scaled) data frame.
#' @importFrom stats as.formula lm coef vcov residuals fitted pt
#' @importFrom utils combn
#' @export
#' @examples
#' farms <- simulate_kiti_data(seed = 1)
#' sel   <- estimate_selection(farms, "vegetables",
#'                             c("rainfall","irrigated","dist_town",
#'                               "dist_coast","experience"))
#' farms$imr <- sel$imr
#' veg <- farms[farms$vegetables == 1, ]
#' mf  <- estimate_mean_function(
#'   data = veg, output_var = "revenue",
#'   input_vars   = c("fertilizers","pesticides","labor","water"),
#'   shifter_vars = c("machinery","rainfall","irrigated",
#'                    "dist_town","dist_coast","experience"))
#' head(mf$coefficients)
estimate_mean_function <- function(data,
                                   output_var,
                                   input_vars,
                                   shifter_vars,
                                   imr_var = "imr",
                                   mean_scale = TRUE) {

  stopifnot(is.data.frame(data))
  needed <- c(output_var, input_vars, shifter_vars, imr_var)
  missing <- setdiff(needed, names(data))
  if (length(missing) > 0) {
    stop("Missing columns in data: ", paste(missing, collapse = ", "))
  }

  df <- data[, needed, drop = FALSE]
  df <- df[stats::complete.cases(df), , drop = FALSE]

  if (mean_scale) {
    scale_cols <- setdiff(needed, imr_var)
    for (v in scale_cols) {
      m <- mean(df[[v]], na.rm = TRUE)
      if (is.finite(m) && m != 0) df[[v]] <- df[[v]] / m
    }
  }

  quad_terms  <- paste0("I(", input_vars, "^2)")
  inter_pairs <- utils::combn(input_vars, 2, simplify = FALSE)
  inter_terms <- vapply(inter_pairs, function(p) paste(p, collapse = ":"), "")

  use_imr <- length(unique(df[[imr_var]])) > 1
  rhs <- c(input_vars, quad_terms, inter_terms, shifter_vars,
           if (use_imr) imr_var)
  fml <- stats::as.formula(paste(output_var, "~", paste(rhs, collapse = " + ")))

  model <- stats::lm(fml, data = df)

  est <- stats::coef(model)
  est <- est[!is.na(est)]

  V <- tryCatch(sandwich::vcovHC(model, type = "HC1"),
                error = function(e) stats::vcov(model))
  se <- sqrt(diag(V))
  common <- intersect(names(est), names(se))
  est <- est[common]; se <- se[common]
  tval <- est / se
  pval <- 2 * stats::pt(-abs(tval), df = model$df.residual)

  coef_table <- data.frame(
    Coefficient = est,
    Std.Error   = se,
    t.Statistic = tval,
    p.Value     = pval,
    row.names   = names(est),
    check.names = FALSE
  )

  list(
    model        = model,
    coefficients = coef_table,
    residuals    = stats::residuals(model),
    fitted       = stats::fitted(model),
    adj_r2       = summary(model)$adj.r.squared,
    formula      = fml,
    scaled_data  = df
  )
}
