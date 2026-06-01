#' Diagnose surface-energy-balance closure from existing flux fields
#'
#' This is a diagnostic function, not a flux model. It inspects existing
#' fields in a \code{weather_station} object and calculates closure quantities
#' from already-computed heat-flux outputs. It does not compute new turbulent
#' fluxes and does not alter the input object.
#'
#' The package sign convention is \eqn{R_n > 0} for net radiative input at the
#' surface, \eqn{G > 0} for soil heat flux into the soil, and \eqn{H > 0} and
#' \eqn{LE > 0} for turbulent fluxes away from the surface. Available energy is
#' calculated as:
#'
#' \deqn{A = R_n - G}
#'
#' using \code{available_energy = rad_bal - soil_flux}.
#'
#' For paired \eqn{H}/\eqn{LE} methods, including Priestley-Taylor,
#' Bulk-Residual, Bowen, and Monin/Profile diagnostics, the function computes:
#'
#' \deqn{closure\_residual = available\_energy - sensible - latent}
#'
#' and:
#'
#' \deqn{closure\_ratio = turbulent\_sum / available\_energy}
#'
#' where \code{turbulent_sum = sensible + latent}.
#'
#' For Penman, which is latent-heat-only in \pkg{fieldClim}, no paired
#' sensible heat flux is available. The function therefore computes:
#'
#' \deqn{unresolved\_complement = available\_energy - latent\_penman}
#'
#' The Penman complement must not be interpreted as measured sensible heat.
#' Monin/Profile residuals are diagnostic and are not forced to close. Formal
#' closure does not validate physical correctness; it only describes the
#' algebraic behaviour of the existing method outputs.
#'
#' @param weather_station A \code{weather_station} object containing
#'   \code{rad_bal}, \code{soil_flux}, and any already-computed flux fields to
#'   inspect.
#' @param methods Character vector of method families to inspect. Supported
#'   values are \code{"priestley_taylor"}, \code{"bulk_residual"},
#'   \code{"bowen"}, \code{"penman"}, and \code{"monin"}.
#' @param min_available Minimum absolute available energy in W m-2 required for
#'   stable closure-ratio interpretation.
#'
#' @return A long \code{data.frame} with one row per input row and requested
#'   method. Columns include \code{datetime}, \code{method},
#'   \code{closure_type}, \code{rad_bal}, \code{soil_flux},
#'   \code{available_energy}, \code{sensible}, \code{latent},
#'   \code{turbulent_sum}, \code{closure_residual}, \code{closure_ratio},
#'   \code{unresolved_complement}, and \code{status}.
#' @export
energy_balance_closure <- function(
    weather_station,
    methods = c("priestley_taylor", "bulk_residual", "bowen", "penman", "monin"),
    min_available = 20) {

  if (!inherits(weather_station, "weather_station")) {
    stop("weather_station must be an object of class 'weather_station'.", call. = FALSE)
  }

  if (!all(c("rad_bal", "soil_flux") %in% names(weather_station))) {
    stop("energy_balance_closure() requires rad_bal and soil_flux.", call. = FALSE)
  }

  method_specs <- list(
    priestley_taylor = list(
      closure_type = "partition_closure",
      sensible = "sensible_priestley_taylor",
      latent = "latent_priestley_taylor",
      penman = FALSE,
      monin = FALSE
    ),
    bulk_residual = list(
      closure_type = "residual_closure",
      sensible = "sensible_bulk",
      latent = "latent_bulk_residual",
      penman = FALSE,
      monin = FALSE
    ),
    bowen = list(
      closure_type = "partition_closure",
      sensible = "sensible_bowen",
      latent = "latent_bowen",
      penman = FALSE,
      monin = FALSE
    ),
    penman = list(
      closure_type = "le_only_open",
      sensible = NA_character_,
      latent = "latent_penman",
      penman = TRUE,
      monin = FALSE
    ),
    monin = list(
      closure_type = "profile_diagnostic",
      sensible = "sensible_monin",
      latent = "latent_monin",
      penman = FALSE,
      monin = TRUE
    )
  )

  methods <- unique(as.character(methods))
  invalid_methods <- setdiff(methods, names(method_specs))
  if (length(invalid_methods) > 0) {
    stop(
      "Unknown method(s): ",
      paste(invalid_methods, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  n <- max(length(weather_station$rad_bal), length(weather_station$soil_flux))
  datetime <- if ("datetime" %in% names(weather_station)) {
    rep_len(weather_station$datetime, n)
  } else {
    rep(as.POSIXct(NA), n)
  }
  rad_bal <- rep_len(weather_station$rad_bal, n)
  soil_flux <- rep_len(weather_station$soil_flux, n)
  available_energy <- rad_bal - soil_flux

  make_rows <- function(method) {
    spec <- method_specs[[method]]
    needed <- spec$latent
    if (!spec$penman) {
      needed <- c(spec$sensible, spec$latent)
    }
    missing_fields <- setdiff(needed, names(weather_station))

    sensible <- rep(NA_real_, n)
    latent <- rep(NA_real_, n)
    turbulent_sum <- rep(NA_real_, n)
    closure_residual <- rep(NA_real_, n)
    closure_ratio <- rep(NA_real_, n)
    unresolved_complement <- rep(NA_real_, n)
    status <- rep("ok", n)

    if (length(missing_fields) > 0) {
      status[] <- "missing_fields"
    } else if (spec$penman) {
      latent <- rep_len(weather_station[[spec$latent]], n)
      unresolved_complement <- available_energy - latent
      finite <- is.finite(rad_bal) &
        is.finite(soil_flux) &
        is.finite(available_energy) &
        is.finite(latent)
      low_available <- is.finite(available_energy) & abs(available_energy) < min_available

      status[] <- "open_complement"
      status[!finite] <- "missing"
      status[finite & low_available] <- "low_available_energy"
    } else {
      sensible <- rep_len(weather_station[[spec$sensible]], n)
      latent <- rep_len(weather_station[[spec$latent]], n)
      turbulent_sum <- sensible + latent
      closure_residual <- available_energy - turbulent_sum
      ratio_ok <- is.finite(available_energy) & abs(available_energy) >= min_available
      closure_ratio[ratio_ok] <- turbulent_sum[ratio_ok] / available_energy[ratio_ok]

      finite <- is.finite(rad_bal) &
        is.finite(soil_flux) &
        is.finite(available_energy) &
        is.finite(sensible) &
        is.finite(latent)
      low_available <- is.finite(available_energy) & abs(available_energy) < min_available
      large_residual <- is.finite(closure_residual) & abs(closure_residual) > 100

      status[!finite] <- "missing"
      status[finite & low_available] <- "low_available_energy"
      status[finite & !low_available & large_residual] <- "large_residual"
      if (isTRUE(spec$monin)) {
        status[finite & !low_available] <- "diagnostic_residual"
      }
    }

    data.frame(
      datetime = datetime,
      method = method,
      closure_type = spec$closure_type,
      rad_bal = rad_bal,
      soil_flux = soil_flux,
      available_energy = available_energy,
      sensible = sensible,
      latent = latent,
      turbulent_sum = turbulent_sum,
      closure_residual = closure_residual,
      closure_ratio = closure_ratio,
      unresolved_complement = unresolved_complement,
      status = status,
      stringsAsFactors = FALSE
    )
  }

  out <- do.call(rbind, lapply(methods, make_rows))
  rownames(out) <- NULL
  out
}

#' Plot energy-balance closure diagnostics
#'
#' Visualizes output from \code{energy_balance_closure()}. This is a plotting
#' helper for diagnostics, not a flux model. It does not compute new turbulent
#' fluxes and does not alter the diagnostic object.
#'
#' For residual plots, paired methods use \code{closure_residual}. Penman uses
#' \code{unresolved_complement}, labelled explicitly as such; the Penman
#' complement is not sensible heat. Monin/Profile residuals remain diagnostic
#' and are not forced to close.
#'
#' Ratio plots use \code{closure_ratio} for paired methods only. Penman is
#' excluded because fieldClim does not provide a paired Penman sensible heat
#' flux. Rows marked \code{low_available_energy} are omitted from ratio plots
#' because closure ratios are unstable near zero available energy.
#'
#' @param x Output from \code{energy_balance_closure()}.
#' @param type Plot type. \code{"residual"} plots closure residuals and Penman
#'   unresolved complements. \code{"ratio"} plots finite closure ratios for
#'   paired methods.
#' @param methods Optional character vector of methods to include.
#' @param ... Additional arguments passed to base plotting functions.
#'
#' @return Invisibly returns \code{x}.
#' @export
plot_energy_balance_closure <- function(
    x,
    type = c("residual", "ratio"),
    methods = NULL,
    ...) {

  type <- match.arg(type)

  required <- c(
    "datetime", "method", "closure_type", "closure_residual",
    "closure_ratio", "unresolved_complement", "status"
  )
  missing_columns <- setdiff(required, names(x))
  if (length(missing_columns) > 0) {
    stop(
      "x must be output from energy_balance_closure(); missing columns: ",
      paste(missing_columns, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  plot_data <- x
  if (!is.null(methods)) {
    plot_data <- plot_data[plot_data$method %in% methods, , drop = FALSE]
  }

  if (nrow(plot_data) == 0) {
    graphics::plot.new()
    graphics::text(0.5, 0.5, "No closure diagnostics to plot")
    return(invisible(x))
  }

  if (type == "residual") {
    plot_data$plot_value <- plot_data$closure_residual
    penman <- plot_data$closure_type == "le_only_open" | plot_data$method == "penman"
    plot_data$plot_value[penman] <- plot_data$unresolved_complement[penman]
    plot_data$plot_label <- ifelse(penman, "unresolved_complement", "closure_residual")
    plot_data <- plot_data[is.finite(plot_data$plot_value), , drop = FALSE]
    ylab <- "Closure residual / unresolved complement (W m-2)"
  } else {
    plot_data <- plot_data[
      plot_data$method != "penman" &
        plot_data$closure_type != "le_only_open" &
        is.finite(plot_data$closure_ratio),
      ,
      drop = FALSE
    ]
    if ("status" %in% names(plot_data)) {
      plot_data <- plot_data[plot_data$status != "low_available_energy", , drop = FALSE]
    }
    plot_data$plot_value <- plot_data$closure_ratio
    plot_data$plot_label <- "closure_ratio"
    ylab <- "Closure ratio ((H + LE) / available energy)"
  }

  if (nrow(plot_data) == 0) {
    graphics::plot.new()
    graphics::text(0.5, 0.5, paste("No", type, "diagnostics to plot"))
    return(invisible(x))
  }

  x_axis <- if (inherits(plot_data$datetime, "POSIXt")) {
    plot_data$datetime
  } else {
    seq_len(nrow(plot_data))
  }

  groups <- unique(paste(plot_data$method, plot_data$plot_label, sep = ": "))
  colors <- seq_along(groups)
  graphics::plot(
    x_axis,
    plot_data$plot_value,
    type = "n",
    xlab = "Time",
    ylab = ylab,
    ...
  )
  graphics::abline(h = if (type == "ratio") 1 else 0, col = "grey70", lty = 2)

  for (i in seq_along(groups)) {
    parts <- strsplit(groups[i], ": ", fixed = TRUE)[[1]]
    rows <- plot_data$method == parts[1] & plot_data$plot_label == parts[2]
    graphics::lines(x_axis[rows], plot_data$plot_value[rows], col = colors[i], type = "b")
  }

  graphics::legend(
    "topright",
    legend = groups,
    col = colors,
    lty = 1,
    pch = 1,
    bty = "n"
  )

  invisible(x)
}
