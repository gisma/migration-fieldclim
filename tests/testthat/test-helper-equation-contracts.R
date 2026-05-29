test_that("hum_absolute follows documented absolute-humidity equation", {
  rh <- 70
  temp <- 25

  # pres_vapor_p() is the documented upstream vapour-pressure helper.
  pvapor <- pres_vapor_p(temp, rh)
  temp_k <- temp + 273.15
  expected <- 0.21668 * pvapor / temp_k

  expect_equal(hum_absolute(rh, temp), expected, tolerance = 1e-12)
})

test_that("hum_specific follows documented specific-humidity equation", {
  rh <- 65
  temp <- 18
  elev <- 250

  pvapor <- pres_vapor_p(temp, rh)
  pressure <- pres_p(elev, temp)
  expected <- 0.622 * pvapor / pressure

  expect_equal(hum_specific(rh, temp, elev), expected, tolerance = 1e-12)
})

test_that("hum_evap_heat follows documented latent-heat equation", {
  temp_scalar <- 25
  temp_vector <- c(0, 10, 25)

  expect_equal(
    hum_evap_heat(temp_scalar),
    (2.5008 - 0.002372 * temp_scalar) * 10^6,
    tolerance = 1e-8
  )
  expect_equal(
    hum_evap_heat(temp_vector),
    (2.5008 - 0.002372 * temp_vector) * 10^6,
    tolerance = 1e-8
  )
})

test_that("hum_moisture_gradient follows documented specific-humidity gradient", {
  hum1 <- 80
  hum2 <- 60
  t1 <- 20
  t2 <- 15
  z1 <- 2
  z2 <- 10
  elev <- 100

  q1 <- hum_specific(hum1, t1, elev)
  q2 <- hum_specific(hum2, t2, elev)
  expected <- (q2 - q1) / (z2 - z1)

  expect_equal(
    hum_moisture_gradient(hum1, hum2, t1, t2, z1, z2, elev),
    expected,
    tolerance = 1e-14
  )
})

test_that("hum_precipitable_water preserves datetime class equivalence and vector length", {
  datetime_ct <- as.POSIXct(c("2022-07-15", "2022-12-15"), tz = "UTC")
  datetime_lt <- as.POSIXlt(datetime_ct)
  lat <- 50
  elev <- 100
  temp <- c(20, 20)

  out_ct <- hum_precipitable_water(datetime_ct, lat, elev, temp)
  out_lt <- hum_precipitable_water(datetime_lt, lat, elev, temp)

  expect_equal(out_ct, out_lt, tolerance = 1e-12)
  expect_equal(length(out_ct), length(datetime_ct))
})

test_that("pressure helpers follow documented pressure equations", {
  temp <- 20
  rh <- 60
  elev <- 500
  p0 <- p0_default
  g <- g_default
  rl <- rl_default
  temp_k <- temp + 273.15

  sat_expected <- 6.1078 * 10^((7.5 * temp) / (235 + temp))
  vapor_expected <- rh / 100 * sat_expected
  pressure_expected <- p0 * exp(-(g * elev) / (rl * temp_k))
  density_expected <- pressure_expected * 100 / (287.05 * temp_k)

  expect_equal(pres_sat_vapor_p(temp), sat_expected, tolerance = 1e-12)
  expect_equal(pres_vapor_p(temp, rh), vapor_expected, tolerance = 1e-12)
  expect_equal(pres_p(elev, temp), pressure_expected, tolerance = 1e-12)
  expect_equal(pres_air_density(elev, temp), density_expected, tolerance = 1e-12)
})

test_that("temperature helpers follow documented conversion and potential-temperature equations", {
  temp_c <- c(-5, 0, 20)
  temp_k <- c(268.15, 273.15, 293.15)

  expect_equal(c2k(temp_c), temp_c + 273.15, tolerance = 1e-12)
  expect_equal(k2c(temp_k), temp_k - 273.15, tolerance = 1e-12)

  t <- 25
  elev <- 270
  p0 <- 1000
  pressure <- pres_p(elev, t)
  air_const <- 0.286
  expected_kelvin <- (t + 273.15) * (p0 / pressure)^air_const
  expected_celsius <- expected_kelvin - 273.15

  expect_equal(temp_pot_temp(t, elev), expected_celsius, tolerance = 1e-12)
})

test_that("mechanical boundary-layer helpers follow documented square-root equations", {
  dist <- c(100, 400)

  expect_equal(bound_mech_low(dist), 0.3 * sqrt(dist), tolerance = 1e-12)
  expect_equal(bound_mech_avg(dist), 0.43 * sqrt(dist), tolerance = 1e-12)
})

test_that("thermal boundary-layer helper follows documented ustar equation with obstacle height", {
  v <- 5
  z <- 10
  obs_height <- 1
  temp_change_dist <- 500
  t_pot_upwind <- 15
  t_pot <- 20
  lapse_rate <- 0.0065

  z0 <- 0.1 * obs_height
  ustar <- v * 0.4 / log(z / z0)
  expected <- (ustar / v) * sqrt(
    temp_change_dist * abs(t_pot_upwind - t_pot) / abs(lapse_rate)
  )

  expect_equal(
    bound_thermal_avg(
      v = v,
      z = z,
      temp_change_dist = temp_change_dist,
      t_pot_upwind = t_pot_upwind,
      t_pot = t_pot,
      lapse_rate = lapse_rate,
      obs_height = obs_height
    ),
    expected,
    tolerance = 1e-12
  )
})

test_that("explicit utility turbulent-flux helper formulas are contract-tested", {
  t <- 22.53
  dpot <- -0.1254715
  dah <- -0.0001465109

  heat_capacity_expected <- 1005 * (1.2754298 - 0.0047219538 * t + 1.6463585 * 10^-5 * t)
  bowen_expected <- heat_capacity_expected * dpot / (hum_evap_heat(t) * dah)

  expect_equal(heat_capacity(t), heat_capacity_expected, tolerance = 1e-12)
  expect_equal(bowen_ratio(t, dpot, dah), bowen_expected, tolerance = 1e-12)
})

test_that("excluded empirical helper source tables are not equation-contract tested", {
  skip("sc(), gam(), alpha, soil, precipitable-water, and surface lookup tables require source/table validation, not equation-contract tests.")
})
