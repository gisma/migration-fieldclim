#' Monin-Obhukov-Length
#'
#' Calculation of the Monin-Obhukov-Length.
#' The calculation depends on the stability of the atmosphere.
#' This value will be taken from the Gradient-Richardson-Number.
#'
#' @rdname turb_flux_monin
#' @param ... Additional arguments.
#' @returns Monin-Obhukov-Length in m.
#' @export
#'
turb_flux_monin <- function(...) {
  UseMethod("turb_flux_monin")
}

#' @rdname turb_flux_monin
#' @param z1 Lower height of measurement (e.g. height of anemometer) in m.
#' @param z2 Upper height of measurement in m.
#' @param v1 Windspeed at lower height (e.g. height of anemometer) in m/s.
#' @param v2 Windspeed at upper height in m/s.
#' @param t1 Temperature at lower height (e.g. height of anemometer) in °C.
#' @param t2 Temperature at upper height in °C.
#' @param elev Elevation above sea level in m.
#' @inheritParams turb_roughness_length
#' @export
#' @references Bendix 2004, p. 241
turb_flux_monin.default <- function(z1 = 2, z2 = 10, v1, v2, t1, t2, elev, surface_type = NULL, obs_height = NULL, ...) {
  grad_rich_no <- turb_flux_grad_rich_no(t1, t2, z1, z2, v1, v2, elev)

  # calculate z0
  if (!is.null(obs_height)) {
    z0 <- turb_roughness_length(obs_height=obs_height)
  } else if (!is.null(surface_type)) {
    z0 <- turb_roughness_length(surface_type=surface_type)
  } else {
    print("The input is not valid. Either obs_height or surface_type has to be defined.")
  }

  # calculate ustar
  if (!is.null(obs_height)) {
    ustar <- turb_ustar(v=v2, z=z2, obs_height=obs_height)
  } else if (!is.null(surface_type)) {
    ustar <- turb_ustar(v=v2, z=z2, surface_type=surface_type)
  } else {
    print("The input is not valid. Either obs_height or surface_type has to be defined.")
  }

  monin <- rep(NA, length(grad_rich_no))
  for (i in 1:length(grad_rich_no)) {
    if (is.na(grad_rich_no[i])) {
      monin[i] <- NA
    } else if (grad_rich_no[i] <= -0.005) {
      monin[i] <- (z1 * (t1[i] + 273.15) * (((v2[i] - v1[i]) / (z2 - z1))^2)) / (9.81 * (t2[i] - t1[i]) / (z2 - z1))
    } else if (grad_rich_no[i] > -0.005 && grad_rich_no[i] < 0.005) {
      monin[i] <- 0.75 * (z1 * (t1[i] + 273.15) * (((v2[i] - v1[i]) / (z2 - z1))^2)) / (9.81 * (t2[i] - t1[i]) / (z2 - z1))
    } else if (grad_rich_no[i] >= 0.005) {
      monin[i] <- 4.7 * ustar[i] * log(z1 / z0) * (z1 - z0) / (v1[i] * 0.4)
    }
  }

  if (any(is.na(monin))) {
    warning("NAs were introduced, due to a either small friction velocity (ustar < 0.2), or missing Gradient-Richardson numbers.")
  }
  monin
}

#' @rdname turb_flux_monin
#' @param weather_station Object of class weather_station
#' @export
turb_flux_monin.weather_station <- function(weather_station, ...) {
  check_availability(weather_station, "z1", "z2", "v1", "v2", "t1", "t2", "elev")
  z1 <- weather_station$z1
  z2 <- weather_station$z2
  v1 <- weather_station$v1
  v2 <- weather_station$v2
  t1 <- weather_station$t1
  t2 <- weather_station$t2
  elev <- weather_station$elev
  obs_height <- weather_station$obs_height
  if (!is.null(obs_height)) {
    check_availability(weather_station, "obs_height")
    return(turb_flux_monin(z1, z2, v1, v2, t1, t2, elev, obs_height = obs_height))
  } else {
    check_availability(weather_station, "surface_type")
    surface_type <- weather_station$surface_type
    return(turb_flux_monin(z1, z2, v1, v2, t1, t2, elev, surface_type = surface_type))
  }
}

