#' Eccentricity factor
#'
#' The track of Earth around the Sun is not a circle, but more like an ellipse.
#'
#' @inheritParams build_weather_station
#' @param datetime POSIXlt or POSIXct date-time vector.
#' @param weather_station A weather_station object.
#' @returns Unitless.
#' @details
#' The eccentricity factor (\eqn{E}) accounts for the elliptical shape of Earth's orbit around the Sun. It is calculated as:
#' \deqn{E = 1.00011 + 0.034221 \cdot \cos(D) + 0.00128 \cdot \sin(D) + 0.000719 \cdot \cos(2D) + 0.000719 \cdot \sin(2D)}
#' where:
#' \eqn{D} is the day angle in radians.
#' @references Bendix 2004, p. 243.
#' @examples
#' # Calculate eccentricity factor
#' sol_eccentricity(as.POSIXlt("2022-06-21"))
#' @export
sol_eccentricity <- function(...) {
  UseMethod("sol_eccentricity")
}

#' @rdname sol_eccentricity
#' @inheritParams build_weather_station
#' @export
sol_eccentricity.default <- function(datetime, ...) {
  day_angle <- sol_day_angle(datetime)
  day_angle <- deg2rad(day_angle)

  1.00011 + 0.034221 * cos(day_angle) + 0.00128 * sin(day_angle) +
    0.000719 * cos(2 * day_angle) + 0.000719 * sin(2 * day_angle)
}

#' @rdname sol_eccentricity
#' @inheritParams build_weather_station
#' @export
sol_eccentricity.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(sol_eccentricity.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  sol_eccentricity(datetime)
}

#' Day angle
#'
#' See a year as a circle. The first day of a (leap) year is 0 degree
#' and the last day 360 degrees.
#'
#' @inheritParams build_weather_station
#' @param datetime POSIXlt or POSIXct date-time vector.
#' @param weather_station A weather_station object.
#' @returns Degree.
#' @details
#' The day angle (\eqn{D}) is calculated as:
#' \deqn{D = \frac{2\pi(J - 1)}{365}}
#' where:
#' \eqn{J} is the Julian day.
#' @references Bendix 2004, p. 243.
#' @examples
#' # Calculate day angle
#' sol_day_angle(as.POSIXlt("2022-06-21"))
#' @export
sol_day_angle <- function(...) {
  UseMethod("sol_day_angle")
}

#' @rdname sol_day_angle
#' @inheritParams build_weather_station
#' @export
sol_day_angle.default <- function(datetime, ...) {
  julian_day <- sol_julian_day(datetime)

  out <- 2 * pi * (julian_day - 1) / 365
  rad2deg(out)
}

#' @rdname sol_day_angle
#' @inheritParams build_weather_station
#' @export
sol_day_angle.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(sol_day_angle.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  sol_day_angle(datetime)
}

#' Julian day
#'
#' Day of year as an integer from 1 to 366.
#'
#' @inheritParams build_weather_station
#' @returns Unitless.
#' @details
#' The Julian day (\eqn{J}) is the day of the year, ranging from 1 to 366.
#' @examples
#' # Calculate Julian day
#' sol_julian_day(as.POSIXlt("2022-06-21"))
#' @export
sol_julian_day <- function(...) {
  UseMethod("sol_julian_day")
}

#' @inheritParams build_weather_station
#' @export
sol_julian_day.default <- function(datetime, ...) {
  as.integer(format(datetime, format = "%j"))
}

#' @inheritParams build_weather_station
#' @export
sol_julian_day.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(sol_julian_day.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  sol_julian_day(datetime)
}

