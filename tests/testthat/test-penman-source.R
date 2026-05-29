source_penman_base_args <- function(...) {
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

source_penman_expected_kpa <- function(args) {
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

test_that("Penman VPD contract remains kPa-scale rather than hPa-scale", {
  args <- source_penman_base_args(rh = 45, rad_bal = 100, soil_flux = 100)

  actual <- do.call(latent_penman, args)

  hpa_expected <- {
    surface_type <- "Temperate grassland"
    rs <- surface_resistance[surface_resistance$surface_type == surface_type, "rs"]
    cp <- 1004
    rho <- 1.2
    gamma <- 0.665 * 10^(-3) * pres_p(args$elev, args$temp)
    es_hPa <- pres_sat_vapor_p(args$temp)
    ea_hPa <- pres_vapor_p(args$temp, args$rh)
    delta <- 4098 * (es_hPa / 10) / ((args$temp + 237.3)^2)
    d <- turb_displacement(args$obs_height, surroundings = "vegetation")
    zom <- 0.123 * args$obs_height
    zoh <- 0.1 * zom
    k <- 0.41
    ra <- (log((args$z - d) / zom) * log((args$z - d) / zoh)) / (k^2 * args$v)
    (delta * (args$rad_bal - args$soil_flux) + gamma * (cp * rho / ra) * (es_hPa - ea_hPa)) /
      (delta + gamma * (1 + rs / ra))
  }

  expect_equal(actual, source_penman_expected_kpa(args), tolerance = 1e-10)
  expect_false(isTRUE(all.equal(as.numeric(actual), as.numeric(hpa_expected), tolerance = 1e-8)))
})

test_that("Penman aerodynamic term responds to humidity and wind directionally", {
  dry <- do.call(latent_penman, source_penman_base_args(rh = 40, v = 2))
  humid <- do.call(latent_penman, source_penman_base_args(rh = 80, v = 2))
  low_wind <- do.call(
    latent_penman,
    source_penman_base_args(rh = 50, v = 1, rad_bal = 100, soil_flux = 100)
  )
  high_wind <- do.call(
    latent_penman,
    source_penman_base_args(rh = 50, v = 4, rad_bal = 100, soil_flux = 100)
  )

  expect_lt(humid, dry)
  expect_gt(high_wind, low_wind)
})

test_that("Penman remains LE-only in direct and workflow output", {
  ws <- physics_standard_weather_station()

  direct <- latent_penman(ws)
  flux <- suppressWarnings(turb_flux_calc(ws))

  expect_type(direct, "double")
  expect_equal(length(direct), length(ws$temp))
  expect_true("latent_penman" %in% names(flux))
  expect_false("sensible_penman" %in% names(flux))
})

test_that("Penman weather-station method accepts rh-only and hum1-only routing", {
  ws_rh <- physics_standard_weather_station()
  ws_rh$hum1 <- NULL
  ws_rh$hum2 <- NULL

  from_rh <- latent_penman(ws_rh)
  direct_rh <- latent_penman(
    datetime = ws_rh$datetime,
    v = ws_rh$v1,
    temp = ws_rh$temp,
    rh = ws_rh$rh,
    z = ws_rh$z1,
    rad_bal = ws_rh$rad_bal,
    elev = ws_rh$elev,
    lat = ws_rh$lat,
    lon = ws_rh$lon,
    soil_flux = ws_rh$soil_flux,
    obs_height = ws_rh$obs_height,
    surface_type = ws_rh$surface_type
  )

  ws_hum1 <- ws_rh
  ws_hum1$hum1 <- c(45, 50)
  ws_hum1$rh <- NULL

  from_hum1 <- latent_penman(ws_hum1)
  direct_hum1 <- latent_penman(
    datetime = ws_hum1$datetime,
    v = ws_hum1$v1,
    temp = ws_hum1$temp,
    rh = ws_hum1$hum1,
    z = ws_hum1$z1,
    rad_bal = ws_hum1$rad_bal,
    elev = ws_hum1$elev,
    lat = ws_hum1$lat,
    lon = ws_hum1$lon,
    soil_flux = ws_hum1$soil_flux,
    obs_height = ws_hum1$obs_height,
    surface_type = ws_hum1$surface_type
  )

  expect_equal(from_rh, direct_rh)
  expect_equal(from_hum1, direct_hum1)
})

test_that("Penman weather-station method currently prefers hum1 over rh", {
  ws <- physics_standard_weather_station()
  ws$rh <- c(35, 35)
  ws$hum1 <- c(80, 80)

  out <- latent_penman(ws)
  hum1_expected <- latent_penman(
    datetime = ws$datetime,
    v = ws$v1,
    temp = ws$temp,
    rh = ws$hum1,
    z = ws$z1,
    rad_bal = ws$rad_bal,
    elev = ws$elev,
    lat = ws$lat,
    lon = ws$lon,
    soil_flux = ws$soil_flux,
    obs_height = ws$obs_height,
    surface_type = ws$surface_type
  )
  rh_expected <- latent_penman(
    datetime = ws$datetime,
    v = ws$v1,
    temp = ws$temp,
    rh = ws$rh,
    z = ws$z1,
    rad_bal = ws$rad_bal,
    elev = ws$elev,
    lat = ws$lat,
    lon = ws$lon,
    soil_flux = ws$soil_flux,
    obs_height = ws$obs_height,
    surface_type = ws$surface_type
  )

  expect_equal(out, hum1_expected)
  expect_false(isTRUE(all.equal(out, rh_expected, tolerance = 1e-8)))
})
