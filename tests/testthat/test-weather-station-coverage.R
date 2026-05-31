
test_that("build_weather_station stores named and unusual fields", {
  stamp <- as.POSIXct("2023-06-01 12:00:00", tz = "UTC")
  ws <- build_weather_station(
    datetime = stamp,
    temp = 20,
    custom_flag = TRUE,
    nested = list(a = 1)
  )

  expect_s3_class(ws, "weather_station")
  expect_equal(ws$datetime, stamp)
  expect_true(ws$custom_flag)
  expect_equal(ws$nested$a, 1)
})

test_that("as.data.frame.weather_station supports flat and legacy measurement objects", {
  stamp <- as.POSIXct(c("2023-06-01 12:00:00", "2023-06-01 13:00:00"), tz = "UTC")
  flat <- build_weather_station(
    datetime = stamp,
    t1 = c(20, 21),
    t2 = c(18, 19),
    v1 = c(2, 2.5),
    v2 = c(3, 3.5),
    ignored_scalar = "site-a"
  )

  full <- as.data.frame(flat)
  expect_equal(full$t1, c(20, 21))
  expect_equal(full$ignored_scalar, rep("site-a", 2))

  reduced <- as.data.frame(flat, reduced = TRUE)
  expect_equal(names(reduced), c("datetime", "t1", "t2", "v1", "v2"))

  unit <- as.data.frame(flat, reduced = TRUE, unit = TRUE)
  expect_true("temperature_lower[degC]" %in% names(unit))
  expect_true("wind_speed_upper[m/s]" %in% names(unit))

  legacy <- structure(
    list(measurements = data.frame(datetime = stamp, temp = c(10, 11))),
    class = "weather_station"
  )
  expect_equal(as.data.frame(legacy)$temp, c(10, 11))
})

test_that("plot_weather_station handles selected and all time-series variables", {
  skip_on_cran()
  stamp <- as.POSIXct(c("2023-06-01 12:00:00", "2023-06-01 13:00:00"), tz = "UTC")
  ws <- build_weather_station(
    datetime = stamp,
    temp = c(20, 21),
    v1 = c(2, 3),
    location = "site-a"
  )

  grDevices::pdf(file = tempfile(fileext = ".pdf"))
  on.exit(grDevices::dev.off(), add = TRUE)

  expect_no_error(plot_weather_station(ws, "temp"))
  expect_no_error(plot_weather_station(ws, NULL))
  expect_error(
    plot_weather_station(ws, "location"),
    "not a valid time series variable",
    fixed = TRUE
  )
})

test_that("plot_weather_station reports when no plottable series exist", {
  stamp <- as.POSIXct(c("2023-06-01 12:00:00", "2023-06-01 13:00:00"), tz = "UTC")
  ws <- build_weather_station(datetime = stamp, location = "site-a")

  grDevices::pdf(file = tempfile(fileext = ".pdf"))
  on.exit(grDevices::dev.off(), add = TRUE)

  expect_error(
    plot_weather_station(ws, NULL),
    "No time series variables available to plot.",
    fixed = TRUE
  )
})
