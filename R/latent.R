#' Latent Heat Priestley-Taylor Method
#'
#' Calculates the latent heat flux using the Priestley-Taylor method. Positive
#' heat flux signifies flux away from the surface, negative values signify flux
#' towards the surface.
#'
#' @param ... Additional arguments.
#' @return Latent heat flux in W m-2.
#' @details
#' The latent heat flux (\eqn{Q_e}) using the Priestley-Taylor method is calculated as:
#' \deqn{Q_e = \alpha_{PT} \cdot \frac{\Delta}{\Delta + \gamma} \cdot (R_n - G)}
#' where:
#' \eqn{\alpha_{PT}} is the Priestley-Taylor coefficient,
#' \eqn{\Delta} is the slope of the saturation vapor pressure curve,
#' \eqn{\gamma} is the psychrometric constant,
#' \eqn{R_n} is the net radiation, and
#' \eqn{G} is the soil heat flux.
#'
#' The Priestley-Taylor coefficient depends on the surface type and is selected
#' from the internal \code{priestley_taylor_coefficient} table. The helpers
#' \code{sc()} and \code{gam()} are Foken table-scale polynomial coefficients
#' used together in the ratio \eqn{\Delta / (\Delta + \gamma)}; their absolute
#' pressure unit scale remains source-open.
#' @param temp Air temperature in degrees C.
#' @param rad_bal Radiation balance in W m-2.
#' @param soil_flux Soil flux in W m-2.
#' @param surface_type Surface type, for which a Priestley-Taylor coefficient will be selected. Options: `r priestley_taylor_coefficient$surface_type`
#' @examples
#' # Calculate latent heat flux using Priestley-Taylor method
#' latent_priestley_taylor(temp = 25, rad_bal = 200, soil_flux = 50, surface_type = "bare soil")
#' @references Foken 2016, p. 220, eq. 5.7.
#' @export
latent_priestley_taylor <- function(...) {
  UseMethod("latent_priestley_taylor")
}

#' @rdname latent_priestley_taylor
#' @export
latent_priestley_taylor.default <- function(temp, rad_bal, soil_flux, surface_type, ...) {
  # Ensure the coefficient table is correctly referenced
  if (!surface_type %in% priestley_taylor_coefficient$surface_type) {
    values_surface <- paste(priestley_taylor_coefficient$surface_type, collapse = " , ")
    stop("'surface_type' must be one of the following: ", values_surface)
  } else {
    alpha_pt <- priestley_taylor_coefficient[which(priestley_taylor_coefficient$surface_type == surface_type), ]$alpha
  }

  # Calculate the slope of the saturation vapor pressure curve (Delta)
  delta <- sc(temp)

  # Calculate the psychrometric constant (Gamma)
  gamma <- gam(temp)

  # Calculate latent heat flux using the correct formula
  out <- alpha_pt * (delta / (delta + gamma)) * (rad_bal - soil_flux)

  # Check if values exceed the valid data range and issue warnings
  if (any(out > 600, na.rm = TRUE)) {
    warning("There are values above 600 W/m^2!")
  }
  if (any(out < -600, na.rm = TRUE)) {
    warning("There are values below -600 W/m^2!")
  }

  return(out)
}

#' @rdname latent_priestley_taylor
#' @param weather_station Object of class weather_station
#' @export
latent_priestley_taylor.weather_station <- function(weather_station, ...) {
  check_availability(weather_station, "temp", "rad_bal", "soil_flux", "surface_type")
  temp <- weather_station$temp
  rad_bal <- weather_station$rad_bal
  soil_flux <- weather_station$soil_flux
  surface_type <- weather_station$surface_type
  return(latent_priestley_taylor(temp, rad_bal, soil_flux, surface_type = surface_type))
}

