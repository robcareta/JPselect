#' Estimate the Just-Pope variance (risk) function
#'
#' Step 3 of Koundouri & Nauges (2005). Given mean-function residuals,
#' fit the Cobb-Douglas risk function in logs,
#' \deqn{\log|\hat{w}| = \xi_0 + \sum_j \xi_j \log(x_j) + \log(\eta).}
#' Standard errors default to a 500-replication nonparametric bootstrap,
#' matching the paper. If `full_data`, `selection_args`, and `mean_args` are
#' supplied, the bootstrap resamples the entire pipeline (probit -> IMR ->
#' mean function -> residuals -> risk function) on each replication so
#' upstream parameter uncertainty propagates into the risk-function SEs.
#' Without those, the bootstrap resamples only the risk-function rows
#' (faster, but ignores Steps 1-2 uncertainty).
#'
#' @param residuals Numeric vector of mean-function residuals (Step 2).
#' @param input_data Data frame aligned with `residuals`, holding input
#'   columns named in `input_vars`.
#' @param input_vars Character vector. Inputs to enter the risk function.
#' @param positive_only Logical. Drop rows with non-positive residuals or
#'   inputs before logging (default `TRUE`).
#' @param bootstrap_reps Integer. Bootstrap replications (default 500;
#'   set 0 for OLS SEs only).
#' @param full_data,selection_args,mean_args Optional. When all three are
#'   supplied, the full pipeline is rerun on each bootstrap draw. See
#'   [jp_fit()] which wires this up for you.
#' @param seed Optional integer seed.
#'
#' @return List with the fitted `lm` object, a coefficient table, the
#'   bootstrap coefficient matrix, and the post-filter sample size.
#' @importFrom stats as.formula lm coef sd pt vcov
#' @export
#' @examples
#' \dontrun{
#' fit <- jp_fit(data = simulate_kiti_data(),
#'               selection_var = "vegetables",
#'               selection_covariates = c("rainfall","irrigated","dist_town",
#'                                        "dist_coast","experience"),
#'               output_var   = "revenue",
#'               input_vars   = c("fertilizers","pesticides","labor","water"),
#'               shifter_vars = c("machinery","rainfall","irrigated",
#'                                "dist_town","dist_coast","experience"),
#'               bootstrap_reps = 100)
#' fit$risk_with$coefficients
#' }
estimate_risk_function <- function(residuals,
                                   input_data,
                                   input_vars,
                                   positive_only = TRUE,
                                   bootstrap_reps = 500,
                                   full_data = NULL,
                                   selection_args = NULL,
                                   mean_args = NULL,
                                   seed = NULL) {

  if (!is.null(seed)) set.seed(seed)
  stopifnot(length(residuals) == nrow(input_data))
  missing <- setdiff(input_vars, names(input_data))
  if (length(missing) > 0) {
    stop("Missing input columns: ", paste(missing, collapse = ", "))
  }

  df <- cbind(.w = residuals, input_data[, input_vars, drop = FALSE])

  if (positive_only) {
    keep <- df$.w != 0 & rowSums(input_data[, input_vars, drop = FALSE] <= 0) == 0
    df <- df[keep, , drop = FALSE]
  }

  df$.lnw <- log(abs(df$.w))
  for (v in input_vars) df[[paste0(".ln_", v)]] <- log(df[[v]])

  rhs <- paste0(".ln_", input_vars)
  fml <- stats::as.formula(paste(".lnw ~", paste(rhs, collapse = " + ")))
  model <- stats::lm(fml, data = df)

  est <- stats::coef(model)

  boot_mat <- NULL
  do_full_boot <- bootstrap_reps > 0 &&
    !is.null(full_data) && !is.null(selection_args) && !is.null(mean_args)

  if (do_full_boot) {
    boot_mat <- .boot_full_pipeline(
      full_data       = full_data,
      selection_args  = selection_args,
      mean_args       = mean_args,
      risk_input_vars = input_vars,
      positive_only   = positive_only,
      reps            = bootstrap_reps,
      coef_names      = names(est)
    )
  } else if (bootstrap_reps > 0) {
    boot_mat <- matrix(NA_real_, nrow = bootstrap_reps, ncol = length(est),
                       dimnames = list(NULL, names(est)))
    n <- nrow(df)
    for (b in seq_len(bootstrap_reps)) {
      idx <- sample.int(n, n, replace = TRUE)
      fit_b <- try(stats::lm(fml, data = df[idx, , drop = FALSE]), silent = TRUE)
      if (!inherits(fit_b, "try-error")) {
        cb <- stats::coef(fit_b)
        boot_mat[b, names(cb)] <- cb
      }
    }
  }

  if (!is.null(boot_mat)) {
    se <- apply(boot_mat, 2, stats::sd, na.rm = TRUE)
  } else {
    se <- sqrt(diag(stats::vcov(model)))
  }
  tval <- est / se
  pval <- 2 * stats::pt(-abs(tval), df = model$df.residual)

  coef_table <- data.frame(
    Coefficient = est,
    Std.Error   = se,
    t.Statistic = tval,
    p.Value     = pval,
    row.names   = sub("^\\.ln_", "", names(est)),
    check.names = FALSE
  )

  list(
    model          = model,
    coefficients   = coef_table,
    boot_estimates = boot_mat,
    n_used         = nrow(df)
  )
}

# Internal: full-pipeline bootstrap. Resamples full_data, re-runs probit
# -> IMR -> mean function -> risk function on each draw.
.boot_full_pipeline <- function(full_data, selection_args, mean_args,
                                risk_input_vars, positive_only, reps,
                                coef_names) {

  boot_mat <- matrix(NA_real_, nrow = reps, ncol = length(coef_names),
                     dimnames = list(NULL, coef_names))
  n <- nrow(full_data)
  crop_col <- selection_args$selection_var
  imr_col  <- if (is.null(mean_args$imr_var)) "imr" else mean_args$imr_var

  for (b in seq_len(reps)) {
    idx <- sample.int(n, n, replace = TRUE)
    boot_df <- full_data[idx, , drop = FALSE]

    sel <- try(do.call(estimate_selection,
                       c(list(data = boot_df), selection_args)),
               silent = TRUE)
    if (inherits(sel, "try-error")) next
    boot_df[[imr_col]] <- sel$imr

    selected <- boot_df[boot_df[[crop_col]] == 1, , drop = FALSE]
    if (nrow(selected) < length(coef_names) + 5) next

    mf <- try(do.call(estimate_mean_function,
                      c(list(data = selected), mean_args)),
              silent = TRUE)
    if (inherits(mf, "try-error")) next

    res_b <- mf$residuals
    inp_b <- mf$scaled_data[, risk_input_vars, drop = FALSE]
    if (positive_only) {
      keep <- res_b != 0 & rowSums(inp_b <= 0) == 0
      res_b <- res_b[keep]
      inp_b <- inp_b[keep, , drop = FALSE]
    }
    if (length(res_b) < length(coef_names) + 2) next

    lnw <- log(abs(res_b))
    Xln <- log(inp_b)
    names(Xln) <- paste0(".ln_", risk_input_vars)
    fit_b <- try(stats::lm(lnw ~ ., data = cbind(lnw = lnw, Xln)),
                 silent = TRUE)
    if (inherits(fit_b, "try-error")) next
    cb <- stats::coef(fit_b)
    boot_mat[b, names(cb)] <- cb
  }
  boot_mat
}
