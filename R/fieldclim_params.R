#' Common fieldClim parameter documentation
#'
#' @param weather_station A `weather_station` object.
#' @param datetime Datetime vector, preferably with explicit timezone information.
#' @param lon Longitude in degrees.
#' @param lat Latitude in degrees.
#' @param elev Elevation above sea level in m.
#' @param temp Air temperature in degrees C.
#' @param rh Relative humidity in percent.
#' @param slope Slope in degrees.
#' @param exposition Exposition or aspect in degrees.
#' @param valley Logical value indicating whether the station is in a valley.
#' @param surface_type Surface-type label.
#' @param surface_temp Surface temperature in degrees C.
#' @param texture Soil texture label.
#' @param moisture Soil moisture in m3 m-3.
#' @param soil_temp1 Soil temperature at first soil depth in degrees C.
#' @param soil_temp2 Soil temperature at second soil depth in degrees C.
#' @param soil_depth1 First soil measurement depth in m.
#' @param soil_depth2 Second soil measurement depth in m.
#'
#' @keywords internal
#' @noRd
fieldclim_params <- function(
    weather_station = NULL,
    datetime = NULL,
    lon = NULL,
    lat = NULL,
    elev = NULL,
    temp = NULL,
    rh = NULL,
    slope = NULL,
    exposition = NULL,
    valley = NULL,
    surface_type = NULL,
    surface_temp = NULL,
    texture = NULL,
    moisture = NULL,
    soil_temp1 = NULL,
    soil_temp2 = NULL,
    soil_depth1 = NULL,
    soil_depth2 = NULL) {
  NULL
}