.normalize_penman_surface_type <- function(surface_type) {
  if (length(surface_type) != 1L || is.na(surface_type)) {
    stop("surface_type must be a single non-missing value.", call. = FALSE)
  }

  surface_type <- as.character(surface_type)

  # Already a Penman-compatible surface resistance class
  if (surface_type %in% surface_resistance$surface_type) {
    return(surface_type)
  }

  # Aliases from general fieldClim surface_properties classes
  aliases <- c(
    "field" = "Temperate grassland",
    "lawn" = "Temperate grassland",
    "grass" = "Temperate grassland",
    "agriculture" = "Cereal crops",
    "acre" = "Cereal crops",
    "crop" = "Cereal crops",
    "cereal crops" = "Cereal crops",
    "coniferous forest" = "Coniferous forest",
    "deciduous forest" = "Temperate deciduous forest",
    "mixed forest" = "Temperate deciduous forest",
    "shrub" = "Broadleaved herbaceous crops"
  )

  key <- tolower(surface_type)

  if (key %in% names(aliases)) {
    return(unname(aliases[[key]]))
  }

  stop(
    "surface_type '", surface_type, "' is not compatible with latent_penman(). ",
    "Use one of: ",
    paste(surface_resistance$surface_type, collapse = ", "),
    "; or a mapped fieldClim type such as field, lawn, agriculture, ",
    "coniferous forest, deciduous forest, mixed forest, or shrub.",
    call. = FALSE
  )
}

#' Latent Heat Penman-Monteith-Type Method
#'
#' Calculates latent heat flux using a simplified Penman-Monteith-type
#' combination equation. Positive latent heat flux signifies flux away from the
#' surface. Negative latent heat flux indicates flux toward the surface or a
#' condensation-like direction, depending on context.
#'
#' @param datetime POSIXt object (POSIXct, POSIXlt). See [base::as.POSIXlt] and [base::strptime] for conversion.
#' @param v Wind velocity in m/s.
#' @param temp Air temperature in degrees C.
#' @param rh Relative humidity in %.
#' @param z Height of measurement for temperature and wind speed in m.
#' @param rad_bal Net radiation balance in W m-2.
#' @param elev Elevation above sea level in m.
#' @param lat Latitude in decimal degrees.
#' @param lon Longitude in decimal degrees.
#' @param soil_flux Soil heat flux in W m-2.
#' @param obs_height Observation height in m. Used for calculating aerodynamic resistance.
#' @param surface_type Surface type for determining surface resistance. Options: `r surface_resistance$surface_type``.
#' @param ... Additional arguments.
#' @param weather_station A weather_station object.
#' @return Latent heat flux in W m-2.
#' @details
#' The latent heat flux (\eqn{Q_e}) using the simplified Penman-Monteith-type
#' method is calculated as:
#' \deqn{Q_e = \frac{\Delta (R_n - G) + \gamma \frac{c_p \rho}{r_a} (e_s - e_a)}{\Delta + \gamma (1 + \frac{r_s}{r_a})}}
#' where:
#' \eqn{\Delta} is the slope of the saturation vapor pressure curve,
#' \eqn{\gamma} is the psychrometric constant,
#' \eqn{R_n} is the net radiation,
#' \eqn{G} is the soil heat flux,
#' \eqn{c_p} is the specific heat of air,
#' \eqn{\rho} is the air density,
#' \eqn{r_a} is the aerodynamic resistance,
#' \eqn{r_s} is the surface resistance,
#' \eqn{e_s} is the saturation vapor pressure, and
#' \eqn{e_a} is the actual vapor pressure.
#'
#' \code{pres_sat_vapor_p()} and \code{pres_vapor_p()} return pressure in hPa.
#' \code{latent_penman()} converts \eqn{e_s} and \eqn{e_a} internally to kPa
#' before computing the aerodynamic vapour-pressure-deficit term. \eqn{\Delta}
#' and \eqn{\gamma} are handled on the same kPa scale.
#'
#' The aerodynamic resistance (\eqn{r_a}) is calculated based on wind speed,
#' observation height, and surface roughness. The surface resistance (\eqn{r_s})
#' is selected based on the specified surface type. The function returns latent
#' heat flux only; it does not return evaporation depth or a paired sensible heat
#' flux and is not forced to close \eqn{R_n - G}.
#'
#' For weather-station objects, the method uses \code{hum1} as relative humidity
#' when present and otherwise uses \code{rh}. Both fields are interpreted as
#' relative humidity in percent for this calculation.
#'
#' **Available Surface Types:**
#' - Temperate grassland
#' - Coniferous forest
#' - Temperate deciduous forest
#' - Tropical rain forest
#' - Cereal crops
#' - Broadleaved herbaceous crops
#'
#' `surface_type` may either be a Penman resistance class
#' (`Temperate grassland`, `Cereal crops`, ...), or a mapped fieldClim
#' surface class such as `field`, `lawn`, `agriculture`,
#' `coniferous forest`, `deciduous forest`, `mixed forest`, or `shrub`.
#' For example, `field` is mapped to `Temperate grassland`.
#'
#' @examples
#' # Calculate latent heat flux using the Penman-Monteith-type method
#' datetime <- as.POSIXlt("2022-07-15 12:00:00")
#' latent_penman(
#'   datetime = datetime, v = 2, temp = 25, rh = 60, z = 2, rad_bal = 200,
#'   elev = 100, lat = 50, lon = 8,
#'   soil_flux = 50, obs_height = 10,
#'   surface_type = "Temperate grassland"
#' )
#' @references Monteith, John L., Mike H. Unsworth, and Ann Webb. "Principles of environmental physics." Quarterly Journal of the Royal Meteorological Society 120.520 (1994): 1699.
#' @export
latent_penman <- function(...) {
  UseMethod("latent_penman")
}

