#' Total Radiation Balance
#'
#' Calculates the total radiation balance by summing the shortwave and longwave radiation balances.
#'
#' @inheritParams build_weather_station
#' @return Total radiation balance in W/m².
#' @details
#' The total radiation balance (\eqn{R_{total}}) is calculated as:
#' \deqn{R_{total} = R_{sw} + R_{lw}}
#' where:
#' \eqn{R_{sw}} is the shortwave radiation balance,
#' \eqn{R_{lw}} is the longwave radiation balance.
#'
#' @examples
#' # Calculate total radiation balance
#' rad_bal(datetime = Sys.time(), lon = 10, lat = 50, elev = 100, temp = 15, rh = 60,
#'         slope = 5, exposition = 180, valley = FALSE, surface_type = "lawn", surface_temp = 15)
#' @references Bendix 2004, p. 45 eq. 3.1.
#' @export
rad_bal <- function(...) {
  UseMethod("rad_bal")
}

#' @rdname rad_bal
#' @export
rad_bal.default <- function(datetime, lon, lat, elev, temp, rh, slope, exposition, valley, surface_type, surface_temp, ...) {
  sw_bal <- rad_sw_bal(datetime, lon, lat, elev, temp, slope, exposition, valley, surface_type, ...)
  lw_bal <- rad_lw_bal(temp, rh, slope, valley, surface_type, surface_temp, ...)
  sw_bal + lw_bal
}

#' @rdname rad_bal
#' @export
rad_bal.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(rad_bal.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }
  rad_bal(datetime, lon, lat, elev, temp, rh, slope, exposition, valley, surface_type, surface_temp, ...)
}

#' Shortwave Radiation Balance
#'
#' Calculates the shortwave radiation balance by summing the shortwave incoming and outgoing radiation as well as diffused incoming and outgoing radiation.
#'
#' @inheritParams build_weather_station
#' @return Shortwave radiation balance in W/m².
#' @details
#' The shortwave radiation balance (\eqn{R_{sw}}) is calculated as:
#' \deqn{R_{sw} = SW_{in} - SW_{out} + D_{in} - D_{out}}
#' where:
#' \eqn{SW_{in}} is the shortwave incoming radiation,
#' \eqn{SW_{out}} is the shortwave outgoing radiation,
#' \eqn{D_{in}} is the diffused incoming radiation,
#' \eqn{D_{out}} is the diffused outgoing radiation.
#'
#' @examples
#' # Calculate shortwave radiation balance
#' rad_sw_bal(datetime = Sys.time(), lon = 10, lat = 50, elev = 100, temp = 15,
#'            slope = 5, exposition = 180, valley = FALSE, surface_type = "lawn")
#' @references Bendix 2004, p. 45 eq. 3.1.
#' @export
rad_sw_bal <- function(...) {
  UseMethod("rad_sw_bal")
}

#' @rdname rad_sw_bal
#' @export
rad_sw_bal.default <- function(datetime, lon, lat, elev, temp, slope, exposition, valley, surface_type, ...) {
  sw_in <- rad_sw_in(datetime, lon, lat, elev, temp,
                     slope, exposition, ...)
  sw_out <- rad_sw_out(datetime, lon, lat, elev, temp,
                       slope, exposition, surface_type, ...)
  diffuse_in <- rad_diffuse_in(datetime, lon, lat, elev, temp,
                               slope, exposition, valley, ...)
  diffuse_out <- rad_diffuse_out(datetime, lon, lat, elev, temp,
                                 slope, exposition, valley, surface_type, ...)

  sw_in - sw_out + diffuse_in - diffuse_out
}

#' @rdname rad_sw_bal
#' @export
rad_sw_bal.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(rad_sw_bal.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }
  rad_sw_bal(datetime, lon, lat, elev, temp, slope, exposition, valley, surface_type, ...)
}

