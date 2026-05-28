test_that("positive soil heat flux lowers available turbulent energy", {
  rad_bal <- 500
  low_soil_flux <- 20
  high_soil_flux <- 80

  expect_lt(
    rad_bal - high_soil_flux,
    rad_bal - low_soil_flux
  )
})

test_that("Priestley-Taylor closes available energy for positive and negative cases", {
  temp <- c(22, 18)
  rad_bal <- c(500, -80)
  soil_flux <- c(50, 20)

  latent <- latent_priestley_taylor(
    temp = temp,
    rad_bal = rad_bal,
    soil_flux = soil_flux,
    surface_type = "field"
  )
  sensible <- sensible_priestley_taylor(
    temp = temp,
    rad_bal = rad_bal,
    soil_flux = soil_flux,
    surface_type = "field"
  )

  expect_gt(rad_bal[1] - soil_flux[1], 0)
  expect_lt(rad_bal[2] - soil_flux[2], 0)
  expect_equal(latent + sensible, rad_bal - soil_flux, tolerance = 1e-8)
})

test_that("pt_only workflow only adds Priestley-Taylor fields", {
  result <- turb_flux_calc(physics_minimal_pt_station(), pt_only = TRUE)

  expect_true("latent_priestley_taylor" %in% names(result))
  expect_true("sensible_priestley_taylor" %in% names(result))

  expect_false("latent_penman" %in% names(result))
  expect_false("sensible_bowen" %in% names(result))
  expect_false("latent_bowen" %in% names(result))
  expect_false("sensible_monin" %in% names(result))
  expect_false("latent_monin" %in% names(result))
  expect_false("sensible_bulk" %in% names(result))
  expect_false("latent_bulk_residual" %in% names(result))

  expect_equal(
    result$latent_priestley_taylor + result$sensible_priestley_taylor,
    result$rad_bal - result$soil_flux,
    tolerance = 1e-8
  )
})

test_that("Bulk-Residual contracts preserve sign, closure, and low-wind control", {
  h_bulk <- sensible_bulk(
    t1 = 20.2,
    t2 = 20.0,
    v1 = 2,
    v2 = 4,
    z1 = 2,
    z2 = 10
  )

  expect_gt(h_bulk, 0)

  rad_bal <- 500
  soil_flux <- 50
  le_res <- latent_bulk_residual(
    rad_bal = rad_bal,
    soil_flux = soil_flux,
    sensible = h_bulk
  )

  expect_equal(h_bulk + le_res, rad_bal - soil_flux, tolerance = 1e-12)

  expect_warning(
    h_low_wind <- sensible_bulk(
      t1 = c(20.2, 20.2),
      t2 = c(20.0, 20.0),
      v1 = c(0, 2),
      v2 = c(0, 4),
      z1 = 2,
      z2 = 10
    ),
    "wind speed"
  )

  expect_true(is.na(h_low_wind[1]))
  expect_false(is.infinite(h_low_wind[1]))
  expect_true(is.finite(h_low_wind[2]))
})

test_that("Bowen closes available energy only for non-singular uncapped cases", {
  args <- list(
    t1 = 20,
    t2 = 19.2,
    hum1 = 60,
    hum2 = 52,
    z1 = 2,
    z2 = 10,
    elev = 261,
    rad_bal = 500,
    soil_flux = 50
  )

  sensible <- do.call(sensible_bowen, args)
  latent <- do.call(latent_bowen, args)

  expect_true(is.finite(sensible))
  expect_true(is.finite(latent))
  expect_equal(sensible + latent, args$rad_bal - args$soil_flux, tolerance = 1e-8)
})

test_that("Bowen partition scales consistently for fixed gradients", {
  args <- list(
    t1 = 20,
    t2 = 19.2,
    hum1 = 60,
    hum2 = 52,
    z1 = 2,
    z2 = 10,
    elev = 261,
    rad_bal = 500,
    soil_flux = 50
  )
  half_energy_args <- args
  half_energy_args$rad_bal <- 275
  half_energy_args$soil_flux <- 50

  sensible <- do.call(sensible_bowen, args)
  latent <- do.call(latent_bowen, args)
  sensible_half <- do.call(sensible_bowen, half_energy_args)
  latent_half <- do.call(latent_bowen, half_energy_args)

  expect_equal(sensible_half, sensible / 2, tolerance = 1e-8)
  expect_equal(latent_half, latent / 2, tolerance = 1e-8)
  expect_equal(sensible_half + latent_half, half_energy_args$rad_bal - half_energy_args$soil_flux, tolerance = 1e-8)
})

test_that("Bowen denominator cap controls near-singular cases without requiring closure", {
  args <- list(
    t1 = 15,
    t2 = 9,
    hum1 = 30,
    hum2 = 88.9447054488,
    z1 = 2,
    z2 = 10,
    elev = 261,
    rad_bal = 500,
    soil_flux = 50,
    cap = 0.05
  )

  expect_warning(
    sensible <- do.call(sensible_bowen, args),
    "below -600"
  )
  expect_warning(
    latent <- do.call(latent_bowen, args),
    "above 600"
  )

  expect_true(is.finite(sensible))
  expect_true(is.finite(latent))
  expect_false(isTRUE(all.equal(sensible + latent, args$rad_bal - args$soil_flux, tolerance = 1e-8)))
})

test_that("Penman weather-station method accepts field surface and returns LE only", {
  ws <- physics_standard_weather_station()

  latent <- latent_penman(ws)

  expect_equal(length(latent), length(ws$temp))
  expect_true(any(is.finite(latent)))
  expect_false("sensible_penman" %in% names(ws))
})

test_that("weather-station wrappers preserve flat object values", {
  ws <- build_weather_station(
    datetime = physics_standard_datetime(2),
    temp = c(13.1, 13.0),
    rad_bal = c(400, 410),
    soil_flux = c(40, 42),
    surface_type = "field"
  )

  expect_s3_class(ws, "weather_station")
  expect_equal(ws$temp, c(13.1, 13.0))
  expect_equal(ws$rad_bal, c(400, 410))
  expect_equal(ws$soil_flux, c(40, 42))
  expect_equal(ws$surface_type, "field")

  out <- as.data.frame(ws)

  expect_equal(out$temp, ws$temp)
  expect_equal(out$rad_bal, ws$rad_bal)
  expect_equal(out$soil_flux, ws$soil_flux)
})

test_that("Monin outputs remain diagnostic and are not forced to close energy", {
  ws <- physics_standard_weather_station()

  flux <- suppressWarnings(turb_flux_calc(ws))

  expect_true("sensible_monin" %in% names(flux))
  expect_true("latent_monin" %in% names(flux))
  expect_equal(flux$rad_bal, ws$rad_bal)
  expect_equal(flux$soil_flux, ws$soil_flux)
  expect_equal(length(flux$sensible_monin), length(ws$temp))
  expect_equal(length(flux$latent_monin), length(ws$temp))
})
