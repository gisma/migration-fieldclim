#' Soil Heat Flux
#'
#' Calculates soil heat flux from measurements in two different depths and thermal conductivity of the soil.
#' Negative values signify flux towards the atmosphere, while positive values signify flux into the soil.
#'
#' @param ... Additional arguments.
#' @param weather_station A weather_station object.
#' @return Soil heat flux in W/m².
#' @details
#' The soil heat flux (\eqn{G}) is calculated using the formula:
#' \deqn{G = -\lambda \cdot \frac{T_1 - T_2}{z_1 - z_2}}
#' where:
#' \eqn{\lambda} is the thermal conductivity of the soil (W/m/K),
#' \eqn{T_1} and \eqn{T_2} are the temperatures at two different depths (°C),
#' \eqn{z_1} and \eqn{z_2} are the depths at which the temperatures are measured (m).
#'
#' @references Bendix 2004, p. 71 eq. 4.2.
#' @examples
#' # Calculate soil heat flux
#' soil_heat_flux(texture = "sand", moisture = 0.25, soil_temp1 = 15, soil_temp2 = 10, soil_depth1 = 0.1, soil_depth2 = 0.3)
#' @export
soil_heat_flux <- function(...) {
  UseMethod("soil_heat_flux")
}

#' @rdname soil_heat_flux
#' @param texture Soil texture. Either "sand", "peat" or "clay".
#' @param moisture Soil moisture content in cubic meters per cubic meter.
#' @param soil_temp1 Temperature at the first depth in °C.
#' @param soil_temp2 Temperature at the second depth in °C.
#' @param soil_depth1 Depth of the first measurement in m.
#' @param soil_depth2 Depth of the second measurement in m.
#' @export
soil_heat_flux.default <- function(texture, moisture, soil_temp1, soil_temp2, soil_depth1, soil_depth2, ...) {
  thermal_cond <- soil_thermal_cond(texture, moisture)
  -thermal_cond * (soil_temp1 - soil_temp2) / (soil_depth1 - soil_depth2)
}

#' @rdname soil_heat_flux
#' @export
soil_heat_flux.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(soil_heat_flux.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  soil_heat_flux(texture, moisture, soil_temp1, soil_temp2, soil_depth1, soil_depth2)
}


#' Soil Thermal Conductivity
#'
#' Calculates soil thermal conductivity from soil texture and soil moisture.
#' Works by linearly interpolating thermal conductivity based on measured data.
#'
#' @param ... Additional arguments.
#' @param weather_station A weather_station object.
#' @return Soil thermal conductivity in W/m/K.
#' @details
#' The thermal conductivity (\eqn{\lambda}) of the soil is determined based on its texture and moisture content.
#' The values are interpolated from measured data for different soil types.
#'
#' @references Bendix 2004, p. 254.
#' @examples
#' # Calculate soil thermal conductivity
#' soil_thermal_cond(texture = "sand", moisture = 0.25)
#' @export
soil_thermal_cond <- function(...) {
  UseMethod("soil_thermal_cond")
}

#' @rdname soil_thermal_cond
#' @param texture Soil texture. Either "sand", "peat" or "clay".
#' @param moisture Soil moisture content in cubic meters per cubic meter.
#' @export
soil_thermal_cond.default <- function(texture, moisture, ...) {
  moisture <- moisture * 100 # convert to Vol-%

  if (texture == "sand") {
    y <- c(0.269, 1.46, 1.98, 2.18, 2.31, 2.49, 2.58)
    x <- c(0, 5, 10, 15, 20, 30, 43)
  } else if (texture == "clay") {
    y <- c(0.276, 0.586, 1.1, 1.43, 1.57, 1.74, 1.95)
    x <- c(0, 5, 10, 15, 20, 30, 43)
  } else if (texture == "peat") {
    y <- c(0.033, 0.042, 0.130, 0.276, 0.421, 0.478, 0.528)
    x <- c(0, 10, 30, 50, 70, 80, 90)
  } else {
    stop("Texture not available. Input has to be either 'sand', 'peat' or 'clay'")
  }

  approx(x, y, moisture)$y
}

#' @rdname soil_thermal_cond
#' @export
soil_thermal_cond.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(soil_thermal_cond.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }

  soil_thermal_cond(texture, moisture)
}


