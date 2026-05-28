#' Build a weather station object
#'
#' Creates a list of class `weather_station` from named input arguments.
#'
#' The function stores all named arguments exactly as provided. It does not
#' calculate physical quantities and it does not validate whether all fields are
#' sufficient for later methods. Downstream functions such as radiation,
#' soil-heat or turbulent-flux functions check whether the fields they need are
#' available.
#'
#' The object is therefore a structured container for station data, site
#' metadata, measurement heights and model assumptions.
#'
#' Common field names used by `fieldClim` methods include:
#'
#' \itemize{
#'   \item `datetime`: datetime vector, preferably with explicit timezone information.
#'   \item `lon`: longitude in degrees.
#'   \item `lat`: latitude in degrees.
#'   \item `elev`: elevation above sea level in m.
#'   \item `temp`: air temperature in degrees C.
#'   \item `rh`: relative humidity in percent.
#'   \item `t1`: air temperature at lower measurement height in degrees C.
#'   \item `t2`: air temperature at upper measurement height in degrees C.
#'   \item `hum1`: relative humidity at lower measurement height in percent.
#'   \item `hum2`: relative humidity at upper measurement height in percent.
#'   \item `v1`: wind speed at lower measurement height in m s-1.
#'   \item `v2`: wind speed at upper measurement height in m s-1.
#'   \item `z1`: lower measurement height in m.
#'   \item `z2`: upper measurement height in m.
#'   \item `rad_bal`: net radiation / radiation balance in W m-2.
#'   \item `soil_flux`: soil heat flux in W m-2.
#'   \item `surface_type`: surface-type label used by surface-dependent methods.
#'   \item `surface_temp`: surface temperature in degrees C.
#'   \item `moisture`: soil moisture in m3 m-3.
#'   \item `texture`: soil texture label.
#'   \item `soil_temp1`: soil temperature at first soil depth in degrees C.
#'   \item `soil_temp2`: soil temperature at second soil depth in degrees C.
#'   \item `soil_depth1`: first soil measurement depth in m.
#'   \item `soil_depth2`: second soil measurement depth in m.
#'   \item `slope`: slope in degrees.
#'   \item `exposition`: exposition / aspect in degrees.
#'   \item `valley`: logical value indicating valley position.
#'   \item `obs_height`: observation or obstacle height in m, depending on method.
#' }
#'
#' These names are conventions used by other `fieldClim` methods. Unknown names
#' are still stored in the object, but they are ignored by methods that do not
#' request them.
#'
#' @param ... Named station fields, site parameters or model assumptions.
#'
#' @return A list of class `weather_station`.
#'
#' @export
build_weather_station <- function(...) {
  out <- list()

  args <- list(...)
  for (i in seq_along(args)) {
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
    temp = "Air Temperature (degrees C)",
    t1 = "Air Temperature at Lower Height (degrees C)",
    t2 = "Air Temperature at Upper Height (degrees C)",
    v1 = "Windspeed at Lower Height (m/s)",
    v2 = "Windspeed at Upper Height (m/s)",
    slope = "Slope (degrees)",
    exposition = "Exposition (degrees)",
    surface_temp = "Surface Temperature (degrees C)",
    rh = "Relative Humidity (%)",
    hum1 = "Relative Humidity at Lower Height (%)",
    hum2 = "Relative Humidity at Upper Height (%)",
    rad_bal = "Radiation Balance (W m-2)",
    moisture = "Soil Moisture (m3 m-3)",
    soil_flux = "Soil Flux (W m-2)",
    soil_temp1 = "Soil Temperature Measurement 1 (degrees C)",
    soil_temp2 = "Soil Temperature Measurement 2 (degrees C)",
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
    graphics::par(mfrow = c(ceiling(sqrt(num_vars)), ceiling(sqrt(num_vars))), mar = c(4, 4, 2, 1))

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
    graphics::par(mfrow = c(1, 1))
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