#' Solar elevation angle
#'
#' @inheritParams build_weather_station
#' @param datetime POSIXlt or POSIXct date-time vector.
#' @param lon Longitude in degrees.
#' @param lat Latitude in degrees.
#' @param weather_station A weather_station object.
#' @returns Degree.
#' @details
#' The solar elevation angle (\eqn{h}) is the apparent angle of the sun above the horizon. It is calculated as:
#' \deqn{h = \arcsin(\sin(\phi) \cdot \sin(\delta) + \cos(\phi) \cdot \cos(\delta) \cdot \cos(H))}
#' where:
#' \eqn{\phi} is the latitude,
#' \eqn{\delta} is the solar declination, and
#' \eqn{H} is the hour angle.
#' @references Bendix 2004, p. 243.
#' @examples
#' # Calculate solar elevation angle
#' sol_elevation(as.POSIXlt("2022-06-21"), lon = 10, lat = 50)
#' @export
sol_elevation <- function(...) {
  UseMethod("sol_elevation")
}

#' @rdname sol_elevation
#' @inheritParams build_weather_station
#' @export
sol_elevation.default <- function(datetime, lon, lat, ...) {
  declination <- sol_declination(datetime)
  hour_angle <- sol_hour_angle(datetime, lon)

  lat <- deg2rad(lat)
  declination <- deg2rad(declination)
  hour_angle <- deg2rad(hour_angle)

  out <- asin(sin(lat) * sin(declination) +
                cos(lat) * cos(declination) * cos(hour_angle))
  rad2deg(out)
}

#' @rdname sol_elevation
#' @inheritParams build_weather_station
#' @export
sol_elevation.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(sol_elevation.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  sol_elevation(datetime, lon, lat)
}

#' Solar declination
#'
#' @inheritParams build_weather_station
#' @param datetime POSIXlt or POSIXct date-time vector.
#' @param weather_station A weather_station object.
#' @returns Degree.
#' @details
#' The solar declination (\eqn{\delta}) is the angle between the rays of the sun and the plane of the Earth's equator. It is calculated as:
#' \deqn{\delta = \arcsin(\sin(23.44^\circ) \cdot \sin(L))}
#' where:
#' \eqn{L} is the ecliptic longitude.
#' @references Bendix 2004, p. 243.
#' @examples
#' # Calculate solar declination
#' sol_declination(as.POSIXlt("2022-06-21"))
#' @export
sol_declination <- function(...) {
  UseMethod("sol_declination")
}

#' @rdname sol_declination
#' @inheritParams build_weather_station
#' @export
sol_declination.default <- function(datetime, ...) {
  ecliptic_length <- sol_ecliptic_length(datetime)
  ecliptic_length <- deg2rad(ecliptic_length)

  out <- asin(sin(deg2rad(23.44)) * sin(ecliptic_length))
  rad2deg(out)
}

#' @rdname sol_declination
#' @inheritParams build_weather_station
#' @export
sol_declination.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(sol_declination.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  sol_declination(datetime)
}


#' Solar ecliptic length
#'
#' Calculates the solar ecliptic length, which is the angle of the Earth's orbit around the sun relative to the vernal equinox.
#'
#' @inheritParams build_weather_station
#' @param datetime POSIXlt or POSIXct date-time vector.
#' @param weather_station A weather_station object.
#' @returns Degree.
#' @details
#' The solar ecliptic length (\eqn{L}) is calculated as:
#' \deqn{L = 279.3 + 0.9856 \cdot J + 1.92 \cdot \sin(M)}
#' where:
#' \eqn{J} is the Julian day,
#' \eqn{M} is the solar medium anomaly in radians.
#' @references Bendix 2004, p. 243.
#' @examples
#' # Calculate solar ecliptic length
#' sol_ecliptic_length(as.POSIXlt("2022-06-21"))
#' @export
sol_ecliptic_length <- function(...) {
  UseMethod("sol_ecliptic_length")
}

#' @rdname sol_ecliptic_length
#' @inheritParams build_weather_station
#' @export
sol_ecliptic_length.default <- function(datetime, ...) {
  julian_day <- sol_julian_day(datetime)
  medium_anomaly <- sol_medium_anomaly(datetime)
  medium_anomaly <- deg2rad(medium_anomaly)

  279.3 + 0.9856 * julian_day + 1.92 * sin(medium_anomaly)
}

#' @rdname sol_ecliptic_length
#' @inheritParams build_weather_station
#' @export
sol_ecliptic_length.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(sol_ecliptic_length.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  sol_ecliptic_length(datetime)
}

