#' Transmittance due to gas
#'
#' Calculates transmittance due to O\eqn{_2} and CO\eqn{_2}.
#'
#' @param datetime POSIXlt object, date and time of the observation.
#' @param lon Longitude in decimal degrees.
#' @param lat Latitude in decimal degrees.
#' @param elev Elevation above sea level in meters.
#' @param temp Air temperature in °C.
#' @param ... Additional arguments.
#' @return Transmittance ratio from 0 to 1, unitless.
#' @details
#' The transmittance due to gases is calculated using the formula:
#' \deqn{T_{gas} = \exp(-0.0127 \cdot M_{abs}^{0.26})}
#' where \eqn{M_{abs}} is the absolute optical air mass.
#' @examples
#' # Calculate transmittance due to gas
#' trans_gas(datetime = as.POSIXlt("2023-08-06 12:00:00", tz = "UTC"), lon = 8.68, lat = 50.77, elev = 100, temp = 20)
#' @references Bendix 2004, p. 246.
#' @export
trans_gas <- function(...) {
  UseMethod("trans_gas")
}

#' @rdname trans_gas
#' @export
trans_gas.default <- function(datetime, lon, lat, elev, temp, ...) {
  air_mass_abs <- trans_air_mass_abs(datetime, lon, lat, elev, temp, ...)
  exp(-0.0127 * air_mass_abs^0.26)
}

#' @rdname trans_gas
#' @export
trans_gas.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(trans_gas.default)
  a <- a[1:(length(a)-1)]
  for (i in a) {
    assign(i, weather_station[[i]])
  }
  trans_gas(datetime, lon, lat, elev, temp, ...)
}



#' Absolute optical air mass
#'
#' Calculates the absolute optical air mass.
#'
#' @param datetime POSIXlt object, date and time of the observation.
#' @param lon Longitude in decimal degrees.
#' @param lat Latitude in decimal degrees.
#' @param elev Elevation above sea level in meters.
#' @param temp Air temperature in °C.
#' @param ... Additional arguments.
#' @return Absolute optical air mass, unitless.
#' @details
#' The absolute optical air mass is calculated using the formula:
#' \deqn{M_{abs} = M_{rel} \cdot \frac{p}{p_0}}
#' where \eqn{M_{rel}} is the relative optical air mass, \eqn{p} is the local air pressure, and \eqn{p_0} is the standard pressure (1013.25 hPa).
#' @examples
#' # Calculate absolute optical air mass
#' trans_air_mass_abs(datetime = as.POSIXlt("2023-08-06 12:00:00", tz = "UTC"), lon = 8.68, lat = 50.77, elev = 100, temp = 20)
#' @references Bendix 2004, p. 247.
#' @export
trans_air_mass_abs <- function(...) {
  UseMethod("trans_air_mass_abs")
}

#' @rdname trans_air_mass_abs
#' @export
trans_air_mass_abs.default <- function(datetime, lon, lat, elev, temp, ...) {
  air_mass_rel <- trans_air_mass_rel(datetime, lon, lat)
  p <- pres_p(elev, temp, ...)
  p0 <- p0_default
  air_mass_rel * (p / p0)
}

#' @rdname trans_air_mass_abs
#' @export
trans_air_mass_abs.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(trans_air_mass_abs.default)
  a <- a[1:(length(a)-1)]
  for (i in a) {
    assign(i, weather_station[[i]])
  }
  trans_air_mass_abs(datetime, lon, lat, elev, temp, ...)
}

#' Relative optical air mass
#'
#' Calculates the relative optical air mass.
#'
#' @param datetime POSIXlt object, date and time of the observation.
#' @param lon Longitude in decimal degrees.
#' @param lat Latitude in decimal degrees.
#' @param ... Additional arguments.
#' @return Relative optical air mass, unitless.
#' @details
#' The relative optical air mass is calculated using the formula:
#' \deqn{M_{rel} = \frac{1}{\sin(elevation) + 1.5 \cdot elevation^{-0.72}}}
#' where \eqn{elevation} is the solar elevation angle in degrees.
#' @examples
#' # Calculate relative optical air mass
#' trans_air_mass_rel(datetime = as.POSIXlt("2023-08-06 12:00:00", tz = "UTC"), lon = 8.68, lat = 50.77)
#' @references Bendix 2004, p. 246.
#' @export
trans_air_mass_rel <- function(...) {
  UseMethod("trans_air_mass_rel")
}

