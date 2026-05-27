# Constants
p0_default <- 1013.25
g_default <- 9.81
rl_default <- 287.05
c2k_default <- 273.15
sigma_default <- 5.6704 * 10^-8
ozone_column_default <- 0.35
vis_default <- 30
sol_const_default <- 1368

# Surface properties
surface_properties <- data.frame(
  surface_type = c(
    "field",
    "acre",
    "lawn",
    "street",
    "agriculture",
    "settlement",
    "coniferous forest",
    "deciduous forest",
    "mixed forest",
    "city",
    "water",
    "shrub"
  ),
  emissivity = c(
    0.92,
    0.98,
    0.95,
    0.95,
    0.95,
    0.80,
    0.98,
    0.98,
    0.98,
    0.90,
    0.95,
    0.96
  ),
  roughness_length = c(
    0.02,
    0.05,
    0.20,
    0.20,
    0.20,
    1.00,
    1.00,
    1.50,
    1.50,
    2.00,
    0.01,
    0.50
  ),
  albedo = c(
    0.200,
    0.050,
    0.260,
    0.120,
    0.220,
    0.300,
    0.100,
    0.170,
    0.135,
    0.220,
    0.050,
    0.170
  )
)

# Priestley-Taylor coefficient
priestley_taylor_coefficient <- data.frame(
  surface_type = c(
    "field",
    "bare soil",
    "coniferous forest",
    "water",
    "wetland",
    "spruce forest"
  ),

  alpha = c(
    1.12,
    1.04,
    1.13,
    1.26,
    1.26,
    1.72
  )
)

surface_resistance <- data.frame(
  surface_type = c(
    "Temperate grassland",
    "Coniferous forest",
    "Temperate deciduous forest",
    "Tropical rain forest",
    "Cereal crops",
    "Broadleaved herbaceous crops"
  ),

  rs = c(
    60,
    50,
    50,
    80,
    30,
    35
  )
)

#' Check Availability
#'
#' Checks availability of passed properties in the weather station object.
#' If property is NULL, aborts with error.
#'
#' @inheritParams build_weather_station
#' @returns Absolutely nothing
#' @noRd
check_availability <- function(weather_station, ...) {
  unlisted <- names(weather_station)
  parameters <- as.character(unlist(list(...)))
  empty <- parameters[!parameters %in% unlisted]
  if (length(empty) > 1) {
    stop(
      paste(empty, collapse = ", "), " are not available in the weather_station object.\n",
      "Please set the needed parameters."
    )
  } else if (length(empty) > 0) {
    stop(
      paste(empty, collapse = ", "), " is not available in the weather_station object.\n",
      "Please set the needed parameter."
    )
  }
}

#check_availability <- function(weather_station, ...) {
#  unlisted <- names(c(weather_station[[1]], weather_station[[2]], weather_station[[3]]))
#  parameters <- as.character(unlist(list(...)))
#  empty <- parameters[!parameters %in% unlisted]
#  if (length(empty) > 1) {
#    stop(
#      paste(empty, collapse = ", "), " are not available in the weather_station object.\n",
#      "Please set the needed parameters."
#    )
#  } else if (length(empty) > 0) {
#    stop(
#      paste(empty, collapse = ", "), " is not available in the weather_station object.\n",
#      "Please set the needed parameter."
#    )
#  }
#}

