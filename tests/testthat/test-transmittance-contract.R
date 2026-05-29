test_that("near-horizon transmittance helpers return controlled finite values", {
  near_horizon <- as.POSIXlt("2023-06-21 04:00:00", tz = "UTC")

  values <- c(
    trans_air_mass_rel(near_horizon, 0, 50),
    trans_air_mass_abs(near_horizon, 0, 50, 100, 20),
    trans_gas(near_horizon, 0, 50, 100, 20),
    trans_ozone(near_horizon, 0, 50),
    trans_rayleigh(near_horizon, 0, 50, 100, 20),
    trans_vapor(near_horizon, 0, 50, 100, 20),
    trans_aerosol(near_horizon, 0, 50, 100, 20)
  )

  expect_true(all(is.finite(values)))
})

test_that("transmittance helpers guard below-horizon air mass", {
  times <- as.POSIXlt(c("2023-06-21 12:00:00", "2023-06-21 00:00:00"), tz = "UTC")

  expect_warning(
    air_mass <- trans_air_mass_rel(times, 0, 50),
    "solar elevation must be positive"
  )

  expect_true(is.finite(air_mass[1]))
  expect_true(is.na(air_mass[2]))
  expect_false(any(is.infinite(air_mass)))
  expect_false(any(is.nan(air_mass)))
})
