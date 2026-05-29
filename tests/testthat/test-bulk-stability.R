test_that("sensible_bulk stability guard leaves default neutral method unchanged", {
  args <- list(
    t1 = c(20.2, 20.0),
    t2 = c(20.0, 20.2),
    v1 = c(2, 2),
    v2 = c(4, 4),
    z1 = 2,
    z2 = 10
  )

  old <- do.call(sensible_bulk, args)
  explicit_none <- do.call(sensible_bulk, c(args, list(stability_method = "none")))

  expect_equal(explicit_none, old)
  expect_null(attr(old, "bulk_Ri_g"))
  expect_null(attr(old, "bulk_stability"))
})

test_that("sensible_bulk ri_guard requires upper wind speed", {
  expect_error(
    sensible_bulk(
      t1 = 20,
      t2 = 19,
      v1 = 2,
      v2 = NULL,
      z1 = 2,
      z2 = 10,
      stability_method = "ri_guard"
    ),
    "requires v2"
  )
})

test_that("sensible_bulk ri_guard classifies unstable neutral and stable finite cases", {
  h_unstable <- sensible_bulk(
    t1 = 20.2,
    t2 = 20.0,
    v1 = 2,
    v2 = 4,
    z1 = 2,
    z2 = 10,
    stability_method = "ri_guard"
  )
  h_neutral <- sensible_bulk(
    t1 = 20,
    t2 = 20,
    v1 = 2,
    v2 = 4,
    z1 = 2,
    z2 = 10,
    stability_method = "ri_guard"
  )
  h_stable <- sensible_bulk(
    t1 = 20.0,
    t2 = 20.2,
    v1 = 2,
    v2 = 4,
    z1 = 2,
    z2 = 10,
    stability_method = "ri_guard"
  )

  expect_true(is.finite(h_unstable))
  expect_true(is.finite(h_neutral))
  expect_true(is.finite(h_stable))
  expect_equal(attr(h_unstable, "bulk_stability"), "unstable")
  expect_equal(attr(h_neutral, "bulk_stability"), "neutral")
  expect_equal(attr(h_stable, "bulk_stability"), "stable")
})

test_that("sensible_bulk ri_guard returns NA for very stable cases", {
  expect_warning(
    h <- sensible_bulk(
      t1 = 20.0,
      t2 = 20.2,
      v1 = 2,
      v2 = 2.2,
      z1 = 2,
      z2 = 10,
      stability_method = "ri_guard"
    ),
    "very stable"
  )

  expect_true(is.na(h))
  expect_equal(attr(h, "bulk_stability"), "very_stable")
  expect_gte(attr(h, "bulk_Ri_g"), 0.25)
})

test_that("sensible_bulk ri_guard returns NA for zero wind shear", {
  expect_warning(
    h <- sensible_bulk(
      t1 = 20,
      t2 = 20,
      v1 = 2,
      v2 = 2,
      z1 = 2,
      z2 = 10,
      stability_method = "ri_guard"
    ),
    "invalid"
  )

  expect_true(is.na(h))
  expect_true(is.na(attr(h, "bulk_stability")))
  expect_false(is.infinite(attr(h, "bulk_Ri_g")))
})

test_that("sensible_bulk ri_guard handles invalid rows locally", {
  expect_warning(
    h <- sensible_bulk(
      t1 = c(20.2, 20),
      t2 = c(20.0, 20),
      v1 = c(2, 2),
      v2 = c(4, 2),
      z1 = 2,
      z2 = 10,
      stability_method = "ri_guard"
    ),
    "invalid"
  )

  expect_true(is.finite(h[1]))
  expect_true(is.na(h[2]))
  expect_equal(length(attr(h, "bulk_Ri_g")), length(h))
  expect_equal(length(attr(h, "bulk_stability")), length(h))
  expect_equal(attr(h, "bulk_stability")[1], "unstable")
  expect_true(is.na(attr(h, "bulk_stability")[2]))
})

test_that("sensible_bulk weather_station method passes Richardson guard", {
  ws <- list(
    t1 = c(20.2, 20.0),
    t2 = c(20.0, 20.2),
    v1 = c(2, 2),
    v2 = c(4, 4),
    z1 = 2,
    z2 = 10,
    elev = 261
  )
  class(ws) <- "weather_station"

  h <- sensible_bulk(ws, stability_method = "ri_guard")

  expect_equal(length(h), 2)
  expect_true(all(is.finite(h)))
  expect_equal(attr(h, "bulk_stability"), c("unstable", "stable"))
  expect_equal(length(attr(h, "bulk_Ri_g")), length(h))
})
