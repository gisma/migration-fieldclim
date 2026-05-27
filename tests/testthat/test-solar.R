test_that("sol_julian_day.default works", {
  datetime <- as.POSIXlt("2018-9-29")
  expect_equal(sol_julian_day(datetime), 272)
})

test_that("sol_julian_day.weather_station works", {
  datetime <- as.POSIXlt(c("2018-9-29", "2018-9-30"))
  weather_station <- build_weather_station(datetime = datetime)
  expect_equal(sol_julian_day(weather_station), c(272, 273))
})

test_that("sol_medium_suntime.default changes timezone", {
  datetime <- c("2018-08-19 13:00:00", "2018-08-19 10:00:00")
  datetime <- as.POSIXlt(datetime, format = "%Y-%m-%d %H:%M:%S", tz = "Africa/Addis_Ababa") # UTC+3
  lon <- 0
  expect_equal(sol_medium_suntime(datetime, lon), c(10, 7))
})