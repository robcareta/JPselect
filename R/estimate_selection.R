#' Estimate the crop-choice selection equation and compute the Inverse Mills Ratio
#'
#' Step 1 of Koundouri & Nauges (2005). Fits a probit on a binary
#' selection indicator (e.g., 1 = farmer grew vegetables, 0 = otherwise)
#' and returns the Inverse Mills Ratio (IMR) for every observation in
#' `data`, ready to be plugged into the Step-2 mean function.
#'
#' @param data A data frame containing the selection indicator and the
#'   covariates listed in `covariates`.
#' @param selection_var Character. Name of the binary 0/1 selection variable.
#' @param covariates Character vector of explanatory variable names.
#'
#' @return A list with:
#' \describe{
#'   \item{model}{The fitted probit (a `glm` object).}
#'   \item{imr}{Inverse Mills Ratio \eqn{\phi(x'\beta)/\Phi(x'\beta)} per row.}
#'   \item{probabilities}{Predicted probability of selection per row.}
#' }
#' @importFrom stats as.formula glm binomial dnorm pnorm predict
#' @export
#' @examples
#' farms <- simulate_kiti_data(seed = 1)
#' sel <- estimate_selection(farms, "vegetables",
#'                           c("rainfall","irrigated","dist_town",
#'                             "dist_coast","experience"))
#' head(sel$imr)
estimate_selection <- function(data, selection_var, covariates) {
  formula <- stats::as.formula(
    paste(selection_var, "~", paste(covariates, collapse = "+"))
  )

  model <- stats::glm(formula, data = data,
                      family = stats::binomial(link = "probit"))

  xb  <- model$linear.predictors
  phi <- stats::dnorm(xb)
  Phi <- stats::pnorm(xb)
  imr <- phi / Phi
  probabilities <- stats::predict(model, type = "response")

  list(
    model         = model,
    imr           = imr,
    probabilities = probabilities
  )
}
