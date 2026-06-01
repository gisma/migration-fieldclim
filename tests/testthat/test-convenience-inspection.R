test_that("inspect_weather_station_inputs is read-only and returns inspection class", {
  ws <- build_weather_station(
    temp = 20,
    rad_bal = 400,
    soil_flux = 50,
    surface_type = "field"
  )
  before <- ws

  out <- inspect_weather_station_inputs(ws)

  expect_s3_class(out, "fieldclim_input_inspection")
  expect_equal(ws, before)
  expect_named(out, c("fields", "gaps", "method_readiness", "qc_flags", "guidance", "summary"))
  expect_false(any(grepl("_filled$", names(ws))))
  expect_false(any(grepl("_filled$", names(out))))
})

test_that("inspect_weather_station_inputs reports existing missing and partial fields", {
  ws <- build_weather_station(
    temp = c(20, NA, 22),
    rh = c(60, 65, 70),
    rad_net = c(350, 360, 370)
  )

  out <- inspect_weather_station_inputs(ws, targets = c("radiation", "humidity", "profiles"))
  fields <- out$fields

  temp <- fields[fields$field == "temp", ]
  rh <- fields[fields$field == "rh", ]
  rad_bal <- fields[fields$field == "rad_bal", ]
  rad_net <- fields[fields$field == "rad_net", ]

  expect_true(temp$present)
  expect_true(temp$any_missing)
  expect_false(temp$all_missing)
  expect_equal(temp$n_missing, 1)
  expect_equal(temp$n_total, 3)
  expect_equal(temp$missing_fraction, 1 / 3)
  expect_equal(temp$source_status, "partial")
  expect_equal(temp$variable_type, "temperature")

  expect_true(rh$present)
  expect_equal(rh$source_status, "present")
  expect_equal(rh$variable_type, "humidity")

  expect_false(rad_bal$present)
  expect_equal(rad_bal$source_status, "missing")

  expect_true(rad_net$present)
  expect_equal(rad_net$source_status, "present")
  expect_equal(rad_net$variable_type, "radiation")
})

test_that("inspect_weather_station_inputs reports gap runs and gap classes", {
  ws <- build_weather_station(
    datetime = as.POSIXct("2023-06-01 00:00:00", tz = "UTC") + seq(0, by = 300, length.out = 20),
    temp = c(1, NA, NA, 4, 5, NA, NA, NA, NA, NA, 11:20),
    rh = rep(60, 20)
  )

  out <- inspect_weather_station_inputs(ws, targets = c("profiles", "humidity"))
  temp_gaps <- out$gaps[out$gaps$field == "temp", ]

  expect_equal(nrow(temp_gaps), 2)
  expect_equal(temp_gaps$gap_start_index, c(2, 6))
  expect_equal(temp_gaps$gap_end_index, c(3, 10))
  expect_equal(temp_gaps$n_timesteps, c(2, 5))
  expect_equal(temp_gaps$gap_class, c("short", "medium"))
  expect_equal(temp_gaps$duration_seconds, c(600, 1500))
})

test_that("inspect_weather_station_inputs reports method readiness without replacement fields", {
  ws <- build_weather_station(
    temp = 20,
    rad_bal = 400,
    soil_flux = 50,
    surface_type = "field"
  )

  out <- inspect_weather_station_inputs(ws, methods = c("priestley_taylor", "bulk_residual"))
  readiness <- out$method_readiness

  pt <- readiness[readiness$method == "priestley_taylor", ]
  bulk <- readiness[readiness$method == "bulk_residual", ]
  ri <- readiness[readiness$method == "bulk_residual_ri_guard", ]

  expect_true(pt$ready)
  expect_equal(pt$missing_fields, "")
  expect_true("priestley_taylor" %in% out$summary$ready_methods)

  expect_false(bulk$ready)
  expect_true(grepl("t1", bulk$missing_fields, fixed = TRUE))
  expect_true(grepl("t2", bulk$missing_fields, fixed = TRUE))
  expect_true(grepl("v1", bulk$missing_fields, fixed = TRUE))
  expect_true(grepl("z1", bulk$missing_fields, fixed = TRUE))
  expect_true(grepl("z2", bulk$missing_fields, fixed = TRUE))

  expect_false(ri$ready)
  expect_true(grepl("v2", ri$missing_fields, fixed = TRUE))
  expect_true("bulk_residual_ri_guard" %in% out$summary$blocked_methods)
  expect_false(any(grepl("_filled", readiness$present_fields, fixed = TRUE)))
})

test_that("inspect_weather_station_inputs returns inspection guidance only", {
  ws <- build_weather_station(temp = 20)
  out <- inspect_weather_station_inputs(ws)

  expect_true(all(c("topic", "guidance") %in% names(out$guidance)))
  expect_true("variable_type" %in% out$guidance$topic)
  expect_true("gap_length" %in% out$guidance$topic)
  expect_true("quality_control" %in% out$guidance$topic)
  expect_true(any(grepl("outside fieldClim", out$guidance$guidance, fixed = TRUE)))
})

test_that("inspect_weather_station_inputs flags simple quality-control problems", {
  ws <- build_weather_station(
    datetime = as.POSIXct(c("2023-06-01 00:00:00", "2023-06-01 00:05:00", "2023-06-01 00:05:00"), tz = "UTC"),
    rh = c(50, 101, -1),
    v1 = c(1, -0.2, 2),
    moisture = c(0.2, 1.2, -0.1)
  )

  out <- inspect_weather_station_inputs(ws, targets = c("humidity", "soil", "profiles"))
  flags <- out$qc_flags

  expect_true("humidity_outside_0_100" %in% flags$flag)
  expect_true("negative_wind_speed" %in% flags$flag)
  expect_true("soil_moisture_outside_0_1" %in% flags$flag)
  expect_true("duplicated_timestamp" %in% flags$flag)
  expect_equal(out$summary$n_qc_flags, nrow(flags))
})

test_that("heat-flux methods require actual inputs and ignore replacement-style names", {
  ws <- build_weather_station(
    temp = 20,
    rad_bal_filled = 400,
    soil_flux_filled = 50,
    surface_type = "field"
  )

  expect_error(sensible_priestley_taylor(ws), "rad_bal")
  expect_error(latent_priestley_taylor(ws), "rad_bal")

  out <- inspect_weather_station_inputs(ws, methods = "priestley_taylor")
  expect_false(out$method_readiness$ready)
  expect_true(grepl("rad_bal", out$method_readiness$missing_fields, fixed = TRUE))
  expect_true(grepl("soil_flux", out$method_readiness$missing_fields, fixed = TRUE))
})

test_that("R source contains no live replacement-column completion terms", {
  r_files <- list.files(test_path("..", "..", "R"), pattern = "[.]R$", full.names = TRUE)
  source_text <- unlist(lapply(r_files, readLines, warn = FALSE), use.names = FALSE)

  forbidden <- c(
    "rad_bal_filled",
    "soil_flux_filled",
    "pressure_filled",
    "allow_modeled",
    "derive_from_measured",
    "complete_weather_station"
  )

  for (term in forbidden) {
    expect_false(any(grepl(term, source_text, fixed = TRUE)), info = term)
  }
})