#' Soil Volumetric Heat Capacity
#'
#' Calculates soil volumetric heat capacity (MJ / (m³ * K)) from soil moisture and texture.
#' Works by linearly interpolating volumetric heat capacity based on measured data.
#'
#' @param ... Additional arguments.
#' @param weather_station A weather_station object.
#' @return Soil volumetric heat capacity in MJ/(m³ * K).
#' @details
#' The volumetric heat capacity (\eqn{C_v}) of the soil is determined based on its texture and moisture content.
#' The values are interpolated from measured data for different soil types.
#'
#' @references Bendix 2004, p. 254.
#' @examples
#' # Calculate soil volumetric heat capacity
#' soil_heat_cap(moisture = 0.25, texture = "sand")
#' @export
soil_heat_cap <- function(...) {
  UseMethod("soil_heat_cap")
}

#' @rdname soil_heat_cap
#' @param moisture Soil moisture in cubic meters per cubic meter.
#' @param texture Soil texture. Either "sand", "peat" or "clay".
#' @importFrom stats approx
#' @export
soil_heat_cap.default <- function(moisture, texture = "sand", ...) {
  moisture <- moisture * 100 # convert to Vol-%

  if (texture == "sand") {
    y <- c(1.17, 1.38, 1.59, 1.8, 2.0, 2.42, 2.97)
    x <- c(0, 5, 10, 15, 20, 30, 43)
  } else if (texture == "clay") {
    y <- c(1.19, 1.4, 1.61, 1.82, 2.03, 2.45, 2.99)
    x <- c(0, 5, 10, 15, 20, 30, 43)
  } else if (texture == "peat") {
    y <- c(0.25, 0.67, 1.51, 2.35, 3.19, 3.61, 4.03)
    x <- c(0, 10, 30, 50, 70, 80, 90)
  } else {
    stop("Texture not available. Input either 'sand', 'peat' or 'clay'")
  }

  vol_heat <- approx(x, y, xout = moisture, yleft = NA, yright = y[7])
  vol_heat$y
}

#' @rdname soil_heat_cap
#' @export
soil_heat_cap.weather_station <- function(weather_station, ...) {
  check_availability(weather_station, "moisture", "texture")
  moisture <- weather_station$moisture
  texture <- weather_station$texture
  return(soil_heat_cap(moisture, texture))
}


#' Soil Attenuation Length
#'
#' Calculates soil attenuation length.
#'
#' @param ... Additional arguments.
#' @param weather_station A weather_station object.
#' @return Soil attenuation length in m.
#' @details
#' The soil attenuation length (\eqn{L}) is calculated using the formula:
#' \deqn{L = \sqrt{\frac{\lambda}{C_v \cdot 10^6 \cdot \pi} \cdot 86400}}
#' where:
#' \eqn{\lambda} is the thermal conductivity of the soil (W/m/K),
#' \eqn{C_v} is the volumetric heat capacity of the soil (MJ/(m³ * K));
#' \eqn{10^6} converts it to J/(m³ * K) for the calculation,
#' \eqn{86400} is the number of seconds in a day.
#'
#' @references Bendix 2004, p. 253.
#' @examples
#' # Calculate soil attenuation length
#' soil_attenuation(moisture = 0.25, texture = "sand")
#' @export
soil_attenuation <- function(...) {
  UseMethod("soil_attenuation")
}

#' @rdname soil_attenuation
#' @param moisture Soil moisture in cubic meters per cubic meter.
#' @param texture Soil texture. Either "sand", "peat" or "clay".
#' @export
soil_attenuation.default <- function(moisture, texture = "sand", ...) {
  thermal_cond <- soil_thermal_cond(texture, moisture)
  vol_heat_cap <- soil_heat_cap(moisture, texture)
  soil_att <- sqrt(thermal_cond / (vol_heat_cap * 10^6 * pi) * 86400)
  soil_att
}

#' @rdname soil_attenuation
#' @export
soil_attenuation.weather_station <- function(weather_station, ...) {
  check_availability(weather_station, "moisture", "texture")
  moisture <- weather_station$moisture
  texture <- weather_station$texture
  return(soil_attenuation(moisture, texture))
}
