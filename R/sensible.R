#' Sensible Heat Priestley-Taylor Method
#'
#' Calculates the sensible heat flux using the Priestley-Taylor method. Positive
#' heat flux signifies flux away from the surface, negative values signify flux
#' towards the surface.
#'
#' @param ... Additional arguments.
#' @param weather_station A weather_station object.
#' @return Sensible heat flux in W/m².
#' @details
#' The sensible heat flux (\eqn{Q_h}) using the Priestley-Taylor method is calculated as:
#' \deqn{Q_h = \frac{(1 - \alpha) \cdot s + \gamma}{s + \gamma} \cdot (R_n - G)}
#' where:
#' \eqn{\alpha} is the Priestley-Taylor coefficient specific to the surface type,
#' \eqn{s} is the slope of the saturation vapor pressure curve,
#' \eqn{\gamma} is the psychrometric constant,
#' \eqn{R_n} is the net radiation, and
#' \eqn{G} is the soil heat flux.
#'
#' This formula is algebraically equivalent to \eqn{(R_n - G) - Q_e}
#' when \code{sensible_priestley_taylor()} and
#' \code{latent_priestley_taylor()} use the same temperature, surface type,
#' radiation balance, and soil heat flux. The helpers \code{sc()} and
#' \code{gam()} are Foken table-scale polynomial coefficients used together in
#' the ratio terms; their absolute pressure unit scale remains source-open.
#'
#' @references Foken 2016, p. 220, eq. 5.6
#' @param temp Air temperature in °C.
#' @param rad_bal Radiation balance in W/m².
#' @param soil_flux Soil flux in W/m².
#' @param surface_type Surface type, for which a Priestley-Taylor coefficient will be selected. Options: field, bare soil, coniferous forest, water, wetland, spruce forest
#' @examples
#' # Calculate sensible heat flux using the Priestley-Taylor method
#' sensible_priestley_taylor(temp = 20, rad_bal = 200, soil_flux = 50, surface_type = "field")
#' @export
sensible_priestley_taylor <- function(...) {
  UseMethod("sensible_priestley_taylor")
}

#' @rdname sensible_priestley_taylor
#' @export
sensible_priestley_taylor.default <- function(temp, rad_bal, soil_flux, surface_type, ...) {
  sc <- sc(temp)
  gam <- gam(temp)

  priestley_taylor_coefficient <- priestley_taylor_coefficient
  if (!surface_type %in% priestley_taylor_coefficient$surface_type) {
    values_surface <- paste(priestley_taylor_coefficient$surface_type, collapse = " , ")
    stop("'surface_type' must be one of the following: ", values_surface)
  } else if (!is.null(surface_type)) {
    alpha_pt <- priestley_taylor_coefficient[which(priestley_taylor_coefficient$surface_type == surface_type), ]$alpha
  }

  out <- (((1 - alpha_pt) * sc + gam) / (sc + gam)) * (rad_bal - soil_flux)

  # values will be checked whether they exceed the valid data range.
  if (any(out > 600, na.rm = TRUE)) {
    warning("There are values above 600 W/m^2!")
  }
  if (any(out < -600, na.rm = TRUE)) {
    warning("There are values below -600 W/m^2!")
  }
  out
}

#' @rdname sensible_priestley_taylor
#' @export
sensible_priestley_taylor.weather_station <- function(weather_station, ...) {
  check_availability(weather_station, "temp", "rad_bal", "soil_flux", "surface_type")
  temp <- weather_station$temp
  rad_bal <- weather_station$rad_bal
  soil_flux <- weather_station$soil_flux
  surface_type <- weather_station$surface_type
  return(sensible_priestley_taylor(temp, rad_bal, soil_flux, surface_type = surface_type))
}