#' Solar medium anomaly
#'
#' Calculates the solar medium anomaly, which is the angular distance of the Earth from its perihelion.
#'
#' @inheritParams build_weather_station
#' @param datetime POSIXlt or POSIXct date-time vector.
#' @param weather_station A weather_station object.
#' @returns Degree.
#' @details
#' The solar medium anomaly (\eqn{M}) is calculated as:
#' \deqn{M = 356.6 + 0.9856 \cdot J}
#' where:
#' \eqn{J} is the Julian day.
#' @references Bendix 2004, p. 243.
#' @examples
#' # Calculate solar medium anomaly
#' sol_medium_anomaly(as.POSIXlt("2022-06-21"))
#' @export
sol_medium_anomaly <- function(...) {
  UseMethod("sol_medium_anomaly")
}

#' @rdname sol_medium_anomaly
#' @inheritParams build_weather_station
#' @export
sol_medium_anomaly.default <- function(datetime, ...) {
  julian_day <- sol_julian_day(datetime)

  356.6 + 0.9856 * julian_day
}

#' @rdname sol_medium_anomaly
#' @inheritParams build_weather_station
#' @export
sol_medium_anomaly.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(sol_medium_anomaly.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  sol_medium_anomaly(datetime)
}

#' Solar hour angle
#'
#' Calculates the solar hour angle, which is the measure of time since solar noon in degrees.
#'
#' @inheritParams build_weather_station
#' @param datetime POSIXlt or POSIXct date-time vector.
#' @param lon Longitude in degrees.
#' @param weather_station A weather_station object.
#' @returns Degree.
#' @details
#' The solar hour angle (\eqn{H}) is calculated as:
#' \deqn{H = 15 \cdot (T_m + E_t - 12)}
#' where:
#' \eqn{T_m} is the solar medium suntime,
#' \eqn{E_t} is the solar time formula.
#' @references Bendix 2004, p. 243.
#' @examples
#' # Calculate solar hour angle
#' sol_hour_angle(as.POSIXlt("2022-06-21 12:00:00"), lon = 10)
#' @export
sol_hour_angle <- function(...) {
  UseMethod("sol_hour_angle")
}

#' @rdname sol_hour_angle
#' @inheritParams build_weather_station
#' @export
sol_hour_angle.default <- function(datetime, lon, ...) {
  datetime <- as.POSIXlt(datetime)
  medium_suntime <- datetime$hour + datetime$min / 60 + datetime$sec / 3600
  time_formula <- sol_time_formula(datetime, lon)

  15 * (medium_suntime + time_formula - 12)
}

#' @rdname sol_hour_angle
#' @inheritParams build_weather_station
#' @export
sol_hour_angle.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(sol_hour_angle.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  sol_hour_angle(datetime, lon)
}

#' Solar medium suntime
#'
#' Calculates the solar medium suntime, which is the mean solar time adjusted for the observer's longitude.
#'
#' @inheritParams build_weather_station
#' @param datetime POSIXlt or POSIXct date-time vector.
#' @param lon Longitude in degrees.
#' @param weather_station A weather_station object.
#' @returns Hour.
#' @details
#' The solar medium suntime (\eqn{T_m}) is calculated as:
#' \deqn{T_m = T_{local} + \frac{lon}{15}}
#' where:
#' \eqn{T_{local}} is the local time zone,
#' \eqn{lon} is the longitude of the observer.
#' @references Bendix 2004, p. 243.
#' @examples
#' # Calculate solar medium suntime
#' sol_medium_suntime(as.POSIXlt("2022-06-21 12:00:00"), lon = 10)
#' @export
sol_medium_suntime <- function(...) {
  UseMethod("sol_medium_suntime")
}

#' @rdname sol_medium_suntime
#' @inheritParams build_weather_station
#' @export
sol_medium_suntime.default <- function(datetime, lon, ...) {
  # change to POSIXct and then change back to POSIXlt for timezone conversion
  datetime <- as.POSIXct(datetime)
  datetime <- as.POSIXlt(datetime, tz = "UTC")
  utc <- datetime$hour + datetime$min / 60 + datetime$sec / 3600

  utc + lon / 15
}