#' Gradient-Richardson-Number
#'
#' Calculation of the Gradient-Richardson-Number. The number represents the
#' stability of the atmosphere. Negative values signify unstable conditions,
#' positive values signify stable conditions, whereas values around zero represent
#' neutral conditions. Invalid heights, invalid wind speeds, and weak wind-shear
#' cases return \code{NA}; these helpers are diagnostics and do not enforce
#' turbulent heat-flux closure.
#'
#' @rdname turb_flux_grad_rich_no
#' @param ... Additional arguments.
#' @returns Gradient Richardson number, or \code{NA} for invalid profile or
#'   weak-shear cases.
#' @export
#' @references Bendix 2004, p. 43, eq. 2.5
turb_flux_grad_rich_no <- function(...) {
  UseMethod("turb_flux_grad_rich_no")
}

#' @rdname turb_flux_grad_rich_no
#' @param t1 Temperature at lower height (e.g. height of anemometer) in °C.
#' @param t2 Temperature at upper height in degrees C.
#' @param z1 Lower height of measurement (e.g. height of anemometer) in m.
#' @param z2 Upper height of measurement in m.
#' @param v1 Windspeed at lower height (e.g. height of anemometer) in m/s.
#' @param v2 Windspeed at upper height in m/s.
#' @param elev Elevation above sea level in m.
#' @param min_shear Minimum absolute wind-speed shear in s-1. Values at or
#'   below this threshold return \code{NA}.
#' @export
turb_flux_grad_rich_no.default <- function(t1, t2, z1 = 2, z2 = 10, v1, v2, elev, min_shear = 1e-4, ...) {
  n <- max(length(t1), length(t2), length(z1), length(z2), length(v1), length(v2), length(elev))
  t1 <- rep_len(t1, n)
  t2 <- rep_len(t2, n)
  z1 <- rep_len(z1, n)
  z2 <- rep_len(z2, n)
  v1 <- rep_len(v1, n)
  v2 <- rep_len(v2, n)
  elev <- rep_len(elev, n)

  invalid_height <- !is.finite(z1) | !is.finite(z2) | z1 <= 0 | z2 <= 0 | z2 <= z1
  invalid_wind <- !is.finite(v1) | !is.finite(v2) | v1 <= 0 | v2 <= 0

  safe_t1 <- t1
  safe_t2 <- t2
  safe_z1 <- z1
  safe_z2 <- z2
  safe_v1 <- v1
  safe_v2 <- v2
  safe_elev <- elev
  invalid_profile <- invalid_height | invalid_wind | !is.finite(t1) | !is.finite(t2) | !is.finite(elev)
  safe_t1[invalid_profile] <- 20
  safe_t2[invalid_profile] <- 20
  safe_z1[invalid_profile] <- 2
  safe_z2[invalid_profile] <- 10
  safe_v1[invalid_profile] <- 2
  safe_v2[invalid_profile] <- 4
  safe_elev[invalid_profile] <- 0

  pot_temp1 <- c2k(temp_pot_temp(safe_t1, safe_elev, ...))
  pot_temp2 <- c2k(temp_pot_temp(safe_t2, safe_elev))
  dz <- safe_z2 - safe_z1
  dtheta_dz <- (pot_temp2 - pot_temp1) / dz
  du_dz <- (safe_v2 - safe_v1) / dz

  grad_rich_no <- (9.81 / pot_temp1) * dtheta_dz / (du_dz^2)
  weak_shear <- abs(du_dz) <= min_shear
  invalid <- invalid_profile | weak_shear | !is.finite(pot_temp1) | pot_temp1 <= 0 |
    !is.finite(dtheta_dz) | !is.finite(du_dz) | !is.finite(grad_rich_no)

  if (any(invalid_height, na.rm = TRUE)) {
    warning("turb_flux_grad_rich_no: invalid heights for some values; returning NA there.", call. = FALSE)
  }
  if (any(invalid_wind, na.rm = TRUE)) {
    warning("turb_flux_grad_rich_no: invalid wind speeds for some values; returning NA there.", call. = FALSE)
  }
  if (any(weak_shear & !invalid_profile, na.rm = TRUE)) {
    warning("turb_flux_grad_rich_no: wind-speed shear is too small for some values; returning NA there.", call. = FALSE)
  }

  grad_rich_no[invalid] <- NA_real_
  grad_rich_no
}

