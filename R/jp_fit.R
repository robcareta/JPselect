#' Fit the full Koundouri-Nauges (2005) three-step pipeline
#'
#' High-level wrapper that runs the entire Just-Pope-with-Heckman procedure
#' in a single call:
#' \enumerate{
#'   \item Probit selection on `selection_var` against
#'         `selection_covariates`; compute the Inverse Mills Ratio.
#'   \item Linear-quadratic mean production function with IMR, fit on the
#'         selected subsample (`selection_var == 1`).
#'   \item Cobb-Douglas risk function on `log|residuals|`, with bootstrap
#'         standard errors that resample the full pipeline.
#' }
#' For comparison purposes the function also fits the parallel
#' "without selectivity correction" path by zeroing the IMR before Step 2.
#' This is the with/without contrast displayed in Tables 4 and 5 of the
#' paper and on [plot.jpfit()].
#'
#' @param data Data frame with one row per farmer covering both the
#'   selected and non-selected groups (Step 1 needs both).
#' @param selection_var Character. Name of the 0/1 selection indicator.
#' @param selection_covariates Character vector of probit covariates.
#' @param output_var Character. Output / yield variable.
#' @param input_vars Character vector of variable inputs.
#' @param shifter_vars Character vector of extra production shifters.
#' @param bootstrap_reps Integer. Bootstrap replications for Step 3 SEs
#'   (default 500, as in the paper).
#' @param mean_scale Logical. Mean-scale all variables before Step 2.
#' @param seed Optional integer seed.
#'
#' @return An object of class `jpfit` with elements `selection`,
#'   `mean_with`, `mean_without`, `risk_with`, `risk_without`, `config`,
#'   and `call`. See [print.jpfit()], [summary.jpfit()], [plot.jpfit()].
#' @export
#' @examples
#' \dontrun{
#' farms <- simulate_kiti_data(seed = 1)
#' fit <- jp_fit(
#'   data         = farms,
#'   selection_var = "vegetables",
#'   selection_covariates = c("rainfall","irrigated","dist_town",
#'                            "dist_coast","experience"),
#'   output_var   = "revenue",
#'   input_vars   = c("fertilizers","pesticides","labor","water"),
#'   shifter_vars = c("machinery","rainfall","irrigated",
#'                    "dist_town","dist_coast","experience"),
#'   bootstrap_reps = 100
#' )
#' print(fit)
#' summary(fit)
#' plot(fit)
#' }
jp_fit <- function(data,
                   selection_var,
                   selection_covariates,
                   output_var,
                   input_vars,
                   shifter_vars,
                   bootstrap_reps = 500,
                   mean_scale = TRUE,
                   seed = NULL) {

  call <- match.call()
  if (!is.null(seed)) set.seed(seed)

  # ----- Step 1: probit selection ----------------------------------------
  sel <- estimate_selection(data, selection_var, selection_covariates)
  imr_col <- paste0("imr_", selection_var)
  data[[imr_col]] <- sel$imr

  selected <- data[data[[selection_var]] == 1, , drop = FALSE]

  # ----- Step 2: mean production function (with and without IMR) ---------
  mean_args <- list(
    output_var   = output_var,
    input_vars   = input_vars,
    shifter_vars = shifter_vars,
    imr_var      = imr_col,
    mean_scale   = mean_scale
  )

  mf_with <- do.call(estimate_mean_function, c(list(data = selected), mean_args))

  selected_noimr <- selected
  selected_noimr[[imr_col]] <- 0
  mf_without <- do.call(estimate_mean_function,
                        c(list(data = selected_noimr), mean_args))

  # ----- Step 3: risk function (with full-pipeline bootstrap) ------------
  sel_args <- list(selection_var = selection_var,
                   covariates    = selection_covariates)

  rf_with <- estimate_risk_function(
    residuals      = mf_with$residuals,
    input_data     = mf_with$scaled_data,
    input_vars     = input_vars,
    bootstrap_reps = bootstrap_reps,
    full_data      = data,
    selection_args = sel_args,
    mean_args      = mean_args,
    seed           = if (is.null(seed)) NULL else seed + 1
  )

  rf_without <- estimate_risk_function(
    residuals      = mf_without$residuals,
    input_data     = mf_without$scaled_data,
    input_vars     = input_vars,
    bootstrap_reps = bootstrap_reps,
    seed           = if (is.null(seed)) NULL else seed + 2
  )

  structure(
    list(
      selection    = sel,
      mean_with    = mf_with,
      mean_without = mf_without,
      risk_with    = rf_with,
      risk_without = rf_without,
      config       = list(
        selection_var        = selection_var,
        selection_covariates = selection_covariates,
        output_var           = output_var,
        input_vars           = input_vars,
        shifter_vars         = shifter_vars,
        imr_var              = imr_col,
        bootstrap_reps       = bootstrap_reps,
        n_total              = nrow(data),
        n_selected           = nrow(selected)
      ),
      call = call
    ),
    class = "jpfit"
  )
}
