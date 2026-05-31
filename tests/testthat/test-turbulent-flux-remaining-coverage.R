
remaining_flux_station <- function(include_penman = TRUE) {
  args <- list(
    datetime = as.POSIXct(c("2023-06-21 12:00:00", "2023-06-21 13:00:00"), tz = "UTC"),
    temp = c(20, 21),
    rh = c(60, 62),
    rad_bal = c(450, 430),
    soil_flux = c(50, 45),
    surface_type = "field",
    surface_temp = c(21, 22),
    t1 = c(21, 20),
    t2 = c(19, 18.5),
    hum1 = c(70, 69),
    hum2 = c(60, 59),
    v1 = c(2, 2.2),
    v2 = c(4, 4.3),
    z1 = 2,
    z2 = 10,
    elev = c(100, 100),
    lon = 8,
    lat = 50,
    obs_height = 1
  )
  if (!include_penman) args$obs_height <- NULL
  do.call(build_weather_station, args)
}

test_that("turb_flux_calc pt_only does not require optional profile fields", {
  ws <- build_weather_station(
    temp = c(20, 21),
    rad_bal = c(400, 420),
    soil_flux = c(50, 55),
    surface_type = "field"
  )

  out <- turb_flux_calc(ws, pt_only = TRUE)
  expect_true("sensible_priestley_taylor" %in% names(out))
  expect_true("latent_priestley_taylor" %in% names(out))
  expect_false("sensible_bulk" %in% names(out))
  expect_false("latent_penman" %in% names(out))
  expect_equal(out$temp, ws$temp)
})

test_that("turb_flux_calc full workflow preserves inputs and adds documented fields", {
  ws <- remaining_flux_station(include_penman = TRUE)
  out <- suppressWarnings(turb_flux_calc(ws))

  expected <- c(
    "stability", "sensible_priestley_taylor", "latent_priestley_taylor",
    "sensible_bowen", "latent_bowen", "sensible_monin", "latent_monin",
    "latent_penman", "sensible_bulk", "latent_bulk_residual"
  )
  expect_true(all(expected %in% names(out)))
  expect_s3_class(out, "weather_station")
  expect_equal(out$temp, ws$temp)
  expect_equal(out$rad_bal, ws$rad_bal)
  expect_length(out$latent_penman, 2)
})

test_that("turb_flux_calc keeps Penman failure non-fatal when Penman inputs are incomplete", {
  ws <- remaining_flux_station(include_penman = FALSE)

  expect_warning(
    out <- turb_flux_calc(ws),
    "latent_penman",
    fixed = TRUE
  )
  expect_true("latent_penman" %in% names(out))
  expect_true(all(is.na(out$latent_penman)))
  expect_true("sensible_bulk" %in% names(out))
  expect_true("latent_bulk_residual" %in% names(out))
})

test_that("turb_flux_calc incomplete required non-Penman inputs aborts before optional fallback", {
  ws <- build_weather_station(
    temp = 20,
    rad_bal = 400,
    soil_flux = 50,
    surface_type = "field"
  )

  expect_error(
    turb_flux_calc(ws),
    regexp = "not available"
  )
})

test_that("turb_flux_bulk_residual preserves class, inputs and adds residual fields", {
  ws <- build_weather_station(
    datetime = as.POSIXct(c("2023-06-21 12:00:00", "2023-06-21 13:00:00"), tz = "UTC"),
    t1 = c(21, 20),
    t2 = c(19, 18.5),
    v1 = c(2, 2.2),
    v2 = c(4, 4.3),
    z1 = 2,
    z2 = 10,
    rad_bal = c(450, 430),
    soil_flux = c(50, 45)
  )

  out <- turb_flux_bulk_residual(ws, warn_threshold = Inf)
  expect_s3_class(out, "weather_station")
  expect_equal(out$datetime, ws$datetime)
  expect_true(all(c("sensible_bulk", "latent_bulk_residual") %in% names(out)))
  expect_equal(out$sensible_bulk + out$latent_bulk_residual, out$rad_bal - out$soil_flux, tolerance = 1e-10)
})

test_that("turb_flux_calc propagates Bowen or Monin invalid-profile warnings without source changes", {
  ws <- remaining_flux_station(include_penman = FALSE)
  ws$z2 <- 1

  expect_error(
    turb_flux_calc(ws),
    regexp = "z1 and z2 must satisfy|invalid heights|not available"
  )
})
