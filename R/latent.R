#' Latent Heat Priestley-Taylor Method
#'
#' Calculates the latent heat flux using the Priestley-Taylor method. Positive
#' heat flux signifies flux away from the surface, negative values signify flux
#' towards the surface.
#'
#' @param ... Additional arguments.
#' @return Latent heat flux in W/m².
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
#' The Priestley-Taylor coefficient depends on the surface type and can be selected from predefined values.
#' @param temp Air temperature in °C.
#' @param rad_bal Radiation balance in W/m².
#' @param soil_flux Soil flux in W/m².
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

#' Latent Heat Penman-Monteith Method
#'
#' Calculates the latent heat flux using the Penman-Monteith equation. Negative
#' heat flux signifies flux away from the surface, while positive values signify flux
#' towards the surface.
#'
#' @param datetime POSIXt object (POSIXct, POSIXlt). See [base::as.POSIXlt] and [base::strptime] for conversion.
#' @param v Wind velocity in m/s.
#' @param temp Air temperature in °C.
#' @param rh Relative humidity in %.
#' @param z Height of measurement for temperature and wind speed in m.
#' @param rad_bal Net radiation balance in W/m².
#' @param elev Elevation above sea level in m.
#' @param lat Latitude in decimal degrees.
#' @param lon Longitude in decimal degrees.
#' @param soil_flux Soil heat flux in W/m².
#' @param obs_height Observation height in m. Used for calculating aerodynamic resistance.
#' @param surface_type Surface type for determining surface resistance. Options: `r surface_resistance$surface_type``.
#' @param ... Additional arguments.
#' @return Latent heat flux in W/m².
#' @details
#' The latent heat flux (\eqn{Q_e}) using the Penman-Monteith method is calculated as:
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
#' The aerodynamic resistance (\eqn{r_a}) is calculated based on wind speed, observation height, and surface roughness. The surface resistance (\eqn{r_s}) is selected based on the specified surface type.
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
#' # Calculate latent heat flux using the Penman-Monteith method
#' datetime <- as.POSIXlt("2022-07-15 12:00:00")
#' latent_penman(
#'   datetime = datetime, v = 2, temp = 25, rh = 60, z = 2, rad_bal = 200,
#'   elev = 100, lat = 50, lon = 8, soil_flux = 50, obs_height = 10, surface_type = "Temperate grassland"
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
  cp <- 1004  # specific heat of air (J/(kg·K))
  rho <- 1.2  # density of air (kg/m³)
  gamma <- 0.665 * 10^(-3) * pres_p(elev, temp)  # psychrometric constant (kPa/°C)

  # Saturation vapor pressure (es) and actual vapor pressure (ea)
  es <- pres_sat_vapor_p(temp)
  ea <- pres_vapor_p(temp, rh)

  # Slope of the saturation vapor pressure curve (Delta)
  delta <- 4098 * (es/10) / ((temp + 237.3)^2)

  # Calculate aerodynamic resistance (ra)
  d <- turb_displacement(obs_height, surroundings = "vegetation")
  zom <- 0.123 * obs_height # roughness length for momentum transfer
  zoh <- 0.1 * zom # roughness length for heat and vapor transfer
  k <- 0.41      # von Karman's constant
  cap_value <- 1e-6

  # Calculate the terms with a cap to ensure they are positive
  log_arg1 <- max((z - d) / zom, cap_value)
  log_arg2 <- max((z - d) / zoh, cap_value)

  # Calculate ra
  ra <- (log(log_arg1) * log(log_arg2)) / (k^2 * v)

  # Net radiation (Rn) and soil heat flux (G)
  Rn <- rad_bal  # W/m²
  G <- soil_flux  # W/m²

  # Penman-Monteith equation
  Qe <- (delta * (Rn - G) + gamma * (cp * rho / ra) * (es - ea)) / (delta + gamma * (1 + rs / ra))

  # Convert from energy flux to mass flux (latent heat of vaporization)
  lv <- hum_evap_heat(temp)  # J/kg
  out <- Qe / lv  # kg/m²/s

  # Convert to W/m² by multiplying with latent heat of vaporization and time conversion if needed
  out <- out * lv

  # Check if values exceed the valid data range and issue warnings
  if (any((!is.na(out)) > 600)) {
    warning("There are values above 600 W/m^2!")
  }
  if (any((!is.na(out)) < -600)) {
    warning("There are values below -600 W/m^2!")
  }

  return(out)
}

#' @rdname latent_penman
#' @inheritParams build_weather_station
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
#' towards the surface.
#'
#' @param ... Additional arguments.
#' @return Latent heat flux in W/m².
#' @details
#' The latent heat flux (\eqn{Q_e}) using the Monin-Obukhov method is calculated as:
#' \deqn{Q_e = -\rho \cdot L_v \cdot \frac{k \cdot u_*}{\phi_q} \cdot \frac{\Delta q}{\Delta z}}
#' where:
#' \eqn{\rho} is the air density,
#' \eqn{L_v} is the latent heat of vaporization,
#' \eqn{k} is the von Kármán constant,
#' \eqn{u_*} is the friction velocity,
#' \eqn{\phi_q} is the stability correction function for humidity,
#' \eqn{\Delta q} is the moisture gradient, and
#' \eqn{\Delta z} is the height difference between measurements.
#'
#' The stability correction function for humidity (\eqn{\phi_q}) is calculated using the gradient Richardson number (\eqn{Ri_g}) and the stability parameter (\eqn{s_1}).
#' The stability parameter (\eqn{s_1}) is the ratio of the upper measurement height to the Monin-Obukhov length.
#' When the Monin-Obukhov length close to zero, the ratio can become excessively large, leading to unrealistic values.
#' To address this, the stability parameter (\eqn{s_1}) is capped to a maximum absolute value.
#' The default cap is set to NULL.
#' \deqn{\phi_q = \begin{cases}
#' 0.95 \cdot (1 - 11.6 \cdot s_1)^{-0.5}, & \text{if } Ri_g \leq 0 \\
#' 0.95 + 7.8 \cdot s_1, & \text{if } Ri_g > 0
#' \end{cases}}
#' @param hum1 Relative humidity at lower height in %.
#' @param hum2 Relative humidity at upper height in %.
#' @param t1 Air temperature at lower height in °C.
#' @param t2 Air temperature at upper height in °C.
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
#' latent_monin(hum1 = 80, hum2 = 60, t1 = 20, t2 = 15, v1 = 3, v2 = 5, z1 = 2, z2 = 10, elev = 100, surface_type = "forest")
#' @references Bendix 2004, p. 77, eq.4.6
#' @references Foken 2016, p. 61, Tab. 2.10
#' @export
latent_monin <- function(...) {
  UseMethod("latent_monin")
}

