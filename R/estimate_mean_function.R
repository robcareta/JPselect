#' Estimate the Just-Pope mean production function with selectivity correction
#'
#' Step 2 of Koundouri & Nauges (2005). Fits one of three functional
#' forms for the mean function `f(x)` plus extra shifters and the
#' Inverse Mills Ratio.
#'
#' \itemize{
#'   \item `"linear_quadratic"` (default): linear, quadratic, and pairwise
#'     interaction terms in inputs. This is the form used in Koundouri &
#'     Nauges (2005). Compatible with additive interaction between the
#'     mean and variance functions, the key Just-Pope requirement.
#'   \item `"quadratic"`: linear and quadratic terms in inputs, no
#'     pairwise interactions. A more parsimonious version, useful when
#'     the sample is small.
#'   \item `"cobb_douglas"`: log-log specification,
#'     \eqn{\log y = \beta_0 + \sum_j \beta_j \log x_j + \text{shifters} + \sigma M + w}.
#'     Requires strictly positive output and inputs. Shankar & Nelson
#'     (1999) showed that the Cobb-Douglas mean + Cobb-Douglas variance
#'     specification is robust to input endogeneity in the JP framework.
#' }
#'
#' Coefficients are obtained by OLS; with the regressors serving as
#' their own instruments, GMM point estimates coincide with OLS, and the
#' paper's heteroskedasticity-robust GMM standard errors are reproduced
#' via HC1 sandwich variances.
#'
#' If the Mill's ratio column is constant (e.g. all zero for the
#' "without selectivity" comparison), the term is dropped from the
#' formula before fitting.
#'
#' @param data Data frame of the selected subsample (`D_l == 1`)
#'   containing all variables listed below.
#' @param output_var Character. Name of the output / yield variable.
#' @param input_vars Character vector. Variable inputs.
#' @param shifter_vars Character vector. Extra production shifters that
#'   enter the mean function linearly (in all three forms).
#' @param imr_var Character. Name of the Mill's ratio column (default
#'   "imr").
#' @param form Functional form: `"linear_quadratic"` (default),
#'   `"quadratic"`, or `"cobb_douglas"`. See *Details*.
#' @param mean_scale Logical. If `TRUE` (default), mean-scale all
#'   variables before estimation, as in Table A1 of the paper. Ignored
#'   under `form = "cobb_douglas"`, where log-scaling makes the
#'   transformation meaningless.
#'
#' @return A list with the fitted `lm` object, a coefficient table with
#'   HC1-robust standard errors, the residuals, fitted values, adjusted
#'   \eqn{R^2}, the formula used, the (possibly scaled) data frame, and
#'   the functional form.
#' @importFrom stats as.formula lm coef vcov residuals fitted pt complete.cases
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
                                   form = c("linear_quadratic", "quadratic",
                                            "cobb_douglas"),
                                   mean_scale = TRUE) {

  form <- match.arg(form)
  stopifnot(is.data.frame(data))
  needed <- c(output_var, input_vars, shifter_vars, imr_var)
  missing <- setdiff(needed, names(data))
  if (length(missing) > 0) {
    stop("Missing columns in data: ", paste(missing, collapse = ", "))
  }

  df <- data[, needed, drop = FALSE]
  df <- df[stats::complete.cases(df), , drop = FALSE]

  if (form == "cobb_douglas") {
    # Require strict positivity of output and inputs before taking logs.
    keep <- df[[output_var]] > 0 &
            rowSums(df[, input_vars, drop = FALSE] <= 0) == 0
    df <- df[keep, , drop = FALSE]
    df[[output_var]] <- log(df[[output_var]])
    for (v in input_vars) df[[v]] <- log(df[[v]])
    mean_scale <- FALSE     # not meaningful in log space
  }

  if (mean_scale) {
    scale_cols <- setdiff(needed, imr_var)
    for (v in scale_cols) {
      m <- mean(df[[v]], na.rm = TRUE)
      if (is.finite(m) && m != 0) df[[v]] <- df[[v]] / m
    }
  }

  quad_terms <- if (form == "cobb_douglas") character(0)
                else paste0("I(", input_vars, "^2)")
  inter_terms <- if (form == "linear_quadratic") {
    inter_pairs <- utils::combn(input_vars, 2, simplify = FALSE)
    vapply(inter_pairs, function(p) paste(p, collapse = ":"), "")
  } else character(0)

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
    scaled_data  = df,
    form         = form
  )
}
