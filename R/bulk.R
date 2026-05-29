#' Sensible heat flux by a simple bulk-transfer approach
#'
#' Calculates sensible heat flux from a vertical temperature difference,
#' wind speed and a simplified aerodynamic resistance.
#'
#' The implemented sensible heat flux is:
#'
#' \deqn{
#' H_{bulk} = \rho c_p \frac{T_1 - T_2}{r_a}
#' }
#'
#' where \eqn{H_{bulk}} is the sensible heat flux in W m-2,
#' \eqn{\rho} is air density in kg m-3, \eqn{c_p} is the specific heat
#' capacity of air in J kg-1 K-1, \eqn{T_1} is the air temperature at the
#' lower measurement height, \eqn{T_2} is the air temperature at the upper
#' measurement height, and \eqn{r_a} is the aerodynamic resistance in s m-1.
#'
#' The aerodynamic resistance is calculated as:
#'
#' \deqn{
#' r_a = \frac{\log(z_2 / z_1)}{k \bar{u}}
#' }
#'
#' where \eqn{z_1} is the lower measurement height in m, \eqn{z_2} is the
#' upper measurement height in m, \eqn{k} is the von Karman constant, and
#' \eqn{\bar{u}} is the mean wind speed in m s-1. If \code{v2} is supplied,
#' \eqn{\bar{u}} is calculated as the mean of \code{v1} and \code{v2}. If
#' \code{v2} is not supplied, \code{v1} is used as \eqn{\bar{u}}.
#'
#' The sign convention follows the package energy-balance convention:
#'
#' \deqn{
#' H > 0
#' }
#'
#' means sensible heat flux away from the surface. Therefore, with
#' \code{z1 < z2}, a positive lower-minus-upper temperature difference
#' \code{t1 - t2} produces positive \eqn{H_{bulk}}.
#'
#' This is a simplified neutral bulk-transfer reference. It is not a full
#' Monin-Obukhov stability-corrected profile method. Stability corrections,
#' roughness sublayer effects and explicit surface-layer similarity functions
#' are not applied here.
#'
#' If \code{stability_method = "ri_guard"}, the neutral estimate is screened
#' with a gradient Richardson number diagnostic:
#' \deqn{
#' Ri_g = \frac{g}{\bar{\theta}} \frac{\Delta \theta / \Delta z}{(\Delta u / \Delta z)^2}
#' }
#' The guard does not rescale valid neutral fluxes. It only returns \code{NA}
#' for invalid or very stable Richardson cases and attaches \code{bulk_Ri_g}
#' and \code{bulk_stability} attributes to the returned vector.
#'
#' Very low wind speeds make the aerodynamic resistance numerically unstable.
#' Values at or below \code{min_wind} are therefore returned as \code{NA} with
#' a warning. Large absolute fluxes are warned about using
#' \code{warn_threshold}, but they are not capped.
#'
#' @param t1 Air temperature at lower measurement height in degrees C.
#' @param t2 Air temperature at upper measurement height in degrees C.
#' @param v1 Wind speed at lower measurement height in m s-1.
#' @param v2 Optional wind speed at upper measurement height in m s-1. If
#'   missing, \code{v1} is used.
#' @param z1 Lower measurement height in m.
#' @param z2 Upper measurement height in m.
#' @param rho Air density in kg m-3. Default is 1.225.
#' @param cp Specific heat capacity of air in J kg-1 K-1. Default is 1005.
#' @param k von Karman constant. Default is 0.41.
#' @param min_wind Minimum wind speed in m s-1 for the resistance calculation.
#'   Values at or below this threshold return \code{NA}.
#' @param warn_threshold Absolute flux threshold in W m-2 for diagnostic
#'   warnings.
#' @param stability_method Optional stability screening method. \code{"none"}
#'   keeps the neutral bulk estimate unchanged; \code{"ri_guard"} attaches a
#'   gradient Richardson diagnostic and returns \code{NA} for invalid or very
#'   stable cases.
#' @param ri_neutral Absolute Richardson-number threshold for neutral class.
#' @param ri_critical Critical Richardson number for very stable guarding.
#' @param min_shear Minimum absolute wind-speed shear in s-1 for Richardson
#'   diagnostics.
#' @param g Gravitational acceleration in m s-2.
#' @param elev Optional elevation above sea level in m. If supplied,
#'   near-surface potential temperature is estimated with \code{temp_pot_temp()};
#'   otherwise Kelvin air temperature is used as a near-surface approximation.
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
    stability_method = c("none", "ri_guard"),
    ri_neutral = 0.01,
    ri_critical = 0.25,
    min_shear = 1e-4,
    g = 9.81,
    elev = NULL,
    ...) {

  stability_method <- match.arg(stability_method)

  if (stability_method == "ri_guard" && is.null(v2)) {
    stop("stability_method = 'ri_guard' requires v2.", call. = FALSE)
  }

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

  if (stability_method == "none") {
    return(h)
  }

  n <- max(length(t1), length(t2), length(v1), length(v2))
  t1_ri <- rep_len(t1, n)
  t2_ri <- rep_len(t2, n)
  v1_ri <- rep_len(v1, n)
  v2_ri <- rep_len(v2, n)

  if (!is.null(elev)) {
    elev_ri <- rep_len(elev, n)
    theta1 <- temp_pot_temp(t1_ri, elev_ri) + 273.15
    theta2 <- temp_pot_temp(t2_ri, elev_ri) + 273.15
  } else {
    theta1 <- t1_ri + 273.15
    theta2 <- t2_ri + 273.15
  }

  theta_mean <- (theta1 + theta2) / 2
  dtheta_dz <- (theta2 - theta1) / (z2 - z1)
  du_dz <- (v2_ri - v1_ri) / (z2 - z1)
  Ri_g <- (g / theta_mean) * dtheta_dz / (du_dz^2)

  invalid <- !is.finite(theta_mean) |
    theta_mean <= 0 |
    !is.finite(dtheta_dz) |
    !is.finite(du_dz) |
    abs(du_dz) <= min_shear |
    !is.finite(Ri_g)

  stability_class <- rep(NA_character_, length(Ri_g))
  stability_class[!invalid & Ri_g < 0] <- "unstable"
  stability_class[!invalid & abs(Ri_g) <= ri_neutral] <- "neutral"
  stability_class[!invalid & Ri_g > ri_neutral & Ri_g < ri_critical] <- "stable"
  stability_class[!invalid & Ri_g >= ri_critical] <- "very_stable"

  guarded_very_stable <- stability_class == "very_stable"
  guarded_very_stable[is.na(guarded_very_stable)] <- FALSE
  guarded <- invalid | guarded_very_stable

  if (any(guarded_very_stable, na.rm = TRUE)) {
    warning(
      "sensible_bulk: very stable Richardson cases for some values; returning NA there.",
      call. = FALSE
    )
  } else if (any(invalid, na.rm = TRUE)) {
    warning(
      "sensible_bulk: invalid Richardson guard inputs for some values; returning NA there.",
      call. = FALSE
    )
  }

  h[guarded] <- NA_real_
  attr(h, "bulk_Ri_g") <- Ri_g
  attr(h, "bulk_stability") <- stability_class
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
    stability_method = c("none", "ri_guard"),
    ri_neutral = 0.01,
    ri_critical = 0.25,
    min_shear = 1e-4,
    g = 9.81,
    elev = NULL,
    ...) {

  stability_method <- match.arg(stability_method)

  weather_station <- t1

  check_availability(
    weather_station,
    "t1", "t2", "v1", "z1", "z2"
  )

  v2 <- if ("v2" %in% names(weather_station)) weather_station$v2 else NULL
  if (is.null(elev) && "elev" %in% names(weather_station)) {
    elev <- weather_station$elev
  }

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
    stability_method = stability_method,
    ri_neutral = ri_neutral,
    ri_critical = ri_critical,
    min_shear = min_shear,
    g = g,
    elev = elev,
    ...
  )
}


