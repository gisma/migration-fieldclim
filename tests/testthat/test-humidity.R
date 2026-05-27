
test_that("hum_precipitable_water works in northern hemisphere", {
  t0 = c(300, 294, 272.2, 287, 257.1)
  pwst = c(4.1167, 2.9243, 0.8539, 2.0852, 0.4176)

  datetime <- as.POSIXlt(c("2023-09-10", "2023-09-10", "2023-12-10", "2023-09-10", "2023-12-10"))
  lat <- c(5, 35, 35, 65, 65)
  a <- c()
  for (i in seq_along(lat)) {
    weather_station <- build_weather_station(
      datetime = datetime[i],
      lat = lat[i],
      elev = 0,
      temp = 20
    )
    expect_equal(
      hum_precipitable_water(weather_station),
      pwst[i] * (t0[i] / weather_station$temp)^0.5
    )
  }
})

test_that("hum_precipitable_water works in southern hemisphere", {
  t0 = c(300, 294, 272.2, 287, 257.1)
  pwst = c(4.1167, 2.9243, 0.8539, 2.0852, 0.4176)

  datetime <- as.POSIXlt(c("2023-09-10", "2023-09-10", "2023-12-10", "2023-09-10", "2023-12-10"))
  lat <- -c(5, 35, 35, 65, 65)
  a <- c()
  for (i in seq_along(lat)) {
    weather_station <- build_weather_station(
      datetime = datetime[i],
      lat = lat[i],
      elev = 0,
      temp = 20
    )
    a[i] <- hum_precipitable_water(weather_station)
  }
  expect_equal(
    a,
    c(
      pwst[1] * (t0[1] / weather_station$temp)^0.5,
      pwst[3] * (t0[3] / weather_station$temp)^0.5,
      pwst[2] * (t0[2] / weather_station$temp)^0.5,
      pwst[5] * (t0[5] / weather_station$temp)^0.5,
      pwst[4] * (t0[4] / weather_station$temp)^0.5
    )
  )
})


