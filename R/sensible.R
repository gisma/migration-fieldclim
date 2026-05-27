#' Sensible Heat Priestley-Taylor Method
#'
#' Calculates the sensible heat flux using the Priestley-Taylor method. Positive
#' heat flux signifies flux away from the surface, negative values signify flux
#' towards the surface.
#'
#' @param ... Additional arguments.
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
#' @references Foken 2016, p. 220, eq. 5.6
#' @param temp Air temperature in °C.
#' @param rad_bal Radiation balance in W/m².
#' @param soil_flux Soil flux in W/m².
#' @param surface_type Surface type, for which a Priestley-Taylor coefficient will be selected. Options: \code{surface_type options}
#' @examples
#' # Calculate sensible heat flux using the Priestley-Taylor method
#' sensible_priestley_taylor(temp = 20, rad_bal = 200, soil_flux = 50, surface_type = "lawn")
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
#' @inheritParams build_weather_station
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
#' towards the surface.
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
#' With Monin-Obukhov length values close to zero, the ratio can result in very high values, which is why the stability parameter (\eqn{s_1}) is capped.
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
  # calculate ustar
  if (!is.null(obs_height)) {
    ustar <- turb_ustar(v=v2, z=z2, obs_height=obs_height)
  } else if (!is.null(surface_type)) {
    ustar <- turb_ustar(v=v2, z=z2, surface_type=surface_type)
  } else {
    print("The input is not valid. Either obs_height or surface_type has to be defined.")
  }

  # calculate Monin-Obukhov-Length
  if (!is.null(obs_height)) {
    monin <- turb_flux_monin(z1=z1, z2=z2, v1=v1, v2=v2, t1=t1, t2=t2, elev=elev, obs_height=obs_height)
  } else if (!is.null(surface_type)) {
    monin <- turb_flux_monin(z1=z1, z2=z2, v1=v1, v2=v2, t1=t1, t2=t2, elev=elev, surface_type=surface_type)
  } else {
    print("The input is not valid. Either obs_height or surface_type has to be defined.")
  }

  grad_rich_no <- turb_flux_grad_rich_no(t1, t2, z1, z2, v1, v2, elev)
  cp <- 1004.834
  k <- 0.35
  s1 <- z2 / monin

  if(!is.null(cap)){
    # Apply cap
    s1 <- pmax(pmin(s1, cap), -cap)
  }

  # temperature gradient
  t_gradient <- (temp_pot_temp(t2, elev) - temp_pot_temp(t1, elev)) / log(z2 - z1)

  air_density <- pres_air_density(elev, t1)
  busi <- rep(NA, length(grad_rich_no))
  for (i in 1:length(busi)) {
    if (is.na(grad_rich_no[i])) {
      busi[i] <- NA
    } else if (grad_rich_no[i] <= 0) {
      busi[i] <- 0.74 * (1 - 9 * s1[i])^(-0.5)
    } else if (grad_rich_no[i] > 0) {
      busi[i] <- 0.74 + 4.7 * s1[i]
    }
  }

  out <- (-1) * air_density * cp * (k * ustar * z2 / busi) * t_gradient

  # values will be checked whether they exceed the valid data range.
  if (any(out > 600, na.rm = TRUE)) {
    warning("There are values above 600 W/m^2!")
  }
  if (any(out < -600, na.rm = TRUE)) {
    warning("There are values below -600 W/m^2!")
  }
  out
}

#' @rdname sensible_monin
#' @inheritParams build_weather_station
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
#' @return Sensible heat flux in W/m².
#' @details
#' The sensible heat flux (\eqn{Q_h}) using the Bowen method is calculated as:
#' \deqn{Q_h = \frac{(R_n - G) \cdot B}{1 + B}}
#' where:
#' \eqn{R_n} is the net radiation,
#' \eqn{G} is the soil heat flux, and
#' \eqn{B} is the Bowen ratio.
#'
#' The Bowen ratio (\eqn{B}) is calculated as:
#' \deqn{B = \frac{\gamma}{L_v} \cdot \frac{\Delta T}{\Delta q}}
#' where:
#' \eqn{\gamma} is the psychrometric constant,
#' \eqn{L_v} is the latent heat of vaporization,
#' \eqn{\Delta T} is the temperature gradient, and
#' \eqn{\Delta q} is the moisture gradient.
#'
#' When \eqn{1 + B} results in values close to zero, the sensible heat flux can become unrealistically high.
#' To prevent this, a cap parameter can be set.
#' The cap parameter ensures that \eqn{1 + B} does not get too close to zero by setting a minimum allowable value.
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
#' @param cap The cap value to prevent division by zero. Default is NULL.
#' @examples
#' # Calculate sensible heat flux using the Bowen method
#' sensible_bowen(t1 = 20, t2 = 15, hum1 = 80, hum2 = 60, z1 = 2, z2 = 10, elev = 100, rad_bal = 200, soil_flux = 50, cap = 1)
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
  if(!is.null(cap)){
    # Apply the documented lower bound to the near-zero denominator.
    near_zero <- abs(denominator) < cap
    denominator[near_zero] <- ifelse(denominator[near_zero] < 0, -cap, cap)
  }

  out <- (rad_bal - soil_flux) * bowen_ratio / denominator
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
#' @inheritParams build_weather_station
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