#' Shortwave Incoming Radiation
#'
#' Calculates the direct shortwave incoming radiation.
#'
#' @inheritParams build_weather_station
#' @return Shortwave incoming radiation in W/m².
#' @details
#' The shortwave incoming radiation (\eqn{SW_{in}}) is calculated using the formula:
#' \deqn{SW_{in} = SW_{toa} \cdot 0.9751 \cdot T_{total} / \sin(E) \cdot \cos(\theta)}
#' where:
#' \eqn{SW_{toa}} is the shortwave radiation at the top of the atmosphere,
#' \eqn{T_{total}} is the total atmospheric transmission,
#' \eqn{E} is the solar elevation angle,
#' \eqn{\theta} is the terrain angle.
#'
#' @examples
#' # Calculate shortwave incoming radiation
#' rad_sw_in(datetime = Sys.time(), lon = 10, lat = 50, elev = 100, temp = 15,
#'           slope = 5, exposition = 180)
#' @references Bendix 2004, p. 46 eq. 3.3, p. 52 eq. 3.8.
#' @export
rad_sw_in <- function(...) {
  UseMethod("rad_sw_in")
}

#' @rdname rad_sw_in
#' @export
rad_sw_in.default <- function(datetime, lon, lat, elev, temp, slope, exposition, ...) {
  sw_toa <- rad_sw_toa(datetime, lon, lat, ...)
  gas <- trans_gas(datetime, lon, lat, elev, temp, ...)
  ozone <- trans_ozone(datetime, lon, lat, ...)
  rayleigh <- trans_rayleigh(datetime, lon, lat, elev, temp, ...)
  vapor <- trans_vapor(datetime, lon, lat, elev, temp, ...)
  aerosol <- trans_aerosol(datetime, lon, lat, elev, temp, ...)
  trans_total <- gas * ozone * rayleigh * vapor * aerosol
  elevation <- sol_elevation(datetime, lon, lat)
  terrain_angle <- terr_terrain_angle(datetime, lon, lat, slope, exposition)
  elevation <- deg2rad(elevation)
  terrain_angle <- deg2rad(terrain_angle)
  out <- sw_toa * 0.9751 * trans_total / sin(elevation) * cos(terrain_angle)
  ifelse((out < 0) | (elevation < 0), 0, out)
}

#' @rdname rad_sw_in
#' @export
rad_sw_in.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(rad_sw_in.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }
  rad_sw_in(datetime, lon, lat, elev, temp, slope, exposition, ...)
}

#' Shortwave Radiation at Top of Atmosphere
#'
#' Calculates the shortwave radiation at the top of the atmosphere without the influence of the atmosphere.
#'
#' @inheritParams build_weather_station
#' @return Shortwave radiation at top of atmosphere in W/m².
#' @details
#' The shortwave radiation at the top of the atmosphere (\eqn{SW_{toa}}) is calculated using the formula:
#' \deqn{SW_{toa} = S \cdot E \cdot \sin(E)}
#' where:
#' \eqn{S} is the solar constant (default 1361 W/m²),
#' \eqn{E} is the eccentricity correction factor,
#' \eqn{E} is the solar elevation angle.
#'
#' @param sol_const Solar radiation constant in W/m², default is 1361.
#' @examples
#' # Calculate shortwave radiation at top of atmosphere
#' rad_sw_toa(datetime = Sys.time(), lon = 10, lat = 50)
#' @references Bendix 2004, p. 244.
#' @export
rad_sw_toa <- function(...) {
  UseMethod("rad_sw_toa")
}

#' @rdname rad_sw_toa
#' @export
rad_sw_toa.default <- function(datetime, lon, lat, ..., sol_const = 1361) {
  eccentricity <- sol_eccentricity(datetime)
  elevation <- sol_elevation(datetime, lon, lat)
  elevation <- deg2rad(elevation)
  out <- sol_const * eccentricity * sin(elevation)
  ifelse(elevation < 0, 0, out)
}

#' @rdname rad_sw_toa
#' @export
rad_sw_toa.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(rad_sw_toa.default)
  a <- a[1:(length(a)-2)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }
  rad_sw_toa(datetime, lon, lat, ...)
}

