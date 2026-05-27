#' Specific humidity
#'
#' Calculates specific humidity from vapor pressure and air pressure.
#'
#' @param ... Additional arguments.
#' @return Numeric. Specific humidity in kg/kg.
#' @details
#' Specific humidity (\eqn{q}) is the ratio of the mass of water vapor to the total mass of the air parcel. It is calculated from the vapor pressure and air pressure using the formula:
#' \deqn{q = 0.622 \times \frac{pvapor}{p}}
#' where \eqn{pvapor} is the vapor pressure and \eqn{p} is the air pressure.
#' @examples
#' # Calculate specific humidity
#' hum_specific(rh = 70, temp = 25, elev = 100)
#' @references Bendix 2004, p. 262.
#' @export
hum_specific <- function(...) {
  UseMethod("hum_specific")
}

#' @rdname hum_specific
#' @param rh Relative humidity in %.
#' @param temp Temperature in °C.
#' @param elev Elevation above sea level in m.
#' @export
hum_specific.default <- function(rh, temp, elev, ...) {
  p_vapor <- pres_vapor_p(temp, rh)
  p <- pres_p(elev, temp, ...)
  0.622 * (p_vapor / p)
}

#' @rdname hum_specific
#' @inheritParams build_weather_station
#' @export
hum_specific.weather_station <- function(weather_station, ...) {
  check_availability(weather_station, "temp", "rh", "elev")
  rh <- weather_station$rh
  temp <- weather_station$temp
  elev <- weather_station$elev
  return(hum_specific(rh, temp, elev))
}

#' Absolute humidity
#'
#' Calculates absolute humidity from vapor pressure and air temperature.
#'
#' @param ... Additional arguments.
#' @return Numeric. Absolute humidity in kg/m³.
#' @details
#' Absolute humidity (\eqn{AH}) is the mass of water vapor per unit volume of air. It is calculated from the vapor pressure and temperature using the formula:
#' \deqn{AH = \frac{0.21668 \times pvapor}{T}}
#' where \eqn{pvapor} is the vapor pressure and \eqn{T} is the temperature in Kelvin.
#' @examples
#' # Calculate absolute humidity
#' hum_absolute(rh = 70, temp = 25)
#' @references Bendix 2004, p. 262.
#' @export
hum_absolute <- function(...) {
  UseMethod("hum_absolute")
}

#' @rdname hum_absolute
#' @param rh Relative humidity in %.
#' @param temp Temperature in °C.
#' @export
hum_absolute.default <- function(rh, temp, ...) {
  p_vapor <- pres_vapor_p(temp, rh)
  temp <- c2k(temp) # to Kelvin
  (0.21668 * p_vapor) / temp
}

#' @rdname hum_absolute
#' @inheritParams build_weather_station
#' @export
hum_absolute.weather_station <- function(weather_station, ...) {
  check_availability(weather_station, "temp", "rh")
  rh <- weather_station$rh
  temp <- weather_station$temp
  return(hum_absolute(rh, temp))
}

#' Enthalpy of vaporization
#'
#' Calculates heat of evaporation for water from air temperature.
#'
#' @param ... Additional arguments.
#' @return Numeric. Enthalpy of vaporization in J/kg.
#' @details
#' The enthalpy of vaporization (\eqn{L}) is the amount of heat required to convert a unit mass of a liquid into vapor without a temperature change. It is calculated using the formula:
#' \deqn{L = (2.5008 - 0.002372 \times T) \times 10^6}
#' where \eqn{T} is the temperature in °C.
#' @examples
#' # Calculate enthalpy of vaporization
#' hum_evap_heat(temp = 25)
#' @references Bendix 2004, p. 261.
#' @export
hum_evap_heat <- function(...) {
  UseMethod("hum_evap_heat")
}

#' @rdname hum_evap_heat
#' @param temp Air temperature in °C.
#' @export
hum_evap_heat.default <- function(temp, ...) {
  (2.5008 - 0.002372 * temp) * 10^6
}

#' @rdname hum_evap_heat
#' @inheritParams build_weather_station
#' @export
hum_evap_heat.weather_station <- function(weather_station, ...) {
  check_availability(weather_station, "temp")
  temp <- weather_station$temp
  return(hum_evap_heat(temp))
}

#' Precipitable water
#'
#' Selects reference temperature and pressure based on location and season.
#' Then calculates precipitable water.
#'
#' Latitude <= 30 degrees is defined as tropic; <= 60 is temperate; others is subarctic.
#' Summer is defined as April to September in the northern hemisphere.
#'
#' @inheritParams build_weather_station
#' @return Numeric. Precipitable water in cm·grams.
#' @details
#' Precipitable water (\eqn{PW}) is the total amount of water vapor in a column of air from the surface to the top of the atmosphere. It is calculated using reference temperature and pressure values based on location and season.
#' @examples
#' # Calculate precipitable water
#' hum_precipitable_water(datetime = as.POSIXlt("2022-07-15"), lat = 50, elev = 100, temp = 20)
#' @references Bendix 2004, p. 246.
#' @export
hum_precipitable_water <- function(...) {
  UseMethod("hum_precipitable_water")
}

