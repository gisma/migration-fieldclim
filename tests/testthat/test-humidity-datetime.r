test_that("hum_precipitable_water accepts POSIXct and POSIXlt datetimes", {
  dt_ct <- as.POSIXct(
    c("2017-06-30 12:00:00", "2017-12-30 12:00:00"),
    tz = "Europe/Berlin"
  )
  dt_lt <- as.POSIXlt(dt_ct)

  out_ct <- hum_precipitable_water(
    datetime = dt_ct,
    lat = 50.8405,
    elev = 261,
    temp = c(20, 5)
  )

  out_lt <- hum_precipitable_water(
    datetime = dt_lt,
    lat = 50.8405,
    elev = 261,
    temp = c(20, 5)
  )

  expect_equal(out_ct, out_lt)
  expect_length(out_ct, length(dt_ct))
  expect_true(all(is.finite(out_ct)))
})

test_that("rad_sw_in accepts POSIXct datetime through vapor transmittance path", {
  dt <- as.POSIXct(
    "2017-06-30 12:00:00",
    tz = "Europe/Berlin"
  )
  
  out <- rad_sw_in(
    datetime = dt,
    lon = 8.6832,
    lat = 50.8405,
    elev = 261,
    temp = 20,
    rh = 60,
    slope = 0,
    exposition = 180
  )
  
  expect_true(is.finite(out))
  expect_gte(out, 0)
})