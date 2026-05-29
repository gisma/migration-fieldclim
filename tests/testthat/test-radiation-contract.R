test_that("shortwave radiation balance follows K_down - K_up", {
  datetime <- as.POSIXlt("2023-06-21 12:00:00", tz = "UTC")
  lon <- 0
  lat <- 50
  elev <- 100
  temp <- 20
  slope <- 0
  exposition <- 180
  valley <- FALSE
  surface_type <- "field"

  k_down_direct <- rad_sw_in(datetime, lon, lat, elev, temp, slope, exposition)
  k_down_diffuse <- rad_diffuse_in(datetime, lon, lat, elev, temp, slope, exposition, valley)
  k_up_direct <- rad_sw_out(datetime, lon, lat, elev, temp, slope, exposition, surface_type)
  k_up_diffuse <- rad_diffuse_out(datetime, lon, lat, elev, temp, slope, exposition, valley, surface_type)

  expect_equal(
    rad_sw_bal(datetime, lon, lat, elev, temp, slope, exposition, valley, surface_type),
    k_down_direct + k_down_diffuse - k_up_direct - k_up_diffuse,
    tolerance = 1e-10
  )
})

test_that("longwave radiation balance follows L_down - L_up", {
  temp <- 20
  rh <- 60
  slope <- 0
  valley <- FALSE
  surface_type <- "field"
  surface_temp <- 22

  expect_equal(
    rad_lw_bal(temp, rh, slope, valley, surface_type, surface_temp),
    rad_lw_in(temp, rh, slope, valley) - rad_lw_out(surface_type, surface_temp),
    tolerance = 1e-10
  )
})

test_that("net radiation balance follows K_star + L_star", {
  datetime <- as.POSIXlt("2023-06-21 12:00:00", tz = "UTC")
  args <- list(
    datetime = datetime, lon = 0, lat = 50, elev = 100, temp = 20,
    rh = 60, slope = 0, exposition = 180, valley = FALSE,
    surface_type = "field", surface_temp = 22
  )

  expect_equal(
    do.call(rad_bal, args),
    with(args, rad_sw_bal(datetime, lon, lat, elev, temp, slope, exposition, valley, surface_type) +
           rad_lw_bal(temp, rh, slope, valley, surface_type, surface_temp)),
    tolerance = 1e-10
  )
})

test_that("valid albedo surfaces reflect non-negative shortwave not exceeding incoming", {
  datetime <- as.POSIXlt("2023-06-21 12:00:00", tz = "UTC")
  sw_in <- rad_sw_in(datetime, 0, 50, 100, 20, 0, 180)

  for (surface_type in surface_properties$surface_type) {
    sw_out <- rad_sw_out(datetime, 0, 50, 100, 20, 0, 180, surface_type)
    expect_true(is.finite(sw_out), info = surface_type)
    expect_gte(sw_out, 0)
    expect_lte(sw_out, sw_in)
  }
})

test_that("unknown albedo surface type preserves current zero-length behavior", {
  datetime <- as.POSIXlt("2023-06-21 12:00:00", tz = "UTC")

  expect_length(
    rad_sw_out(datetime, 0, 50, 100, 20, 0, 180, "unknown-surface"),
    0
  )
  expect_length(
    rad_diffuse_out(datetime, 0, 50, 100, 20, 0, 180, FALSE, "unknown-surface"),
    0
  )
})

test_that("modeled incoming shortwave is controlled at night", {
  night <- as.POSIXlt("2023-06-21 00:00:00", tz = "UTC")

  expect_equal(rad_sw_toa(night, 0, 50), 0)
  expect_equal(suppressWarnings(rad_sw_in(night, 0, 50, 100, 20, 0, 180)), 0)
  expect_equal(suppressWarnings(rad_diffuse_in(night, 0, 50, 100, 20, 0, 180, FALSE)), 0)
})
