
test_that("roughness length covers obstacle, surface and weather_station branches", {
  expect_equal(turb_roughness_length(obs_height = 2), 0.2, tolerance = 1e-12)
  expect_true(is.finite(turb_roughness_length(surface_type = "field")))
  expect_error(turb_roughness_length(surface_type = "not-a-surface"), "Invalid surface type", fixed = TRUE)
  expect_error(turb_roughness_length(), "Please check the input values", fixed = TRUE)

  ws_obs <- build_weather_station(obs_height = 2)
  ws_surface <- build_weather_station(surface_type = "field")
  expect_equal(turb_roughness_length(ws_obs), 0.2, tolerance = 1e-12)
  expect_equal(turb_roughness_length(ws_surface), turb_roughness_length(surface_type = "field"), tolerance = 1e-12)
})

test_that("displacement height covers vegetation, city and invalid surroundings", {
  expect_equal(turb_displacement(obs_height = 3, surroundings = "vegetation"), 2, tolerance = 1e-12)
  expect_equal(turb_displacement(obs_height = 10, surroundings = "city"), 8, tolerance = 1e-12)
  expect_error(turb_displacement(obs_height = 10, surroundings = "water"), "vegetation", fixed = TRUE)

  ws <- build_weather_station(obs_height = 3)
  expect_equal(turb_displacement(ws), 2, tolerance = 1e-12)
  expect_equal(turb_displacement(ws, surroundings = "city"), 2.4, tolerance = 1e-12)
})

test_that("ustar covers valid, weather_station and infinite geometry branches", {
  expect_true(is.finite(turb_ustar(v = 5, z = 10, obs_height = 1)))
  expect_true(is.finite(turb_ustar(v = 5, z = 10, surface_type = "field")))
  expect_error(turb_ustar(v = 5, z = 10), "Either obs_height or surface_type", fixed = TRUE)

  ws_obs <- build_weather_station(v2 = c(3, 4), z2 = c(10, 10), obs_height = 1)
  ws_surface <- build_weather_station(v2 = c(3, 4), z2 = c(10, 10), surface_type = "field")
  expect_length(turb_ustar(ws_obs), 2)
  expect_length(turb_ustar(ws_surface), 2)
  expect_true(all(is.finite(turb_ustar(ws_obs))))

  expect_warning(
    bad <- turb_ustar(v = 5, z = 1, obs_height = 10),
    "infinite",
    fixed = TRUE
  )
  expect_true(is.na(bad))
})

test_that("turbulent flux profile helpers cover obs_height and surface branches", {
  args <- list(z1 = 2, z2 = 10, v1 = c(2, 2), v2 = c(4, 5), t1 = c(20, 19), t2 = c(18, 18.5), elev = c(100, 100))

  mon_obs <- suppressWarnings(do.call(turb_flux_monin, c(args, list(obs_height = 1))))
  mon_surface <- suppressWarnings(do.call(turb_flux_monin, c(args, list(surface_type = "field"))))
  expect_length(mon_obs, 2)
  expect_length(mon_surface, 2)

  heat_ex <- suppressWarnings(do.call(turb_flux_ex_quotient_temp, c(args, list(obs_height = 1))))
  imp_ex <- suppressWarnings(do.call(turb_flux_ex_quotient_imp, c(args, list(surface_type = "field"))))
  expect_length(heat_ex, 2)
  expect_length(imp_ex, 2)

  imp <- suppressWarnings(do.call(turb_flux_imp_exchange, c(args, list(surface_type = "field"))))
  expect_length(imp, 2)
})

test_that("turbulent flux weather_station wrappers dispatch with obs_height", {
  ws <- build_weather_station(
    z1 = 2,
    z2 = 10,
    v1 = c(2, 2),
    v2 = c(4, 5),
    t1 = c(20, 19),
    t2 = c(18, 18.5),
    elev = c(100, 100),
    obs_height = 1
  )

  expect_length(suppressWarnings(turb_flux_monin(ws)), 2)
  expect_length(suppressWarnings(turb_flux_ex_quotient_temp(ws)), 2)
  expect_length(suppressWarnings(turb_flux_ex_quotient_imp(ws)), 2)
  expect_length(suppressWarnings(turb_flux_imp_exchange(ws)), 2)
})

test_that("turb_flux_calc full workflow includes fallback and bulk outputs", {
  ws <- build_weather_station(
    datetime = as.POSIXct(c("2023-06-01 12:00:00", "2023-06-01 13:00:00"), tz = "UTC"),
    temp = c(20, 21),
    rad_bal = c(450, 420),
    soil_flux = c(50, 40),
    surface_type = "field",
    t1 = c(21, 20),
    t2 = c(19, 18),
    hum1 = c(70, 68),
    hum2 = c(60, 58),
    v1 = c(2, 2.2),
    v2 = c(4, 4.5),
    z1 = 2,
    z2 = 10,
    elev = c(100, 100),
    lon = 8,
    lat = 50
  )

  expect_warning(
    out <- turb_flux_calc(ws),
    "latent_penman",
    fixed = TRUE
  )
  expect_s3_class(out, "weather_station")
  expect_true(all(c("sensible_bulk", "latent_bulk_residual", "stability", "latent_penman") %in% names(out)))
  expect_true(all(is.na(out$latent_penman)))
  expect_equal(out$sensible_bulk + out$latent_bulk_residual, out$rad_bal - out$soil_flux, tolerance = 1e-8)
})

test_that("turb_flux_bulk_residual passes Richardson guard through", {
  ws <- build_weather_station(
    t1 = c(20, 20),
    t2 = c(19.5, 21),
    v1 = c(1, 1),
    v2 = c(3, 1),
    z1 = 2,
    z2 = 10,
    rad_bal = c(400, 400),
    soil_flux = c(50, 50),
    elev = c(100, 100)
  )

  expect_warning(
    out <- turb_flux_bulk_residual(ws, stability_method = "ri_guard"),
    regexp = "Richardson"
  )
  expect_equal(length(attr(out$sensible_bulk, "bulk_Ri_g")), 2)
  expect_equal(length(attr(out$sensible_bulk, "bulk_stability")), 2)
  expect_true(is.finite(out$sensible_bulk[1]))
  expect_true(is.na(out$sensible_bulk[2]))
  expect_true(is.na(out$latent_bulk_residual[2]))
})