#' @rdname hum_precipitable_water
#' @inheritParams build_weather_station
#' @inheritDotParams pres_p.default g rl
#' @export
hum_precipitable_water.default <- function(datetime, lat, elev, temp, ...) {
  df <- data.frame(
    t0 = c(300, 294, 272.2, 287, 257.1),
    pwst = c(4.1167, 2.9243, 0.8539, 2.0852, 0.4176),
    row.names = c("tropic", "temperate_summer", "temperate_winter", "subarctic_summer", "subarctic_winter")
  )

  temp_standard <- c()
  pw_standard <- c()

  for (i in seq_along(datetime)) {
    if (abs(lat) <= 30) { # tropic
      temp_standard[i] <- df["tropic", "t0"]
      pw_standard[i] <- df["tropic", "pwst"]
    } else if ((abs(lat) <= 60) && (lat > 0)) { # temperate, northern hemisphere
      if ((datetime[i]$mon + 1) %in% 4:9) {
        temp_standard[i] <- df["temperate_summer", "t0"]
        pw_standard[i] <- df["temperate_summer", "pwst"]
      } else {
        temp_standard[i] <- df["temperate_winter", "t0"]
        pw_standard[i] <- df["temperate_winter", "pwst"]
      }
    } else if ((abs(lat) <= 60) && (lat < 0)) { # temperate, southern hemisphere
      if ((datetime[i]$mon + 1) %in% 4:9) {
        temp_standard[i] <- df["temperate_winter", "t0"]
        pw_standard[i] <- df["temperate_winter", "pwst"]
      } else {
        temp_standard[i] <- df["temperate_summer", "t0"]
        pw_standard[i] <- df["temperate_summer", "pwst"]
      }
    } else if (lat > 0) { # subarctic, northern hemisphere
      if ((datetime[i]$mon + 1) %in% 4:9) {
        temp_standard[i] <- df["subarctic_summer", "t0"]
        pw_standard[i] <- df["subarctic_summer", "pwst"]
      } else {
        temp_standard[i] <- df["subarctic_winter", "t0"]
        pw_standard[i] <- df["subarctic_winter", "pwst"]
      }
    } else if (lat < 0) { # subarctic, southern hemisphere
      if ((datetime[i]$mon + 1) %in% 4:9) {
        temp_standard[i] <- df["subarctic_winter", "t0"]
        pw_standard[i] <- df["subarctic_winter", "pwst"]
      } else {
        temp_standard[i] <- df["subarctic_summer", "t0"]
        pw_standard[i] <- df["subarctic_summer", "pwst"]
      }
    }
  }

  p <- pres_p(elev, temp, ...)
  p0 <- p0_default # will be cancelled in pres_p

  pw_standard * (p / p0) * (temp_standard / temp)^0.5
}

#' @rdname hum_precipitable_water
#' @inheritParams build_weather_station
#' @export
hum_precipitable_water.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(hum_precipitable_water.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  hum_precipitable_water(datetime, lat, elev, temp, ...)
}

#' Moisture gradient
#'
#' Calculates moisture gradient.
#'
#' @param ... Additional arguments.
#' @return Numeric. Moisture gradient.
#' @details
#' The moisture gradient is calculated as the difference in specific humidity at two heights divided by the difference in heights:
#' \deqn{\Delta q / \Delta z}
#' where \eqn{\Delta q} is the difference in specific humidity and \eqn{\Delta z} is the difference in heights.
#' @examples
#' # Calculate moisture gradient
#' hum_moisture_gradient(hum1 = 80, hum2 = 60, t1 = 20, t2 = 15, z1 = 2, z2 = 10, elev = 100)
#' @export
hum_moisture_gradient <- function(...) {
  UseMethod("hum_moisture_gradient")
}

#' @rdname hum_moisture_gradient
#' @param hum1 Relative humidity at lower height in %.
#' @param hum2 Relative humidity at upper height in %.
#' @param t1 Air temperature at lower height in °C.
#' @param t2 Air temperature at upper height in °C.
#' @param z1 Lower measurement height in m.
#' @param z2 Upper measurement height in m.
#' @param elev Elevation above sea level in m.
#' @export
hum_moisture_gradient.default <- function(hum1, hum2, t1, t2, z1 = 2, z2 = 10, elev, ...) {
  sh1 <- hum_specific(hum1, t1, elev)
  sh2 <- hum_specific(hum2, t2, elev)
  (sh2 - sh1) / (z2 - z1)
}

#' @rdname hum_moisture_gradient
#' @inheritParams build_weather_station
#' @export
hum_moisture_gradient.weather_station <- function(weather_station, ...) {
  check_availability(weather_station, "z1", "z2", "t1", "t2", "hum1", "hum2", "elev")
  hum1 <- weather_station$hum1
  hum2 <- weather_station$hum2
  t1 <- weather_station$t1
  t2 <- weather_station$t2
  z1 <- weather_station$z1
  z2 <- weather_station$z2
  elev <- weather_station$elev
  return(hum_moisture_gradient(hum1, hum2, t1, t2, z1, z2, elev))
}