#' Incoming Diffused Radiation
#'
#' Calculates the diffused shortwave incoming radiation.
#'
#' @inheritParams build_weather_station
#' @return Diffused shortwave incoming radiation in W/m².
#' @details
#' The diffused shortwave incoming radiation (\eqn{D_{in}}) is calculated using the formula:
#' \deqn{D_{in} = 0.5 \cdot [(1 - (1 - \text{vapor}) - (1 - \text{ozone})) \cdot SW_{toa} - SW_{in}] \cdot \text{sky\_view} \cdot (1 + \cos(\theta)^2 \cdot \sin(\phi)^3)}
#' where:
#' \eqn{\text{vapor}} is the vapor transmission,
#' \eqn{\text{ozone}} is the ozone transmission,
#' \eqn{SW_{toa}} is the shortwave radiation at the top of the atmosphere,
#' \eqn{SW_{in}} is the shortwave incoming radiation,
#' \eqn{\text{sky\_view}} is the sky view factor,
#' \eqn{\theta} is the terrain angle, and
#' \eqn{\phi} is the solar angle.
#'
#' @examples
#' # Calculate diffused shortwave incoming radiation
#' rad_diffuse_in(datetime = Sys.time(), lon = 10, lat = 50, elev = 100, temp = 15,
#'                slope = 5, exposition = 180, valley = FALSE)
#' @references Bendix 2004, p. 58 eq. 3.14, p. 55 eq. 3.9.
#' @export
rad_diffuse_in <- function(...) {
  UseMethod("rad_diffuse_in")
}

#' @rdname rad_diffuse_in
#' @export
rad_diffuse_in.default <- function(datetime, lon, lat, elev, temp, slope, exposition, valley, ...) {
  vapor <- trans_vapor(datetime, lon, lat, elev, temp, ...)
  ozone <- trans_ozone(datetime, lon, lat, ...)
  sw_toa <- rad_sw_toa(datetime, lon, lat, ...)
  sw_in <- rad_sw_in(datetime, lon, lat, elev, temp, slope, exposition, ...)

  sky_view <- terr_sky_view(slope, valley)
  terrain_angle <- terr_terrain_angle(datetime, lon, lat, slope, exposition)
  elevation <- sol_elevation(datetime, lon, lat)
  solar_angle <- 90 - elevation

  terrain_angle <- deg2rad(terrain_angle)
  solar_angle <- deg2rad(solar_angle)

  out <- 0.5 * ((1 - (1 - vapor) - (1 - ozone)) * sw_toa - sw_in) *
    sky_view * (1 + cos(terrain_angle)^2 * sin(solar_angle)^3)
  ifelse(elevation < 0, 0, out)
}

#' @rdname rad_diffuse_in
#' @export
rad_diffuse_in.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(rad_diffuse_in.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }
  rad_diffuse_in(datetime, lon, lat, elev, temp, slope, exposition, valley, ...)
}

#' Shortwave Outgoing Radiation
#'
#' Calculates the reflected shortwave incoming radiation.
#'
#' @inheritParams build_weather_station
#' @return Reflected shortwave incoming radiation in W/m².
#' @details
#' The reflected shortwave incoming radiation (\eqn{SW_{out}}) is calculated using the formula:
#' \deqn{SW_{out} = SW_{in} \cdot \alpha}
#' where:
#' \eqn{SW_{in}} is the shortwave incoming radiation,
#' \eqn{\alpha} is the albedo of the surface.
#'
#' @examples
#' # Calculate reflected shortwave incoming radiation
#' rad_sw_out(datetime = Sys.time(), lon = 10, lat = 50, elev = 100, temp = 15,
#'            slope = 5, exposition = 180, surface_type = "lawn")
#' @references Bendix 2004, p. 45 eq. 3.1.
#' @export
rad_sw_out <- function(...) {
  UseMethod("rad_sw_out")
}

#' @rdname rad_sw_out
#' @export
rad_sw_out.default <- function(datetime, lon, lat, elev, temp, slope, exposition, surface_type, ...) {
  sw_in <- rad_sw_in(datetime, lon, lat, elev, temp, slope, exposition)
  albedo <- surface_properties[which(surface_properties$surface_type == surface_type), ]$albedo
  sw_in * albedo
}

