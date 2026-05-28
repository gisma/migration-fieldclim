penman_base_args <- function(...) {
  modifyList(
    list(
      datetime = as.POSIXct("2017-06-30 12:00:00", tz = "Europe/Berlin"),
      v = 2,
      temp = 25,
      rh = 60,
      z = 2,
      rad_bal = 200,
      elev = 261,
      lat = 50.8405,
      lon = 8.6832,
      soil_flux = 40,
      obs_height = 1,
      surface_type = "field"
    ),
    list(...)
  )
}

penman_expected_kpa <- function(args) {
  surface_type <- "Temperate grassland"
  rs <- surface_resistance[surface_resistance$surface_type == surface_type, "rs"]
  cp <- 1004
  rho <- 1.2
  gamma <- 0.665 * 10^(-3) * pres_p(args$elev, args$temp)
  es_hPa <- pres_sat_vapor_p(args$temp)
  ea_hPa <- pres_vapor_p(args$temp, args$rh)
  es_kPa <- es_hPa / 10
  ea_kPa <- ea_hPa / 10
  vpd_kPa <- es_kPa - ea_kPa
  delta <- 4098 * es_kPa / ((args$temp + 237.3)^2)
  d <- turb_displacement(args$obs_height, surroundings = "vegetation")
  zom <- 0.123 * args$obs_height
  zoh <- 0.1 * zom
  k <- 0.41
  ra <- (log((args$z - d) / zom) * log((args$z - d) / zoh)) / (k^2 * args$v)
  (delta * (args$rad_bal - args$soil_flux) + gamma * (cp * rho / ra) * vpd_kPa) /
    (delta + gamma * (1 + rs / ra))
}

test_that("latent_penman uses kPa vapour-pressure deficit scale", {
  saturated_args <- penman_base_args(rh = 100, rad_bal = 100, soil_flux = 100)
  dry_args <- penman_base_args(rh = 50, rad_bal = 100, soil_flux = 100)

  saturated <- do.call(latent_penman, saturated_args)
  dry <- do.call(latent_penman, dry_args)

  expect_equal(saturated, 0, tolerance = 1e-10)
  expect_gt(dry, saturated)
  expect_equal(dry, penman_expected_kpa(dry_args), tolerance = 1e-10)
})

test_that("latent_penman keeps Rn minus G available-energy sign", {
  low_soil <- do.call(latent_penman, penman_base_args(soil_flux = 20))
  high_soil <- do.call(latent_penman, penman_base_args(soil_flux = 80))

  expect_lt(high_soil, low_soil)
})

test_that("latent_penman weather-station field mapping and vector length are preserved", {
  ws <- physics_standard_weather_station()

  out <- latent_penman(ws)

  expect_equal(length(out), length(ws$temp))
  expect_true(any(is.finite(out)))
})

test_that("latent_penman invalid aerodynamic elements are local", {
  args <- penman_base_args(
    datetime = rep(as.POSIXct("2017-06-30 12:00:00", tz = "Europe/Berlin"), 2),
    v = c(2, 2),
    temp = c(25, 25),
    rh = c(60, 60),
    z = c(2, 0.5),
    rad_bal = c(200, 200),
    elev = c(261, 261),
    lat = c(50.8405, 50.8405),
    lon = c(8.6832, 8.6832),
    soil_flux = c(40, 40),
    obs_height = c(1, 1)
  )

  expect_warning(
    out <- do.call(latent_penman, args),
    "invalid aerodynamic resistance"
  )

  expect_equal(length(out), 2)
  expect_true(is.finite(out[1]))
  expect_true(is.na(out[2]))
})

test_that("turb_flux_calc keeps Penman failure non-fatal", {
  ws <- physics_standard_weather_station()
  ws$datetime <- as.character(ws$datetime)

  warnings <- character()
  flux <- withCallingHandlers(
    turb_flux_calc(ws),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  expect_true(any(grepl("latent_penman", warnings)))
  expect_true("latent_penman" %in% names(flux))
  expect_true(all(is.na(flux$latent_penman)))
  expect_true("sensible_priestley_taylor" %in% names(flux))
  expect_true("latent_priestley_taylor" %in% names(flux))
  expect_true("sensible_bulk" %in% names(flux))
  expect_true("latent_bulk_residual" %in% names(flux))
})