#' @rdname turb_flux_grad_rich_no
#' @param weather_station Object of class weather_station
#' @export
turb_flux_grad_rich_no.weather_station <- function(weather_station, ...) {
  check_availability(weather_station, "z1", "z2", "v1", "v2", "t1", "t2", "elev")
  t1 <- weather_station$t1
  t2 <- weather_station$t2
  z1 <- weather_station$z1
  z2 <- weather_station$z2
  v1 <- weather_station$v1
  v2 <- weather_station$v2
  elev <- weather_station$elev
  return(turb_flux_grad_rich_no(t1, t2, z1, z2, v1, v2, elev))
}

#' Stability
#'
#' Conversion of Gradient-Richardson-Number to stability string. Non-finite
#' Richardson numbers return \code{NA}. This is a diagnostic classification,
#' not a heat-flux closure check.
#'
#' @rdname turb_flux_stability
#' @param ... Additional arguments.
#' @returns A stability class string: "unstable", "neutral",
#'   "stable", or \code{NA}, according to the current
#'   Gradient-Richardson-Number thresholds.
#' @export
#' @references Based on Bendix 2004, p.43, picture 2.10
turb_flux_stability <- function(...) {
  UseMethod("turb_flux_stability")
}

#' @rdname turb_flux_stability
#' @param grad_rich_no Gradient-Richardson-Number
#' @export
turb_flux_stability.default <- function(grad_rich_no, ...) {
  stability <- rep(NA_character_, length(grad_rich_no))
  valid <- is.finite(grad_rich_no)
  stability[valid & grad_rich_no <= -0.005] <- "unstable"
  stability[valid & grad_rich_no > -0.005 & grad_rich_no < 0.005] <- "neutral"
  stability[valid & grad_rich_no >= 0.005] <- "stable"
  stability
}

#' @rdname turb_flux_stability
#' @param weather_station Object of class weather_station
#' @export
turb_flux_stability.weather_station <- function(weather_station, ...) {
  grad_rich_no <- turb_flux_grad_rich_no(weather_station)
  return(turb_flux_stability(grad_rich_no))
}


#' Exchange quotient for heat transmission
#'
#' Calculation of the exchange quotient of the turbulent heat transmission.
#'
#' @rdname turb_flux_ex_quotient_temp
#' @param ... Additional arguments.
#' @returns Exchange quotient for heat transmission in kg/(m*s).
#' @export
turb_flux_ex_quotient_temp <- function(...) {
  UseMethod("turb_flux_ex_quotient_temp")
}

