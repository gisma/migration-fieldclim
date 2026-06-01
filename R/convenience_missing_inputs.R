#' Inspect weather-station inputs for fieldClim workflows
#'
#' Reports available, missing and partially missing inputs for common
#' `fieldClim` method families. This function is read-only: it does not alter,
#' complete, impute, interpolate, model or replace any value in the supplied
#' `weather_station` object.
#'
#' The inspection classifies variable groups, missing-value runs and selected
#' quality-control issues. It is intended to help users decide which downstream
#' methods cannot run because inputs are missing and which variables need
#' external quality-control review. Any treatment of missing meteorological
#' time-series values must happen outside `fieldClim` in a documented workflow.
#'
#' @param weather_station Object of class `weather_station`.
#' @param targets Character vector selecting input groups to inspect. Use
#'   `"all"` to include all known groups.
#' @param methods Character vector selecting method readiness checks. Use
#'   `"all"` to include all known methods.
#'
#' @return A list of class `fieldclim_input_inspection` with fields:
#'   `fields`, `gaps`, `method_readiness`, `qc_flags`, `guidance`, and
#'   `summary`.
#' @export
inspect_weather_station_inputs <- function(
    weather_station,
    targets = c("all", "radiation", "soil", "humidity", "pressure", "profiles", "heat_flux"),
    methods = c("all", "priestley_taylor", "bulk_residual", "bowen", "monin_profile", "penman")) {

  if (!inherits(weather_station, "weather_station")) {
    stop("weather_station must be an object of class 'weather_station'.", call. = FALSE)
  }

  targets <- .fieldclim_match_choices(targets, c("all", "radiation", "soil", "humidity", "pressure", "profiles", "heat_flux"))
  methods <- .fieldclim_match_choices(methods, c("all", "priestley_taylor", "bulk_residual", "bowen", "monin_profile", "penman"))

  target_groups <- if ("all" %in% targets) {
    c("radiation", "soil", "humidity", "pressure", "profiles", "heat_flux", "metadata")
  } else {
    unique(c(targets, "metadata"))
  }

  known_fields <- .fieldclim_known_input_fields()
  known_fields <- known_fields[known_fields$group %in% target_groups, , drop = FALSE]

  fields <- .fieldclim_field_status(weather_station, known_fields)
  gaps <- .fieldclim_gap_status(weather_station, fields)
  method_readiness <- .fieldclim_method_readiness(weather_station, fields, methods)
  qc_flags <- .fieldclim_qc_flags(weather_station, fields, gaps)
  guidance <- .fieldclim_inspection_guidance()

  unsafe_missing_fields <- fields$field[
    fields$source_status == "missing" &
      fields$field %in% c("v2", "z1", "z2", "surface_type", "hum1", "hum2", "t1", "t2")
  ]

  summary <- list(
    n_fields = nrow(fields),
    n_missing_fields = sum(fields$source_status == "missing"),
    n_partial_fields = sum(fields$source_status == "partial"),
    n_gaps = nrow(gaps),
    n_qc_flags = nrow(qc_flags),
    ready_methods = method_readiness$method[method_readiness$ready],
    blocked_methods = method_readiness$method[!method_readiness$ready],
    unsafe_missing_fields = unsafe_missing_fields
  )

  out <- list(
    fields = fields,
    gaps = gaps,
    method_readiness = method_readiness,
    qc_flags = qc_flags,
    guidance = guidance,
    summary = summary
  )
  class(out) <- "fieldclim_input_inspection"
  out
}

