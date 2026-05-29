test_that("radiation balance functions follow component balance equations", {
  args <- list(
    datetime = as.POSIXlt("2023-08-06 12:00:00", tz = "UTC"),
    lon = 10,
    lat = 50,
    elev = 100,
    temp = 15,
    rh = 60,
    slope = 5,
    exposition = 180,
    valley = FALSE,
    surface_type = "lawn",
    surface_temp = 15
  )

  k_down <- rad_sw_in(
    args$datetime, args$lon, args$lat, args$elev, args$temp,
    args$slope, args$exposition
  ) + rad_diffuse_in(
    args$datetime, args$lon, args$lat, args$elev, args$temp,
    args$slope, args$exposition, args$valley
  )
  k_up <- rad_sw_out(
    args$datetime, args$lon, args$lat, args$elev, args$temp,
    args$slope, args$exposition, args$surface_type
  ) + rad_diffuse_out(
    args$datetime, args$lon, args$lat, args$elev, args$temp,
    args$slope, args$exposition, args$valley, args$surface_type
  )

  l_down <- rad_lw_in(args$temp, args$rh, args$slope, args$valley)
  l_up <- rad_lw_out(args$surface_type, args$surface_temp)

  k_star <- k_down - k_up
  l_star <- l_down - l_up
  rn <- k_star + l_star

  expect_equal(
    rad_sw_bal(
      args$datetime, args$lon, args$lat, args$elev, args$temp,
      args$slope, args$exposition, args$valley, args$surface_type
    ),
    k_star,
    tolerance = 1e-8
  )
  expect_equal(
    rad_lw_bal(args$temp, args$rh, args$slope, args$valley, args$surface_type, args$surface_temp),
    l_star,
    tolerance = 1e-8
  )
  expect_equal(
    rad_bal(
      args$datetime, args$lon, args$lat, args$elev, args$temp, args$rh,
      args$slope, args$exposition, args$valley, args$surface_type, args$surface_temp
    ),
    rn,
    tolerance = 1e-8
  )
})

test_that("soil_heat_flux follows documented conductive flux equation", {
  texture <- "sand"
  moisture <- 0.25
  soil_temp1 <- 18
  soil_temp2 <- 12
  soil_depth1 <- 0.1
  soil_depth2 <- 0.3

  lambda <- soil_thermal_cond(texture, moisture)
  expected <- -lambda * (soil_temp1 - soil_temp2) / (soil_depth1 - soil_depth2)

  expect_equal(
    soil_heat_flux(texture, moisture, soil_temp1, soil_temp2, soil_depth1, soil_depth2),
    expected,
    tolerance = 1e-10
  )
})

test_that("Priestley-Taylor functions follow documented available-energy partition", {
  temp <- 22
  rad_bal <- 500
  soil_flux <- 50
  surface_type <- "field"

  alpha <- priestley_taylor_coefficient[
    priestley_taylor_coefficient$surface_type == surface_type,
    "alpha"
  ]
  slope_coeff <- sc(temp)
  gamma_coeff <- gam(temp)
  available <- rad_bal - soil_flux
  expected_le <- alpha * slope_coeff / (slope_coeff + gamma_coeff) * available
  expected_h <- available - expected_le

  le <- latent_priestley_taylor(temp, rad_bal, soil_flux, surface_type)
  h <- sensible_priestley_taylor(temp, rad_bal, soil_flux, surface_type)

  expect_equal(le, expected_le, tolerance = 1e-10)
  expect_equal(h, expected_h, tolerance = 1e-10)
  expect_equal(h + le, available, tolerance = 1e-10)
})

