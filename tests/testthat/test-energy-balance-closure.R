test_that("bulk residual closure diagnostics close available energy", {
  ws <- structure(list(
    datetime = as.POSIXct("2024-06-01 12:00:00", tz = "UTC") + 0:1,
    rad_bal = c(400, 300),
    soil_flux = c(60, 40),
    sensible_bulk = c(120, 80),
    latent_bulk_residual = c(220, 180),
    latent_penman = c(150, 120),
    sensible_monin = c(90, 70),
    latent_monin = c(130, 100)
  ), class = "weather_station")

  out <- energy_balance_closure(ws, methods = "bulk_residual")

  expect_equal(out$closure_residual, c(0, 0))
  expect_equal(out$closure_ratio, c(1, 1))
})

test_that("Penman closure diagnostics report unresolved complement only", {
  ws <- structure(list(
    datetime = as.POSIXct("2024-06-01 12:00:00", tz = "UTC") + 0:1,
    rad_bal = c(400, 300),
    soil_flux = c(60, 40),
    sensible_bulk = c(120, 80),
    latent_bulk_residual = c(220, 180),
    latent_penman = c(150, 120),
    sensible_monin = c(90, 70),
    latent_monin = c(130, 100)
  ), class = "weather_station")

  out <- energy_balance_closure(ws, methods = "penman")

  expect_equal(out$unresolved_complement, ws$rad_bal - ws$soil_flux - ws$latent_penman)
  expect_true(all(is.na(out$sensible)))
  expect_true(all(is.na(out$closure_residual)))
  expect_true(all(is.na(out$closure_ratio)))
  expect_equal(out$status, rep("open_complement", 2))
})

test_that("Monin closure diagnostics remain diagnostic residuals", {
  ws <- structure(list(
    datetime = as.POSIXct("2024-06-01 12:00:00", tz = "UTC") + 0:1,
    rad_bal = c(400, 300),
    soil_flux = c(60, 40),
    sensible_bulk = c(120, 80),
    latent_bulk_residual = c(220, 180),
    latent_penman = c(150, 120),
    sensible_monin = c(90, 70),
    latent_monin = c(130, 100)
  ), class = "weather_station")

  out <- energy_balance_closure(ws, methods = "monin")
  expected <- ws$rad_bal - ws$soil_flux - ws$sensible_monin - ws$latent_monin

  expect_equal(out$closure_residual, expected)
  expect_equal(out$status, rep("diagnostic_residual", 2))
})

test_that("missing method fields return missing_fields without aborting", {
  ws <- structure(list(
    datetime = as.POSIXct("2024-06-01 12:00:00", tz = "UTC") + 0:1,
    rad_bal = c(400, 300),
    soil_flux = c(60, 40),
    sensible_bulk = c(120, 80),
    latent_bulk_residual = c(220, 180),
    latent_penman = c(150, 120),
    sensible_monin = c(90, 70),
    latent_monin = c(130, 100)
  ), class = "weather_station")

  out <- energy_balance_closure(ws, methods = c("priestley_taylor", "bowen"))

  expect_equal(unique(out$status), "missing_fields")
  expect_equal(unique(out$method), c("priestley_taylor", "bowen"))
})

test_that("methods argument filters closure diagnostics", {
  ws <- structure(list(
    datetime = as.POSIXct("2024-06-01 12:00:00", tz = "UTC") + 0:1,
    rad_bal = c(400, 300),
    soil_flux = c(60, 40),
    sensible_bulk = c(120, 80),
    latent_bulk_residual = c(220, 180),
    latent_penman = c(150, 120),
    sensible_monin = c(90, 70),
    latent_monin = c(130, 100)
  ), class = "weather_station")

  out <- energy_balance_closure(ws, methods = "penman")

  expect_equal(unique(out$method), "penman")
})

test_that("energy_balance_closure output contains required columns", {
  ws <- structure(list(
    datetime = as.POSIXct("2024-06-01 12:00:00", tz = "UTC") + 0:1,
    rad_bal = c(400, 300),
    soil_flux = c(60, 40),
    sensible_bulk = c(120, 80),
    latent_bulk_residual = c(220, 180),
    latent_penman = c(150, 120),
    sensible_monin = c(90, 70),
    latent_monin = c(130, 100)
  ), class = "weather_station")

  out <- energy_balance_closure(ws, methods = "bulk_residual")
  required <- c(
    "datetime", "method", "closure_type", "rad_bal", "soil_flux",
    "available_energy", "sensible", "latent", "turbulent_sum",
    "closure_residual", "closure_ratio", "unresolved_complement", "status"
  )

  expect_equal(names(out), required)
})


test_that("plot_energy_balance_closure runs for residual diagnostics", {
  ws <- structure(list(
    datetime = as.POSIXct("2024-06-01 12:00:00", tz = "UTC") + 0:1,
    rad_bal = c(400, 300),
    soil_flux = c(60, 40),
    sensible_bulk = c(120, 80),
    latent_bulk_residual = c(220, 180),
    latent_penman = c(150, 120),
    sensible_monin = c(90, 70),
    latent_monin = c(130, 100)
  ), class = "weather_station")
  closure <- energy_balance_closure(ws, methods = c("bulk_residual", "penman", "monin"))

  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_no_error(plot_energy_balance_closure(closure, type = "residual"))
})

test_that("plot_energy_balance_closure runs for ratio diagnostics", {
  ws <- structure(list(
    datetime = as.POSIXct("2024-06-01 12:00:00", tz = "UTC") + 0:1,
    rad_bal = c(400, 300),
    soil_flux = c(60, 40),
    sensible_bulk = c(120, 80),
    latent_bulk_residual = c(220, 180),
    latent_penman = c(150, 120),
    sensible_monin = c(90, 70),
    latent_monin = c(130, 100)
  ), class = "weather_station")
  closure <- energy_balance_closure(ws, methods = c("bulk_residual", "penman", "monin"))

  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  expect_no_error(plot_energy_balance_closure(closure, type = "ratio"))
})

test_that("Penman unresolved complement is not recoded as closure residual", {
  ws <- structure(list(
    datetime = as.POSIXct("2024-06-01 12:00:00", tz = "UTC") + 0:1,
    rad_bal = c(400, 300),
    soil_flux = c(60, 40),
    sensible_bulk = c(120, 80),
    latent_bulk_residual = c(220, 180),
    latent_penman = c(150, 120),
    sensible_monin = c(90, 70),
    latent_monin = c(130, 100)
  ), class = "weather_station")
  closure <- energy_balance_closure(ws, methods = "penman")

  expect_true(all(is.na(closure$closure_residual)))
  expect_equal(
    closure$unresolved_complement,
    ws$rad_bal - ws$soil_flux - ws$latent_penman
  )

  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  result <- plot_energy_balance_closure(closure, type = "residual")
  expect_identical(result, closure)
})