.fieldclim_match_choices <- function(x, choices) {
  if (missing(x) || is.null(x)) {
    return("all")
  }
  x <- as.character(x)
  invalid <- setdiff(x, choices)
  if (length(invalid) > 0) {
    stop(
      "Invalid value: ",
      paste(invalid, collapse = ", "),
      ". Allowed values are: ",
      paste(choices, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  unique(x)
}

.fieldclim_known_input_fields <- function() {
  data.frame(
    field = c(
      "datetime", "lat", "lon", "elev",
      "rad_bal", "rad_net", "rad_sw_in", "rad_sw_out", "rad_lw_in", "rad_lw_out",
      "albedo", "surface_type", "surface_temp", "slope", "exposition", "valley",
      "soil_flux", "soil_temp1", "soil_temp2", "soil_depth1", "soil_depth2",
      "thermal_cond", "texture", "moisture",
      "rh", "hum1", "hum2", "vapour_pressure", "vapor_pressure",
      "absolute_humidity", "specific_humidity",
      "pressure",
      "temp", "t1", "t2", "potential_temperature",
      "v1", "v2", "wind_dir", "z1", "z2", "obs_height"
    ),
    group = c(
      "metadata", "metadata", "metadata", "metadata",
      "radiation", "radiation", "radiation", "radiation", "radiation", "radiation",
      "radiation", "radiation", "radiation", "radiation", "radiation", "radiation",
      "soil", "soil", "soil", "soil", "soil", "soil", "soil", "soil",
      "humidity", "humidity", "humidity", "humidity", "humidity",
      "humidity", "humidity",
      "pressure",
      "profiles", "profiles", "profiles", "profiles",
      "profiles", "profiles", "profiles", "profiles", "profiles", "profiles"
    ),
    variable_type = c(
      "metadata", "metadata", "metadata", "metadata",
      "radiation", "radiation", "radiation", "radiation", "radiation", "radiation",
      "radiation", "surface", "temperature", "metadata", "metadata", "metadata",
      "soil heat flux", "soil temperature", "soil temperature", "metadata", "metadata",
      "soil thermal property", "soil texture", "soil moisture",
      "humidity", "humidity", "humidity", "humidity", "humidity",
      "humidity", "humidity",
      "pressure",
      "temperature", "temperature", "temperature", "temperature",
      "wind speed", "wind speed", "wind direction", "metadata", "metadata", "metadata"
    ),
    stringsAsFactors = FALSE
  )
}

.fieldclim_field_status <- function(weather_station, known_fields) {
  rows <- lapply(seq_len(nrow(known_fields)), function(i) {
    field <- known_fields$field[i]
    present <- field %in% names(weather_station)
    value <- if (present) weather_station[[field]] else NULL
    n_total <- if (present) length(value) else 0L
    n_missing <- if (present && n_total > 0L) sum(is.na(value)) else if (present) 0L else 0L
    all_missing <- !present || (n_total > 0L && n_missing == n_total)
    any_missing <- !present || n_missing > 0L

    source_status <- if (!present || all_missing) {
      "missing"
    } else if (any_missing) {
      "partial"
    } else {
      "present"
    }

    data.frame(
      field = field,
      present = present,
      all_missing = all_missing,
      any_missing = any_missing,
      n_missing = n_missing,
      n_total = n_total,
      missing_fraction = if (n_total > 0L) n_missing / n_total else NA_real_,
      source_status = source_status,
      group = known_fields$group[i],
      variable_type = known_fields$variable_type[i],
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

.fieldclim_gap_status <- function(weather_station, fields) {
  present_fields <- fields$field[fields$present & fields$n_total > 0L]
  if (length(present_fields) == 0L) {
    return(.fieldclim_empty_gaps())
  }

  datetime <- if ("datetime" %in% names(weather_station) && inherits(weather_station$datetime, "POSIXt")) {
    weather_station$datetime
  } else {
    NULL
  }

  out <- lapply(present_fields, function(field) {
    value <- weather_station[[field]]
    missing <- is.na(value)
    if (!any(missing)) {
      return(.fieldclim_empty_gaps())
    }

    runs <- rle(missing)
    ends <- cumsum(runs$lengths)
    starts <- ends - runs$lengths + 1L
    missing_runs <- which(runs$values)

    rows <- lapply(missing_runs, function(i) {
      start_i <- starts[i]
      end_i <- ends[i]
      n_steps <- runs$lengths[i]
      start_time <- .fieldclim_datetime_at(datetime, start_i)
      end_time <- .fieldclim_datetime_at(datetime, end_i)
      duration_seconds <- .fieldclim_gap_duration(datetime, start_i, end_i, n_steps)

      data.frame(
        field = field,
        variable_type = fields$variable_type[fields$field == field][1],
        gap_start_index = start_i,
        gap_end_index = end_i,
        n_timesteps = n_steps,
        start_time = start_time,
        end_time = end_time,
        duration_seconds = duration_seconds,
        gap_class = .fieldclim_gap_class(n_steps),
        stringsAsFactors = FALSE
      )
    })
    do.call(rbind, rows)
  })

  gaps <- do.call(rbind, out)
  rownames(gaps) <- NULL
  gaps
}

.fieldclim_empty_gaps <- function() {
  data.frame(
    field = character(),
    variable_type = character(),
    gap_start_index = integer(),
    gap_end_index = integer(),
    n_timesteps = integer(),
    start_time = as.POSIXct(character()),
    end_time = as.POSIXct(character()),
    duration_seconds = numeric(),
    gap_class = character(),
    stringsAsFactors = FALSE
  )
}

.fieldclim_datetime_at <- function(datetime, index) {
  if (is.null(datetime) || index > length(datetime)) {
    return(as.POSIXct(NA))
  }
  as.POSIXct(datetime[index])
}

.fieldclim_gap_duration <- function(datetime, start_i, end_i, n_steps) {
  if (is.null(datetime) || length(datetime) < 2L || end_i > length(datetime)) {
    return(NA_real_)
  }
  dt <- diff(as.numeric(as.POSIXct(datetime)))
  step <- stats::median(dt[is.finite(dt) & dt > 0], na.rm = TRUE)
  if (!is.finite(step)) {
    return(NA_real_)
  }
  n_steps * step
}

.fieldclim_gap_class <- function(n_steps) {
  if (is.na(n_steps)) {
    return(NA_character_)
  }
  if (n_steps <= 2L) {
    "short"
  } else if (n_steps <= 12L) {
    "medium"
  } else {
    "long"
  }
}

.fieldclim_method_specs <- function() {
  list(
    priestley_taylor = list(
      required = c("temp", "rad_bal", "soil_flux", "surface_type"),
      alternatives = list(),
      notes = "Requires available measured input fields for temperature, net radiation, soil heat flux and surface type."
    ),
    bulk_residual = list(
      required = c("t1", "t2", "v1", "z1", "z2", "rad_bal", "soil_flux"),
      alternatives = list(),
      notes = "Neutral bulk path can use v1 only; v2 is optional for mean wind."
    ),
    bulk_residual_ri_guard = list(
      required = c("t1", "t2", "v1", "v2", "z1", "z2", "rad_bal", "soil_flux"),
      alternatives = list(),
      notes = "Optional Richardson guard requires v2 and remains unavailable when v2 is missing."
    ),
    bowen = list(
      required = c("t1", "t2", "hum1", "hum2", "z1", "z2", "elev", "rad_bal", "soil_flux"),
      alternatives = list(),
      notes = "Requires two-level temperature and humidity profiles."
    ),
    monin_profile = list(
      required = c("t1", "t2", "hum1", "hum2", "v1", "v2", "z1", "z2", "elev"),
      alternatives = list(surface_type_or_obs_height = c("surface_type", "obs_height")),
      notes = "Requires profile inputs plus either surface_type or obs_height."
    ),
    penman = list(
      required = c("datetime", "v1", "temp", "rad_bal", "elev", "lat", "lon", "soil_flux", "obs_height", "surface_type"),
      alternatives = list(hum1_or_rh = c("hum1", "rh")),
      notes = "Uses hum1 when present, otherwise rh; both are interpreted as relative humidity percent."
    )
  )
}

.fieldclim_method_readiness <- function(weather_station, fields, methods) {
  selected <- if ("all" %in% methods) {
    c("priestley_taylor", "bulk_residual", "bulk_residual_ri_guard", "bowen", "monin_profile", "penman")
  } else {
    out <- methods
    if ("bulk_residual" %in% out) {
      out <- unique(c(out, "bulk_residual_ri_guard"))
    }
    out
  }

  specs <- .fieldclim_method_specs()
  rows <- lapply(selected, function(method) {
    spec <- specs[[method]]
    required <- spec$required
    field_status <- fields[match(required, fields$field), ]
    present_required <- required[!is.na(field_status$field) & field_status$present]
    missing_required <- required[is.na(field_status$field) | field_status$source_status == "missing"]
    partial_required <- required[!is.na(field_status$field) & field_status$source_status == "partial"]

    present_alt <- character()
    missing_alt <- character()
    partial_alt <- character()
    if (length(spec$alternatives) > 0) {
      for (alt_name in names(spec$alternatives)) {
        choices <- spec$alternatives[[alt_name]]
        choice_status <- fields[match(choices, fields$field), ]
        available <- choices[!is.na(choice_status$field) & choice_status$source_status != "missing"]
        if (length(available) > 0) {
          present_alt <- c(present_alt, available[1])
          if (choice_status$source_status[match(available[1], choices)] == "partial") {
            partial_alt <- c(partial_alt, available[1])
          }
        } else {
          missing_alt <- c(missing_alt, alt_name)
        }
      }
    }

    missing_fields <- c(missing_required, missing_alt)
    partial_fields <- c(partial_required, partial_alt)
    present_fields <- c(present_required, present_alt)

    data.frame(
      method = method,
      required_fields = paste(c(required, names(spec$alternatives)), collapse = ", "),
      present_fields = paste(present_fields, collapse = ", "),
      missing_fields = paste(missing_fields, collapse = ", "),
      partial_fields = paste(partial_fields, collapse = ", "),
      ready = length(missing_fields) == 0,
      notes = spec$notes,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

.fieldclim_qc_flags <- function(weather_station, fields, gaps) {
  rows <- list()
  add_flag <- function(field, row_index, flag, severity, message) {
    rows[[length(rows) + 1L]] <<- data.frame(
      field = field,
      row_index = row_index,
      flag = flag,
      severity = severity,
      message = message,
      stringsAsFactors = FALSE
    )
  }

  for (field in intersect(c("rh", "hum1", "hum2"), names(weather_station))) {
    value <- weather_station[[field]]
    bad <- which(!is.na(value) & (value < 0 | value > 100))
    if (length(bad) > 0L) {
      add_flag(field, bad, "humidity_outside_0_100", "error", "Relative humidity should be within 0..100 percent before downstream use.")
    }
  }

  for (field in intersect(c("v1", "v2"), names(weather_station))) {
    value <- weather_station[[field]]
    bad <- which(!is.na(value) & value < 0)
    if (length(bad) > 0L) {
      add_flag(field, bad, "negative_wind_speed", "error", "Wind speed should not be negative.")
    }
  }

  if ("moisture" %in% names(weather_station)) {
    value <- weather_station$moisture
    bad <- which(!is.na(value) & (value < 0 | value > 1))
    if (length(bad) > 0L) {
      add_flag("moisture", bad, "soil_moisture_outside_0_1", "warning", "Soil moisture is expected as m3 m-3 and should usually be within 0..1.")
    }
  }

  if ("datetime" %in% names(weather_station) && inherits(weather_station$datetime, "POSIXt")) {
    duplicated_time <- which(duplicated(weather_station$datetime))
    if (length(duplicated_time) > 0L) {
      add_flag("datetime", duplicated_time, "duplicated_timestamp", "warning", "Duplicated timestamps can invalidate gap-length and workflow interpretation.")
    }

    dt <- diff(as.numeric(as.POSIXct(weather_station$datetime)))
    finite_dt <- dt[is.finite(dt)]
    if (length(finite_dt) > 1L && length(unique(finite_dt)) > 1L) {
      add_flag("datetime", NA_integer_, "irregular_timestep", "warning", "Datetime spacing is irregular; inspect timebase before external gap treatment.")
    }
  }

  long_gaps <- gaps[gaps$gap_class == "long", , drop = FALSE]
  if (nrow(long_gaps) > 0L) {
    for (i in seq_len(nrow(long_gaps))) {
      add_flag(long_gaps$field[i], long_gaps$gap_start_index[i], "long_gap", "warning", "Long missing-data run; variable type and gap length should guide any external treatment.")
    }
  }

  if (length(rows) == 0L) {
    return(.fieldclim_empty_qc_flags())
  }

  flags <- do.call(rbind, rows)
  rownames(flags) <- NULL
  flags
}

.fieldclim_empty_qc_flags <- function() {
  data.frame(
    field = character(),
    row_index = integer(),
    flag = character(),
    severity = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}

.fieldclim_inspection_guidance <- function() {
  data.frame(
    topic = c(
      "variable_type",
      "gap_length",
      "quality_control",
      "method_availability",
      "external_workflow"
    ),
    guidance = c(
      "Classify the variable first; temperature, humidity, wind, radiation, soil and pressure variables have different treatment risks.",
      "Classify gap length before choosing an external data workflow; short and long gaps are not equivalent.",
      "Apply quality control before external missing-data treatment; flag physically impossible values, spikes and sensor failures first.",
      "fieldClim reports which heat-flux methods lack required inputs; it does not make missing inputs usable.",
      "Any missing-data treatment must be performed outside fieldClim with documented provenance."
    ),
    stringsAsFactors = FALSE
  )
}
