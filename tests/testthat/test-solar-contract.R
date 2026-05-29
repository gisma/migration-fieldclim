test_that("solar functions handle POSIXct and POSIXlt consistently", {
  datetime_ct <- as.POSIXct("2023-06-21 12:00:00", tz = "UTC")
  datetime_lt <- as.POSIXlt(datetime_ct, tz = "UTC")

  expect_equal(sol_hour_angle(datetime_ct, 0), sol_hour_angle(datetime_lt, 0), tolerance = 1e-12)
  expect_equal(sol_elevation(datetime_ct, 0, 50), sol_elevation(datetime_lt, 0, 50), tolerance = 1e-12)
  expect_equal(sol_azimuth(datetime_ct, 0, 50), sol_azimuth(datetime_lt, 0, 50), tolerance = 1e-12)
})