#' @rdname rad_sw_out
#' @export
rad_sw_out.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(rad_sw_out.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }
  rad_sw_out(datetime, lon, lat, elev, temp, slope, exposition, surface_type, ...)
}

#' Diffused Outgoing Radiation
#'
#' Calculates the reflected diffused incoming radiation.
#'
#' @inheritParams build_weather_station
#' @return Reflected diffused incoming radiation in W/m².
#' @details
#' The reflected diffused incoming radiation (\eqn{D_{out}}) is calculated using the formula:
#' \deqn{D_{out} = D_{in} \cdot \alpha}
#' where:
#' \eqn{D_{in}} is the diffused incoming radiation,
#' \eqn{\alpha} is the albedo of the surface.
#'
#' @examples
#' # Calculate reflected diffused incoming radiation
#' rad_diffuse_out(datetime = Sys.time(), lon = 10, lat = 50, elev = 100, temp = 15,
#'                 slope = 5, exposition = 180, valley = FALSE, surface_type = "lawn")
#' @references Bendix 2004, p. 45 eq. 3.1.
#' @export
rad_diffuse_out <- function(...) {
  UseMethod("rad_diffuse_out")
}

#' @rdname rad_diffuse_out
#' @export
rad_diffuse_out.default <- function(datetime, lon, lat, elev, temp, slope, exposition, valley, surface_type, ...) {
  diffuse_in <- rad_diffuse_in(datetime, lon, lat, elev, temp, slope, exposition, valley, ...)
  albedo <- surface_properties[which(surface_properties$surface_type == surface_type), ]$albedo
  diffuse_in * albedo
}

#' @rdname rad_diffuse_out
#' @export
rad_diffuse_out.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(rad_diffuse_out.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }
  rad_diffuse_out(datetime, lon, lat, elev, temp, slope, exposition, valley, surface_type, ...)
}

#' Longwave Radiation Balance
#'
#' Calculates the sum of longwave incoming and outgoing radiation.
#'
#' @inheritParams build_weather_station
#' @return Longwave radiation balance in W/m².
#' @details
#' The longwave radiation balance (\eqn{R_{lw}}) is calculated as:
#' \deqn{R_{lw} = LW_{in} - LW_{out}}
#' where:
#' \eqn{LW_{in}} is the longwave incoming radiation,
#' \eqn{LW_{out}} is the longwave outgoing radiation.
#'
#' @examples
#' # Calculate longwave radiation balance
#' rad_lw_bal(temp = 15, rh = 60, slope = 5, valley = FALSE, surface_type = "lawn", surface_temp = 15)
#' @references Bendix 2004, p. 68. eq. 3.25.
#' @export
rad_lw_bal <- function(...) {
  UseMethod("rad_lw_bal")
}

#' @rdname rad_lw_bal
#' @export
rad_lw_bal.default <- function(temp, rh, slope, valley, surface_type, surface_temp, ...) {
  lw_in <- rad_lw_in(temp, rh, slope, valley, ...)
  lw_out <- rad_lw_out(surface_type, surface_temp, ...)
  lw_in - lw_out
}

#' @rdname rad_lw_bal
#' @export
rad_lw_bal.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(rad_lw_bal.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }
  rad_lw_bal(temp, rh, slope, valley, surface_type, surface_temp, ...)
}

#' Longwave Incoming Radiation
#'
#' Calculates the longwave radiation of the atmosphere.
#'
#' @inheritParams build_weather_station
#' @return Longwave incoming radiation in W/m².
#' @details
#' The longwave incoming radiation (\eqn{LW_{in}}) is calculated as:
#' \deqn{LW_{in} = \epsilon_{air} \cdot \sigma \cdot T_{air}^4 \cdot \text{sky\_view}}
#' where:
#' \eqn{\epsilon_{air}} is the emissivity of the air,
#' \eqn{\sigma} is the Stefan-Boltzmann constant,
#' \eqn{T_{air}} is the air temperature in Kelvin, and
#' \eqn{\text{sky\_view}} is the sky view factor.
#'
#' @examples
#' # Calculate longwave incoming radiation
#' rad_lw_in(temp = 15, rh = 60, slope = 5, valley = FALSE)
#' @references Bendix 2004, p. 68 eq. 3.24.
#' @export
rad_lw_in <- function(...) {
  UseMethod("rad_lw_in")
}