#' @rdname latent_penman
#' @export
latent_penman.default <- function(datetime,
                                  v,
                                  temp,
                                  rh,
                                  z = 2,
                                  rad_bal,
                                  elev,
                                  lat,
                                  lon,
                                  soil_flux,
                                  obs_height,
                                  surface_type,
                                  ...) {
  surface_type <- .normalize_penman_surface_type(surface_type)
  if (!inherits(datetime, "POSIXt")) {
    stop("datetime has to be of class POSIXt.")
  }
  if (!surface_type %in% surface_resistance$surface_type) {
    values_surface <- paste(surface_resistance$surface_type, collapse = " , ")
    stop("'surface_type' must be one of the following: ", values_surface)
  } else {
    rs <- surface_resistance[which(surface_resistance$surface_type == surface_type), ]$rs
  }

  # Day of year
  doy <- as.numeric(strftime(datetime, format = "%j"))
  # Decimal hour
  lt <- as.POSIXlt(datetime)
  ut <- lt$hour + lt$min / 60 + lt$sec / 3600

  # Constants
  cp <- 1004  # specific heat of air (J/(kg K))
  rho <- 1.2  # density of air (kg m-3)
  gamma <- 0.665 * 10^(-3) * pres_p(elev, temp)  # psychrometric constant (kPa/degrees C)

  # Saturation vapor pressure (es) and actual vapor pressure (ea)
  es_hPa <- pres_sat_vapor_p(temp)
  ea_hPa <- pres_vapor_p(temp, rh)
  es_kPa <- es_hPa / 10
  ea_kPa <- ea_hPa / 10
  vpd_kPa <- es_kPa - ea_kPa

  # Slope of the saturation vapor pressure curve (Delta)
  delta <- 4098 * es_kPa / ((temp + 237.3)^2)

  # Calculate aerodynamic resistance (ra)
  d <- turb_displacement(obs_height, surroundings = "vegetation")
  zom <- 0.123 * obs_height # roughness length for momentum transfer
  zoh <- 0.1 * zom # roughness length for heat and vapor transfer
  k <- 0.41      # von Karman's constant
  cap_value <- 1e-6

  # Calculate the terms and keep invalid aerodynamic cases local to their element.
  log_arg1 <- (z - d) / zom
  log_arg2 <- (z - d) / zoh

  # Calculate ra
  v_ra <- rep(v, length.out = length(log_arg1))
  invalid_ra <- !is.finite(log_arg1) | !is.finite(log_arg2) |
    log_arg1 <= 0 | log_arg2 <= 0 |
    !is.finite(v_ra) | v_ra <= 0
  valid_ra <- !invalid_ra
  ra <- rep(NA_real_, length(valid_ra))
  ra[valid_ra] <- (log(log_arg1[valid_ra]) * log(log_arg2[valid_ra])) / (k^2 * v_ra[valid_ra])

  if (any(invalid_ra, na.rm = TRUE)) {
    warning(
      "latent_penman: invalid aerodynamic resistance for some values; returning NA there.",
      call. = FALSE
    )
  }

  # Net radiation (Rn) and soil heat flux (G)
  Rn <- rad_bal  # W m-2
  G <- soil_flux  # W m-2

  # Penman-Monteith equation
  Qe <- (delta * (Rn - G) + gamma * (cp * rho / ra) * vpd_kPa) / (delta + gamma * (1 + rs / ra))

  # Convert from energy flux to mass flux (latent heat of vaporization)
  lv <- hum_evap_heat(temp)  # J/kg
  out <- Qe / lv  # kg m-2 s-1

  # Convert to W m-2 by multiplying with latent heat of vaporization and time conversion if needed
  out <- out * lv

  # Check if values exceed the valid data range and issue warnings
  if (any(out > 600, na.rm = TRUE)) {
    warning("There are values above 600 W/m^2!")
  }
  if (any(out < -600, na.rm = TRUE)) {
    warning("There are values below -600 W/m^2!")
  }

  return(out)
}