#' @rdname latent_monin
#' @export
latent_monin.default <- function(hum1, hum2, t1, t2, v1, v2, z1 = 2, z2 = 10, elev, cap = NULL, surface_type = NULL, obs_height = NULL, ...) {
  # calculate ustar
  if (!is.null(obs_height)) {
    ustar <- turb_ustar(v = v2, z = z2, obs_height = obs_height)
  } else if (!is.null(surface_type)) {
    ustar <- turb_ustar(v = v2, z = z2, surface_type = surface_type)
  } else {
    stop("The input is not valid. Either obs_height or surface_type has to be defined.")
  }

  # calculate Monin-Obukhov-Length
  if (!is.null(obs_height)) {
    monin <- turb_flux_monin(z1 = z1, z2 = z2, v1 = v1, v2 = v2, t1 = t1, t2 = t2, elev = elev, obs_height = obs_height)
  } else if (!is.null(surface_type)) {
    monin <- turb_flux_monin(z1 = z1, z2 = z2, v1 = v1, v2 = v2, t1 = t1, t2 = t2, elev = elev, surface_type = surface_type)
  } else {
    stop("The input is not valid. Either obs_height or surface_type has to be defined.")
  }

  grad_rich_no <- turb_flux_grad_rich_no(t1, t2, z1, z2, v1, v2, elev)
  moist_gradient <- hum_moisture_gradient(hum1, hum2, t1, t2, z1, z2, elev)
  air_density <- pres_air_density(elev, t1)
  lv <- hum_evap_heat(t1)
  k <- 0.4 # Karman constant
  schmidt <- 1
  s1 <- z2 / monin # s1 = variant of the greek letter sigma

  if(!is.null(cap)){
    # Apply cap
    s1 <- pmax(pmin(s1, cap), -cap)
  }

  busi <- rep(NA, length(grad_rich_no))
  for (i in 1:length(busi)) {
    if (is.na(grad_rich_no[i])) {
      busi[i] <- NA
    } else if (grad_rich_no[i] <= 0) {
      busi[i] <- 0.95 * (1 - (11.6 * s1[i]))^-0.5
    } else if (grad_rich_no[i] > 0) {
      busi[i] <- 0.95 + (7.8 * s1[i])
    }
  }
  out <- (-1) * air_density * lv * ((k * ustar) / busi) * moist_gradient

  # Check if values exceed the valid data range.
  if (any(out > 600, na.rm = TRUE)) {
    warning("There are values above 600 W/m²!")
  }
  if (any(out < -600, na.rm = TRUE)) {
    warning("There are values below -600 W/m²!")
  }

  return(out)
}

#' @rdname latent_monin
#' @inheritParams build_weather_station
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
#' Values above 600 W/m² and below -600 W/m² will be recognized
#' as measurement mistakes and smoothed respectively.
#'
#' @param ... Additional arguments.
#' @param t1 Temperature at lower height in °C.
#' @param t2 Temperature at upper height in °C.
#' @param hum1 Relative humidity at lower height in %.
#' @param hum2 Relative humidity at upper height in %.
#' @param z1 Lower height of measurement in m.
#' @param z2 Upper height of measurement in m.
#' @param elev Elevation above sea level in m.
#' @param rad_bal Radiation balance in W/m².
#' @param soil_flux Soil flux in W/m².
#' @param cap A small value to prevent division by zero or near-zero values when calculating the Bowen ratio. Default is NULL.
#' @return Latent heat flux in W/m².
#' @details
#' The latent heat flux (\eqn{Q_e}) using the Bowen method is calculated as:
#' \deqn{Q_e = \frac{R_n - G}{1 + B}}
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
#' When \eqn{1 + B} results in values close to zero, the latent heat flux can become unrealistically high.
#' To prevent this, a cap parameter can be set.
#' The cap parameter ensures that \eqn{1 + B} does not get too close to zero by setting a minimum allowable value.
#' @examples
#' # Calculate latent heat flux using Bowen method
#' latent_bowen(t1 = 20, t2 = 15, hum1 = 80, hum2 = 60, z1 = 2, z2 = 10, elev = 100, rad_bal = 200, soil_flux = 50)
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
  if(!is.null(cap)){
    near_zero <- abs(denominator) < cap
    denominator[near_zero] <- ifelse(denominator[near_zero] < 0, -cap, cap)
  }

  out <- (rad_bal - soil_flux) / denominator

  # Check if values exceed the valid data range and issue warnings
  if (any(out > 600, na.rm = TRUE)) {
    warning("There are values above 600 W/m²!")
  }
  if (any(out < -600, na.rm = TRUE)) {
    warning("There are values below -600 W/m²!")
  }

  return(out)
}

#' @rdname latent_bowen
#' @inheritParams build_weather_station
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
