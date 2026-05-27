# define values for test data
ah <- 10 # Measurement height
h <- 1.2 # Obstacle height in m
vh <- 1.2 # Vegetation height in m
v <- 3.5 # wind velocity

# test turb_roughness_length
test_that("turb_roughness_length", {
  expect_equal(
    turb_roughness_length(obs_height = h),
    0.12
  )
  expect_equal(
    turb_roughness_length(surface_type = "field"),
    0.02
  )
})

# test turb_displacement
test_that("turb_displacement", {
  expect_equal(
    turb_displacement(vh),
    0.8
  )
})

# test turb_ustar
test_that("turb_ustar", {
  expect_equal(turb_ustar(v, ah, obs_height = h),
    0.3165381,
    tolerance = 1e-3
  )
  expect_equal(turb_ustar(v, ah, surface_type = "field"),
               0.225,
               tolerance = 1e-3
  )
})
