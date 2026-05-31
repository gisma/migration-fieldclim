
radiation_remaining_station <- function(datetime) {
  build_weather_station(
    datetime = datetime,
    lon = 8,
    lat = 50,
    elev = 100,
    temp = rep(15, length(datetime)),
    rh = rep(60, length(datetime)),
    slope = rep(5, length(datetime)),
    exposition = rep(180, length(datetime)),
    valley = FALSE,
    surface_type = "lawn",
    surface_temp = rep(16, length(datetime))
  )
}

test_that("remaining solar POSIXct/POSIXlt and weather_station paths are equivalent", {
  time_ct <- as.POSIXct("2023-06-21 09:30:00", tz = "UTC")
  time_lt <- as.POSIXlt(time_ct)
  ws <- build_weather_station(datetime = time_ct, lon = 8, lat = 50)

  expect_equal(sol_medium_suntime(time_ct, 8), sol_medium_suntime(time_lt, 8), tolerance = 1e-12)
  expect_equal(sol_time_formula(time_ct, 8), sol_time_formula(time_lt, 8), tolerance = 1e-12)
  expect_equal(sol_ecliptic_length(time_ct), sol_ecliptic_length(time_lt), tolerance = 1e-12)
  expect_equal(sol_medium_anomaly(time_ct), sol_medium_anomaly(time_lt), tolerance = 1e-12)

  expect_equal(sol_julian_day(ws), sol_julian_day(time_ct))
  expect_equal(sol_medium_suntime(ws), sol_medium_suntime(time_ct, 8), tolerance = 1e-12)
  expect_equal(sol_time_formula(ws), sol_time_formula(time_ct, 8), tolerance = 1e-12)
  expect_equal(sol_ecliptic_length(ws), sol_ecliptic_length(time_ct), tolerance = 1e-12)
  expect_equal(sol_medium_anomaly(ws), sol_medium_anomaly(time_ct), tolerance = 1e-12)
})

test_that("solar azimuth covers morning and afternoon branches", {
  morning <- as.POSIXct("2023-06-21 08:00:00", tz = "UTC")
  afternoon <- as.POSIXct("2023-06-21 16:00:00", tz = "UTC")

  am <- sol_azimuth(morning, lon = 8, lat = 50)
  pm <- sol_azimuth(afternoon, lon = 8, lat = 50)

  expect_true(is.finite(am))
  expect_true(is.finite(pm))
  expect_true(am >= 0 && am <= 360)
  expect_true(pm >= 0 && pm <= 360)
  expect_false(isTRUE(all.equal(am, pm)))
})

test_that("shortwave radiation handles vector day and night cases", {
  times <- as.POSIXct(c("2023-06-21 12:00:00", "2023-06-21 00:00:00"), tz = "UTC")
  ws <- radiation_remaining_station(times)

  expect_warning(
    toa <- rad_sw_toa(ws),
    regexp = NA
  )
  expect_length(toa, 2)
  expect_gt(toa[1], 0)
  expect_equal(toa[2], 0, tolerance = 1e-12)

  expect_warning(
    sw_in <- rad_sw_in(ws),
    "solar elevation must be positive",
    fixed = TRUE
  )
  expect_length(sw_in, 2)
  expect_gt(sw_in[1], 0)
  expect_equal(sw_in[2], 0, tolerance = 1e-12)
})

test_that("radiation weather_station wrappers cover component functions", {
  times <- as.POSIXct(c("2023-06-21 12:00:00", "2023-06-21 13:00:00"), tz = "UTC")
  ws <- radiation_remaining_station(times)

  expect_length(rad_sw_toa(ws), 2)
  expect_length(rad_sw_in(ws), 2)
  expect_length(rad_diffuse_in(ws), 2)
  expect_length(rad_sw_out(ws), 2)
  expect_length(rad_diffuse_out(ws), 2)
  expect_length(rad_lw_in(ws), 2)
  expect_length(rad_lw_out(ws), 2)
  expect_length(rad_emissivity_air(ws), 2)
  expect_length(rad_sw_bal(ws), 2)
  expect_length(rad_lw_bal(ws), 2)
  expect_length(rad_bal(ws), 2)
})

test_that("boundary solar geometry inputs return controlled numeric or NA results", {
  pole_time <- as.POSIXct("2023-06-21 12:00:00", tz = "UTC")
  elev <- sol_elevation(pole_time, lon = 0, lat = 90)
  az <- suppressWarnings(sol_azimuth(pole_time, lon = 0, lat = 90))

  expect_true(is.finite(elev))
  expect_true(is.na(az) || is.finite(az))
})

test_that("unknown radiation surface type policy remains open", {
  skip("Unknown radiation surface_type behavior is not documented as a stable policy; source code was not changed to define it.")
})
