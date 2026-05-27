test_that("Potential Temperature", {
  expect_equal(temp_pot_temp(25, 270),
    27.7,
    tolerance = 1e-2  )
  # expect_equal(temp_pot_temp(c(25, NA), c(NA, 1000)),
  #             c(NA_integer_, NA_integer_))
})