test_that("Bulk-Residual functions follow neutral resistance and residual equations", {
  t1 <- 20.4
  t2 <- 19.9
  v1 <- 2
  v2 <- 4
  z1 <- 2
  z2 <- 10
  rho <- 1.225
  cp <- 1005
  k <- 0.41
  rad_bal <- 500
  soil_flux <- 50

  ra_v1 <- log(z2 / z1) / (k * v1)
  h_v1 <- rho * cp * (t1 - t2) / ra_v1
  expect_equal(
    sensible_bulk(t1, t2, v1, z1 = z1, z2 = z2, rho = rho, cp = cp, k = k),
    h_v1,
    tolerance = 1e-10
  )

  u_mean <- (v1 + v2) / 2
  ra_mean <- log(z2 / z1) / (k * u_mean)
  h_mean <- rho * cp * (t1 - t2) / ra_mean
  le_res <- rad_bal - soil_flux - h_mean

  h <- sensible_bulk(t1, t2, v1, v2, z1, z2, rho = rho, cp = cp, k = k)
  le <- latent_bulk_residual(rad_bal, soil_flux, h)

  expect_equal(h, h_mean, tolerance = 1e-10)
  expect_equal(le, le_res, tolerance = 1e-10)
  expect_equal(h + le, rad_bal - soil_flux, tolerance = 1e-10)
})

test_that("Bulk Richardson guard attributes follow documented Ri equation", {
  t1 <- c(20.2, 20.0, 20.0)
  t2 <- c(20.0, 20.0, 20.2)
  v1 <- c(2, 2, 2)
  v2 <- c(4, 4, 4)
  z1 <- 2
  z2 <- 10
  g <- 9.81

  h <- sensible_bulk(
    t1 = t1,
    t2 = t2,
    v1 = v1,
    v2 = v2,
    z1 = z1,
    z2 = z2,
    stability_method = "ri_guard",
    g = g
  )

  theta1 <- t1 + 273.15
  theta2 <- t2 + 273.15
  theta_mean <- (theta1 + theta2) / 2
  dtheta_dz <- (theta2 - theta1) / (z2 - z1)
  du_dz <- (v2 - v1) / (z2 - z1)
  expected_ri <- (g / theta_mean) * dtheta_dz / (du_dz^2)
  expected_class <- c("unstable", "neutral", "stable")

  expect_equal(attr(h, "bulk_Ri_g"), expected_ri, tolerance = 1e-12)
  expect_equal(attr(h, "bulk_stability"), expected_class)
  expect_true(all(is.finite(h)))
})

test_that("Bowen functions follow documented fieldClim beta partition", {
  t1 <- 20
  t2 <- 19.2
  hum1 <- 60
  hum2 <- 52
  z1 <- 2
  z2 <- 10
  elev <- 261
  rad_bal <- 500
  soil_flux <- 50

  theta1 <- temp_pot_temp(t1, elev)
  theta2 <- temp_pot_temp(t2, elev)
  dpot <- (theta2 - theta1) / (z2 - z1)
  ah1 <- hum_absolute(hum1, t1)
  ah2 <- hum_absolute(hum2, t2)
  dah <- (ah2 - ah1) / (z2 - z1)
  gamma_code <- 0.00066 * (1 + 0.000946 * t1)
  beta <- gamma_code * dpot / dah
  available <- rad_bal - soil_flux
  expected_h <- available * beta / (1 + beta)
  expected_le <- available / (1 + beta)

  h <- sensible_bowen(t1, t2, hum1, hum2, z1, z2, elev, rad_bal, soil_flux)
  le <- latent_bowen(t1, t2, hum1, hum2, z1, z2, elev, rad_bal, soil_flux)

  expect_true(is.finite(beta))
  expect_gt(abs(1 + beta), 0.1)
  expect_equal(h, expected_h, tolerance = 1e-10)
  expect_equal(le, expected_le, tolerance = 1e-10)
  expect_equal(h + le, available, tolerance = 1e-10)
})

