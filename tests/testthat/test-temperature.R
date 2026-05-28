#' The argument `elev` is converted internally to air pressure using `pres_p()`.
#' The sea-level pressure used in `pres_p()` is not the same as the
#' potential-temperature reference pressure of 1000 hPa.
test_that("Potential Temperature", {
  expect_equal(
    temp_pot_temp(25, 270),
    26.520455365680,
    tolerance = 1e-8
  )
})