#' @rdname trans_air_mass_rel
#' @export
trans_air_mass_rel.default <- function(datetime, lon, lat, ...) {
  elevation <- sol_elevation(datetime, lon, lat)
  1 / (sin(deg2rad(elevation)) + 1.5 * elevation^-0.72)
}

#' @rdname trans_air_mass_rel
#' @export
trans_air_mass_rel.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(trans_air_mass_rel.default)
  a <- a[1:(length(a)-1)]
  for (i in a) {
    assign(i, weather_station[[i]])
  }
  trans_air_mass_rel(datetime, lon, lat)
}

#' Transmittance due to ozone
#'
#' Calculates transmittance due to atmospheric ozone.
#'
#' @param datetime POSIXlt object, date and time of the observation.
#' @param lon Longitude in decimal degrees.
#' @param lat Latitude in decimal degrees.
#' @param ozone_column Atmospheric ozone as column in cm, default `ozone_column_default`.
#' @param ... Additional arguments.
#' @return Transmittance ratio from 0 to 1, unitless.
#' @details
#' The transmittance due to ozone is calculated using the formula:
#' \deqn{T_{ozone} = 1 - (0.1611 \cdot x \cdot (1 + 139.48 \cdot x)^{-0.3035} - 0.002715 \cdot x \cdot (1 + 0.044 \cdot x + 0.0003 \cdot x^2)^{-1})}
#' where \eqn{x} is the product of the ozone column and the relative optical air mass.
#' @examples
#' # Calculate transmittance due to ozone
#' trans_ozone(datetime = as.POSIXlt("2023-08-06 12:00:00", tz = "UTC"), lon = 8.68, lat = 50.77, ozone_column = 0.3)
#' @references Bendix 2004, p. 245.
#' @export
trans_ozone <- function(...) {
  UseMethod("trans_ozone")
}

#' @rdname trans_ozone
#' @export
trans_ozone.default <- function(datetime, lon, lat, ..., ozone_column = ozone_column_default) {
  air_mass_rel <- trans_air_mass_rel(datetime, lon, lat)
  x <- ozone_column * air_mass_rel
  1 - (
    0.1611 * x * (1 + 139.48 * x)^-0.3035 -
      0.002715 * x * (1 + 0.044 * x + 0.0003 * x^2)^-1
  )
}

#' @rdname trans_ozone
#' @export
trans_ozone.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(trans_ozone.default)
  a <- a[1:(length(a)-2)]
  for (i in a) {
    assign(i, weather_station[[i]])
  }
  trans_ozone(datetime, lon, lat, ...)
}


#' Transmittance due to rayleigh scattering
#'
#' Calculates transmittance due to Rayleigh scattering.
#'
#' @param datetime POSIXlt object, date and time of the observation.
#' @param lon Longitude in decimal degrees.
#' @param lat Latitude in decimal degrees.
#' @param elev Elevation above sea level in meters.
#' @param temp Air temperature in °C.
#' @param ... Additional arguments.
#' @return Transmittance ratio from 0 to 1, unitless.
#' @details
#' The transmittance due to Rayleigh scattering is calculated using the formula:
#' \deqn{T_{rayleigh} = \exp(-0.0903 \cdot M_{abs}^{0.84} \cdot (1 + M_{abs} - M_{abs}^{1.01}))}
#' where \eqn{M_{abs}} is the absolute optical air mass.
#' @examples
#' # Calculate transmittance due to rayleigh scattering
#' trans_rayleigh(datetime = as.POSIXlt("2023-08-06 12:00:00", tz = "UTC"), lon = 8.68, lat = 50.77, elev = 100, temp = 20)
#' @references Bendix 2004, p. 245.
#' @export
trans_rayleigh <- function(...) {
  UseMethod("trans_rayleigh")
}

#' @rdname trans_rayleigh
#' @export
trans_rayleigh.default <- function(datetime, lon, lat, elev, temp, ...) {
  air_mass_abs <- trans_air_mass_abs(datetime, lon, lat, elev, temp, ...)
  exp(-0.0903 * air_mass_abs^0.84 * (1 + air_mass_abs - air_mass_abs^1.01))
}

#' @rdname trans_rayleigh
#' @export
trans_rayleigh.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(trans_rayleigh.default)
  a <- a[1:(length(a)-1)]
  for (i in a) {
    assign(i, weather_station[[i]])
  }
  trans_rayleigh(datetime, lon, lat, elev, temp, ...)
}

