# test data
t <- 22.53
dpot <- -0.1254715
dah <- -0.0001465109


test_that("sc PT coefficient", {
  expect_equal(sc(t = t),
    0.00106759104,
    tolerance = 1e-3
  )
})

test_that("gamma PT coefficient", {
  expect_equal(gam(t = t),
    0.0004001164196,
    tolerance = 1e-3
  )
})

test_that("heat capacity", {
  expect_equal(heat_capacity(t = t),
    1175.262181,
    tolerance = 1e-3
  )
})

test_that("Bowen Coefficient", {
  expect_equal(bowen_ratio(t = t, dpot = dpot, dah = dah),
    0.4112514782,
    tolerance = 1e-3
  )
})