#' @rdname turb_flux_ex_quotient_temp
#' @param t1 Temperature at lower height (e.g. height of anemometer) in °C.
#' @param t2 Temperature at upper height in degrees C.
#' @param z1 Lower height of measurement (e.g. height of anemometer) in m.
#' @param z2 Upper height of measurement in m.
#' @param v1 Windspeed at lower height (e.g. height of anemometer) in m/s.
#' @param v2 Windspeed at upper height in m/s.
#' @param elev Elevation above sea level in m.
#' @inheritParams turb_roughness_length
#' @export
#' @references Foken 2016, p. 362: Businger.
turb_flux_ex_quotient_temp.default <- function(t1, t2, z1=2, z2=10, v1, v2, elev, surface_type = NULL, obs_height = NULL, ...) {
  grad_rich_no <- turb_flux_grad_rich_no(t1, t2, z1, z2, v1, v2, elev)

  # calculate ustar
  if (!is.null(obs_height)) {
    ustar <- turb_ustar(v=v2, z=z2, obs_height=obs_height)
  } else if (!is.null(surface_type)) {
    ustar <- turb_ustar(v=v2, z=z2, surface_type=surface_type)
  } else {
    print("The input is not valid. Either obs_height or surface_type has to be defined.")
  }

  # calculate Monin-Obhukov-Length
  if (!is.null(obs_height)) {
    monin <- turb_flux_monin(z1=z1, z2=z2, v1=v1, v2=v2, t1=t1, t2=t2, elev=elev, obs_height=obs_height)
  } else if (!is.null(surface_type)) {
    monin <- turb_flux_monin(z1=z1, z2=z2, v1=v1, v2=v2, t1=t1, t2=t2, elev=elev, surface_type=surface_type)
  } else {
    print("The input is not valid. Either obs_height or surface_type has to be defined.")
  }

  air_density <- pres_air_density(elev, t1)
  ex <- rep(NA, length(grad_rich_no))
  for (i in 1:length(grad_rich_no)) {
    if (is.na(grad_rich_no[i])) {
      ex[i] <- NA
    } else if (grad_rich_no[i] <= -0.005) {
      ex[i] <- (0.4 * ustar[i] * z1 / (0.74 * (1 - 9 * z1 / monin[i])^(-0.5))) * air_density[i]
    } else if (grad_rich_no[i] > -0.005 && grad_rich_no[i] < 0.005) {
      ex[i] <- 0.4 * ustar[i] * z1
    } else if (grad_rich_no[i] >= 0.005) {
      ex[i] <- (0.4 * ustar[i] * z1 / (0.74 + 4.7 * z1 / monin[i])) * air_density[i]
    }
  }
  ex
}

#' @rdname turb_flux_ex_quotient_temp
#' @param weather_station Object of class weather_station
#' @export
turb_flux_ex_quotient_temp.weather_station <- function(weather_station, ...) {
  check_availability(weather_station, "t1", "t2", "z1", "z2", "v1", "v2", "elev")
  t1 <- weather_station$t1
  t2 <- weather_station$t2
  z1 <- weather_station$z1
  z2 <- weather_station$z2
  v1 <- weather_station$v1
  v2 <- weather_station$v2
  elev <- weather_station$elev
  obs_height <- weather_station$obs_height
  if (!is.null(obs_height)) {
    return(turb_flux_ex_quotient_temp(t1, t2, z1, z2, v1, v2, elev, obs_height = obs_height))
  } else {
    check_availability(weather_station, "surface_type")
    surface_type <- weather_station$surface_type
    return(turb_flux_ex_quotient_temp(t1, t2, z1, z2, v1, v2, elev, surface_type = surface_type))
  }
}


#' Exchange quotient for impulse transmission
#'
#' Calculation of the exchange quotient of the turbulent impulse transmission.
#'
#' @rdname turb_flux_ex_quotient_imp
#' @param ... Additional arguments.
#' @returns Exchange quotient for impulse transmission in kg/(m*s).
#' @export
#'
turb_flux_ex_quotient_imp <- function(...) {
  UseMethod("turb_flux_ex_quotient_imp")
}