#' @rdname rad_lw_in
#' @export
rad_lw_in.default <- function(temp, rh, slope, valley, ..., sigma = sigma_default) {
  emissivity_air <- rad_emissivity_air(temp, rh, ...)
  sky_view <- terr_sky_view(slope, valley)
  temp <- c2k(temp)
  emissivity_air * sigma * temp^4 * sky_view
}

#' @rdname rad_lw_in
#' @export
rad_lw_in.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(rad_lw_in.default)
  a <- a[1:(length(a)-2)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }
  rad_lw_in(temp, rh, slope, valley, ...)
}

#' Emissivity of the Atmosphere
#'
#' Calculates the emissivity of the atmosphere.
#'
#' @inheritParams build_weather_station
#' @return Emissivity ratio from 0 to 1.
#' @details
#' The emissivity of the atmosphere (\eqn{\epsilon_{air}}) is calculated as:
#' \deqn{\epsilon_{air} = (1.24 \cdot \frac{e}{T_{air}})^{1/7}}
#' where:
#' \eqn{e} is the vapor pressure,
#' \eqn{T_{air}} is the air temperature in Kelvin.
#'
#' @examples
#' # Calculate emissivity of the atmosphere
#' rad_emissivity_air(temp = 15, rh = 60)
#' @references Bendix 2004, p. 66 eq. 3.22.
#' @export
rad_emissivity_air <- function(...) {
  UseMethod("rad_emissivity_air")
}

#' @rdname rad_emissivity_air
#' @export
rad_emissivity_air.default <- function(temp, rh, ...) {
  vapor_p <- pres_vapor_p(temp, rh, ...)
  temp <- c2k(temp)
  (1.24 * vapor_p / temp)^(1 / 7)
}

#' @rdname rad_emissivity_air
#' @export
rad_emissivity_air.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(rad_emissivity_air.default)
  a <- a[1:(length(a)-1)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }
  rad_emissivity_air(temp, rh, ...)
}

#' Longwave Outgoing Radiation
#'
#' Calculates the longwave radiation of the surface.
#'
#' @inheritParams build_weather_station
#' @return Longwave outgoing radiation in W/m².
#' @details
#' The longwave outgoing radiation (\eqn{LW_{out}}) is calculated as:
#' \deqn{LW_{out} = \epsilon \cdot \sigma \cdot T_{surface}^4}
#' where:
#' \eqn{\epsilon} is the emissivity of the surface,
#' \eqn{\sigma} is the Stefan-Boltzmann constant, and
#' \eqn{T_{surface}} is the surface temperature in Kelvin.
#'
#' @examples
#' # Calculate longwave outgoing radiation
#' rad_lw_out(surface_type = "lawn", surface_temp = 15)
#' @references Bendix 2004, p. 66 eq. 3.20.
#' @export
rad_lw_out <- function(...) {
  UseMethod("rad_lw_out")
}

#' @rdname rad_lw_out
#' @export
rad_lw_out.default <- function(surface_type, surface_temp, ..., sigma = sigma_default) {
  emissivity <- surface_properties[which(surface_properties$surface_type == surface_type), ]$emissivity
  surface_temp <- c2k(surface_temp)
  emissivity * sigma * surface_temp^4
}

#' @rdname rad_lw_out
#' @export
rad_lw_out.weather_station <- function(weather_station, ...) {
  a <- methods::formalArgs(rad_lw_out.default)
  a <- a[1:(length(a)-2)]
  for(i in a) {
    assign(i, weather_station[[i]])
  }
  rad_lw_out(surface_type, surface_temp, ...)
}