#' Latent heat flux as residual of the surface energy balance
#'
#' Calculates latent heat flux as the residual of the available turbulent
#' energy after subtracting sensible heat flux.
#'
#' The package energy-balance convention is:
#'
#' \deqn{
#' R_n = G + H + LE
#' }
#'
#' when storage is omitted. Here \eqn{R_n} is net radiation, \eqn{G} is soil
#' heat flux, \eqn{H} is sensible heat flux, and \eqn{LE} is latent heat flux.
#'
#' The implemented residual is:
#'
#' \deqn{
#' LE_{res} = R_n - G - H
#' }
#'
#' where \eqn{LE_{res}} is latent heat flux in W m-2, \eqn{R_n} is net
#' radiation in W m-2, \eqn{G} is soil heat flux in W m-2, and \eqn{H} is
#' sensible heat flux in W m-2.
#'
#' The sign convention is:
#'
#' \itemize{
#'   \item \eqn{R_n > 0}: radiative energy input at the surface.
#'   \item \eqn{G > 0}: heat flux into the soil.
#'   \item \eqn{H > 0}: sensible heat flux away from the surface.
#'   \item \eqn{LE > 0}: latent heat flux away from the surface.
#' }
#'
#' In the Bulk-Residual workflow, \code{sensible_bulk()} first estimates
#' \eqn{H_{bulk}}. The latent heat flux is then calculated as:
#'
#' \deqn{
#' LE_{res} = R_n - G - H_{bulk}
#' }
#'
#' Therefore the Bulk-Residual workflow closes the available energy by
#' construction:
#'
#' \deqn{
#' H_{bulk} + LE_{res} = R_n - G
#' }
#'
#' This closure is algebraic. It does not prove that \eqn{H_{bulk}} is a
#' physically perfect sensible-heat estimate. Any error in \eqn{R_n}, \eqn{G},
#' or \eqn{H_{bulk}} is inherited by the residual latent heat flux.
#'
#' Large absolute residuals are warned about using \code{warn_threshold}, but
#' they are not capped.
#'
#' @param rad_bal Net radiation \eqn{R_n} in W m-2.
#' @param soil_flux Soil heat flux \eqn{G} in W m-2.
#' @param sensible Sensible heat flux \eqn{H} in W m-2.
#' @param rho Air density in kg m-3, used by the weather-station method when
#'   \code{sensible} is not supplied and \code{sensible_bulk()} is calculated
#'   internally.
#' @param cp Specific heat capacity of air in J kg-1 K-1, used by the
#'   weather-station method when \code{sensible} is not supplied.
#' @param k von Karman constant, used by the weather-station method when
#'   \code{sensible} is not supplied.
#' @param min_wind Minimum wind speed in m s-1 used by the internal bulk
#'   calculation in the weather-station method.
#' @param warn_threshold Absolute flux threshold in W m-2 for diagnostic
#'   warnings.
#' @param ... Further arguments passed to methods.
#'
#' @return Latent heat flux in W m-2.
#'
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
#' Adds \code{sensible_bulk} and \code{latent_bulk_residual} to a
#' \code{weather_station} object.
#'
#' This workflow combines the simple bulk-transfer estimate of sensible heat
#' flux with an energy-balance residual for latent heat flux.
#'
#' First, sensible heat flux is estimated with:
#'
#' \deqn{
#' H_{bulk} = \rho c_p \frac{T_1 - T_2}{r_a}
#' }
#'
#' with:
#'
#' \deqn{
#' r_a = \frac{\log(z_2 / z_1)}{k \bar{u}}
#' }
#'
#' Then latent heat flux is calculated as:
#'
#' \deqn{
#' LE_{res} = R_n - G - H_{bulk}
#' }
#'
#' The resulting workflow closes the available turbulent energy exactly:
#'
#' \deqn{
#' H_{bulk} + LE_{res} = R_n - G
#' }
#'
#' under the package sign convention. Here \eqn{R_n > 0} is net radiative
#' input at the surface, \eqn{G > 0} is heat flux into the soil,
#' \eqn{H > 0} is sensible heat flux away from the surface, and
#' \eqn{LE > 0} is latent heat flux away from the surface.
#'
#' The workflow is intended as a transparent reference and teaching path. It is
#' not a full Monin-Obukhov method and does not apply stability corrections.
#' The latent heat flux is a residual and therefore depends directly on the
#' quality of \code{rad_bal}, \code{soil_flux}, and the bulk sensible heat
#' estimate.
#'
#' Required fields in \code{weather_station} are:
#'
#' \itemize{
#'   \item \code{t1}: lower air temperature in degrees C.
#'   \item \code{t2}: upper air temperature in degrees C.
#'   \item \code{v1}: lower wind speed in m s-1.
#'   \item \code{z1}: lower measurement height in m.
#'   \item \code{z2}: upper measurement height in m.
#'   \item \code{rad_bal}: net radiation \eqn{R_n} in W m-2.
#'   \item \code{soil_flux}: soil heat flux \eqn{G} in W m-2.
#' }
#'
#' If \code{v2} is present, it is used together with \code{v1} to compute mean
#' wind speed. If \code{v2} is missing, \code{v1} is used.
#'
#' @param weather_station A \code{weather_station} object.
#' @param ... Further arguments passed to \code{sensible_bulk()} and
#'   \code{latent_bulk_residual()}.
#'
#' @return The input \code{weather_station} object with additional fields
#'   \code{sensible_bulk} and \code{latent_bulk_residual}.
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
