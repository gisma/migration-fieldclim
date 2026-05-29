test_that("sc returns positive increasing vector output over normal temperatures", {
  temps <- c(0, 10, 20, 30)
  out <- sc(temps)

  expect_length(out, length(temps))
  expect_true(all(is.finite(out)))
  expect_true(all(out > 0))
  expect_true(all(diff(out) > 0))
})

test_that("sc non-finite input behavior is locked", {
  out <- sc(c(20, NA, Inf))

  expect_length(out, 3)
  expect_true(is.finite(out[1]))
  expect_true(is.na(out[2]))
  expect_true(is.nan(out[3]))
})

test_that("gam returns finite positive vector output over normal temperatures", {
  temps <- c(0, 10, 20, 30)
  out <- gam(temps)

  expect_length(out, length(temps))
  expect_true(all(is.finite(out)))
  expect_true(all(out > 0))
})

test_that("gam magnitude is commensurable with sc for normal temperatures", {
  temps <- c(10, 20, 30)
  ratio <- sc(temps) / gam(temps)

  expect_true(all(is.finite(ratio)))
  expect_true(all(ratio > 1))
  expect_true(all(ratio < 10))
})

test_that("valid Priestley-Taylor surface types return finite flux and close", {
  temp <- 22
  rad_bal <- 400
  soil_flux <- 40

  for (surface_type in priestley_taylor_coefficient$surface_type) {
    le <- latent_priestley_taylor(temp, rad_bal, soil_flux, surface_type)
    h <- sensible_priestley_taylor(temp, rad_bal, soil_flux, surface_type)

    expect_true(is.finite(le))
    expect_true(is.finite(h))
    expect_equal(le + h, rad_bal - soil_flux, tolerance = 1e-10)
  }
})

test_that("invalid Priestley-Taylor surface type errors clearly", {
  expect_error(
    latent_priestley_taylor(22, 400, 40, "unknown"),
    "surface_type"
  )
  expect_error(
    sensible_priestley_taylor(22, 400, 40, "unknown"),
    "surface_type"
  )
})

test_that("Priestley-Taylor closure holds for positive and negative available energy", {
  temp <- c(22, 22)
  rad_bal <- c(400, -50)
  soil_flux <- c(40, 20)
  surface_type <- "field"

  le <- latent_priestley_taylor(temp, rad_bal, soil_flux, surface_type)
  h <- sensible_priestley_taylor(temp, rad_bal, soil_flux, surface_type)

  expect_equal(le + h, rad_bal - soil_flux, tolerance = 1e-10)
  expect_gt(le[1], 0)
  expect_gt(h[1], 0)
  expect_lt(le[2], 0)
  expect_lt(h[2], 0)
})

test_that("increasing positive soil_flux lowers PT latent heat when other inputs are fixed", {
  temp <- 22
  rad_bal <- 400
  surface_type <- "field"

  le_low_g <- latent_priestley_taylor(temp, rad_bal, soil_flux = 20, surface_type)
  le_high_g <- latent_priestley_taylor(temp, rad_bal, soil_flux = 80, surface_type)

  expect_lt(le_high_g, le_low_g)
})

test_that("pt_only workflow remains isolated to Priestley-Taylor outputs", {
  ws <- build_weather_station(
    temp = c(20, 21),
    rad_bal = c(300, 320),
    soil_flux = c(30, 40),
    surface_type = "field"
  )

  result <- turb_flux_calc(ws, pt_only = TRUE)

  expect_true("sensible_priestley_taylor" %in% names(result))
  expect_true("latent_priestley_taylor" %in% names(result))
  expect_false("latent_penman" %in% names(result))
  expect_false("sensible_bowen" %in% names(result))
  expect_false("latent_bowen" %in% names(result))
  expect_false("sensible_monin" %in% names(result))
  expect_false("latent_monin" %in% names(result))
  expect_false("sensible_bulk" %in% names(result))
  expect_false("latent_bulk_residual" %in% names(result))
})