#' @rdname turb_flux_ex_quotient_imp
#' @param t1 Temperature at lower height (e.g. height of anemometer) in °C.
#' @param t2 Temperature at upper height in degrees C.
#' @param z1 Lower height of measurement (e.g. height of anemometer) in m.
#' @param z2 Upper height of measurement in m.
#' @param v1 Windspeed at lower height (e.g. height of anemometer) in m/s.
#' @param v2 Windspeed at upper height in m/s.
#' @param elev Elevation above sea level in m.
#' @inheritParams turb_roughness_length
#' @export
#' @references Foken 2016, p. 361: Businger.
turb_flux_ex_quotient_imp.default <- function(t1, t2, z1=2, z2=10, v1, v2, elev, surface_type = NULL, obs_height = NULL, ...) {
  grad_rich_no <- turb_flux_grad_rich_no(t1, t2, z1, z2, v1, v2, elev)

  # calculate ustar
  if (!is.null(obs_height)) {
    ustar <- turb_ustar(v=v2, z=z2, obs_height=obs_height)
  } else if (!is.null(surface_type)) {
    ustar <- turb_ustar(v=v2, z=z2, surface_type=surface_type)
  } else {
    print("The input is not valid. Either obs_height or surface_type has to be defined.")
  }

  # calculate Monin-Obhukov-Length
  if (!is.null(obs_height)) {
    monin <- turb_flux_monin(z1=z1, z2=z2, v1=v1, v2=v2, t1=t1, t2=t2, elev=elev, obs_height=obs_height)
  } else if (!is.null(surface_type)) {
    monin <- turb_flux_monin(z1=z1, z2=z2, v1=v1, v2=v2, t1=t1, t2=t2, elev=elev, surface_type=surface_type)
  } else {
    print("The input is not valid. Either obs_height or surface_type has to be defined.")
  }

  air_density <- pres_air_density(elev, t1)
  ex <- rep(NA, length(grad_rich_no))
  for (i in 1:length(grad_rich_no)) {
    if (is.na(grad_rich_no[i])) {
      ex[i] <- NA
    } else if (grad_rich_no[i] <= -0.005) {
      ex[i] <- (0.4 * ustar[i] * z1 / ((1 - 15 * z1 / monin[i])^(-0.25))) * air_density[i]
    } else if (grad_rich_no[i] > -0.005 && grad_rich_no[i] < 0.005) {
      ex[i] <- (0.4 * ustar[i] * z1) * air_density[i]
    } else if (grad_rich_no[i] >= 0.005) {
      ex[i] <- (0.4 * ustar[i] * monin[i] / 4.7) * air_density[i]
    }
  }
  ex
}

#' @rdname turb_flux_ex_quotient_imp
#' @param weather_station Object of class weather_station
#' @export
turb_flux_ex_quotient_imp.weather_station <- function(weather_station, ...) {
  check_availability(weather_station, "t1", "t2", "z1", "z2", "v1", "v2", "elev")
  t1 <- weather_station$t1
  t2 <- weather_station$t2
  z1 <- weather_station$z1
  z2 <- weather_station$z2
  v1 <- weather_station$v1
  v2 <- weather_station$v2
  elev <- weather_station$elev
  obs_height <- weather_station$obs_height
  if (!is.null(obs_height)) {
    return(turb_flux_ex_quotient_imp(t1, t2, z1, z2, v1, v2, elev, obs_height = obs_height))
  } else {
    check_availability(weather_station, "surface_type")
    surface_type <- weather_station$surface_type
    return(turb_flux_ex_quotient_imp(t1, t2, z1, z2, v1, v2, elev, surface_type = surface_type))
  }
}


#' Turbulent impulse exchange
#'
#' Calculation of the turbulent impulse exchange.
#'
#' @rdname turb_flux_imp_exchange
#' @param ... Additional arguments.
#' @returns Turbulent impulse exchange in kg/(m*s\eqn{^2}).
#' @export
#'
turb_flux_imp_exchange <- function(...) {
  UseMethod("turb_flux_imp_exchange")
}

#' @rdname turb_flux_imp_exchange
#' @param t1 Temperature at lower height (e.g. height of anemometer) in °C.
#' @param t2 Temperature at upper height in degrees C.
#' @param v1 Windspeed at lower height (e.g. height of anemometer) in m/s.
#' @param v2 Windspeed at upper height in m/s.
#' @param z1 Lower height of measurement (e.g. height of anemometer) in m.
#' @param z2 Upper height of measurement in m.
#' @param elev Elevation above sea level in m.
#' @inheritParams turb_roughness_length
#' @export
turb_flux_imp_exchange.default <- function(t1, t2, v1, v2, z1 = 2, z2 = 10, elev, surface_type = NULL, obs_height = NULL, ...) {
  # calculate quotient
  if (!is.null(obs_height)) {
    ex_quotient <- turb_flux_ex_quotient_imp(t1, t2, z1, z2, v1, v2, elev, obs_height=obs_height)
  } else if (!is.null(surface_type)) {
    ex_quotient <- turb_flux_ex_quotient_imp(t1, t2, z1, z2, v1, v2, elev, surface_type=surface_type)
  } else {
    print("The input is not valid. Either obs_height or surface_type has to be defined.")
  }
  ia <- ex_quotient * (v2 - v1) / (z2 - z1)
  ia
}

