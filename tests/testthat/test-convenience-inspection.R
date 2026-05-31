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
  expect_false("fields" %in% names(ws))
  expect_false("method_readiness" %in% names(ws))
  expect_named(out, c("fields", "method_readiness", "possible_actions", "summary"))
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
  expect_equal(temp$source_status, "partial")

  expect_true(rh$present)
  expect_equal(rh$source_status, "present")

  expect_false(rad_bal$present)
  expect_equal(rad_bal$source_status, "missing")

  expect_true(rad_net$present)
  expect_equal(rad_net$source_status, "present")
})

test_that("inspect_weather_station_inputs reports Priestley-Taylor readiness", {
  ws <- build_weather_station(
    temp = 20,
    rad_bal = 400,
    soil_flux = 50,
    surface_type = "field"
  )

  out <- inspect_weather_station_inputs(ws, methods = "priestley_taylor")
  readiness <- out$method_readiness

  expect_equal(readiness$method, "priestley_taylor")
  expect_true(readiness$ready)
  expect_equal(readiness$missing_fields, "")
  expect_true("priestley_taylor" %in% out$summary$ready_methods)
})

test_that("inspect_weather_station_inputs reports Bulk-Residual and ri_guard blocked fields", {
  ws <- build_weather_station(
    temp = 20,
    rad_bal = 400,
    soil_flux = 50,
    surface_type = "field"
  )

  out <- inspect_weather_station_inputs(ws, methods = "bulk_residual")
  readiness <- out$method_readiness

  bulk <- readiness[readiness$method == "bulk_residual", ]
  ri <- readiness[readiness$method == "bulk_residual_ri_guard", ]

  expect_false(bulk$ready)
  expect_true(grepl("t1", bulk$missing_fields, fixed = TRUE))
  expect_true(grepl("t2", bulk$missing_fields, fixed = TRUE))
  expect_true(grepl("v1", bulk$missing_fields, fixed = TRUE))
  expect_true(grepl("z1", bulk$missing_fields, fixed = TRUE))
  expect_true(grepl("z2", bulk$missing_fields, fixed = TRUE))

  expect_false(ri$ready)
  expect_true(grepl("v2", ri$missing_fields, fixed = TRUE))
  expect_true("bulk_residual_ri_guard" %in% out$summary$blocked_methods)
})

test_that("inspect_weather_station_inputs lists explicit future actions only", {
  ws <- build_weather_station(temp = 20)
  out <- inspect_weather_station_inputs(ws)
  actions <- out$possible_actions

  v2 <- actions[actions$target_field == "v2", ]
  sw_in <- actions[actions$target_field == "rad_sw_in", ]
  sw_out <- actions[actions$target_field == "rad_sw_out", ]

  expect_equal(v2$source_type, "not_recommended")
  expect_equal(v2$risk_level, "not_recommended")
  expect_equal(v2$allowed_strategy, "no filling")
  expect_equal(v2$default_action, "inspect_only")

  expect_equal(sw_in$source_type, "modeled")
  expect_equal(sw_in$risk_level, "high")
  expect_equal(sw_in$allowed_strategy, "allow_modeled")
  expect_equal(sw_in$default_action, "inspect_only")

  expect_equal(sw_out$source_type, "modeled")
  expect_equal(sw_out$risk_level, "high")
  expect_equal(sw_out$default_action, "inspect_only")
  expect_true(all(actions$default_action == "inspect_only"))
})

test_that("inspect_weather_station_inputs never creates new weather_station fields", {
  ws <- build_weather_station(
    datetime = as.POSIXct("2023-06-01 12:00:00", tz = "UTC"),
    temp = c(20, NA),
    rh = c(60, 65)
  )
  old_names <- names(ws)

  out <- inspect_weather_station_inputs(ws)

  expect_equal(names(ws), old_names)
  expect_false(any(names(out) %in% names(ws)))
  expect_false("rad_bal" %in% names(ws))
  expect_false("soil_flux" %in% names(ws))
})

