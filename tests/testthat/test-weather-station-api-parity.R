test_that("humidity weather_station methods match direct calls", {
  ws <- build_weather_station(
    datetime = physics_standard_datetime(2),
    lat = 50.8405,
    elev = 261,
    temp = c(22, 21),
    rh = c(55, 60),
    t1 = c(22.4, 21.8),
    t2 = c(21.2, 20.7),
    hum1 = c(60, 62),
    hum2 = c(55, 58),
    z1 = 2,
    z2 = 10
  )

  expect_equal(hum_absolute(ws), hum_absolute(ws$rh, ws$temp), tolerance = 1e-12)
  expect_equal(hum_specific(ws), hum_specific(ws$rh, ws$temp, ws$elev), tolerance = 1e-12)
  expect_equal(hum_evap_heat(ws), hum_evap_heat(ws$temp), tolerance = 1e-12)
  expect_equal(
    hum_precipitable_water(ws),
    hum_precipitable_water(ws$datetime, ws$lat, ws$elev, ws$temp),
    tolerance = 1e-12
  )
  expect_equal(
    hum_moisture_gradient(ws),
    hum_moisture_gradient(
      ws$hum1, ws$hum2, ws$t1, ws$t2, ws$z1, ws$z2, ws$elev
    ),
    tolerance = 1e-12
  )
})

test_that("soil weather_station methods match direct calls for valid inputs", {
  ws <- build_weather_station(
    texture = "sand",
    moisture = c(0.20, 0.25),
    soil_temp1 = c(18, 19),
    soil_temp2 = c(12, 13),
    soil_depth1 = c(0.10, 0.10),
    soil_depth2 = c(0.30, 0.30)
  )

  expect_equal(
    soil_heat_flux(ws),
    soil_heat_flux(
      ws$texture, ws$moisture, ws$soil_temp1, ws$soil_temp2,
      ws$soil_depth1, ws$soil_depth2
    ),
    tolerance = 1e-12
  )
  expect_equal(
    soil_thermal_cond(ws),
    soil_thermal_cond(ws$texture, ws$moisture),
    tolerance = 1e-12
  )
  expect_equal(
    soil_heat_cap(ws),
    soil_heat_cap(ws$moisture, ws$texture),
    tolerance = 1e-12
  )
})

test_that("Priestley-Taylor weather_station methods match direct calls", {
  ws <- physics_minimal_pt_station()

  expect_equal(
    sensible_priestley_taylor(ws),
    sensible_priestley_taylor(ws$temp, ws$rad_bal, ws$soil_flux, ws$surface_type),
    tolerance = 1e-12
  )
  expect_equal(
    latent_priestley_taylor(ws),
    latent_priestley_taylor(ws$temp, ws$rad_bal, ws$soil_flux, ws$surface_type),
    tolerance = 1e-12
  )
})

test_that("Bulk-Residual weather_station methods match direct calls", {
  ws <- physics_standard_weather_station()

  h_ws <- sensible_bulk(ws, warn_threshold = Inf)
  h_direct <- sensible_bulk(
    t1 = ws$t1,
    t2 = ws$t2,
    v1 = ws$v1,
    v2 = ws$v2,
    z1 = ws$z1,
    z2 = ws$z2,
    elev = ws$elev,
    warn_threshold = Inf
  )

  expect_equal(h_ws, h_direct, tolerance = 1e-12)

  le_ws <- latent_bulk_residual(ws, sensible = h_ws, warn_threshold = Inf)
  le_direct <- latent_bulk_residual(
    ws$rad_bal, ws$soil_flux, h_direct, warn_threshold = Inf
  )

  expect_equal(le_ws, le_direct, tolerance = 1e-12)

  workflow <- turb_flux_bulk_residual(ws, warn_threshold = Inf)

  expect_equal(workflow$sensible_bulk, h_direct, tolerance = 1e-12)
  expect_equal(workflow$latent_bulk_residual, le_direct, tolerance = 1e-12)
})

test_that("Bowen weather_station methods match direct calls for non-singular inputs", {
  ws <- physics_standard_weather_station()

  expect_equal(
    suppressWarnings(sensible_bowen(ws)),
    suppressWarnings(sensible_bowen(
      ws$t1, ws$t2, ws$hum1, ws$hum2, ws$z1, ws$z2,
      ws$elev, ws$rad_bal, ws$soil_flux
    )),
    tolerance = 1e-12
  )
  expect_equal(
    suppressWarnings(latent_bowen(ws)),
    suppressWarnings(latent_bowen(
      ws$t1, ws$t2, ws$hum1, ws$hum2, ws$z1, ws$z2,
      ws$elev, ws$rad_bal, ws$soil_flux
    )),
    tolerance = 1e-12
  )
})