#' Transmittance due to water vapor
#'
#' Calculates transmittance due to water vapor.
#'
#' @param datetime POSIXlt object, date and time of the observation.
#' @param lon Longitude in decimal degrees.
#' @param lat Latitude in decimal degrees.
#' @param elev Elevation above sea level in meters.
#' @param temp Air temperature in °C.
#' @param ... Additional arguments.
#' @return Transmittance ratio from 0 to 1, unitless.
#' @details
#' The transmittance due to water vapor is calculated using the formula:
#' \deqn{T_{vapor} = 1 - 2.4959 \cdot x \cdot ((1 + 79.034 \cdot x)^{0.6828} + 6.385 \cdot x)^{-1}}
#' where \eqn{x} is the product of the precipitable water and the relative optical air mass.
#' @examples
#' # Calculate transmittance due to water vapor
#' trans_vapor(datetime = as.POSIXlt("2023-08-06 12:00:00", tz = "UTC"), lon = 8.68, lat = 50.77, elev = 100, temp = 20)
#' @references Bendix 2004, p. 245.
#' @export
trans_vapor <- function(...) {
  UseMethod("trans_vapor")
}

#' @rdname trans_vapor
#' @export
trans_vapor.default <- function(datetime, lon, lat, elev, temp, ...) {
  precipitable_water <- hum_precipitable_water(datetime, lat, elev, temp, ...)
  air_mass_rel <- trans_air_mass_rel(datetime, lon, lat)
  x <- precipitable_water * air_mass_rel
  1 - 2.4959 * x * ((1 + 79.034 * x)^0.6828 + 6.385 * x)^-1
}

#' @rdname trans_vapor
#' @export
trans_vapor.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(trans_vapor.default)
  a <- a[1:(length(a)-1)]
  for (i in a) {
    assign(i, weather_station[[i]])
  }
  trans_vapor(datetime, lon, lat, elev, temp, ...)
}

#' Transmittance due to aerosols
#'
#' Calculates transmittance due to fine particles in the air.
#'
#' @param datetime POSIXlt object, date and time of the observation.
#' @param lon Longitude in decimal degrees.
#' @param lat Latitude in decimal degrees.
#' @param elev Elevation above sea level in meters.
#' @param temp Air temperature in °C.
#' @param vis Visibility in km, default `vis_default`.
#' @param ... Additional arguments.
#' @return Transmittance ratio from 0 to 1, unitless.
#' @details
#' The transmittance due to aerosols is calculated using the formula:
#' \deqn{T_{aerosol} = \exp(-x^{0.873} \cdot (1 + x - x^{0.7088}) \cdot M_{abs}^{0.9108})}
#' where \eqn{x} is a function of the visibility and \eqn{M_{abs}} is the absolute optical air mass.
#' @examples
#' # Calculate transmittance due to aerosols
#' trans_aerosol(datetime = as.POSIXlt("2023-08-06 12:00:00", tz = "UTC"), lon = 8.68, lat = 50.77, elev = 100, temp = 20, vis = 50)
#' @references Bendix 2004, p. 246.
#' @export
trans_aerosol <- function(...) {
  UseMethod("trans_aerosol")
}

#' @rdname trans_aerosol
#' @export
trans_aerosol.default <- function(datetime, lon, lat, elev, temp, ..., vis = vis_default) {
  air_mass_abs <- trans_air_mass_abs(datetime, lon, lat, elev, temp, ...)
  df <- data.frame(
    vis = seq(10, 60, 10),
    tau38 = c(0.71, 0.43, 0.33, 0.27, 0.22, 0.20),
    tau50 = c(0.46, 0.28, 0.21, 0.17, 0.14, 0.13)
  )
  mod38 <- stats::lm(log(df$tau38) ~ log(df$vis))
  mod50 <- stats::lm(log(df$tau50) ~ log(df$vis))
  tau38 <- exp(mod38$coefficients[[1]]) * vis^mod38$coefficients[[2]]
  tau50 <- exp(mod50$coefficients[[1]]) * vis^mod50$coefficients[[2]]
  x <- 0.2758 * tau38 + 0.35 * tau50
  exp(-x^0.873 * (1 + x - x^0.7088) * air_mass_abs^0.9108)
}

#' @rdname trans_aerosol
#' @export
trans_aerosol.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(trans_aerosol.default)
  a <- a[1:(length(a)-2)]
  for (i in a) {
    assign(i, weather_station[[i]])
  }
  trans_aerosol(datetime, lon, lat, elev, temp, ...)
}