#' Sensible Heat using Monin-Obukhov length
#'
#' Calculates the sensible heat flux using the Monin-Obukhov length. Positive
#' flux signifies flux away from the surface, negative values signify flux
#' towards the surface. Monin-Obukhov outputs are diagnostic profile/stability
#' estimates and are not expected to close \eqn{R_n - G}.
#'
#' @param ... Additional arguments.
#' @return Sensible heat flux in W/m².
#' @details
#' The sensible heat flux (\eqn{Q_h}) using the Monin-Obukhov method is calculated as:
#' \deqn{Q_h = - \rho \cdot c_p \cdot \frac{k \cdot u_* \cdot z_2}{\phi_h} \cdot \frac{\Delta \theta}{\Delta z}}
#' where:
#' \eqn{\rho} is the air density,
#' \eqn{c_p} is the specific heat capacity of air,
#' \eqn{k} is the von Kármán constant,
#' \eqn{u_*} is the friction velocity,
#' \eqn{\phi_h} is the stability correction function for heat,
#' \eqn{\Delta \theta} is the potential temperature gradient, and
#' \eqn{\Delta z} is the height difference between measurements.
#'
#' The stability correction function for heat (\eqn{\phi_h}) is calculated using the gradient Richardson number (\eqn{Ri_g}) and the stability parameter (\eqn{s_1}).
#' The stability parameter is the ratio of the higher measurement height and the Monin-Obukhov length.
#' With Monin-Obukhov length values close to zero, the ratio can result in very high values, which is why the stability parameter (\eqn{s_1}) can be capped.
#' The implemented potential-temperature gradient uses the measurement-height
#' difference \eqn{z_2 - z_1}. Invalid heights, invalid wind speeds, and invalid
#' numerical profile states are guarded elementwise and return \code{NA} with a
#' warning. Zero potential-temperature gradient returns zero sensible heat flux.
#' The default cap is set to NULL.
#' @references Bendix 2004, p. 77, eq. 4.6,
#' @references Foken 2016, p. 362: Businger
#' @param t1 Air temperature at lower height in °C.
#' @param t2 Air temperature at upper height in °C.
#' @param z1 Lower height of measurement in m.
#' @param z2 Upper height of measurement in m (Use highest point of measurement as values are less disturbed).
#' @param v1 Windspeed at lower height (e.g. height of anemometer) in m/s.
#' @param v2 Windspeed at upper height in m/s.
#' @param elev Elevation above sea level in m.
#' @param cap The maximum absolute value for the stability parameter \eqn{s_1}. Default is NULL.
#' @inheritParams turb_roughness_length
#' @examples
#' # Calculate sensible heat flux using the Monin-Obukhov method
#' sensible_monin(t1 = 20, t2 = 15, z1 = 2, z2 = 10, v1 = 3, v2 = 5, elev = 100, surface_type = "lawn")
#' @export
sensible_monin <- function(...) {
  UseMethod("sensible_monin")
}

