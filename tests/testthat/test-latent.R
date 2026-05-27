# define values for test data
hum1 <- 89
hum2 <- 88
t1 <- 22
t2 <- 21
v1 <- 1
v2 <- 2.3
z1 <- 2
z2 <- 10
elev <- 270
rad_bal <- 400
soil_flux <- 40
lat <- -35.37
lon <- 71.5946
datetime <- as.POSIXlt("2007-12-25 10:30:00")

# test latent_bowen
test_that("latent_bowen", {
  expect_equal(
    latent_bowen(
      t1 = t1, t2 = t2,
      hum1 = hum1, hum2 = hum2,
      z1 = z1, z2 = z2,
      elev <- elev,
      rad_bal = rad_bal,
      soil_flux = soil_flux),
    229.22891,
    tolerance = 1e-3
  )
})

# test latent_monin
test_that("latent_monin", {
  expect_equal(
    latent_monin(hum1, hum2, t1, t2, v1, v2, z1, z2, elev, surface_type = "field"),
    74.67933,
    tolerance = 1e-3
  )
})

# test latent_priestley_taylor
test_that("latent_priestley_taylor", {
  expect_equal(
    latent_priestley_taylor(t1, rad_bal, soil_flux, surface_type = "field"),
    291.09541,
    tolerance = 1e-3
  )
})

test_that("latent_bowen cap limits a near-zero denominator", {
  out <- suppressWarnings(latent_bowen(
    20, 21, 50, 43.5352563773, 2, 10, 270, 400, 40, cap = 1
  ))
  expect_equal(out, 360, tolerance = 1e-5)
})