#' @rdname latent_penman
#' @export
latent_penman.weather_station <- function(weather_station, ...) {
  check_availability(
    weather_station,
    "datetime",
    "v1",
    "temp",
    "z1",
    "rad_bal",
    "elev",
    "lat",
    "lon",
    "soil_flux",
    "obs_height",
    "surface_type"
  )

  if (!("rh" %in% names(weather_station)) && !("hum1" %in% names(weather_station))) {
    stop(
      "rh or hum1 is not available in the weather_station object. ",
      "Please set relative humidity as rh or hum1.",
      call. = FALSE
    )
  }

  datetime <- weather_station$datetime
  v <- weather_station$v1
  temp <- weather_station$temp

  # Prefer profile humidity if available, otherwise use the standard rh field.
  rh <- if ("hum1" %in% names(weather_station)) {
    weather_station$hum1
  } else {
    weather_station$rh
  }

  z <- weather_station$z1
  rad_bal <- weather_station$rad_bal
  elev <- weather_station$elev
  lat <- weather_station$lat
  lon <- weather_station$lon
  soil_flux <- weather_station$soil_flux
  obs_height <- weather_station$obs_height

  # Allows field/lawn/agriculture etc. for weather_station objects.
  surface_type <- .normalize_penman_surface_type(weather_station$surface_type)

  latent_penman(
    datetime = datetime,
    v = v,
    temp = temp,
    rh = rh,
    z = z,
    rad_bal = rad_bal,
    elev = elev,
    lat = lat,
    lon = lon,
    soil_flux = soil_flux,
    obs_height = obs_height,
    surface_type = surface_type,
    ...
  )
}

