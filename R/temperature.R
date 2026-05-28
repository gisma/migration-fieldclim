#' Potential Temperature
#'
#' Calculates the potential air temperature, which is the temperature that a parcel of air would have if it were expanded or compressed adiabatically to a standard pressure (usually 1000 hPa).
#'
#' @param ... Additional arguments.
#' @param weather_station A weather_station object.
#' @return Potential temperature in °C.
#' @details
#' The potential temperature (\eqn{\theta}) is calculated using the formula:
#' \deqn{\theta = T \left(\frac{p_0}{p}\right)^{R/c_p}}
#' where:
#' \eqn{T} is the temperature in Kelvin,
#' \eqn{p_0} is the standard pressure (1000 hPa),
#' \eqn{p} is the actual pressure,
#' \eqn{R} is the specific gas constant for dry air (287 J/(kg·K)),
#' \eqn{c_p} is the specific heat at constant pressure (1004 J/(kg·K)).
#'
#' The argument \code{elev} is elevation above sea level in m. It is
#' converted internally to pressure using \code{pres_p()}. The 1013.25 hPa
#' default in \code{pres_p()} is used for pressure estimation, while
#' potential temperature uses 1000 hPa as the reference pressure.
#'
#' @references Bendix 2004, p. 261.
#' @examples
#' # Calculate potential temperature at a given temperature and elevation
#' temp_pot_temp(t = 20, elev = 500)
#' @export
temp_pot_temp <- function(...) {
  UseMethod("temp_pot_temp")
}

#' @rdname temp_pot_temp
#' @param t Temperature in °C.
#' @param elev Elevation above sea level in m.
#' @export
temp_pot_temp.default <- function(t, elev, ...) {
  p0 <- 1000 # standard air pressure in hPa
  p <- pres_p(elev, t, ...) # calculate air pressure
  air_const <- 0.286 # specific gas constant / specific heat capacity
  t <- c2k(t) # to Kelvin
  k2c(t * (p0 / p)**air_const)
}

#' @rdname temp_pot_temp
#' @param height Height of measurement, either "upper" or "lower".
#' @export
temp_pot_temp.weather_station <- function(weather_station, height = "lower", ...) {
  if (height == "lower") {
    check_availability(weather_station, "t1", "elev")
    t <- weather_station$t1
    elev <- weather_station$elev
  } else if (height == "upper") {
    check_availability(weather_station, "t2", "elev")
    t <- weather_station$t2
    elev <- weather_station$elev
  }
  return(temp_pot_temp(t, elev))
}
