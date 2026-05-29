test_that("soil_heat_flux follows positive-into-soil sign convention", {
  out <- soil_heat_flux(
    texture = "sand",
    moisture = 0.25,
    soil_temp1 = 15,
    soil_temp2 = 10,
    soil_depth1 = 0.1,
    soil_depth2 = 0.3
  )

  expect_gt(out, 0)
})

test_that("soil_heat_flux handles vector input and invalid depths locally", {
  expect_warning(
    out <- soil_heat_flux(
      texture = "sand",
      moisture = c(0.25, 0.25, 0.25),
      soil_temp1 = c(15, 15, 15),
      soil_temp2 = c(10, 10, 10),
      soil_depth1 = c(0.1, 0.1, -0.1),
      soil_depth2 = c(0.3, 0.1, 0.3)
    ),
    "invalid soil depths"
  )

  expect_length(out, 3)
  expect_true(is.finite(out[1]))
  expect_true(is.na(out[2]))
  expect_true(is.na(out[3]))
  expect_false(any(is.infinite(out)))
})

test_that("soil_thermal_cond returns finite positive values for valid textures", {
  textures <- c("sand", "clay", "peat")

  for (texture in textures) {
    out <- soil_thermal_cond(texture, 0.25)
    expect_true(is.finite(out))
    expect_gte(out, 0)
  }
})

test_that("soil_thermal_cond rejects invalid texture", {
  expect_error(
    soil_thermal_cond("silt", 0.25),
    "Texture not available"
  )
})

test_that("soil_heat_cap returns finite positive MJ-scale values for valid textures", {
  textures <- c("sand", "clay", "peat")

  for (texture in textures) {
    out <- soil_heat_cap(0.25, texture)
    expect_true(is.finite(out))
    expect_gt(out, 0)
    expect_lt(out, 10)
  }
})

test_that("soil_attenuation applies C_v times 10^6 conversion", {
  moisture <- 0.25
  texture <- "sand"
  expected <- sqrt(
    soil_thermal_cond(texture, moisture) /
      (soil_heat_cap(moisture, texture) * 10^6 * pi) * 86400
  )

  expect_equal(soil_attenuation(moisture, texture), expected)
})

test_that("soil thermal helpers lock current moisture-domain behavior", {
  expect_true(is.finite(soil_thermal_cond("sand", 0)))
  expect_true(is.finite(soil_heat_cap(0, "sand")))

  expect_true(is.finite(soil_thermal_cond("sand", 0.25)))
  expect_true(is.finite(soil_heat_cap(0.25, "sand")))

  expect_true(is.na(soil_thermal_cond("sand", 1)))
  expect_equal(soil_heat_cap(1, "sand"), soil_heat_cap(0.43, "sand"))

  expect_true(is.na(soil_thermal_cond("sand", -0.01)))
  expect_true(is.na(soil_heat_cap(-0.01, "sand")))
})
