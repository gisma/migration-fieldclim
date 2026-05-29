#' sc Priestley-Taylor slope coefficient
#'
#' Internal Priestley-Taylor helper for the package-scale slope coefficient
#' used together with gam().
#'
#' The function represents the temperature-dependent sc values from the same
#' Foken/Stull Table 6 scale used by gam(). The coefficients are based on
#' specific humidity and have units kg kg-1 K-1. The helper is used in the
#' Priestley-Taylor ratio sc / (sc + gam()) and should not be mixed with
#' coefficients on another unit scale.
#'
#' @param t Air temperature in deg C.
#'
#' @returns Foken/Stull table-scale slope coefficient in kg kg-1 K-1.
#' @noRd
sc <- function(t) {
  8.5 * 10^(-7) * (t + 273.15)^2 - 0.0004479 * (t + 273.15) + 0.05919
}


#' gamma Priestley-Taylor coefficient
#'
#' Internal Priestley-Taylor helper for the package-scale psychrometric
#' coefficient used together with sc().
#'
#' The function is documented in the package source as a polynomial fit to
#' Table 6 in Foken (2013, p. 48). That table gives temperature-dependent
#' gamma and sc values based on specific humidity after Stull (1988).
#' Therefore, gam() returns a Foken/Stull table-scale coefficient in
#' kg kg-1 K-1 for use in the Priestley-Taylor ratio. It is not the FAO-56
#' psychrometric constant in kPa K-1.
#'
#' @param t Air temperature in deg C.
#'
#' @returns Foken/Stull table-scale psychrometric coefficient in kg kg-1 K-1.
#' @noRd
gam <- function(t) {
  0.0004 + (0.00041491 - 0.0004) / (1 + (299.44 / (t + 273.15))^383.4)
}


#' Bowen-ratio
#'
#' Calculates Bowen-ratio.
#'
#' @param t Air temperature in °C.
#' @param dpot Difference in potential temperature between the two measurement
#' heights in °C.
#' @param dah Difference in absolute humidity (kg/m\eqn{^3}) between the two measurement heights.
#'
#' @returns Bowen-ratio
#' @noRd
#' @references Bendix 2004, p. 221eq9.21.
bowen_ratio <- function(t, dpot, dah) {
  heat_cap <- heat_capacity(t)
  evap_heat <- hum_evap_heat(t)
  (heat_cap * dpot) / (evap_heat * dah)
}

#' Volumetric heat capacity
#'
#' Calculates volumetric heat capacity
#'
#' @param t Air temperature in °C.
#'
#' @returns Heat capacity density in J/(K*m\eqn{^3})
#' @noRd
#' @references Bendix 2004, p. 261.
heat_capacity <- function(t) {
  1005 * (1.2754298 - 0.0047219538 * t + 1.6463585 * 10^-5 * t)
}