#' Latent Heat using Monin-Obukhov length
#'
#' Calculates the latent heat flux using the Monin-Obukhov length. Positive
#' flux signifies flux away from the surface, negative values signify flux
#' towards the surface. Monin-Obukhov outputs are diagnostic profile/stability
#' estimates and are not expected to close \eqn{R_n - G}.
#'
#' @param ... Additional arguments.
#' @return Latent heat flux in W m-2.
#' @details
#' The latent heat flux (\eqn{Q_e}) using the Monin-Obukhov method is calculated as:
#' \deqn{Q_e = -\rho \cdot L_v \cdot \frac{k \cdot u_*}{\phi_q} \cdot \frac{\Delta q}{\Delta z}}
#' where:
#' \eqn{\rho} is the air density,
#' \eqn{L_v} is the latent heat of vaporization,
#' \eqn{k} is the von Karman constant,
#' \eqn{u_*} is the friction velocity,
#' \eqn{\phi_q} is the stability correction function for humidity,
#' \eqn{\Delta q} is the moisture gradient, and
#' \eqn{\Delta z} is the height difference between measurements.
#'
#' The stability correction function for humidity (\eqn{\phi_q}) is calculated using the gradient Richardson number (\eqn{Ri_g}) and the stability parameter (\eqn{s_1}).
#' The stability parameter (\eqn{s_1}) is the ratio of the upper measurement height to the Monin-Obukhov length.
#' When the Monin-Obukhov length is close to zero, the ratio can become excessively large, leading to unrealistic values.
#' To address this, the stability parameter (\eqn{s_1}) can be capped to a maximum absolute value. Invalid heights, invalid wind speeds, and invalid numerical profile states are guarded elementwise and return \code{NA} with a warning. Zero moisture gradient returns zero latent heat flux. The default cap is set to NULL.
#' \deqn{\phi_q = \begin{cases}
#' 0.95 \cdot (1 - 11.6 \cdot s_1)^{-0.5}, & \text{if } Ri_g \leq 0 \\
#' 0.95 + 7.8 \cdot s_1, & \text{if } Ri_g > 0
#' \end{cases}}
#' @param hum1 Relative humidity at lower height in %.
#' @param hum2 Relative humidity at upper height in %.
#' @param t1 Air temperature at lower height in degrees C.
#' @param t2 Air temperature at upper height in degrees C.
#' @param v1 Windspeed at lower height (e.g. height of anemometer) in m/s.
#' @param v2 Windspeed at upper height in m/s.
#' @param z1 Lower height of measurement in m.
#' @param z2 Upper height of measurement in m.
#' @param elev Elevation above sea level in m.
#' @param cap The maximum absolute value for the stability parameter \eqn{s_1}. Default is NULL.
#' @param surface_type Surface type, for which a roughness length will be selected.
#' @param obs_height Height of the obstacles (if provided).
#' @inheritParams turb_roughness_length
#' @examples
#' # Calculate latent heat flux using Monin-Obukhov length
#' latent_monin(
#'   hum1 = 80, hum2 = 60, t1 = 20, t2 = 15,
#'   v1 = 3, v2 = 5, z1 = 2, z2 = 10,
#'   elev = 100, surface_type = "coniferous forest"
#' )
#' @references Bendix 2004, p. 77, eq.4.6
#' @references Foken 2016, p. 61, Tab. 2.10
#' @export
latent_monin <- function(...) {
  UseMethod("latent_monin")
}

