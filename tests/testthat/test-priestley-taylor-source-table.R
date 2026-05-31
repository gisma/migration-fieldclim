test_that("gam() reproduces Foken 2013 Table 6 gamma values", {
  temp_k <- c(270, 280, 290, 300)
  temp_c <- temp_k - 273.15
  expected_gamma <- c(0.00040, 0.00040, 0.00040, 0.00041)

  expect_equal(
    gam(temp_c),
    expected_gamma,
    tolerance = 2e-6
  )
})

test_that("sc() reproduces Foken 2013 Table 6 sc values", {
  temp_k <- c(270, 280, 290, 300)
  temp_c <- temp_k - 273.15
  expected_sc <- c(0.00022, 0.00042, 0.00078, 0.00132)

  expect_equal(
    sc(temp_c),
    expected_sc,
    tolerance = 2e-5
  )
})

test_that("sc() and gam() are on the same Foken/Stull table scale", {
  temp_c <- c(-3.15, 6.85, 16.85, 26.85)

  ratio <- sc(temp_c) / (sc(temp_c) + gam(temp_c))

  expect_true(all(is.finite(ratio)))
  expect_true(all(ratio > 0))
  expect_true(all(ratio < 1))
  expect_true(all(diff(ratio) > 0))
})
