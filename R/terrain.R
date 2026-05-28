#' Sky View Factor
#'
#' Calculates the sky view factor, which represents how much sky can be seen from a given point.
#'
#' @param slope Slope of the terrain in degrees.
#' @param valley Logical value indicating if the location is in a valley (TRUE) or not (FALSE).
#' @param ... Additional arguments passed to other methods.
#' @param weather_station A weather_station object.
#' @return Ratio from 0 to 1, unitless, representing the sky view factor.
#' @details The sky view factor (\eqn{SVF}) is calculated as:
#' \deqn{SVF = \frac{1 + \cos(\theta)}{2}} for non-valley locations,
#' and \deqn{SVF = \cos(\theta)} for valley locations,
#' where \eqn{\theta} is the slope angle.
#'
#' The terrain view factor can be calculated by `1 - terr_sky_view()`, which represents how much terrain can be seen from the point.
#'
#' @references Bendix 2004, p. 63 eq. 3.15.
#' @examples
#' # Sky view factor for a slope of 30 degrees not in a valley
#' terr_sky_view(slope = 30, valley = FALSE)
#'
#' # Sky view factor for a slope of 30 degrees in a valley
#' terr_sky_view(slope = 30, valley = TRUE)
#' @export
terr_sky_view <- function(...) {
  UseMethod("terr_sky_view")
}

#' @rdname terr_sky_view
#' @export
terr_sky_view.default <- function(slope, valley, ...) {
  slope <- deg2rad(slope)

  if (!valley) {
    return((1 + cos(slope)) / 2)
  } else {
    return(cos(slope))
  }
}

#' @rdname terr_sky_view
#' @export
terr_sky_view.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(terr_sky_view.default)
  a <- a[1:(length(a) - 1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  terr_sky_view(slope, valley)
}


#' Terrain Angle
#'
#' Calculates the angle between the terrain slope and the incoming solar radiation.
#'
#' @param datetime POSIXlt or POSIXct object representing the date and time.
#' @param lon Longitude in decimal degrees.
#' @param lat Latitude in decimal degrees.
#' @param slope Slope of the terrain in degrees.
#' @param exposition Exposition of the slope in degrees (direction the slope faces).
#' @param ... Additional arguments passed to other methods.
#' @param weather_station A weather_station object.
#' @return Angle in degrees between the terrain slope and the incoming solar radiation.
#' @details The terrain angle (\eqn{\theta_t}) is calculated as:
#' \deqn{\theta_t = \arccos\left(\cos(\theta_s) \cdot \sin(\alpha) + \sin(\theta_s) \cdot \cos(\alpha) \cdot \cos(\phi - \beta)\right)}
#' where:
#' \eqn{\theta_s} is the slope angle,
#' \eqn{\alpha} is the solar elevation angle,
#' \eqn{\phi} is the solar azimuth angle, and
#' \eqn{\beta} is the slope exposition angle.
#'
#' @references Bendix 2004, p. 52 eq. 3.7.
#' @examples
#' # Calculate terrain angle for a given datetime, location, and slope
#' datetime <- as.POSIXlt("2023-08-06 12:00:00", tz = "UTC")
#' terr_terrain_angle(datetime, lon = 8.6841, lat = 50.1109, slope = 30, exposition = 90)
#' @export
terr_terrain_angle <- function(...) {
  UseMethod("terr_terrain_angle")
}

#' @rdname terr_terrain_angle
#' @export
terr_terrain_angle.default <- function(datetime, lon, lat, slope, exposition, ...) {
  elevation <- sol_elevation(datetime, lon, lat)
  azimuth <- sol_azimuth(datetime, lon, lat)

  slope <- deg2rad(slope)
  elevation <- deg2rad(elevation)
  azimuth <- deg2rad(azimuth)
  exposition <- deg2rad(exposition)

  out <- acos(
    cos(slope) * sin(elevation) +
      sin(slope) * cos(elevation) * cos(azimuth - exposition)
  )
  rad2deg(out)
}

#' @rdname terr_terrain_angle
#' @export
terr_terrain_angle.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(terr_terrain_angle.default)
  a <- a[1:(length(a) - 1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  terr_terrain_angle(datetime, lon, lat, slope, exposition)
}
