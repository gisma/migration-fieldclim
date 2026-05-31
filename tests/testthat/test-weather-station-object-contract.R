
test_that("minimal weather_station objects preserve scalar fields and names", {
  ws <- build_weather_station(
    datetime = as.POSIXct("2023-06-01 12:00:00", tz = "UTC"),
    lat = 50,
    lon = 8,
    elev = 100,
    temp = 20,
    rh = 60,
    v1 = 2,
    rad_bal = 400
  )

  expect_s3_class(ws, "weather_station")
  expect_equal(
    names(ws),
    c("datetime", "lat", "lon", "elev", "temp", "rh", "v1", "rad_bal")
  )
  expect_equal(ws$lat, 50)
  expect_equal(ws$rad_bal, 400)
})

test_that("vector weather_station fields are stored unchanged", {
  time <- as.POSIXct(c("2023-06-01 12:00:00", "2023-06-01 13:00:00"), tz = "UTC")
  ws <- build_weather_station(
    datetime = time,
    lat = c(50, 50.1),
    lon = c(8, 8.1),
    elev = c(100, 110),
    temp = c(20, 21),
    rh = c(60, 65),
    v1 = c(2, 3),
    v2 = c(4, 5),
    rad_bal = c(400, 420),
    soil_flux = c(50, 55)
  )

  expect_equal(ws$datetime, time)
  expect_equal(ws$temp, c(20, 21))
  expect_equal(ws$v2, c(4, 5))
  expect_equal(ws$soil_flux, c(50, 55))
})

test_that("build_weather_station omits explicit NULL fields without validation", {
  ws <- build_weather_station(temp = 20, obs_height = NULL, optional = NULL)

  expect_s3_class(ws, "weather_station")
  expect_true("temp" %in% names(ws))
  expect_false("obs_height" %in% names(ws))
  expect_false("optional" %in% names(ws))
  expect_false("surface_type" %in% names(ws))
})

test_that("mismatched vector lengths are stored, while data.frame conversion follows base recycling rules", {
  ws <- build_weather_station(
    datetime = as.POSIXct(c("2023-06-01 12:00:00", "2023-06-01 13:00:00"), tz = "UTC"),
    temp = c(20, 21),
    rh = 60
  )

  expect_equal(length(ws$temp), 2)
  expect_equal(length(ws$rh), 1)
  expect_equal(as.data.frame(ws)$rh, c(60, 60))

  bad <- build_weather_station(datetime = ws$datetime, temp = c(20, 21, 22))
  expect_error(as.data.frame(bad), regexp = "arguments imply differing number of rows")
})

test_that("as.data.frame.weather_station handles flat, missing measurements and legacy measurements", {
  time <- as.POSIXct(c("2023-06-01 12:00:00", "2023-06-01 13:00:00"), tz = "UTC")
  flat <- build_weather_station(datetime = time, t1 = c(20, 21), rad_bal = c(400, 420))
  expect_equal(as.data.frame(flat)$rad_bal, c(400, 420))

  legacy <- structure(
    list(measurements = data.frame(datetime = time, t1 = c(18, 19), rad_bal = c(300, 320))),
    class = "weather_station"
  )
  expect_equal(as.data.frame(legacy)$t1, c(18, 19))

  reduced_units <- as.data.frame(legacy, reduced = TRUE, unit = TRUE)
  expect_true("temperature_lower[degC]" %in% names(reduced_units))
  expect_true("total_radiation_balance[W/m^2]" %in% names(reduced_units))
})

test_that("plot_weather_station covers known labels, fallback labels and invalid variables", {
  time <- as.POSIXct(c("2023-06-01 12:00:00", "2023-06-01 13:00:00"), tz = "UTC")
  ws <- build_weather_station(
    datetime = time,
    temp = c(20, 21),
    t1 = c(20, 21),
    t2 = c(18, 19),
    v1 = c(2, 3),
    v2 = c(4, 5),
    slope = c(5, 6),
    exposition = c(180, 190),
    surface_temp = c(22, 23),
    rh = c(60, 61),
    hum1 = c(70, 71),
    hum2 = c(65, 66),
    rad_bal = c(400, 420),
    moisture = c(0.2, 0.25),
    soil_flux = c(50, 55),
    soil_temp1 = c(15, 16),
    soil_temp2 = c(12, 13),
    soil_depth1 = c(0.1, 0.1),
    soil_depth2 = c(0.3, 0.3),
    custom_series = c(1, 2),
    location = "site-a"
  )

  grDevices::pdf(file = tempfile(fileext = ".pdf"))
  on.exit(grDevices::dev.off(), add = TRUE)

  expect_no_error(plot_weather_station(ws, NULL))
  expect_no_error(plot_weather_station(ws, "custom_series"))
  expect_error(plot_weather_station(ws, "location"), "not a valid time series variable", fixed = TRUE)
})

test_that("check_availability succeeds and reports singular/plural missing fields", {
  ws <- build_weather_station(temp = 20, rh = 60)

  expect_no_error(fieldClim:::check_availability(ws, "temp", "rh"))
  expect_error(fieldClim:::check_availability(ws, "elev"), "elev is not available", fixed = TRUE)
  expect_error(fieldClim:::check_availability(ws, "elev", "lat"), "elev, lat are not available", fixed = TRUE)
})

test_that("print and summary weather_station methods are not package-specific", {
  skip("No package-specific print.weather_station or summary.weather_station method is implemented; base list methods already apply.")
})