test_that("latent_penman follows documented kPa VPD combination equation", {
  datetime <- as.POSIXct("2017-06-30 12:00:00", tz = "Europe/Berlin")
  v <- 2
  temp <- 25
  rh <- 55
  z <- 2
  rad_bal <- 200
  elev <- 261
  lat <- 50.8405
  lon <- 8.6832
  soil_flux <- 40
  obs_height <- 1
  surface_type <- "field"

  rs <- surface_resistance[
    surface_resistance$surface_type == "Temperate grassland",
    "rs"
  ]
  cp <- 1004
  rho <- 1.2
  gamma <- 0.665 * 10^(-3) * pres_p(elev, temp)
  es_hPa <- pres_sat_vapor_p(temp)
  ea_hPa <- pres_vapor_p(temp, rh)
  es_kPa <- es_hPa / 10
  ea_kPa <- ea_hPa / 10
  vpd_kPa <- es_kPa - ea_kPa
  delta <- 4098 * es_kPa / ((temp + 237.3)^2)
  d <- turb_displacement(obs_height, surroundings = "vegetation")
  zom <- 0.123 * obs_height
  zoh <- 0.1 * zom
  k <- 0.41
  ra <- (log((z - d) / zom) * log((z - d) / zoh)) / (k^2 * v)
  expected <- (delta * (rad_bal - soil_flux) + gamma * (cp * rho / ra) * vpd_kPa) /
    (delta + gamma * (1 + rs / ra))
  hpa_scaled <- (delta * (rad_bal - soil_flux) + gamma * (cp * rho / ra) * (es_hPa - ea_hPa)) /
    (delta + gamma * (1 + rs / ra))

  actual <- latent_penman(
    datetime = datetime,
    v = v,
    temp = temp,
    rh = rh,
    z = z,
    rad_bal = rad_bal,
    elev = elev,
    lat = lat,
    lon = lon,
    soil_flux = soil_flux,
    obs_height = obs_height,
    surface_type = surface_type
  )

  expect_equal(actual, expected, tolerance = 1e-10)
  expect_false(isTRUE(all.equal(as.numeric(actual), as.numeric(hpa_scaled), tolerance = 1e-8)))
})

test_that("sensible_monin uses vertical height difference in potential-temperature gradient", {
  t1 <- 22
  t2 <- 21
  z1 <- 2
  z2 <- 10
  v1 <- 1
  v2 <- 2.3
  elev <- 270
  surface_type <- "field"

  actual <- sensible_monin(t1, t2, z1, z2, v1, v2, elev, surface_type = surface_type)

  ustar <- turb_ustar(v = v2, z = z2, surface_type = surface_type)
  monin <- turb_flux_monin(z1, z2, v1, v2, t1, t2, elev, surface_type = surface_type)
  grad_rich_no <- turb_flux_grad_rich_no(t1, t2, z1, z2, v1, v2, elev)
  cp <- 1004.834
  k <- 0.35
  s1 <- z2 / monin
  busi <- if (grad_rich_no <= 0) {
    0.74 * (1 - 9 * s1)^(-0.5)
  } else {
    0.74 + 4.7 * s1
  }
  vertical_gradient <- (temp_pot_temp(t2, elev) - temp_pot_temp(t1, elev)) / (z2 - z1)
  log_gradient <- (temp_pot_temp(t2, elev) - temp_pot_temp(t1, elev)) / log(z2 - z1)
  air_density <- pres_air_density(elev, t1)
  expected_vertical <- (-1) * air_density * cp * (k * ustar * z2 / busi) * vertical_gradient
  expected_log <- (-1) * air_density * cp * (k * ustar * z2 / busi) * log_gradient

  expect_equal(actual, expected_vertical, tolerance = 1e-8)
  expect_false(isTRUE(all.equal(as.numeric(actual), as.numeric(expected_log), tolerance = 1e-8)))
})

test_that("Monin zero-gradient equations return zero flux for valid profiles", {
  expect_equal(
    sensible_monin(20, 20, 2, 10, 2, 4, 261, surface_type = "field"),
    0,
    tolerance = 1e-12
  )
  expect_equal(
    latent_monin(60, 60, 20, 20, 2, 4, 2, 10, 261, surface_type = "field"),
    0,
    tolerance = 1e-12
  )
})
