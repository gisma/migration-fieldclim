bowen_source_beta <- function(t1, t2, hum1, hum2, z1 = 2, z2 = 10, elev = 261) {
  dpot <- (temp_pot_temp(t2, elev) - temp_pot_temp(t1, elev)) / (z2 - z1)
  dah <- (hum_absolute(hum2, t2) - hum_absolute(hum1, t1)) / (z2 - z1)
  gamma_code <- 0.00066 * (1 + 0.000946 * t1)
  gamma_code * dpot / dah
}

bowen_source_args <- function(...) {
  modifyList(
    list(
      t1 = 20,
      t2 = 19.2,
      hum1 = 60,
      hum2 = 52,
      z1 = 2,
      z2 = 10,
      elev = 261,
      rad_bal = 500,
      soil_flux = 50
    ),
    list(...)
  )
}

test_that("Bowen beta pathway is shared by sensible and latent functions", {
  args <- bowen_source_args()
  beta <- do.call(bowen_source_beta, args[c("t1", "t2", "hum1", "hum2", "z1", "z2", "elev")])

  sensible <- do.call(sensible_bowen, args)
  latent <- do.call(latent_bowen, args)

  expect_true(is.finite(beta))
  expect_equal(as.numeric(sensible / latent), as.numeric(beta), tolerance = 1e-10)
  expect_equal(sensible + latent, args$rad_bal - args$soil_flux, tolerance = 1e-10)
})

test_that("Bowen non-singular finite case closes available energy", {
  args <- bowen_source_args(rad_bal = 320, soil_flux = 70)

  sensible <- do.call(sensible_bowen, args)
  latent <- do.call(latent_bowen, args)

  expect_true(is.finite(sensible))
  expect_true(is.finite(latent))
  expect_equal(sensible + latent, args$rad_bal - args$soil_flux, tolerance = 1e-10)
})

test_that("Bowen capped case is finite but not required to close", {
  args <- bowen_source_args(
    t1 = 15,
    t2 = 9,
    hum1 = 30,
    hum2 = 88.9447054488,
    cap = 0.05
  )

  expect_warning(
    sensible <- do.call(sensible_bowen, args),
    "below -600"
  )
  expect_warning(
    latent <- do.call(latent_bowen, args),
    "above 600"
  )

  expect_true(is.finite(sensible))
  expect_true(is.finite(latent))
  expect_false(isTRUE(all.equal(sensible + latent, args$rad_bal - args$soil_flux, tolerance = 1e-8)))
})

test_that("Bowen zero humidity gradient is controlled as invalid beta", {
  args <- bowen_source_args(t1 = 20, t2 = 20, hum1 = 60, hum2 = 60)

  expect_warning(
    sensible <- do.call(sensible_bowen, args),
    "invalid Bowen ratio"
  )
  expect_warning(
    latent <- do.call(latent_bowen, args),
    "invalid Bowen ratio"
  )

  expect_true(is.na(sensible))
  expect_true(is.na(latent))
  expect_false(is.infinite(sensible))
  expect_false(is.infinite(latent))
})

test_that("Bowen sign behavior follows current beta sign", {
  positive_args <- bowen_source_args(t1 = 20, t2 = 19.2, hum1 = 60, hum2 = 52)
  negative_args <- bowen_source_args(t1 = 20, t2 = 21, hum1 = 70, hum2 = 50)

  beta_pos <- do.call(bowen_source_beta, positive_args[c("t1", "t2", "hum1", "hum2", "z1", "z2", "elev")])
  beta_neg <- do.call(bowen_source_beta, negative_args[c("t1", "t2", "hum1", "hum2", "z1", "z2", "elev")])
  sensible_pos <- do.call(sensible_bowen, positive_args)
  latent_pos <- do.call(latent_bowen, positive_args)
  sensible_neg <- do.call(sensible_bowen, negative_args)
  latent_neg <- do.call(latent_bowen, negative_args)

  expect_gt(beta_pos, 0)
  expect_gt(sensible_pos, 0)
  expect_gt(latent_pos, 0)
  expect_lt(beta_neg, 0)
  expect_lt(sensible_neg, 0)
  expect_gt(latent_neg, negative_args$rad_bal - negative_args$soil_flux)
})

test_that("Bowen invalid inputs are vector-local and do not leak Inf or NaN", {
  args <- bowen_source_args(
    t1 = c(20, NA_real_),
    t2 = c(19.2, 19),
    hum1 = c(60, 60),
    hum2 = c(52, 52)
  )

  expect_warning(
    sensible <- do.call(sensible_bowen, args),
    "invalid Bowen ratio"
  )
  expect_warning(
    latent <- do.call(latent_bowen, args),
    "invalid Bowen ratio"
  )

  expect_true(is.finite(sensible[1]))
  expect_true(is.finite(latent[1]))
  expect_true(is.na(sensible[2]))
  expect_true(is.na(latent[2]))
  expect_false(any(is.infinite(sensible)))
  expect_false(any(is.infinite(latent)))
})

test_that("Bowen gamma_code behavior is locked separately from source helper", {
  t1 <- 22.53
  t2 <- 21.5
  hum1 <- 89
  hum2 <- 88
  z1 <- 2
  z2 <- 10
  elev <- 270
  dpot <- (temp_pot_temp(t2, elev) - temp_pot_temp(t1, elev)) / (z2 - z1)
  dah <- (hum_absolute(hum2, t2) - hum_absolute(hum1, t1)) / (z2 - z1)

  beta_current <- bowen_source_beta(t1, t2, hum1, hum2, z1, z2, elev)
  beta_gamma_code <- (0.00066 * (1 + 0.000946 * t1)) * dpot / dah
  beta_helper_form <- heat_capacity(t1) * dpot / (hum_evap_heat(t1) * dah)

  expect_equal(beta_current, beta_gamma_code, tolerance = 1e-12)
  expect_false(isTRUE(all.equal(as.numeric(beta_current), as.numeric(beta_helper_form), tolerance = 1e-8)))
})