#' Create a data.frame from a weather station object
#'
#' Create a data.frame from a weather station object, that contains weather station measurements.
#'
#' @param x Object of class weather_station.
#' @param reduced TRUE, to only output the most important columns.
#' @param unit TRUE, to generate longer column labels with units.
#' @param ... Not used.
#'
#' @returns data.frame
#' The columns of the data frame depend on `reduced` and `unit`.
#' If `reduced = F`, the data.frame contains all columns of the weather station
#' measurements. Legacy objects storing measurements in `x$measurements` are
#' supported as well.
#' If `reduced = T`, the data.frame contains: "datetime", "t1", "t2", "v1", "v2", "p1", "p2", "hum1", "hum2", "soil_flux", "sw_in", "sw_out", "lw_in", "lw_out", "sw_bal", "lw_bal", "rad_bal", "stability", "sensible_priestley_taylor", "latent_priestley_taylor","sensible_bowen", "latent_bowen","sensible_monin", "latent_monin","latent_penman"
#' If `unit = T`, the column names are replaced by more detailed names, containing the respective uits.
#'
#' @examples
#' \dontrun{
#' # create a weather_station object
#' test_station <- build_weather_station(
#'   lat = 50.840503,
#'   lon = 8.6833,
#'   elev = 270,
#'   surface_type = "Meadow",
#'   obs_height = 0.3, # obstacle height
#'   z1 = 2, # measurement heights
#'   z2 = 10,
#'   datetime = ws$datetime,
#'   t1 = ws$t1, # temperature
#'   t2 = ws$t2,
#'   v1 = ws$v1, # windspeed
#'   v2 = ws$v2,
#'   hum1 = ws$hum1, # humidity
#'   hum2 = ws$hum2,
#'   sw_in = ws$rad_sw_in, # shortwave radiation
#'   sw_out = ws$rad_sw_out,
#'   lw_in = ws$rad_lw_in, # longwave radiation
#'   lw_out = ws$rad_lw_out,
#'   soil_flux = ws$heatflux_soil
#' )
#'
#' # add turbulent fluxes to the object
#' station_turbulent <- turb_flux_calc(test_station)
#'
#' # create a data.frame which contains the same coloumns as the weather_station object
#' normal <- as.data.frame(station_turbulent)
#'
#' # create a reduced data.frame
#' reduced <- as.data.frame(station_turbulent, reduced = T)
#'
#' # create a reduced data.frame with detailed units
#' unit <- as.data.frame(station_turbulent, reduced = T, unit = T)
#' }
#' @export
as.data.frame.weather_station <- function(x, ...,
                                          reduced = F, unit = F) {
  measurements <- if (is.null(x$measurements)) unclass(x) else x$measurements
  out <- as.data.frame(measurements)

  # Define important columns
  important <- c(
    "datetime",
    "t1", "t2",
    "v1", "v2",
    "p1", "p2",
    "hum1", "hum2",
    "soil_flux",
    "sw_in", "sw_out",
    "lw_in", "lw_out",
    "sw_bal", "lw_bal", "rad_bal", "stability",
    "sensible_priestley_taylor", "latent_priestley_taylor",
    "sensible_bowen", "latent_bowen",
    "sensible_monin", "latent_monin",
    "latent_penman"
  )

  if (reduced) {
    out <- out[, important[important %in% colnames(out)]]
  }

  if (unit) {
    replacement <- c(
      "datetime",
      "temperature_lower[degC]",
      "temperature_upper[degC]",
      "wind_speed_lower[m/s]",
      "wind_speed_upper[m/s]",
      "pressure_lower[hPa]",
      "pressure_upper[hPa]",
      "humidity_lower[%]",
      "humidity_upper[%]",
      "soil_flux[W/m^2]",
      "shortwave_radiation_in[W/m^2]",
      "shortwave_radiation_out[W/m^2]",
      "longwave_radiation_in[W/m^2]",
      "longwave_radiation_out[W/m^2]",
      "shortwave_radiation_balance[W/m^2]",
      "longwave_radiation_balance[W/m^2]",
      "total_radiation_balance[W/m^2]",
      "atmospheric_stability",
      "sensible_heat[W/m^2]_Priestly-Taylor",
      "latent_heat[W/m^2]_Priestly-Taylor",
      "sensible_heat[W/m^2]_Bowen",
      "latent_heat[W/m^2]_Bowen",
      "sensible_heat[W/m^2]_Monin",
      "latent_heat[W/m^2]_Monin",
      "latent_heat[W/m^2]_Penman"
    )

    for (i in seq_along(important)) {
      names(out)[names(out) == important[i]] <- replacement[i]
    }
  }
  out
}

#' Radian to degree
#'
#' @param angle Angle in radian.
#' @returns Degree.
#' @noRd
rad2deg <- function(angle) {
  angle * 180 / pi
}

#' Degree to radian
#'
#' @param angle Angle in degree.
#' @returns Radian.
#' @noRd
deg2rad <- function(angle) {
  angle * pi / 180
}

#' Degree Celcius to Kelvin
#'
#' @param temp Temperature in degree Celcius.
#' @returns Kelvin
#' @noRd
c2k <- function(temp) {
  temp + c2k_default
}

#' Kelvin to degree Celcius
#'
#' @param temp Temperature in Kelvin.
#' @returns Degree Celcius.
#' @noRd
k2c <- function(temp) {
  temp - c2k_default
}
