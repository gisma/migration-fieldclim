#' Build a weather station object
#'
#' Creates a list of class `weather_station` that contains all input arguments.
#'
#' Provided input arguments will only be used if they are listed in the section
#' "Arguments". No warning message is generated for unused arguments.
#'
#' @param ... Additional arguments.
#' @param weather_station Object of class `weather_station`.
#' @param datetime Datetime of class `POSIXlt`. See [base::as.POSIXlt()].
#'    Make sure to provide the correct timezone information!
#' @param lon Longitude in degree.
#' @param lat Latitude in degree.
#' @param elev Elevation above sea level in m.
#' @param temp Air temperature in degree Celcius.
#' @param t1 Air temperature at lower height in degree Celcius.
#' @param t2 Air temperature at upper height in degree Celcius.
#' @param v1 Windspeed at lower height (e.g. height of anemometer) in m/s.
#' @param v2 Windspeed at upper height in m/s.
#' @param slope Slope in degree.
#' @param exposition Exposition in degree.
#' @param surface_type Surface type.
#'   Allowed values are: `r surface_properties$surface_type`.
#'   EXCEPTION: for functions related to Priestley-Taylor methods,
#'   allowed values are: `r priestley_taylor_coefficient$surface_type`.
#' @param obs_height Height of obstacle in m.
#' @param valley Is the position in a valley (`TRUE`) or on a slope (`FALSE`)?
#' @param surface_temp Surface temperature in degree Celcius.
#' @param rh Relative humidity in %.
#' @param hum1 Relative humidity at lower height in %.
#' @param hum2 Relative humidity at upper height in %.
#' @param rad_bal Radiation balance in W/m\eqn{^2}.
#' @param texture Soil texture. Either "sand", "clay", or "peat".
#' @param moisture Soil moisture in cubic meter/cubic meter.
#' @param soil_flux Soil flux in W/m\eqn{^2}.
#' @param soil_temp1 Soil temperature in degree Celcius of measurement 1.
#' @param soil_temp2 Soil temperature in degree Celcius of measurement 2.
#' @param soil_depth1 Depth of the soil temperature measurement 1 in m.
#' @param soil_depth2 Depth of the soil temperature measurement 2 in m.
#' @inheritDotParams rad_sw_toa.default sol_const
#' @inheritDotParams pres_p.default p0 g rl
#' @inheritDotParams trans_ozone.default ozone_column
#' @inheritDotParams trans_aerosol.default vis
#' @inheritDotParams pres_sat_vapor_p.default a b
#' @inheritDotParams rad_lw_in.default sigma
#'
#' @export
build_weather_station <- function(...) {
  out <- list()

  args <- list(...)
  for (i in seq_along(args)) {
    # Add additional parameters to the right spot in the list
    name <- names(args)[i]
    value <- args[[i]]
    out[[name]] <- value
  }

  class(out) <- "weather_station"

  out
}


#' Plot Weather Station Data
#'
#' This function creates a time series plot of a specified variable from a weather station object. If no variable is specified, it will plot all time series variables in a grid layout.
#'
#' @param weather_station A list or data frame containing weather station data. The object should contain a `datetime` field and other variables.
#' @param variable_name A character string specifying the name of the variable to be plotted. If `NULL`, all time series variables will be plotted in a grid layout.
#'
#' @details
#' The `plot_weather_station` function generates a time series line plot for a specified variable within a weather station object. If no variable is specified, it plots all available time series variables in a grid layout. Non-time series variables, such as those with a single value or character data, are automatically excluded.
#'
#' The function uses base R plotting functions to ensure minimal dependencies and simplicity in usage.
#'
#' @return A plot is created as a side effect.
#'
#' @examples
#' # Assuming `weather_station` is a list or data frame with a datetime field and other variables
#' # Example weather_station object creation
#' weather_station <- list(
#'   datetime = as.POSIXct(c("2023-08-01 00:00", "2023-08-01 01:00", "2023-08-01 02:00")),
#'   temp = c(15.5, 16.0, 16.5),
#'   windspeed = c(3.2, 3.5, 3.1),
#'   location = "Test Location"  # This will be excluded from the plot
#' )
#'
#' # Plot the temperature data
#' plot_weather_station(weather_station, "temp")
#'
#' # Plot all time series variables
#' plot_weather_station(weather_station, NULL)
#'
#' @export
plot_weather_station <- function(weather_station, variable_name = NULL) {
  # Mapping of variable names to labels and units
  variable_labels <- list(
    temp = "Air Temperature (°C)",
    t1 = "Air Temperature at Lower Height (°C)",
    t2 = "Air Temperature at Upper Height (°C)",
    v1 = "Windspeed at Lower Height (m/s)",
    v2 = "Windspeed at Upper Height (m/s)",
    slope = "Slope (°)",
    exposition = "Exposition (°)",
    surface_temp = "Surface Temperature (°C)",
    rh = "Relative Humidity (%)",
    hum1 = "Relative Humidity at Lower Height (%)",
    hum2 = "Relative Humidity at Upper Height (%)",
    rad_bal = "Radiation Balance (W/m²)",
    moisture = "Soil Moisture (m³/m³)",
    soil_flux = "Soil Flux (W/m²)",
    soil_temp1 = "Soil Temperature Measurement 1 (°C)",
    soil_temp2 = "Soil Temperature Measurement 2 (°C)",
    soil_depth1 = "Soil Depth Measurement 1 (m)",
    soil_depth2 = "Soil Depth Measurement 2 (m)"
  )

  # Identify variables that are time series (same length as datetime)
  time_series_vars <- names(weather_station)[sapply(weather_station, function(x) length(x) == length(weather_station$datetime))]

  # Exclude the datetime variable itself from plotting
  time_series_vars <- setdiff(time_series_vars, "datetime")

  # Check if a specific variable was provided
  if (is.null(variable_name)) {
    # Plot all time series variables in a grid layout
    num_vars <- length(time_series_vars)

    if (num_vars == 0) {
      stop("No time series variables available to plot.")
    }

    # Set up grid layout for plots
    par(mfrow = c(ceiling(sqrt(num_vars)), ceiling(sqrt(num_vars))), mar = c(4, 4, 2, 1))

    for (var in time_series_vars) {
      # Get the label and unit for the variable
      label <- ifelse(!is.null(variable_labels[[var]]), variable_labels[[var]], var)

      plot(
        weather_station$datetime, weather_station[[var]],
        type = "l",
        col = "blue",
        lwd = 2,
        xlab = "Time",
        ylab = label,
        main = paste("Time Series of", label)
      )
    }

    # Reset layout to single plot
    par(mfrow = c(1, 1))
  } else {
    # Check if the variable exists in the list of time series variables
    if (!variable_name %in% time_series_vars) {
      stop(paste("Variable", variable_name, "is not a valid time series variable in the weather station object."))
    }

    # Extract the datetime and the chosen variable
    datetime <- weather_station$datetime
    variable_data <- weather_station[[variable_name]]

    # Get the label and unit for the variable
    label <- ifelse(!is.null(variable_labels[[variable_name]]), variable_labels[[variable_name]], variable_name)

    # Create a time series plot
    plot(
      datetime, variable_data,
      type = "l",  # Line plot
      col = "blue",
      lwd = 2,
      xlab = "Time",
      ylab = label,
      main = paste("Time Series of", label)
    )
  }
}