#' @rdname turb_flux_imp_exchange
#' @param weather_station Object of class weather_station
#' @export
turb_flux_imp_exchange.weather_station <- function(weather_station, ...) {
  check_availability(weather_station, "t1", "t2", "z1", "z2", "v1", "v2", "elev")
  t1 <- weather_station$t1
  t2 <- weather_station$t2
  z1 <- weather_station$z1
  z2 <- weather_station$z2
  v1 <- weather_station$v1
  v2 <- weather_station$v2
  elev <- weather_station$elev
  obs_height <- weather_station$obs_height
  if (!is.null(obs_height)) {
    return(turb_flux_imp_exchange(t1, t2, v1, v2, z1, z2, elev, obs_height = obs_height))
  } else {
    check_availability(weather_station, "surface_type")
    surface_type <- weather_station$surface_type
    return(turb_flux_imp_exchange(t1, t2, v1, v2, z1, z2, elev, surface_type = surface_type))
  }
}


#' Sensible and latent heat fluxes
#'
#' Calculate sensible and latent heat-flux estimates for a
#' `weather_station` object using the available `fieldClim` method families:
#' Priestley-Taylor, Bulk-Residual, Bowen-ratio, Monin-Obukhov/profile and
#' Penman-type latent heat flux.
#'
#' The methods are not interchangeable measurements. Priestley-Taylor,
#' Bulk-Residual and Bowen-ratio are energy-partition or residual workflows.
#' Penman returns latent heat flux only. Monin-Obukhov/profile outputs are
#' diagnostic and are not forced to close the available energy.
#'
#' @param weather_station Object of class `weather_station`.
#' @param pt_only If `TRUE`, calculate only the Priestley-Taylor sensible and
#'   latent heat fluxes. This supports the introductory or robust available-energy
#'   workflow without requiring inputs for the optional additional methods.
#'   If `FALSE`, the full workflow attempts the available additional methods,
#'   including Bulk-Residual, Bowen-ratio, Monin-Obukhov/profile and Penman-type
#'   latent heat flux. Unavailable optional inputs produce `NA` values and/or
#'   warnings according to the respective method.
#'
#' @return Object of class `weather_station` with additional heat-flux fields.
#'   Depending on `pt_only` and on available input fields, these may include:
#'   `sensible_priestley_taylor`, `latent_priestley_taylor`,
#'   `sensible_bulk`, `latent_bulk_residual`,
#'   `sensible_bowen`, `latent_bowen`,
#'   `sensible_monin`, `latent_monin`, and `latent_penman`.
#' @export
turb_flux_calc <- function(weather_station, pt_only = FALSE) {
  if (pt_only) {
    weather_station$sensible_priestley_taylor <- sensible_priestley_taylor(weather_station)
    weather_station$latent_priestley_taylor <- latent_priestley_taylor(weather_station)
    return(weather_station)
  }
  sensible_blk <- sensible_bulk(weather_station)
  latent_blk_res <- latent_bulk_residual(weather_station, sensible = sensible_blk)
  stability <- turb_flux_stability(weather_station)
  sensible_pt <- sensible_priestley_taylor(weather_station)
  latent_pt <- latent_priestley_taylor(weather_station)
  sensible_bow <- sensible_bowen(weather_station)
  latent_bow <- latent_bowen(weather_station)
  sensible_mon <- sensible_monin(weather_station)
  latent_mon <- latent_monin(weather_station)
  latent_pen <- tryCatch(
    latent_penman(weather_station),
    error = function(e) {
      warning("latent_penman()  could not be calculated: ", conditionMessage(e), call. = FALSE)
      rep(NA_real_, length(latent_pt))
    }
  )

  weather_station$stability <- stability
  weather_station$sensible_priestley_taylor <- sensible_pt
  weather_station$latent_priestley_taylor <- latent_pt
  weather_station$sensible_bowen <- sensible_bow
  weather_station$latent_bowen <- latent_bow
  weather_station$sensible_monin <- sensible_mon
  weather_station$latent_monin <- latent_mon
  weather_station$latent_penman <- latent_pen
  weather_station$sensible_bulk <- sensible_blk
  weather_station$latent_bulk_residual <- latent_blk_res
  return(weather_station)
}