#' @rdname latent_monin
#' @export
latent_monin.default <- function(hum1, hum2, t1, t2, v1, v2, z1 = 2, z2 = 10, elev, cap = NULL, surface_type = NULL, obs_height = NULL, ...) {
  if (is.null(obs_height) && is.null(surface_type)) {
    stop("The input is not valid. Either obs_height or surface_type has to be defined.", call. = FALSE)
  }

  n <- max(length(hum1), length(hum2), length(t1), length(t2), length(v1), length(v2), length(z1), length(z2), length(elev))
  hum1 <- rep_len(hum1, n)
  hum2 <- rep_len(hum2, n)
  t1 <- rep_len(t1, n)
  t2 <- rep_len(t2, n)
  v1 <- rep_len(v1, n)
  v2 <- rep_len(v2, n)
  z1 <- rep_len(z1, n)
  z2 <- rep_len(z2, n)
  elev <- rep_len(elev, n)

  invalid_height <- !is.finite(z1) | !is.finite(z2) | z1 <= 0 | z2 <= 0 | z2 <= z1
  invalid_wind <- !is.finite(v1) | !is.finite(v2) | v1 <= 0 | v2 <= 0
  invalid_profile <- invalid_height | invalid_wind | !is.finite(hum1) | !is.finite(hum2) |
    !is.finite(t1) | !is.finite(t2) | !is.finite(elev)

  safe_hum1 <- hum1
  safe_hum2 <- hum2
  safe_t1 <- t1
  safe_t2 <- t2
  safe_v1 <- v1
  safe_v2 <- v2
  safe_z1 <- z1
  safe_z2 <- z2
  safe_elev <- elev
  safe_hum1[invalid_profile] <- 60
  safe_hum2[invalid_profile] <- 55
  safe_t1[invalid_profile] <- 20
  safe_t2[invalid_profile] <- 19
  safe_v1[invalid_profile] <- 2
  safe_v2[invalid_profile] <- 4
  safe_z1[invalid_profile] <- 2
  safe_z2[invalid_profile] <- 10
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
  moist_gradient <- hum_moisture_gradient(safe_hum1, safe_hum2, safe_t1, safe_t2, safe_z1, safe_z2, safe_elev)
  air_density <- pres_air_density(safe_elev, safe_t1)
  lv <- hum_evap_heat(safe_t1)
  k <- 0.4
  s1 <- safe_z2 / monin

  if (!is.null(cap)) {
    s1 <- pmax(pmin(s1, cap), -cap)
  }

  busi <- rep(NA_real_, length(grad_rich_no))
  unstable <- is.finite(grad_rich_no) & grad_rich_no <= 0
  stable <- is.finite(grad_rich_no) & grad_rich_no > 0
  busi[unstable] <- 0.95 * (1 - (11.6 * s1[unstable]))^-0.5
  busi[stable] <- 0.95 + (7.8 * s1[stable])

  out <- (-1) * air_density * lv * ((k * ustar) / busi) * moist_gradient

  zero_gradient <- !invalid_profile & is.finite(moist_gradient) & moist_gradient == 0
  out[zero_gradient] <- 0

  invalid_numeric <- !is.finite(out) & !zero_gradient
  invalid_out <- invalid_profile | invalid_numeric

  if (any(invalid_height, na.rm = TRUE)) {
    warning("latent_monin: invalid heights for some values; returning NA there.", call. = FALSE)
  }
  if (any(invalid_wind, na.rm = TRUE)) {
    warning("latent_monin: invalid wind speeds for some values; returning NA there.", call. = FALSE)
  }
  if (any(invalid_numeric & !invalid_profile, na.rm = TRUE)) {
    warning("latent_monin: invalid Monin-Obukhov numerical state for some values; returning NA there.", call. = FALSE)
  }

  out[invalid_out] <- NA_real_

  if (any(out > 600, na.rm = TRUE)) {
    warning("There are values above 600 W m-2!")
  }
  if (any(out < -600, na.rm = TRUE)) {
    warning("There are values below -600 W m-2!")
  }

  return(out)
}

#' @rdname latent_monin
#' @export
latent_monin.weather_station <- function(weather_station, cap = NULL, ...) {
  check_availability(weather_station, "z1", "z2", "t1", "t2", "hum1", "hum2", "v1", "v2", "elev")
  hum1 <- weather_station$hum1
  hum2 <- weather_station$hum2
  t1 <- weather_station$t1
  t2 <- weather_station$t2
  z1 <- weather_station$z1
  z2 <- weather_station$z2
  v1 <- weather_station$v1
  v2 <- weather_station$v2
  elev <- weather_station$elev
  obs_height <- weather_station$obs_height
  if (!is.null(obs_height)) {
    return(latent_monin(hum1, hum2, t1, t2, v1, v2, z1, z2, elev, cap, obs_height = obs_height))
  } else {
    check_availability(weather_station, "surface_type")
    surface_type <- weather_station$surface_type
    return(latent_monin(hum1, hum2, t1, t2, v1, v2, z1, z2, elev, cap, surface_type = surface_type))
  }
}



