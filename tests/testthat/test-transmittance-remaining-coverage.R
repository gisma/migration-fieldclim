
test_that("trans_air_mass_rel handles mixed valid and invalid solar elevations locally", {
  times <- as.POSIXct(c("2023-06-21 12:00:00", "2023-06-21 00:00:00"), tz = "UTC")

  expect_warning(
    air_mass <- trans_air_mass_rel(times, lon = 8, lat = 50),
    "solar elevation must be positive",
    fixed = TRUE
  )
  expect_length(air_mass, 2)
  expect_true(is.finite(air_mass[1]))
  expect_true(is.na(air_mass[2]))
})

test_that("very low positive solar elevation is finite when a suitable case is available", {
  candidates <- seq(
    as.POSIXct("2023-03-20 05:30:00", tz = "UTC"),
    as.POSIXct("2023-03-20 07:00:00", tz = "UTC"),
    by = "5 min"
  )
  elevation <- sol_elevation(candidates, lon = 0, lat = 50)
  idx <- which(is.finite(elevation) & elevation > 0 & elevation < 5)[1]

  if (is.na(idx)) {
    skip("No deterministic low-positive solar elevation case found for this platform/timebase.")
  }

  air_mass <- trans_air_mass_rel(candidates[idx], lon = 0, lat = 50)
  expect_true(is.finite(air_mass))
  expect_gt(air_mass, 0)
})

test_that("trans_vapor follows POSIXct path through precipitable water", {
  time_ct <- as.POSIXct("2023-07-15 12:00:00", tz = "UTC")
  time_lt <- as.POSIXlt(time_ct)

  expect_equal(
    trans_vapor(time_ct, lon = 8, lat = 50, elev = 100, temp = 20),
    trans_vapor(time_lt, lon = 8, lat = 50, elev = 100, temp = 20),
    tolerance = 1e-12
  )
})

test_that("transmittance functions propagate vector-local invalid night values", {
  times <- as.POSIXct(c("2023-06-21 12:00:00", "2023-06-21 00:00:00"), tz = "UTC")

  expect_warning(gas <- trans_gas(times, 8, 50, 100, 20), "solar elevation", fixed = TRUE)
  expect_warning(abs_mass <- trans_air_mass_abs(times, 8, 50, 100, 20), "solar elevation", fixed = TRUE)
  expect_warning(ozone <- trans_ozone(times, 8, 50), "solar elevation", fixed = TRUE)
  expect_warning(rayleigh <- trans_rayleigh(times, 8, 50, 100, 20), "solar elevation", fixed = TRUE)
  expect_warning(vapor <- trans_vapor(times, 8, 50, 100, 20), "solar elevation", fixed = TRUE)
  expect_warning(aerosol <- trans_aerosol(times, 8, 50, 100, 20), "solar elevation", fixed = TRUE)

  for (value in list(gas, abs_mass, ozone, rayleigh, vapor, aerosol)) {
    expect_length(value, 2)
    expect_true(is.finite(value[1]))
    expect_true(is.na(value[2]))
  }
})

test_that("transmittance weather_station wrappers preserve vector length with custom defaults", {
  ws <- build_weather_station(
    datetime = as.POSIXct(c("2023-06-21 12:00:00", "2023-06-21 13:00:00"), tz = "UTC"),
    lon = 8,
    lat = 50,
    elev = c(100, 120),
    temp = c(20, 22)
  )

  expect_length(trans_ozone(ws, ozone_column = 0.3), 2)
  expect_length(trans_aerosol(ws, vis = 40), 2)
  expect_true(all(is.finite(trans_ozone(ws, ozone_column = 0.3))))
  expect_true(all(is.finite(trans_aerosol(ws, vis = 40))))
})

test_that("non-finite solar inputs are controlled through air mass guard", {
  expect_warning(
    out <- trans_air_mass_rel(as.POSIXct("2023-06-21 12:00:00", tz = "UTC"), lon = NaN, lat = 50),
    "solar elevation must be positive",
    fixed = TRUE
  )
  expect_true(is.na(out))
})