#' @rdname sol_medium_suntime
#' @inheritParams build_weather_station
#' @export
sol_medium_suntime.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(sol_medium_suntime.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  sol_medium_suntime(datetime, lon)
}

#' Solar time formula
#'
#' Calculates the solar time formula, which corrects the solar medium suntime to account for the Earth's elliptical orbit and axial tilt.
#'
#' @inheritParams build_weather_station
#' @param datetime POSIXlt or POSIXct date-time vector.
#' @param lon Longitude in degrees.
#' @param weather_station A weather_station object.
#' @returns Hour.
#' @details
#' The solar time formula (\eqn{E_t}) is calculated as:
#' \deqn{E_t = 0.1644 \cdot \sin(2L) - 0.1277 \cdot \sin(M)}
#' where:
#' \eqn{L} is the ecliptic longitude,
#' \eqn{M} is the solar medium anomaly.
#' @references Bendix 2004, p. 243.
#' @examples
#' # Calculate solar time formula
#' sol_time_formula(as.POSIXlt("2022-06-21 12:00:00"), lon = 10)
#' @export
sol_time_formula <- function(...) {
  UseMethod("sol_time_formula")
}

#' @rdname sol_time_formula
#' @inheritParams build_weather_station
#' @export
sol_time_formula.default <- function(datetime, lon, ...) {
  medium_anomaly <- sol_medium_anomaly(datetime)

  lon <- deg2rad(lon)
  medium_anomaly <- deg2rad(medium_anomaly)

  0.1644 * sin(2 * lon) - 0.1277 * sin(medium_anomaly)
}

#' @rdname sol_time_formula
#' @inheritParams build_weather_station
#' @export
sol_time_formula.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(sol_time_formula.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  sol_time_formula(datetime, lon)
}

#' Solar azimuth
#'
#' Calculates the solar azimuth, which is the compass direction from which the sunlight is coming at any specific point on the earth's surface.
#'
#' @inheritParams build_weather_station
#' @param datetime POSIXlt or POSIXct date-time vector.
#' @param lon Longitude in degrees.
#' @param lat Latitude in degrees.
#' @param weather_station A weather_station object.
#' @returns Degree.
#' @details
#' The solar azimuth (\eqn{A}) is calculated as:
#' \deqn{A = \arccos\left(\frac{\sin(\delta) \cdot \cos(\phi) - \cos(\delta) \cdot \sin(\phi) \cdot \cos(H)}{\cos(h)}\right)}
#' where:
#' \eqn{\delta} is the solar declination,
#' \eqn{\phi} is the latitude,
#' \eqn{H} is the hour angle,
#' \eqn{h} is the solar elevation angle.
#' @references Bendix 2004, p. 243.
#' @examples
#' # Calculate solar azimuth
#' sol_azimuth(as.POSIXlt("2022-06-21 12:00:00"), lon = 10, lat = 50)
#' @export
sol_azimuth <- function(...) {
  UseMethod("sol_azimuth")
}

#' @rdname sol_azimuth
#' @inheritParams build_weather_station
#' @export
sol_azimuth.default <- function(datetime, lon, lat, ...) {
  datetime <- as.POSIXlt(datetime)
  declination <- sol_declination(datetime)
  hour_angle <- sol_hour_angle(datetime, lon)
  elevation <- sol_elevation(datetime, lon, lat)
  medium_suntime <- datetime$hour + datetime$min / 60 + datetime$sec / 3600

  declination <- deg2rad(declination)
  lat <- deg2rad(lat)
  hour_angle <- deg2rad(hour_angle)
  elevation <- deg2rad(elevation)

  out <- acos(
    (sin(declination) * cos(lat) -
       cos(declination) * sin(lat) * cos(hour_angle)
    ) / cos(elevation)
  )
  out <- rad2deg(out)

  ifelse(medium_suntime < 12, out, 360 - out)
}

#' @rdname sol_azimuth
#' @inheritParams build_weather_station
#' @export
sol_azimuth.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(sol_azimuth.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  sol_azimuth(datetime, lon, lat)
}

