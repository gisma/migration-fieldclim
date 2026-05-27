# Test data
elev <- 200
t <- 20.8
p <- 989.9613

test_that("pres_p.weather_station works with additional args", {
  weather_station <- build_weather_station(
    elev = 0,
    temp = 25
  )
  expect_equal(pres_p(weather_station, p0 = 1), 1)
})


