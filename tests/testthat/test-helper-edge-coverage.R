
test_that("temperature conversion and potential temperature helpers handle vectors and weather_station heights", {
  temp_c <- c(-5, 0, 25)
  expect_equal(c2k(temp_c), c(268.15, 273.15, 298.15), tolerance = 1e-12)
  expect_equal(k2c(c2k(temp_c)), temp_c, tolerance = 1e-12)

  elev <- c(0, 270, 1000)
  theta <- temp_pot_temp(temp_c, elev)
  expect_length(theta, 3)
  expect_true(all(is.finite(theta)))

  ws <- build_weather_station(t1 = c(20, 21), t2 = c(18, 19), elev = c(100, 200))
  expect_equal(temp_pot_temp(ws, height = "lower"), temp_pot_temp(ws$t1, ws$elev), tolerance = 1e-12)
  expect_equal(temp_pot_temp(ws, height = "upper"), temp_pot_temp(ws$t2, ws$elev), tolerance = 1e-12)
})

test_that("pressure helpers handle RH edges, vectors and weather_station methods", {
  temp <- c(0, 20, 30)
  rh <- c(0, 50, 100)
  elev <- c(0, 100, 250)

  sat <- pres_sat_vapor_p(temp)
  vapor <- pres_vapor_p(temp, rh)
  pressure <- pres_p(elev, temp)
  density <- pres_air_density(elev, temp)

  expect_equal(vapor[1], 0, tolerance = 1e-12)
  expect_equal(vapor[3], sat[3], tolerance = 1e-12)
  expect_length(pressure, 3)
  expect_length(density, 3)
  expect_true(all(is.finite(pressure)))
  expect_true(all(is.finite(density)))

  ws <- build_weather_station(temp = temp, rh = rh, elev = elev)
  expect_equal(pres_sat_vapor_p(ws), sat, tolerance = 1e-12)
  expect_equal(pres_vapor_p(ws), vapor, tolerance = 1e-12)
  expect_equal(pres_p(ws), pressure, tolerance = 1e-12)
  expect_equal(pres_air_density(ws), density, tolerance = 1e-12)
})

test_that("check_availability reports singular and plural missing fields", {
  ws <- build_weather_station(temp = 20)

  expect_error(
    fieldClim:::check_availability(ws, "rh"),
    "rh is not available",
    fixed = TRUE
  )
  expect_error(
    fieldClim:::check_availability(ws, "rh", "elev"),
    "rh, elev are not available",
    fixed = TRUE
  )
  expect_no_error(fieldClim:::check_availability(ws, "temp"))
})

test_that("unit conversion helpers preserve NA and Inf semantics", {
  values <- c(NA_real_, Inf, -Inf, 0)
  expect_equal(k2c(c2k(values)), values)
  expect_true(is.na(c2k(NA_real_)))
  expect_equal(c2k(Inf), Inf)
})
