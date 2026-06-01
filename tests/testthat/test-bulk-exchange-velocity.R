test_that("sensible_bulk keeps wind_mean as default exchange velocity", {
  h <- sensible_bulk(
    t1 = 20,
    t2 = 19,
    v1 = 1,
    v2 = 3,
    z1 = 2,
    z2 = 10,
    warn_threshold = Inf
  )

  wind_mean <- 2
  expected <- 1.225 * 1005 * (20 - 19) /
    (log(10 / 2) / (0.41 * wind_mean))

  expect_equal(h, expected)
})

test_that("sensible_bulk can use profile-derived friction velocity", {
  h <- sensible_bulk(
    t1 = 20,
    t2 = 19,
    v1 = 1,
    v2 = 3,
    z1 = 2,
    z2 = 10,
    exchange_velocity = "u_star_profile",
    warn_threshold = Inf
  )

  k <- 0.41
  ustar <- k * (3 - 1) / log(10 / 2)
  expected <- 1.225 * 1005 * (20 - 19) /
    (log(10 / 2) / (k * ustar))

  expect_equal(h, expected)
})

test_that("u_star_profile requires v2", {
  expect_error(
    sensible_bulk(
      t1 = 20,
      t2 = 19,
      v1 = 1,
      z1 = 2,
      z2 = 10,
      warn_threshold = Inf,
      exchange_velocity = "u_star_profile"
    ),
    "requires v2"
  )
})

test_that("sensible_bulk guards non-positive profile-derived friction velocity", {
  expect_warning(
    h <- sensible_bulk(
      t1 = 20,
      t2 = 19,
      v1 = 2,
      v2 = 1,
      z1 = 2,
      z2 = 10,
      exchange_velocity = "u_star_profile"
    ),
    "profile-derived friction velocity"
  )

  expect_true(is.na(h))
})

test_that("sensible_bulk can use roughness-derived friction velocity", {
  h <- sensible_bulk(
    t1 = 20,
    t2 = 19,
    v1 = 1,
    v2 = 3,
    z1 = 2,
    z2 = 10,
    surface_type = "field",
    warn_threshold = Inf,
    exchange_velocity = "u_star_roughness"
  )

  k <- 0.41
  z0 <- turb_roughness_length(surface_type = "field")
  ustar <- k * 3 / log(10 / z0)

  expected <- 1.225 * 1005 * (20 - 19) /
    (log(10 / 2) / (k * ustar))

  expect_equal(h, expected)
})

test_that("u_star_roughness requires surface_type or obs_height", {
  expect_error(
    sensible_bulk(
      t1 = 20,
      t2 = 19,
      v1 = 1,
      z1 = 2,
      z2 = 10,
      exchange_velocity = "u_star_roughness"
    ),
    "requires surface_type or obs_height"
  )
})

test_that("weather_station method passes u_star_profile correctly", {
  ws <- build_weather_station(
    t1 = c(20, 21),
    t2 = c(19, 20),
    v1 = c(1, 1),
    v2 = c(3, 3),
    z1 = 2,
    z2 = 10
  )

  h_ws <- sensible_bulk(ws, exchange_velocity = "u_star_profile", warn_threshold = Inf)

  h_direct <- sensible_bulk(
    t1 = ws$t1,
    t2 = ws$t2,
    v1 = ws$v1,
    v2 = ws$v2,
    z1 = ws$z1,
    z2 = ws$z2,
    exchange_velocity = "u_star_profile",
    warn_threshold = Inf
  )

  expect_equal(h_ws, h_direct)
})

test_that("weather_station method passes u_star_roughness correctly", {
  ws <- build_weather_station(
    t1 = c(20, 21),
    t2 = c(19, 20),
    v1 = c(1, 1),
    v2 = c(3, 3),
    z1 = 2,
    z2 = 10,
    surface_type = "field"
  )

  h_ws <- sensible_bulk(ws, exchange_velocity = "u_star_roughness", warn_threshold = Inf)

  h_direct <- sensible_bulk(
    t1 = ws$t1,
    t2 = ws$t2,
    v1 = ws$v1,
    v2 = ws$v2,
    z1 = ws$z1,
    z2 = ws$z2,
    surface_type = ws$surface_type,
    exchange_velocity = "u_star_roughness",
    warn_threshold = Inf
  )

  expect_equal(h_ws, h_direct)
})

test_that("turb_flux_bulk_residual passes exchange_velocity through dots", {
  ws <- build_weather_station(
    t1 = c(20, 21),
    t2 = c(19, 20),
    v1 = c(1, 1),
    v2 = c(3, 3),
    z1 = 2,
    z2 = 10,
    rad_bal = c(400, 300),
    soil_flux = c(60, 40),
    surface_type = "field"
  )

  out <- turb_flux_bulk_residual(
    ws,
    exchange_velocity = "u_star_profile",
    warn_threshold = Inf
  )

  expect_true("sensible_bulk" %in% names(out))
  expect_true("latent_bulk_residual" %in% names(out))

  expect_equal(
    out$sensible_bulk + out$latent_bulk_residual,
    out$rad_bal - out$soil_flux
  )
})
