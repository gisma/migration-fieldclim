test_that("Monin-Obukhov remains diagnostic-only", {
  expect_false("rad_bal" %in% names(formals(sensible_monin.default)))
  expect_false("soil_flux" %in% names(formals(sensible_monin.default)))
  expect_false("rad_bal" %in% names(formals(latent_monin.default)))
  expect_false("soil_flux" %in% names(formals(latent_monin.default)))
})

test_that("sensible_monin returns finite diagnostic output for a normal case", {
  expect_no_warning(
    h <- sensible_monin(
      t1 = 20,
      t2 = 19.9,
      z1 = 2,
      z2 = 10,
      v1 = 2,
      v2 = 4,
      elev = 261,
      surface_type = "lawn"
    )
  )

  expect_true(is.finite(h))
  expect_gt(h, 0)
})

test_that("latent_monin returns finite diagnostic output for a normal case", {
  expect_no_warning(
    le <- latent_monin(
      hum1 = 60,
      hum2 = 55,
      t1 = 20,
      t2 = 19,
      z1 = 2,
      z2 = 10,
      v1 = 2,
      v2 = 4,
      elev = 261,
      surface_type = "lawn"
    )
  )

  expect_true(is.finite(le))
  expect_gt(le, 0)
})

test_that("Monin-Obukhov guards invalid heights", {
  common <- list(t1 = 20, t2 = 19, z1 = 10, z2 = 2, v1 = 2, v2 = 4, elev = 261, surface_type = "lawn")

  expect_warning(
    h <- do.call(sensible_monin, common),
    "invalid heights"
  )
  expect_warning(
    le <- do.call(latent_monin, c(list(hum1 = 60, hum2 = 55), common)),
    "invalid heights"
  )

  expect_true(is.na(h))
  expect_true(is.na(le))
})

test_that("Monin-Obukhov guards low or invalid wind", {
  common <- list(t1 = 20, t2 = 19, z1 = 2, z2 = 10, v1 = 0, v2 = 4, elev = 261, surface_type = "lawn")

  expect_warning(
    h <- do.call(sensible_monin, common),
    "invalid wind"
  )
  expect_warning(
    le <- do.call(latent_monin, c(list(hum1 = 60, hum2 = 55), common)),
    "invalid wind"
  )

  expect_true(is.na(h))
  expect_true(is.na(le))
})

test_that("Monin-Obukhov controls zero temperature and humidity gradients", {
  expect_no_warning(
    h <- sensible_monin(
      t1 = 20,
      t2 = 20,
      z1 = 2,
      z2 = 10,
      v1 = 2,
      v2 = 4,
      elev = 261,
      surface_type = "lawn"
    )
  )
  expect_no_warning(
    le <- latent_monin(
      hum1 = 60,
      hum2 = 60,
      t1 = 20,
      t2 = 20,
      z1 = 2,
      z2 = 10,
      v1 = 2,
      v2 = 4,
      elev = 261,
      surface_type = "lawn"
    )
  )

  expect_equal(h, 0)
  expect_equal(le, 0)
})

test_that("Monin-Obukhov invalid vector elements do not corrupt valid rows", {
  expect_warning(
    h <- sensible_monin(
      t1 = c(20, 20),
      t2 = c(19, 19),
      z1 = 2,
      z2 = 10,
      v1 = c(2, 0),
      v2 = c(4, 4),
      elev = 261,
      surface_type = "lawn"
    ),
    "invalid wind"
  )
  expect_warning(
    le <- latent_monin(
      hum1 = c(60, 60),
      hum2 = c(55, 55),
      t1 = c(20, 20),
      t2 = c(19, 19),
      z1 = 2,
      z2 = 10,
      v1 = c(2, 0),
      v2 = c(4, 4),
      elev = 261,
      surface_type = "lawn"
    ),
    "invalid wind"
  )

  expect_true(is.finite(h[1]))
  expect_true(is.na(h[2]))
  expect_true(is.finite(le[1]))
  expect_true(is.na(le[2]))
})

test_that("turb_flux_grad_rich_no controls signs and zero wind shear", {
  ri <- turb_flux_grad_rich_no(
    t1 = c(20, 20, 20),
    t2 = c(19, 20, 20.2),
    z1 = 2,
    z2 = 10,
    v1 = 2,
    v2 = 4,
    elev = 261
  )

  expect_true(is.finite(ri[1]))
  expect_lt(ri[1], 0)
  expect_true(is.finite(ri[2]))
  expect_equal(ri[2], 0, tolerance = 1e-12)
  expect_true(is.finite(ri[3]))
  expect_gt(ri[3], 0)

  expect_warning(
    zero_shear <- turb_flux_grad_rich_no(
      t1 = 20,
      t2 = 20,
      z1 = 2,
      z2 = 10,
      v1 = 2,
      v2 = 2,
      elev = 261
    ),
    "shear"
  )
  expect_true(is.na(zero_shear))
})

test_that("turb_flux_stability classifies finite and invalid Richardson values", {
  stability <- turb_flux_stability(c(-0.01, 0, 0.02, NA, Inf, NaN))

  expect_equal(stability[1], "unstable")
  expect_equal(stability[2], "neutral")
  expect_equal(stability[3], "stable")
  expect_true(is.na(stability[4]))
  expect_true(is.na(stability[5]))
  expect_true(is.na(stability[6]))
})