#' @rdname sensible_monin
#' @export
sensible_monin.default <- function(t1, t2, z1 = 2, z2 = 10, v1, v2, elev, cap = NULL, surface_type = NULL, obs_height = NULL, ...) {
  if (is.null(obs_height) && is.null(surface_type)) {
    stop("The input is not valid. Either obs_height or surface_type has to be defined.", call. = FALSE)
  }

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
  invalid_profile <- invalid_height | invalid_wind | !is.finite(t1) | !is.finite(t2) | !is.finite(elev)

  safe_t1 <- t1
  safe_t2 <- t2
  safe_z1 <- z1
  safe_z2 <- z2
  safe_v1 <- v1
  safe_v2 <- v2
  safe_elev <- elev
  safe_t1[invalid_profile] <- 20
  safe_t2[invalid_profile] <- 19
  safe_z1[invalid_profile] <- 2
  safe_z2[invalid_profile] <- 10
  safe_v1[invalid_profile] <- 2
  safe_v2[invalid_profile] <- 4
  safe_elev[invalid_profile] <- 0

  if (!is.null(obs_height)) {
    ustar <- turb_ustar(v = safe_v2, z = safe_z2, obs_height = obs_height)
    monin <- turb_flux_monin(z1 = safe_z1, z2 = safe_z2, v1 = safe_v1, v2 = safe_v2,
                             t1 = safe_t1, t2 = safe_t2, elev = safe_elev, obs_height = obs_height)
  } else {
    ustar <- turb_ustar(v = safe_v2, z = safe_z2, surface_type = surface_type)
    monin <- turb_flux_monin(z1 = safe_z1, z2 = safe_z2, v1 = safe_v1, v2 = safe_v2,
                             t1 = safe_t1, t2 = safe_t2, elev = safe_elev, surface_type = surface_type)
  }

  grad_rich_no <- suppressWarnings(turb_flux_grad_rich_no(safe_t1, safe_t2, safe_z1, safe_z2, safe_v1, safe_v2, safe_elev))
  cp <- 1004.834
  k <- 0.35
  s1 <- safe_z2 / monin

  if (!is.null(cap)) {
    s1 <- pmax(pmin(s1, cap), -cap)
  }

  t_gradient <- (temp_pot_temp(safe_t2, safe_elev) - temp_pot_temp(safe_t1, safe_elev)) / (safe_z2 - safe_z1)

  air_density <- pres_air_density(safe_elev, safe_t1)
  busi <- rep(NA_real_, length(grad_rich_no))
  unstable <- is.finite(grad_rich_no) & grad_rich_no <= 0
  stable <- is.finite(grad_rich_no) & grad_rich_no > 0
  busi[unstable] <- 0.74 * (1 - 9 * s1[unstable])^(-0.5)
  busi[stable] <- 0.74 + 4.7 * s1[stable]

  out <- (-1) * air_density * cp * (k * ustar * safe_z2 / busi) * t_gradient

  zero_gradient <- !invalid_profile & is.finite(t_gradient) & t_gradient == 0
  out[zero_gradient] <- 0

  invalid_numeric <- !is.finite(out) & !zero_gradient
  invalid_out <- invalid_profile | invalid_numeric

  if (any(invalid_height, na.rm = TRUE)) {
    warning("sensible_monin: invalid heights for some values; returning NA there.", call. = FALSE)
  }
  if (any(invalid_wind, na.rm = TRUE)) {
    warning("sensible_monin: invalid wind speeds for some values; returning NA there.", call. = FALSE)
  }
  if (any(invalid_numeric & !invalid_profile, na.rm = TRUE)) {
    warning("sensible_monin: invalid Monin-Obukhov numerical state for some values; returning NA there.", call. = FALSE)
  }

  out[invalid_out] <- NA_real_

  if (any(out > 600, na.rm = TRUE)) {
    warning("There are values above 600 W/m^2!")
  }
  if (any(out < -600, na.rm = TRUE)) {
    warning("There are values below -600 W/m^2!")
  }
  out
}

#' @rdname sensible_monin
#' @export
sensible_monin.weather_station <- function(weather_station, cap = NULL, ...) {
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
    return(sensible_monin(t1, t2, z1, z2, v1, v2, elev, cap, obs_height = obs_height))
  } else {
    check_availability(weather_station, "surface_type")
    surface_type <- weather_station$surface_type
    return(sensible_monin(t1, t2, z1, z2, v1, v2, elev, cap, surface_type = surface_type))
  }
}