#' Latent Heat using Bowen Method
#'
#' Calculates the latent heat flux using the Bowen Method. Positive
#' flux signifies flux away from the surface, negative values signify flux
#' towards the surface.
#' Values above 600 W m-2 and below -600 W m-2 trigger warnings.
#' Output flux values are not smoothed; only the optional denominator cap
#' guards near-zero partition denominators.
#'
#' @param ... Additional arguments.
#' @param t1 Temperature at lower height in degrees C.
#' @param t2 Temperature at upper height in degrees C.
#' @param hum1 Relative humidity at lower height in %.
#' @param hum2 Relative humidity at upper height in %.
#' @param z1 Lower height of measurement in m.
#' @param z2 Upper height of measurement in m.
#' @param elev Elevation above sea level in m.
#' @param rad_bal Radiation balance in W m-2.
#' @param soil_flux Soil flux in W m-2.
#' @param cap A positive denominator guard for near-zero \eqn{1 + B}. Default is NULL.
#' @param weather_station A weather_station object.
#' @return Latent heat flux in W m-2.
#' @details
#' The latent heat flux (\eqn{Q_e}) using the Bowen method is calculated as:
#' \deqn{Q_e = \frac{R_n - G}{1 + B}}
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
#' When \eqn{1 + B} is close to zero, the latent heat flux can become
#' unrealistically high. The \code{cap} parameter is a numerical safeguard that
#' replaces near-zero denominators with \code{+/- cap}. Exact closure with
#' \code{sensible_bowen()} is guaranteed only for finite uncapped denominators;
#' capped cases are guarded diagnostic outputs and may not close
#' \code{rad_bal - soil_flux} exactly. Non-finite Bowen ratios or denominators
#' return \code{NA} for affected elements with a warning.
#' @examples
#' # Calculate latent heat flux using Bowen method
#' latent_bowen(
#'   t1 = 20, t2 = 15, hum1 = 80, hum2 = 60,
#'   z1 = 2, z2 = 10, elev = 100,
#'   rad_bal = 200, soil_flux = 50
#' )
#' @references Bendix 2004, p. 221, eq. 9.21
#' @export
latent_bowen <- function(...) {
  UseMethod("latent_bowen")
}

#' @rdname latent_bowen
#' @export
latent_bowen.default <- function(t1, t2, hum1, hum2, z1 = 2, z2 = 10, elev,
                                 rad_bal, soil_flux, cap = NULL, ...) {
  # Calculating potential temperature delta
  t1_pot <- temp_pot_temp(t1, elev)
  t2_pot <- temp_pot_temp(t2, elev)
  dpot <- (t2_pot - t1_pot) / (z2 - z1)

  # Calculating absolute humidity delta
  af1 <- hum_absolute(hum1, t1)
  af2 <- hum_absolute(hum2, t2)
  dah <- (af2 - af1) / (z2 - z1)

  # Calculate Bowen ratio
  gamma <- 0.00066 * (1 + 0.000946 * t1)
  bowen_ratio <- gamma * dpot / dah

  # Define a small cap to prevent division by a value close to zero
  denominator <- 1 + bowen_ratio
  invalid_partition <- !is.finite(bowen_ratio) | !is.finite(denominator)
  if(!is.null(cap)){
    near_zero <- !invalid_partition & abs(denominator) < cap
    denominator[near_zero] <- ifelse(denominator[near_zero] < 0, -cap, cap)
  }

  out <- (rad_bal - soil_flux) / denominator
  out[invalid_partition] <- NA_real_
  if (any(invalid_partition, na.rm = TRUE)) {
    warning("latent_bowen: invalid Bowen ratio or denominator for some values; returning NA there.", call. = FALSE)
  }

  # Check if values exceed the valid data range and issue warnings
  if (any(out > 600, na.rm = TRUE)) {
    warning("There are values above 600 W m-2!")
  }
  if (any(out < -600, na.rm = TRUE)) {
    warning("There are values below -600 W m-2!")
  }

  return(out)
}

#' @rdname latent_bowen
#' @export
latent_bowen.weather_station <- function(weather_station, cap = NULL, ...) {
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
  return(latent_bowen(t1, t2, hum1, hum2, z1, z2, elev, rad_bal, soil_flux, cap))
}
