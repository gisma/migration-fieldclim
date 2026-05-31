
radiation_coverage_args <- function(datetime) {
  list(
    datetime = datetime,
    lon = 8,
    lat = 50,
    elev = 100,
    temp = c(18, 19),
    rh = c(55, 60),
    slope = c(5, 10),
    exposition = c(180, 170),
    valley = FALSE,
    surface_type = "lawn",
    surface_temp = c(19, 20)
  )
}

test_that("solar and transmittance helpers are consistent for POSIXct and POSIXlt", {
  time_ct <- as.POSIXct("2023-06-21 12:00:00", tz = "UTC")
  time_lt <- as.POSIXlt(time_ct)

  expect_equal(sol_julian_day(time_ct), sol_julian_day(time_lt))
  expect_equal(sol_eccentricity(time_ct), sol_eccentricity(time_lt), tolerance = 1e-12)
  expect_equal(sol_elevation(time_ct, lon = 8, lat = 50), sol_elevation(time_lt, lon = 8, lat = 50), tolerance = 1e-12)
  expect_equal(trans_air_mass_abs(time_ct, 8, 50, 100, 20), trans_air_mass_abs(time_lt, 8, 50, 100, 20), tolerance = 1e-12)
})

test_that("solar weather_station methods dispatch to direct helpers", {
  time <- as.POSIXct("2023-06-21 12:00:00", tz = "UTC")
  ws <- build_weather_station(datetime = time, lon = 8, lat = 50)

  expect_equal(sol_day_angle(ws), sol_day_angle(time), tolerance = 1e-12)
  expect_equal(sol_declination(ws), sol_declination(time), tolerance = 1e-12)
  expect_equal(sol_hour_angle(ws), sol_hour_angle(time, 8), tolerance = 1e-12)
  expect_equal(sol_azimuth(ws), sol_azimuth(time, 8, 50), tolerance = 1e-12)
})

test_that("night and non-positive solar elevation cases are controlled", {
  night <- as.POSIXct("2023-12-21 00:00:00", tz = "UTC")

  expect_equal(rad_sw_toa(night, lon = 8, lat = 50), 0, tolerance = 1e-12)
  expect_warning(
    sw_in <- rad_sw_in(night, lon = 8, lat = 50, elev = 100, temp = 0, slope = 0, exposition = 180),
    "solar elevation must be positive",
    fixed = TRUE
  )
  expect_equal(sw_in, 0, tolerance = 1e-12)
  expect_warning(
    air_mass <- trans_air_mass_rel(night, lon = 8, lat = 50),
    "solar elevation must be positive",
    fixed = TRUE
  )
  expect_true(is.na(air_mass))
})

test_that("radiation balance wrappers handle vector weather_station inputs", {
  times <- as.POSIXct(c("2023-06-21 12:00:00", "2023-06-21 13:00:00"), tz = "UTC")
  args <- radiation_coverage_args(times)
  ws <- do.call(build_weather_station, args)

  sw <- rad_sw_bal(ws)
  lw <- rad_lw_bal(ws)
  rn <- rad_bal(ws)

  expect_length(sw, 2)
  expect_length(lw, 2)
  expect_length(rn, 2)
  expect_equal(rn, sw + lw, tolerance = 1e-8)
  expect_true(all(is.finite(rn)))
})

test_that("transmittance weather_station wrappers handle vector station inputs", {
  times <- as.POSIXct(c("2023-06-21 12:00:00", "2023-06-21 13:00:00"), tz = "UTC")
  ws <- build_weather_station(
    datetime = times,
    lon = 8,
    lat = 50,
    elev = c(100, 120),
    temp = c(20, 21)
  )

  expect_length(trans_gas(ws), 2)
  expect_length(trans_rayleigh(ws), 2)
  expect_length(trans_vapor(ws), 2)
  expect_length(trans_aerosol(ws), 2)
  expect_true(all(is.finite(trans_gas(ws))))
})

test_that("invalid radiation surface_type behaviour is documented as open", {
  skip("Invalid radiation surface_type policy is not documented; existing numeric(0) style behavior is covered in contract audits, not expanded here.")
})
