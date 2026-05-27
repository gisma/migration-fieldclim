#' Mechanical internal boundary layer; lowest height.
#'
#' This function calculates the lowest height of the mechanical internal boundary layer (MIBL).
#' The MIBL height is calculated based on the distance to the point of roughness change using
#' an empirical relationship described by Bendix (2004, p. 242).
#'
#' @param dist Numeric. The distance to the point of roughness change in meters (m).
#' @return Numeric. The height of the boundary layer in meters (m).
#' @details
#' The mechanical internal boundary layer (MIBL) is a concept used in meteorology to describe the
#' layer of air that develops after a change in surface roughness. The height of the MIBL is
#' important for understanding the vertical distribution of wind speed and other meteorological
#' variables.
#'
#' The function uses the formula:
#' \deqn{height = 0.3 \sqrt{dist}}
#' where \eqn{dist} is the distance to the point of roughness change in meters.
#'
#' @examples
#' # Calculate the lowest height of the MIBL for a distance of 100 meters
#' bound_mech_low(100)
#'
#' @references
#' Bendix, J. (2004). Weather and Climate: An Introduction. Springer.
#'
#' @export
bound_mech_low <- function(dist) {
  0.3 * sqrt(dist)
}

#' Mechanical internal boundary layer; average height.
#'
#' This function calculates the average height of the mechanical internal boundary layer (MIBL).
#' The MIBL height is calculated based on the distance to the point of roughness change using
#' an empirical relationship described by Bendix (2004, p. 242).
#'
#' @param dist Numeric. The distance to the point of roughness change in meters (m).
#' @return Numeric. The average height of the boundary layer in meters (m).
#' @details
#' The mechanical internal boundary layer (MIBL) is a concept used in meteorology to describe the
#' layer of air that develops after a change in surface roughness. The height of the MIBL is
#' important for understanding the vertical distribution of wind speed and other meteorological
#' variables.
#'
#' The function uses the formula:
#' \deqn{height = 0.43 \sqrt{dist}}
#' where \eqn{dist} is the distance to the point of roughness change in meters.
#'
#' @examples
#' # Calculate the average height of the MIBL for a distance of 100 meters
#' bound_mech_avg(100)
#'
#' @references
#' Bendix, J. (2004). Weather and Climate: An Introduction. Springer.
#'
#' @export
bound_mech_avg <- function(dist) {
  0.43 * sqrt(dist)
}

#' Thermal internal boundary layer.
#'
#' This function calculates the average height of the thermal internal boundary layer (TIBL).
#' The TIBL height is calculated based on various meteorological parameters such as windspeed,
#' height of the anemometer, type of surface, distance to the point of temperature change,
#' potential temperatures, and lapse rate, following the method described by Bendix (2004, p. 242).
#'
#' @param v Numeric. The windspeed at the height of the anemometer in meters per second (m/s).
#' @param z Numeric. The height of the anemometer in meters (m).
#' @param surface_type Character. The type of surface. Options: "field", "acre", "lawn", "street", "agriculture", "settlement", "coniferous forest", "deciduous forest", "mixed forest", "city", "water", "shrub". Either `surface_type` or `obs_height` must be provided.
#' @param temp_change_dist Numeric. The distance to the point of temperature change in meters (m).
#' @param t_pot_upwind Numeric. The potential temperature in the upwind direction in degrees Celsius (°C).
#' @param t_pot Numeric. The potential temperature at the site in degrees Celsius (°C).
#' @param lapse_rate Numeric. The lapse rate in degrees Celsius per meter (°C/m).
#' @param obs_height Numeric. The observation height for roughness length calculation in meters (m). Either `obs_height` or `surface_type` must be provided.
#' @return Numeric. The average height of the thermal boundary layer in meters (m).
#' @details
#' The thermal internal boundary layer (TIBL) forms as air flows over a surface with a different temperature, causing thermal stratification.
#' This function computes the average height of the TIBL, which is influenced by windspeed, temperature differences, and the atmospheric lapse rate.
#'
#' The function uses the formula:
#' \deqn{height = \frac{u_*}{v} \sqrt{\frac{d \Delta \theta}{\gamma}}}
#' where \eqn{u_*} is the friction velocity, \eqn{v} is the windspeed, \eqn{d} is the distance to the temperature change point,
#' \eqn{\Delta \theta} is the potential temperature difference, and \eqn{\gamma} is the lapse rate.
#'
#' @examples
#' # Calculate the average height of the TIBL with given parameters
#' bound_thermal_avg(v = 5, z = 10, temp_change_dist = 500, t_pot_upwind = 15, t_pot = 20, lapse_rate = 0.0065, surface_type = "lawn")
#'
#' @references
#' Bendix, J. (2004). Weather and Climate: An Introduction. Springer.
#'
#' @export
bound_thermal_avg <- function(v, z, temp_change_dist, t_pot_upwind, t_pot, lapse_rate,
                              surface_type = NULL, obs_height = NULL) {
  # Calculate ustar
  if (!is.null(obs_height)) {
    ustar <- turb_ustar(v = v, z = z, obs_height = obs_height)
  } else if (!is.null(surface_type)) {
    ustar <- turb_ustar(v = v, z = z, surface_type = surface_type)
  } else {
    stop("The input is not valid. Either obs_height or surface_type has to be defined.")
  }
  (ustar / v) * sqrt((temp_change_dist * abs(t_pot_upwind - t_pot)) / abs(lapse_rate))
}
