#' Air Pressure
#'
#' Calculate air pressure based on the barometric formula.
#'
#' The formula assumes that the temperature does not change with altitude.
#' The results are accurate for elevations lower than 5 km.
#'
#' @rdname pres_p
#' @inheritParams build_weather_station
#' @param elev Elevation above sea level in m.
#' @param temp Air temperature in degrees C.
#' @param weather_station A weather_station object.
#' @return Air pressure in hPa.
#' @details
#' The air pressure (\eqn{p}) is calculated using the barometric formula:
#' \deqn{p = p_0 \cdot \exp{\left(-\frac{g \cdot h}{R \cdot T}\right)}}
#' where:
#' \eqn{p_0} is the standard pressure (default 1013.25 hPa),
#' \eqn{g} is the gravitational acceleration (default 9.80665 m/s²),
#' \eqn{h} is the elevation above sea level in meters (m),
#' \eqn{R} is the specific gas constant for air (default 287.05 m²/s²/K), and
#' \eqn{T} is the temperature in Kelvin (K).
#' @param p0 Standard pressure in hPa, default `r p0_default`.
#' @param g Gravitational acceleration in \eqn{m \cdot s^{-2}}, default `r g_default`.
#' @param rl Specific gas constant for air in \eqn{m^2 \cdot s^{-2} \cdot K^{-1}}, default `r rl_default`.
#' @examples
#' # Calculate air pressure at an elevation of 500 meters and temperature of 15°C
#' pres_p(elev = 500, temp = 15)
#' @references Lente & Ősz 2020 eq. 5.
#' @export
pres_p <- function(...) {
  UseMethod("pres_p")
}

#' @rdname pres_p
#' @export
pres_p.default <- function(elev, temp, ...,
    p0 = p0_default, g = g_default, rl = rl_default) {
  temp <- c2k(temp)

  p0 * exp(-(g * elev) / (rl * temp))
}

#' @rdname pres_p
#' @export
pres_p.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(pres_p.default)
  a <- a[1:(length(a)-4)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  pres_p(elev, temp, ...)
}

#' Vapor Pressure
#'
#' Calculates vapor pressure from relative humidity and saturation vapor pressure.
#'
#' @inheritParams build_weather_station
#' @param temp Air temperature in degrees C.
#' @param rh Relative humidity in percent.
#' @param weather_station A weather_station object.
#' @return Vapor pressure in hPa.
#' @details
#' The vapor pressure (\eqn{e}) is calculated as:
#' \deqn{e = \frac{RH}{100} \cdot e_s}
#' where:
#' \eqn{RH} is the relative humidity in %,
#' \eqn{e_s} is the saturation vapor pressure in hPa.
#'
#' @examples
#' # Calculate vapor pressure at a temperature of 20°C and 60% relative humidity
#' pres_vapor_p(temp = 20, rh = 60)
#' @references Bendix 2004, p. 262
#' @export
pres_vapor_p <- function(...) {
  UseMethod("pres_vapor_p")
}

#' @rdname pres_vapor_p
#' @export
pres_vapor_p.default <- function(temp, rh, ...) {
  sat_vapor_p <- pres_sat_vapor_p(temp, ...)
  (rh / 100) * sat_vapor_p
}

#' @rdname pres_vapor_p
#' @export
pres_vapor_p.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(pres_vapor_p.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }
  pres_vapor_p(temp, rh, ...)
}

#' Saturated Vapor Pressure
#'
#' Calculates the saturation vapor pressure for a given temperature.
#'
#' @inheritParams build_weather_station
#' @param temp Air temperature in degrees C.
#' @param weather_station A weather_station object.
#' @return Saturation vapor pressure in hPa.
#' @details
#' The saturation vapor pressure (\eqn{e_s}) is calculated using the formula:
#' \deqn{e_s = 6.1078 \cdot 10^{\left(\frac{a \cdot T}{b + T}\right)}}
#' where:
#' \eqn{T} is the temperature in °C,
#' \eqn{a} and \eqn{b} are constants that vary depending on the state of water:
#' - Over water: \eqn{a = 7.5}, \eqn{b = 235}
#' - Over undercooled water: \eqn{a = 7.6}, \eqn{b = 240.7}
#' - Over ice: \eqn{a = 9.5}, \eqn{b = 265.5}
#'
#' @param a Constant a, default is 7.5 over water.
#' @param b Constant b, default is 235 over water.
#' @examples
#' # Calculate saturation vapor pressure at a temperature of 20°C
#' pres_sat_vapor_p(temp = 20)
#' @references Bendix 2004, p. 261.
#' @export
pres_sat_vapor_p <- function(...) {
  UseMethod("pres_sat_vapor_p")
}

#' @rdname pres_sat_vapor_p
#' @export
pres_sat_vapor_p.default <- function(temp, ..., a = 7.5, b = 235) {
  6.1078 * 10^((a * temp) / (b + temp))
}

#' @rdname pres_sat_vapor_p
#' @export
pres_sat_vapor_p.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(pres_sat_vapor_p.default)
  a <- a[1:(length(a)-3)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }
  pres_sat_vapor_p(temp, ...)
}

#' Air Density
#'
#' Calculates the air density.
#'
#' @rdname pres_air_density
#' @param ... Additional arguments.
#' @param elev Elevation above sea level in m.
#' @param temp Air temperature in degrees C.
#' @param weather_station A weather_station object.
#' @return Air density in kg/m³.
#' @details
#' The air density (\eqn{\rho}) is calculated using the formula:
#' \deqn{\rho = \frac{p \cdot 100}{R \cdot T}}
#' where:
#' \eqn{p} is the air pressure in hPa,
#' \eqn{R} is the specific gas constant for air (287.05 m²/s²/K), and
#' \eqn{T} is the temperature in Kelvin (K).
#'
#' @examples
#' # Calculate air density at an elevation of 500 meters and temperature of 15°C
#' pres_air_density(elev = 500, temp = 15)
#' @export
pres_air_density <- function(...) {
  UseMethod("pres_air_density")
}

#' @rdname pres_air_density
#' @export
pres_air_density.weather_station <- function(weather_station, ...) {
  check_availability(weather_station, "elev", "temp")
  elev <- weather_station$elev
  temp <- weather_station$temp
  return(pres_air_density(elev, temp))
}

#' @rdname pres_air_density
#' @export
pres_air_density.default <- function(elev, temp, ...) {
  p <- pres_p(elev, temp)
  (p * 100) / (287.05 * (temp + 273.15))
}