test_that("Monin-Obukhov weather_station methods match direct calls", {
  ws <- physics_standard_weather_station()

  expect_equal(
    suppressWarnings(sensible_monin(ws)),
    suppressWarnings(sensible_monin(
      t1 = ws$t1,
      t2 = ws$t2,
      z1 = ws$z1,
      z2 = ws$z2,
      v1 = ws$v1,
      v2 = ws$v2,
      elev = ws$elev,
      obs_height = ws$obs_height
    )),
    tolerance = 1e-12
  )
  expect_equal(
    suppressWarnings(latent_monin(ws)),
    suppressWarnings(latent_monin(
      hum1 = ws$hum1,
      hum2 = ws$hum2,
      t1 = ws$t1,
      t2 = ws$t2,
      v1 = ws$v1,
      v2 = ws$v2,
      z1 = ws$z1,
      z2 = ws$z2,
      elev = ws$elev,
      obs_height = ws$obs_height
    )),
    tolerance = 1e-12
  )
})

test_that("Penman weather_station method matches direct call with current humidity routing", {
  ws <- physics_standard_weather_station()

  expect_equal(
    suppressWarnings(latent_penman(ws)),
    suppressWarnings(latent_penman(
      datetime = ws$datetime,
      v = ws$v1,
      temp = ws$temp,
      rh = ws$hum1,
      z = ws$z1,
      rad_bal = ws$rad_bal,
      elev = ws$elev,
      lat = ws$lat,
      lon = ws$lon,
      soil_flux = ws$soil_flux,
      obs_height = ws$obs_height,
      surface_type = ws$surface_type
    )),
    tolerance = 1e-12
  )
})

test_that("turb_flux_calc pt_only adds only Priestley-Taylor fields", {
  ws <- physics_minimal_pt_station()
  out <- turb_flux_calc(ws, pt_only = TRUE)

  expect_named(
    out,
    c(
      "temp", "rad_bal", "soil_flux", "surface_type",
      "sensible_priestley_taylor", "latent_priestley_taylor"
    )
  )
  expect_equal(
    out$sensible_priestley_taylor,
    sensible_priestley_taylor(ws),
    tolerance = 1e-12
  )
  expect_equal(
    out$latent_priestley_taylor,
    latent_priestley_taylor(ws),
    tolerance = 1e-12
  )

  absent_fields <- c(
    "latent_penman", "sensible_bowen", "latent_bowen",
    "sensible_monin", "latent_monin",
    "sensible_bulk", "latent_bulk_residual"
  )
  expect_false(any(absent_fields %in% names(out)))
})

test_that("turb_flux_calc full workflow includes documented fields when inputs are available", {
  ws <- physics_standard_weather_station()
  out <- suppressWarnings(turb_flux_calc(ws))

  expected_fields <- c(
    "stability",
    "sensible_priestley_taylor",
    "latent_priestley_taylor",
    "sensible_bowen",
    "latent_bowen",
    "sensible_monin",
    "latent_monin",
    "latent_penman",
    "sensible_bulk",
    "latent_bulk_residual"
  )

  expect_true(all(expected_fields %in% names(out)))
  expect_equal(
    out$sensible_bulk,
    suppressWarnings(sensible_bulk(ws)),
    tolerance = 1e-12
  )
  expect_equal(
    out$latent_bulk_residual,
    suppressWarnings(latent_bulk_residual(ws, sensible = out$sensible_bulk)),
    tolerance = 1e-12
  )
})

test_that("turb_flux_calc keeps Penman failure non-fatal", {
  ws <- physics_standard_weather_station()
  ws$datetime <- as.character(ws$datetime)

  messages <- character()
  out <- withCallingHandlers(
    turb_flux_calc(ws),
    warning = function(w) {
      messages <<- c(messages, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  expect_true(any(grepl("latent_penman", messages, fixed = TRUE)))
  expect_true(all(is.na(out$latent_penman)))
  expect_true(all(c(
    "sensible_priestley_taylor", "latent_priestley_taylor",
    "sensible_bulk", "latent_bulk_residual",
    "sensible_bowen", "latent_bowen",
    "sensible_monin", "latent_monin"
  ) %in% names(out)))
})

test_that("turb_flux_bulk_residual passes Richardson guard to sensible_bulk", {
  ws <- build_weather_station(
    t1 = c(22.0, 20.0),
    t2 = c(21.0, 20.1),
    v1 = c(2.0, 2.0),
    v2 = c(4.0, 4.0),
    z1 = 2,
    z2 = 10,
    elev = 261,
    rad_bal = c(500, 450),
    soil_flux = c(50, 40)
  )

  out <- turb_flux_bulk_residual(
    ws,
    stability_method = "ri_guard",
    warn_threshold = Inf
  )
  h_direct <- sensible_bulk(
    ws,
    stability_method = "ri_guard",
    warn_threshold = Inf
  )

  expect_equal(out$sensible_bulk, h_direct, tolerance = 1e-12)
  expect_equal(
    attr(out$sensible_bulk, "bulk_Ri_g"),
    attr(h_direct, "bulk_Ri_g"),
    tolerance = 1e-12
  )
  expect_equal(
    attr(out$sensible_bulk, "bulk_stability"),
    attr(h_direct, "bulk_stability")
  )
  expect_equal(
    out$latent_bulk_residual,
    suppressWarnings(latent_bulk_residual(ws, sensible = out$sensible_bulk)),
    tolerance = 1e-12
  )
})
