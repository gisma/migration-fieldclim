# define values for test data
hum1 <- 89
hum2 <- 88
t1 <- 22
t2 <- 21
z1 <- 2
z2 <- 10
v1 <- 1
v2 <- 2.3
elev <- 270
rad_bal <- 400
soil_flux <- 40

# test sensible_bowen
test_that("sensible_bowen", {
  expect_equal(
    sensible_bowen(t1, t2, hum1, hum2, z1, z2, elev, rad_bal, soil_flux),
    130.77109,
    tolerance = 1e-3
  )
})


# test sensible_priestley_taylor
test_that("sensible_priestley_taylor", {
  expect_equal(sensible_priestley_taylor(t = t1, rad_bal, soil_flux, surface_type = "field"),
    68.90459,
    tolerance = 1e-3
  )
})

test_that("sensible_monin checks extreme calculated output", {
  expect_warning(
    sensible_monin(22, 21, 2, 10, 1, 2.3, 270, surface_type = "field"),
    "above 600"
  )
})

test_that("sensible_bowen cap limits a near-zero denominator", {
  out <- suppressWarnings(sensible_bowen(
    20, 21, 50, 43.5352563773, 2, 10, 270, 400, 40, cap = 1
  ))
  expect_equal(out, -360, tolerance = 1e-5)
})
