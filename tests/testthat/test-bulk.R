test_that("sensible_bulk follows temperature-gradient sign", {
  h_positive <- sensible_bulk(
    t1 = 20.2,
    t2 = 20.0,
    v1 = 2,
    v2 = 4,
    z1 = 2,
    z2 = 10
  )

  h_negative <- sensible_bulk(
    t1 = 20.0,
    t2 = 20.2,
    v1 = 2,
    v2 = 4,
    z1 = 2,
    z2 = 10
  )

  expect_gt(h_positive, 0)
  expect_lt(h_negative, 0)
})


test_that("latent_bulk_residual closes available energy", {
  rad_bal <- c(500, 200, -20)
  soil_flux <- c(50, 20, -10)
  sensible <- c(100, -30, -20)

  latent <- latent_bulk_residual(
    rad_bal = rad_bal,
    soil_flux = soil_flux,
    sensible = sensible
  )

  expect_equal(
    sensible + latent,
    rad_bal - soil_flux
  )
})


test_that("bulk-residual weather_station method adds expected fields", {
  ws <- list(
    datetime = as.POSIXct(
      c("2017-06-30 12:00:00", "2017-06-30 12:05:00"),
      tz = "Europe/Berlin"
    ),
    t1 = c(20.2, 20.3),
    t2 = c(20.0, 20.1),
    v1 = c(2, 2.5),
    v2 = c(4, 4.5),
    z1 = 2,
    z2 = 10,
    rad_bal = c(500, 520),
    soil_flux = c(50, 60)
  )

  class(ws) <- "weather_station"

  out <- turb_flux_bulk_residual(ws)

  expect_true("sensible_bulk" %in% names(out))
  expect_true("latent_bulk_residual" %in% names(out))

  expect_equal(
    out$sensible_bulk + out$latent_bulk_residual,
    out$rad_bal - out$soil_flux
  )
})


test_that("sensible_bulk returns NA for too small wind", {
  expect_warning(
    h <- sensible_bulk(
      t1 = c(20.2, 20.2),
      t2 = c(20.0, 20.0),
      v1 = c(0, 2),
      v2 = c(0, 4),
      z1 = 2,
      z2 = 10
    ),
    "wind speed"
  )

  expect_true(is.na(h[1]))
  expect_true(is.finite(h[2]))
})
