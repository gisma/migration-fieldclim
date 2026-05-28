#' Sensible heat flux by a simple bulk-transfer approach
#'
#' Calculates sensible heat flux from a vertical temperature difference,
#' wind speed and a simplified aerodynamic resistance.
#'
#' The sign convention follows the package energy-balance convention:
#'
#' `H > 0` means sensible heat flux away from the surface.
#'
#' Therefore, with `t1` as lower air temperature and `t2` as upper air
#' temperature, positive `t1 - t2` produces positive sensible heat flux.
#'
#' @param t1 Air temperature at lower measurement height.
#' @param t2 Air temperature at upper measurement height.
#' @param v1 Wind speed at lower measurement height.
#' @param v2 Optional wind speed at upper measurement height. If missing,
#'   `v1` is used.
#' @param z1 Lower measurement height in m.
#' @param z2 Upper measurement height in m.
#' @param rho Air density in kg m-3. Default is 1.225.
#' @param cp Specific heat capacity of air in J kg-1 K-1. Default is 1005.
#' @param k von Karman constant. Default is 0.41.
#' @param min_wind Minimum wind speed for the resistance calculation.
#'   Values at or below this threshold return `NA`.
#' @param warn_threshold Absolute flux threshold for diagnostic warnings.
#' @param ... Further arguments passed to methods.
#'
#' @return Sensible heat flux in W m-2.
#'
#' @export
sensible_bulk <- function(t1, ...) {
  UseMethod("sensible_bulk")
}

#' @rdname sensible_bulk
#' @export
sensible_bulk.default <- function(
    t1,
    t2,
    v1,
    v2 = NULL,
    z1,
    z2,
    rho = 1.225,
    cp = 1005,
    k = 0.41,
    min_wind = 0.1,
    warn_threshold = 600,
    ...) {

  if (length(z1) != 1 || length(z2) != 1) {
    stop("z1 and z2 must be scalar measurement heights.", call. = FALSE)
  }

  if (!is.finite(z1) || !is.finite(z2) || z1 <= 0 || z2 <= z1) {
    stop("z1 and z2 must satisfy 0 < z1 < z2.", call. = FALSE)
  }

  if (is.null(v2)) {
    wind_mean <- v1
  } else {
    wind_mean <- (v1 + v2) / 2
  }

  bad_wind <- is.na(wind_mean) | wind_mean <= min_wind

  if (any(bad_wind, na.rm = TRUE)) {
    warning(
      "sensible_bulk: wind speed is missing or too small for some values; returning NA there.",
      call. = FALSE
    )
  }

  wind_mean[bad_wind] <- NA_real_

  delta_t <- t1 - t2
  r_a <- log(z2 / z1) / (k * wind_mean)

  h <- rho * cp * delta_t / r_a

  if (any(abs(h) > warn_threshold, na.rm = TRUE)) {
    warning(
      "sensible_bulk: there are values above the diagnostic threshold of ",
      warn_threshold,
      " W m-2.",
      call. = FALSE
    )
  }

  h
}

#' @rdname sensible_bulk
#' @export
sensible_bulk.weather_station <- function(
    t1,
    rho = 1.225,
    cp = 1005,
    k = 0.41,
    min_wind = 0.1,
    warn_threshold = 600,
    ...) {

  weather_station <- t1

  check_availability(
    weather_station,
    "t1", "t2", "v1", "z1", "z2"
  )

  v2 <- if ("v2" %in% names(weather_station)) weather_station$v2 else NULL

  sensible_bulk.default(
    t1 = weather_station$t1,
    t2 = weather_station$t2,
    v1 = weather_station$v1,
    v2 = v2,
    z1 = weather_station$z1,
    z2 = weather_station$z2,
    rho = rho,
    cp = cp,
    k = k,
    min_wind = min_wind,
    warn_threshold = warn_threshold,
    ...
  )
}


#' Latent heat flux as residual of the surface energy balance
#'
#' Calculates latent heat flux as residual from net radiation, soil heat flux
#' and sensible heat flux.
#'
#' The sign convention is:
#'
#' `Rn > 0`: radiative energy input at the surface
#'
#' `G > 0`: heat flux into the soil
#'
#' `H > 0`: sensible heat flux away from the surface
#'
#' `LE > 0`: latent heat flux away from the surface
#'
#' Therefore:
#'
#' `LE = Rn - G - H`
#' @param rho Air density in kg m-3.
#' @param cp Specific heat capacity of air in J kg-1 K-1.
#' @param k von Karman constant.
#' @param min_wind Minimum wind speed used by the internal bulk calculation.
#' @param rad_bal Net radiation `Rn` in W m-2.
#' @param soil_flux Soil heat flux `G` in W m-2.
#' @param sensible Sensible heat flux `H` in W m-2.
#' @param warn_threshold Absolute flux threshold for diagnostic warnings.
#' @param ... Further arguments passed to methods.
#'
#' @return Latent heat flux in W m-2.
#'
#' @export
latent_bulk_residual <- function(rad_bal, ...) {
  UseMethod("latent_bulk_residual")
}

#' @rdname latent_bulk_residual
#' @export
latent_bulk_residual.default <- function(
    rad_bal,
    soil_flux,
    sensible,
    warn_threshold = 600,
    ...) {

  le <- rad_bal - soil_flux - sensible

  if (any(abs(le) > warn_threshold, na.rm = TRUE)) {
    warning(
      "latent_bulk_residual: there are values above the diagnostic threshold of ",
      warn_threshold,
      " W m-2.",
      call. = FALSE
    )
  }

  le
}

#' @rdname latent_bulk_residual
#' @export
latent_bulk_residual.weather_station <- function(
    rad_bal,
    sensible = NULL,
    rho = 1.225,
    cp = 1005,
    k = 0.41,
    min_wind = 0.1,
    warn_threshold = 600,
    ...) {

  weather_station <- rad_bal

  check_availability(
    weather_station,
    "rad_bal", "soil_flux"
  )

  if (is.null(sensible)) {
    sensible <- sensible_bulk.weather_station(
      weather_station,
      rho = rho,
      cp = cp,
      k = k,
      min_wind = min_wind,
      warn_threshold = warn_threshold,
      ...
    )
  }

  latent_bulk_residual.default(
    rad_bal = weather_station$rad_bal,
    soil_flux = weather_station$soil_flux,
    sensible = sensible,
    warn_threshold = warn_threshold,
    ...
  )
}



#' Bulk-residual turbulent heat flux workflow
#'
#' Adds `sensible_bulk` and `latent_bulk_residual` to a `weather_station`
#' object.
#' @param weather_station A `weather_station` object.
#' @param ... Further arguments passed to `sensible_bulk()`.
#'
#' @return The input `weather_station` object with additional fields:
#'   `sensible_bulk` and `latent_bulk_residual`.
#'
#' @export
turb_flux_bulk_residual <- function(weather_station, ...) {
  check_availability(
    weather_station,
    "t1", "t2", "v1", "z1", "z2", "rad_bal", "soil_flux"
  )

  h_bulk <- sensible_bulk(weather_station, ...)
  le_residual <- latent_bulk_residual(weather_station, sensible = h_bulk, ...)

  weather_station$sensible_bulk <- h_bulk
  weather_station$latent_bulk_residual <- le_residual

  weather_station
}