#' Sensible Heat using Bowen Method
#'
#' Calculates the sensible heat flux using the Bowen Method. Positive
#' flux signifies flux away from the surface, negative values signify flux
#' towards the surface.
#'
#' @param ... Additional arguments.
#' @param weather_station A weather_station object.
#' @return Sensible heat flux in W/m².
#' @details
#' The sensible heat flux (\eqn{Q_h}) using the Bowen method is calculated as:
#' \deqn{Q_h = \frac{(R_n - G) \cdot B}{1 + B}}
#' where:
#' \eqn{R_n} is the net radiation,
#' \eqn{G} is the soil heat flux, and
#' \eqn{B} is the Bowen ratio.
#'
#' The implemented Bowen ratio (\eqn{B}) is calculated from a
#' potential-temperature gradient and an absolute-humidity gradient:
#' \deqn{B = \gamma_{code} \cdot \frac{\Delta \theta / \Delta z}{\Delta AH / \Delta z}}
#' where:
#' \eqn{\gamma_{code} = 0.00066 \cdot (1 + 0.000946 \cdot t_1)}
#' is the empirical implementation coefficient; its exact source-form
#' equivalence remains source-open,
#' \eqn{\theta} is potential temperature, and
#' \eqn{AH} is absolute humidity.
#' The inputs \code{t1} and \code{t2} are converted to potential temperature
#' before the temperature gradient is formed. The inputs \code{hum1} and
#' \code{hum2} are relative humidity values that are converted internally to
#' absolute humidity before the humidity gradient is formed.
#'
#' When \eqn{1 + B} is close to zero, the sensible heat flux can become
#' unrealistically high. The \code{cap} parameter is a numerical safeguard that
#' replaces near-zero denominators with \code{+/- cap}. Exact closure with
#' \code{latent_bowen()} is guaranteed only for finite uncapped denominators;
#' capped cases are guarded diagnostic outputs and may not close
#' \code{rad_bal - soil_flux} exactly. Non-finite Bowen ratios or denominators
#' return \code{NA} for affected elements with a warning.
#' @references Bendix 2004, p. 221, eq. 9.21
#' @param t1 Temperature at lower height in °C.
#' @param t2 Temperature at upper height in °C.
#' @param hum1 Relative humidity at lower height in %.
#' @param hum2 Relative humidity at upper height in %.
#' @param z1 Lower height of measurement in m.
#' @param z2 Upper height of measurement in m.
#' @param elev Elevation above sea level in m.
#' @param rad_bal Radiation balance in W/m².
#' @param soil_flux Soil flux in W/m².
#' @param cap A positive denominator guard for near-zero \eqn{1 + B}. Default is NULL.
#' @examples
#' # Calculate sensible heat flux using the Bowen method
#' sensible_bowen(
#'   t1 = 20, t2 = 15, hum1 = 80, hum2 = 60,
#'   z1 = 2, z2 = 10, elev = 100,
#'   rad_bal = 200, soil_flux = 50, cap = 1
#' )
#' @export
sensible_bowen <- function(...) {
  UseMethod("sensible_bowen")
}

#' @rdname sensible_bowen
#' @export
sensible_bowen.default <- function(t1, t2, hum1, hum2, z1 = 2, z2 = 10, elev, rad_bal, soil_flux, cap = NULL, ...) {
  # Calculating potential temperature delta
  t1_pot <- temp_pot_temp(t1, elev)
  t2_pot <- temp_pot_temp(t2, elev)
  dpot <- (t2_pot - t1_pot) / (z2 - z1)

  # Calculating absolute humidity
  af1 <- hum_absolute(hum1, t1)
  af2 <- hum_absolute(hum2, t2)
  dah <- (af2 - af1) / (z2 - z1)

  # Calculate bowen ratio
  gamma <- 0.00066 * (1 + 0.000946 * t1)
  bowen_ratio <- gamma * dpot / dah

  denominator <- 1 + bowen_ratio
  invalid_partition <- !is.finite(bowen_ratio) | !is.finite(denominator)
  if(!is.null(cap)){
    # Apply the documented lower bound to the near-zero denominator.
    near_zero <- !invalid_partition & abs(denominator) < cap
    denominator[near_zero] <- ifelse(denominator[near_zero] < 0, -cap, cap)
  }

  out <- (rad_bal - soil_flux) * bowen_ratio / denominator
  out[invalid_partition] <- NA_real_
  if (any(invalid_partition, na.rm = TRUE)) {
    warning("sensible_bowen: invalid Bowen ratio or denominator for some values; returning NA there.", call. = FALSE)
  }
  # values of sensible bowen will be checked whether they exceed the valid data range.
  if (any(out > 600, na.rm = TRUE)) {
    warning("There are values above 600 W/m^2!")
  }
  if (any(out < -600, na.rm = TRUE)) {
    warning("There are values below -600 W/m^2!")
  }
  out
}

#' @rdname sensible_bowen
#' @export
sensible_bowen.weather_station <- function(weather_station, cap = NULL, ...) {
  check_availability(weather_station, "z1", "z2", "t1", "t2", "hum1", "hum2", "elev", "rad_bal", "soil_flux")
  hum1 <- weather_station$hum1
  hum2 <- weather_station$hum2
  t1 <- weather_station$t1
  t2 <- weather_station$t2
  z1 <- weather_station$z1
  z2 <- weather_station$z2
  elev <- weather_station$elev
  rad_bal <- weather_station$rad_bal
  soil_flux <- weather_station$soil_flux
  return(sensible_bowen(t1, t2, hum1, hum2, z1, z2, elev, rad_bal, soil_flux, cap))
}
