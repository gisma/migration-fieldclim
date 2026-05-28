test_that("as.data.frame supports current flat and legacy weather station objects", {
  flat <- build_weather_station(
    datetime = as.POSIXlt(c("2017-06-30 00:00", "2017-06-30 00:05")),
    temp = c(13.1, 13.0)
  )

  expect_equal(as.data.frame(flat)$temp, c(13.1, 13.0))

  legacy <- structure(
    list(measurements = list(temp = c(13.1, 13.0))),
    class = "weather_station"
  )

  expect_equal(as.data.frame(legacy)$temp, c(13.1, 13.0))
})


read_caldern_test <- function() {
  path <- system.file(
    "extdata",
    "caldern_wiese_2017-06-30.csv",
    package = "fieldClim",
    mustWork = TRUE
  )

  input <- read.csv(
    path,
    na.strings = c("NA", "NULL", "")
  )

  input$datetime <- as.POSIXct(
    input$datetime,
    format = "%Y-%m-%d %H:%M:%S",
    tz = "Europe/Berlin"
  )

  input
}


build_caldern_test_ws <- function() {
  input <- read_caldern_test()

  build_weather_station(
    datetime = input$datetime,
    lon = 8.6832,
    lat = 50.8405,
    elev = 261,

    temp = input$Ta_2m,
    rh = input$Huma_2m,

    t1 = input$Ta_2m,
    t2 = input$Ta_10m,
    hum1 = input$Huma_2m,
    hum2 = input$Huma_10m,

    v1 = input$Windspeed_2m,
    v2 = input$Windspeed_10m,
    z1 = 2,
    z2 = 10,

    rad_bal = input$rad_net,
    soil_flux = input$heatflux_soil,

    moisture = input$water_vol_soil,
    surface_temp = input$Ts,
    obs_height = 2,
    surface_type = "field"
  )
}


test_that("heat flux warning checks use calculated values", {
  expect_warning(
    latent_priestley_taylor(20, 10000, 0, surface_type = "field"),
    "above 600"
  )

  expect_warning(
    sensible_priestley_taylor(20, 10000, 0, surface_type = "field"),
    "above 600"
  )
})


test_that("Priestley-Taylor follows the positive available energy convention", {
  latent <- latent_priestley_taylor(22, 400, 40, surface_type = "field")
  sensible <- sensible_priestley_taylor(22, 400, 40, surface_type = "field")

  expect_gt(latent, 0)
  expect_gt(sensible, 0)
  expect_equal(latent + sensible, 400 - 40, tolerance = 1e-8)
})


test_that("soil attenuation passes moisture and texture in the documented order", {
  expected <- sqrt(
    soil_thermal_cond("sand", 0.25) /
      (soil_heat_cap(0.25, "sand") * 10^6 * pi) * 86400
  )

  expect_equal(soil_attenuation(0.25, "sand"), expected)
})


test_that("packaged Caldern teaching data contain the selected complete day", {
  input <- read_caldern_test()

  input <- input[
    !is.na(input$datetime) &
      input$datetime >= as.POSIXct("2017-06-30 00:00:00", tz = "Europe/Berlin") &
      input$datetime <= as.POSIXct("2017-06-30 23:55:00", tz = "Europe/Berlin"),
  ]

  expected_columns <- c(
    "record", "datetime", "Ta_2m", "Huma_2m",
    "Ta_10m", "Huma_10m", "Windspeed_2m",
    "Windspeed_10m", "rad_sw_in", "rad_sw_out",
    "RsNet", "RlNet", "rad_net", "LUpCo", "LDnCo",
    "water_vol_soil", "Ts", "heatflux_soil", "PCP"
  )

  required <- c(
    "Ta_2m", "Huma_2m", "rad_sw_in", "rad_sw_out",
    "RsNet", "RlNet", "rad_net", "water_vol_soil",
    "Ts", "heatflux_soil"
  )

  expect_equal(nrow(input), 288)
  expect_identical(names(input), expected_columns)
  expect_true(all(complete.cases(input[, required])))
})


test_that("PT-only workflow runs on the packaged Caldern teaching day", {
  input <- read_caldern_test()

  station <- build_weather_station(
    temp = input$Ta_2m,
    rad_bal = input$rad_net,
    soil_flux = input$heatflux_soil,
    surface_type = "field"
  )

  result <- turb_flux_calc(station, pt_only = TRUE)

  expect_length(result$latent_priestley_taylor, 288)
  expect_length(result$sensible_priestley_taylor, 288)
  expect_false("latent_penman" %in% names(result))

  expect_equal(
    result$latent_priestley_taylor + result$sensible_priestley_taylor,
    input$rad_net - input$heatflux_soil,
    tolerance = 1e-8
  )
})


test_that("latent_penman.weather_station maps field surface type to Penman grassland resistance", {
  input <- read_caldern_test()

  ws <- build_weather_station(
    datetime = input$datetime,
    lon = 8.6832,
    lat = 50.8405,
    elev = 261,
    temp = input$Ta_2m,
    rh = input$Huma_2m,
    v1 = input$Windspeed_2m,
    z1 = 2,
    rad_bal = input$rad_net,
    soil_flux = input$heatflux_soil,
    obs_height = 2,
    surface_type = "field"
  )

  out <- latent_penman(ws)

  expect_equal(length(out), nrow(input))
  expect_true(any(is.finite(out)))
})


test_that("turb_flux_calc calculates Penman for field surface type", {
  ws <- build_caldern_test_ws()

  flux <- suppressWarnings(turb_flux_calc(ws))

  expect_true("latent_penman" %in% names(flux))
  expect_equal(length(flux$latent_penman), length(ws$temp))
  expect_true(any(is.finite(flux$latent_penman)))
})


test_that("full workflow includes Bulk-Residual fields", {
  ws <- build_caldern_test_ws()

  flux <- suppressWarnings(turb_flux_calc(ws))

  expect_true("sensible_bulk" %in% names(flux))
  expect_true("latent_bulk_residual" %in% names(flux))

  expect_equal(length(flux$sensible_bulk), length(ws$temp))
  expect_equal(length(flux$latent_bulk_residual), length(ws$temp))

  expect_equal(
    flux$sensible_bulk + flux$latent_bulk_residual,
    ws$rad_bal - ws$soil_flux,
    tolerance = 1e-8
  )
})
