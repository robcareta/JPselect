test_that("jp_fit reproduces known seed-42 risk-function coefficients", {
  skip_on_cran()
  farms <- simulate_kiti_data(seed = 42)
  fit <- jp_fit(
    data                 = farms,
    selection_var        = "vegetables",
    selection_covariates = c("rainfall","irrigated","dist_town",
                             "dist_coast","experience"),
    output_var           = "revenue",
    input_vars           = c("fertilizers","pesticides","labor","water"),
    shifter_vars         = c("machinery","rainfall","irrigated",
                             "dist_town","dist_coast","experience"),
    bootstrap_reps       = 0  # point estimates only, no bootstrap
  )
  rf <- fit$risk_with$coefficients
  expect_equal(round(rf["fertilizers","Coefficient"], 3),  0.057)
  expect_equal(round(rf["pesticides", "Coefficient"], 3),  0.007)
  expect_equal(round(rf["labor",      "Coefficient"], 3), -0.107)
  expect_equal(round(rf["water",      "Coefficient"], 3), -0.046)
})

test_that("plot.jpfit returns ggplot objects", {
  skip_on_cran()
  farms <- simulate_kiti_data(seed = 42)
  fit <- jp_fit(
    data                 = farms,
    selection_var        = "vegetables",
    selection_covariates = c("rainfall","irrigated","dist_town",
                             "dist_coast","experience"),
    output_var           = "revenue",
    input_vars           = c("fertilizers","pesticides","labor","water"),
    shifter_vars         = c("machinery","rainfall","irrigated",
                             "dist_town","dist_coast","experience"),
    bootstrap_reps       = 0
  )
  for (w in c("risk","probit","mean")) {
    expect_s3_class(plot(fit, what = w), "ggplot")
  }
})

test_that("simulate_kiti_data has expected structure", {
  farms <- simulate_kiti_data(seed = 1)
  expect_equal(nrow(farms), 239)
  expect_equal(sum(farms$vegetables), 95)
  expect_equal(sum(farms$cereals),    89)
  expect_equal(sum(farms$citrus),     55)
  expect_true(all(farms$revenue > 0))
})
