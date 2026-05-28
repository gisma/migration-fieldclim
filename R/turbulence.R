#' Roughness length
#'
#' Calculates the roughness length of a surface based on the obstacle height or the type of the surface.
#'
#' Possible surface types are:
#' "field", "acre", "lawn", "street", "agriculture", "settlement", "coniferous forest", "deciduous forest", "mixed forest", "city", "water", "shrub".
#'
#' You need to specify only one of `surface_type` or `obs_height`.
#'
#' @param ... Additional arguments.
#' @return Numeric. Roughness length in meters (m).
#' @details
#' This function calculates the roughness length (\eqn{z_0}) of a surface. The roughness length is a measure of the roughness of the surface,
#' which affects the wind profile near the ground. It can be calculated either based on the height of obstacles on the surface or by specifying
#' the type of surface.
#'
#' When the obstacle height (`obs_height`) is provided, the roughness length is calculated as 10% of the obstacle height.
#'
#' When the surface type (`surface_type`) is provided, the roughness length is looked up from predefined values.
#'
#' @examples
#' # Calculates roughness length based on obstacle height
#' turb_roughness_length(obs_height = 10)
#'
#' # Calculate roughness length based on surface type
#' turb_roughness_length(surface_type = "deciduous forest")
#'
#' @references Bendix 2004, p. 239
#' @export
turb_roughness_length <- function(...) {
  UseMethod("turb_roughness_length")
}

#' @rdname turb_roughness_length
#' @param surface_type Type of surface. Options: r surface_properties$surface_type
#' @param obs_height Height of obstacle in meters (m).
#' @param ... Additional arguments.
#' @return Numeric. Roughness length in meters (m).
#' @export
turb_roughness_length.default <- function(surface_type = NULL, obs_height = NULL, ...) {
  surface_properties <- surface_properties
  if (!is.null(obs_height)) {
    return(obs_height * 0.1)
  } else if (!is.null(surface_type)) {
    z0 <- surface_properties[surface_properties$surface_type == surface_type, "roughness_length"]
    if (length(z0) == 0) stop("Invalid surface type.")
    return(z0)
  } else {
    stop("The input is not valid. Please check the input values.")
  }
}


#' @rdname turb_roughness_length
#' @param weather_station Object of class weather_station
#' @param ... Additional arguments.
#' @method turb_roughness_length weather_station
#' @export
#'
turb_roughness_length.weather_station <- function(weather_station, ...) {
  obs_height <- weather_station$obs_height
  surface_type <- weather_station$surface_type
  if (!is.null(obs_height)) {
    check_availability(weather_station, "obs_height")
    return(turb_roughness_length(obs_height = obs_height))
  } else {
    check_availability(weather_station, "surface_type")
    return(turb_roughness_length(surface_type = surface_type))
  }
}


#' Displacement height
#'
#' Calculates the displacement height caused by an obstacle (e.g., a crop field). This function works for both vegetation and urban environments.
#'
#' @rdname turb_displacement
#' @param ... Additional arguments.
#' @export
turb_displacement <- function(...) {
  UseMethod("turb_displacement")
}

#' @rdname turb_displacement
#' @param obs_height Numeric. Height of vegetation or buildings in meters (m).
#' @param surroundings Character. Type of surroundings. Options: "vegetation" or "city".
#' @return Numeric. Displacement height in meters (m).
#' @details
#' This function calculates the displacement height (\eqn{d}) caused by an obstacle, such as vegetation or buildings. The displacement height is an important parameter in boundary layer meteorology as it affects the wind profile near the ground.
#'
#' For vegetation, the displacement height is calculated as two-thirds of the obstacle height.
#'
#' For urban environments (dense housing), the displacement height is calculated as 80% of the obstacle height.
#'
#' @examples
#' # Calculate displacement height for vegetation with a height of 10 meters
#' turb_displacement(obs_height = 10, surroundings = "vegetation")
#'
#' # Calculate displacement height for a city with buildings of height 10 meters
#' turb_displacement(obs_height = 10, surroundings = "city")
#'
#' @references
#' Bendix, J. (2004). Weather and Climate: An Introduction. Springer.
#'
#' @export
turb_displacement.default <- function(obs_height, surroundings = "vegetation", ...) {
  if (surroundings == "vegetation") {
    return((2 / 3) * obs_height) # for vegetation
  } else if (surroundings == "city") {
    return(0.8 * obs_height) # for dense housing
  } else {
    stop("Please set 'surroundings' to either 'vegetation' or 'city'.")
  }
}

