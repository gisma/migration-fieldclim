test_that("missing-data inspection vignette dataset exists and preserves Caldern columns", {
  original_path <- system.file(
    "extdata",
    "caldern_wiese_2017-06-30.csv",
    package = "fieldClim"
  )
  gap_path <- system.file(
    "extdata",
    "caldern_wiese_2017-06-30-gaps.csv",
    package = "fieldClim"
  )

  expect_true(file.exists(gap_path))

  original <- read.csv(original_path, na.strings = c("NA", "NULL", ""))
  gaps <- read.csv(gap_path, na.strings = c("NA", "NULL", ""))

  expect_equal(names(gaps), names(original))
  expect_equal(nrow(gaps), nrow(original))
})

test_that("missing-data inspection vignette dataset contains controlled gaps and QC examples", {
  original <- read.csv(
    system.file("extdata", "caldern_wiese_2017-06-30.csv", package = "fieldClim"),
    na.strings = c("NA", "NULL", "")
  )
  gaps <- read.csv(
    system.file("extdata", "caldern_wiese_2017-06-30-gaps.csv", package = "fieldClim"),
    na.strings = c("NA", "NULL", "")
  )

  expect_gt(sum(is.na(gaps$Ta_2m)), sum(is.na(original$Ta_2m)))
  expect_gt(sum(is.na(gaps$Huma_2m)), sum(is.na(original$Huma_2m)))
  expect_gt(sum(is.na(gaps$rad_net)), sum(is.na(original$rad_net)))
  expect_gt(sum(is.na(gaps$Windspeed_2m)), sum(is.na(original$Windspeed_2m)))
  expect_gt(sum(is.na(gaps$heatflux_soil)), sum(is.na(original$heatflux_soil)))

  expect_true(any(gaps$Huma_2m > 100, na.rm = TRUE))
  expect_true(any(gaps$Windspeed_2m < 0, na.rm = TRUE))
  expect_true(any(gaps$rad_sw_in > 1500, na.rm = TRUE))
})

test_that("missing-data inspection vignette dataset exposes duplicate and irregular timestamps", {
  gaps <- read.csv(
    system.file("extdata", "caldern_wiese_2017-06-30-gaps.csv", package = "fieldClim"),
    na.strings = c("NA", "NULL", "")
  )
  datetime <- as.POSIXct(gaps$datetime, tz = "Europe/Berlin")

  expect_true(any(duplicated(datetime)))
  expect_gt(length(unique(diff(as.numeric(datetime)))), 1)
})

test_that("inspection workflow for vignette data is read-only and creates no filled columns", {
  gaps <- read.csv(
    system.file("extdata", "caldern_wiese_2017-06-30-gaps.csv", package = "fieldClim"),
    na.strings = c("NA", "NULL", "")
  )
  gaps$datetime <- as.POSIXct(gaps$datetime, tz = "Europe/Berlin")

  ws <- build_weather_station(
    datetime = gaps$datetime,
    lat = 50.84,
    lon = 8.68,
    elev = 260,
    temp = gaps$Ta_2m,
    rh = gaps$Huma_2m,
    t1 = gaps$Ta_2m,
    t2 = gaps$Ta_10m,
    hum1 = gaps$Huma_2m,
    hum2 = gaps$Huma_10m,
    v1 = gaps$Windspeed_2m,
    v2 = gaps$Windspeed_10m,
    z1 = 2,
    z2 = 10,
    rad_sw_in = gaps$rad_sw_in,
    rad_sw_out = gaps$rad_sw_out,
    rad_bal = gaps$rad_net,
    soil_flux = gaps$heatflux_soil,
    moisture = gaps$water_vol_soil,
    soil_temp1 = gaps$Ts,
    obs_height = 2,
    surface_type = "field"
  )
  before <- ws

  inspection <- inspect_weather_station_inputs(ws)

  expect_equal(ws, before)
  expect_s3_class(inspection, "fieldclim_input_inspection")
  expect_false(any(grepl("_filled$", names(ws))))
  expect_false(any(grepl("_filled$", names(inspection))))
  expect_false(exists("complete_weather_station", where = asNamespace("fieldClim"), inherits = FALSE))

  expect_true(any(inspection$fields$source_status == "partial"))
  expect_true(all(c("short", "medium", "long") %in% inspection$gaps$gap_class))
  expect_true("humidity_outside_0_100" %in% inspection$qc_flags$flag)
  expect_true("negative_wind_speed" %in% inspection$qc_flags$flag)
  expect_true("duplicated_timestamp" %in% inspection$qc_flags$flag)
  expect_true("irregular_timestep" %in% inspection$qc_flags$flag)
  expect_true("long_gap" %in% inspection$qc_flags$flag)
})