#' @rdname turb_displacement
#' @param weather_station Object of class weather_station
#' @export
turb_displacement.weather_station <- function(weather_station, surroundings = "vegetation", ...) {
  check_availability(weather_station, "obs_height")
  obs_height <- weather_station$obs_height
  return(turb_displacement(obs_height, surroundings))
}


#' Friction velocity
#'
#' Calculates the friction velocity of the surface.
#'
#' @rdname turb_ustar
#' @param ... Additional arguments.
#' @param weather_station A weather_station object.
#' @return Numeric. Friction velocity in meters per second (m/s).
#' @references Bendix 2004, p. 239
#' @export
turb_ustar <- function(...) {
  UseMethod("turb_ustar")
}

#' @rdname turb_ustar
#' @param v Numeric. Windspeed at the height of the anemometer in meters per second (m/s).
#' @param z Numeric. Height of the anemometer in meters (m).
#' @param surface_type Character. Type of surface. Options: "field", "acre", "lawn", "street", "agriculture", "settlement", "coniferous forest", "deciduous forest", "mixed forest", "city", "water", "shrub".
#' @param obs_height Numeric. Height of obstacle in meters (m).
#' @param ... Additional arguments.
#' @return Numeric. Friction velocity in meters per second (m/s).
#' @details
#' This function calculates the friction velocity (\eqn{u_*}) of the surface, which is a measure of the shear stress exerted by the wind on the surface. The friction velocity is important in boundary layer meteorology for understanding momentum transfer.
#'
#' The friction velocity is calculated using the formula:
#' \deqn{u_* = \frac{v \cdot 0.4}{\log(z / z_0)}}
#' where \eqn{v} is the windspeed at the height of the anemometer, \eqn{z} is the height of the anemometer, and \eqn{z_0} is the roughness length.
#'
#' The roughness length (\eqn{z_0}) can be determined based on the obstacle height (`obs_height`) or the type of surface (`surface_type`).
#'
#' @examples
#' # Calculate friction velocity based on obstacle height
#' turb_ustar(v = 5, z = 10, obs_height = 1)
#'
#' # Calculate friction velocity based on surface type
#' turb_ustar(v = 5, z = 10, surface_type = "lawn")
#'
#' @export
turb_ustar.default <- function(v, z, surface_type = NULL, obs_height = NULL, ...) {
  if (!is.null(obs_height)) {
    z0 <- turb_roughness_length(obs_height = obs_height)
  } else if (!is.null(surface_type)) {
    z0 <- turb_roughness_length(surface_type = surface_type)
  } else {
    stop("The input is not valid. Either obs_height or surface_type has to be defined.")
  }

  ustar <- (v * 0.4) / log(z / z0)

  if (any(is.infinite(ustar))) {
    warning("One or more ustar values are infinite. They are set to NA.")
    ustar[is.infinite(ustar)] <- NA
  }

  return(ustar)
}

#' @rdname turb_ustar
#' @export
turb_ustar.weather_station <- function(weather_station, obs_height = NULL, ...) {
  check_availability(weather_station, "v2", "z2")
  v <- weather_station$v2
  z <- weather_station$z2
  obs_height <- weather_station$obs_height
  if (!is.null(obs_height)) {
    return(turb_ustar(v, z, obs_height = obs_height))
  } else {
    check_availability(weather_station, "surface_type")
    surface_type <- weather_station$surface_type
    return(turb_ustar(v, z, surface_type = surface_type))
  }
}

