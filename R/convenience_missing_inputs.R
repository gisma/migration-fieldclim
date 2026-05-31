#' Inspect weather-station inputs for fieldClim workflows
#'
#' Reports available, missing and partially missing inputs for common
#' `fieldClim` method families. This function is read-only: it does not fill,
#' derive, model, overwrite or mutate any field in the supplied
#' `weather_station` object.
#'
#' @param weather_station Object of class `weather_station`.
#' @param targets Character vector selecting input groups to inspect. Use
#'   `"all"` to include all known groups.
#' @param methods Character vector selecting method readiness checks. Use
#'   `"all"` to include all known methods.
#'
#' @return A list of class `fieldclim_input_inspection` with fields:
#'   `fields`, `method_readiness`, `possible_actions`, and `summary`.
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
  method_readiness <- .fieldclim_method_readiness(weather_station, methods)
  possible_actions <- .fieldclim_possible_actions()
  possible_actions <- possible_actions[possible_actions$group %in% target_groups, names(possible_actions) != "group", drop = FALSE]

  unsafe_missing_fields <- fields$field[
    fields$source_status == "missing" &
      fields$field %in% c("v2", "z1", "z2", "surface_type", "hum1", "hum2", "t1", "t2")
  ]

  summary <- list(
    n_fields = nrow(fields),
    n_missing_fields = sum(fields$source_status == "missing"),
    n_partial_fields = sum(fields$source_status == "partial"),
    ready_methods = method_readiness$method[method_readiness$ready],
    blocked_methods = method_readiness$method[!method_readiness$ready],
    unsafe_missing_fields = unsafe_missing_fields
  )

  out <- list(
    fields = fields,
    method_readiness = method_readiness,
    possible_actions = possible_actions,
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
      "v1", "v2", "z1", "z2", "obs_height"
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
      "profiles", "profiles", "profiles", "profiles", "profiles"
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
      source_status = source_status,
      group = known_fields$group[i],
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

.fieldclim_method_specs <- function() {
  list(
    priestley_taylor = list(
      required = c("temp", "rad_bal", "soil_flux", "surface_type"),
      alternatives = list(),
      notes = "Requires measured or explicitly prepared available-energy inputs."
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

.fieldclim_method_readiness <- function(weather_station, methods) {
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
    present_required <- required[required %in% names(weather_station)]
    missing_required <- setdiff(required, names(weather_station))

    present_alt <- character()
    missing_alt <- character()
    if (length(spec$alternatives) > 0) {
      for (alt_name in names(spec$alternatives)) {
        choices <- spec$alternatives[[alt_name]]
        found <- choices[choices %in% names(weather_station)]
        if (length(found) > 0) {
          present_alt <- c(present_alt, found)
        } else {
          missing_alt <- c(missing_alt, alt_name)
        }
      }
    }

    missing_fields <- c(missing_required, missing_alt)
    present_fields <- c(present_required, present_alt)

    data.frame(
      method = method,
      required_fields = paste(c(required, names(spec$alternatives)), collapse = ", "),
      present_fields = paste(present_fields, collapse = ", "),
      missing_fields = paste(missing_fields, collapse = ", "),
      ready = length(missing_fields) == 0,
      notes = spec$notes,
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, rows)
}

.fieldclim_possible_actions <- function() {
  data.frame(
    target_field = c(
      "rad_bal", "rad_sw_in", "rad_sw_out", "soil_flux", "thermal_cond",
      "vapour_pressure", "absolute_humidity", "specific_humidity", "pressure",
      "v2", "z1", "z2", "surface_type", "hum1", "hum2", "t1", "t2", "profile_gradients"
    ),
    possible_action = c(
      "Derive net radiation from measured shortwave and longwave components.",
      "Model incoming shortwave from solar geometry and transmittance.",
      "Model reflected shortwave from surface-type albedo.",
      "Derive soil heat flux from soil temperature gradient and conductivity.",
      "Model or table-derive thermal conductivity from texture and moisture.",
      "Derive vapour pressure from relative humidity and temperature.",
      "Derive absolute humidity from relative humidity and temperature.",
      "Derive specific humidity from relative humidity, temperature and elevation.",
      "Model pressure from elevation and temperature.",
      "No filling recommended.",
      "Only explicit user-supplied height; no automatic filling.",
      "Only explicit user-supplied height; no automatic filling.",
      "Only explicit user-supplied surface type; no automatic default.",
      "Only explicit user mapping/default from profile information.",
      "Only explicit user mapping/default from profile information.",
      "Only explicit user mapping/default from profile information.",
      "Only explicit user mapping/default from profile information.",
      "No reconstruction from single-height data."
    ),
    required_inputs = c(
      "rad_sw_in, rad_sw_out, rad_lw_in, rad_lw_out",
      "datetime, lon, lat, elev, slope, exposition, temp/rh as needed",
      "rad_sw_in, surface_type or albedo",
      "soil_temp1, soil_temp2, soil_depth1, soil_depth2, thermal_cond",
      "texture, moisture",
      "rh, temp",
      "rh, temp",
      "rh, temp, elev",
      "elev, temp",
      "",
      "user supplied z1",
      "user supplied z2",
      "user supplied surface_type",
      "explicit user mapping",
      "explicit user mapping",
      "explicit user mapping",
      "explicit user mapping",
      ""
    ),
    source_type = c(
      "derived_from_measured", "modeled", "modeled", "derived_from_measured", "modeled",
      "derived_from_measured", "derived_from_measured", "derived_from_measured", "modeled",
      "not_recommended", "user_default", "user_default", "user_default", "user_default", "user_default",
      "user_default", "user_default", "not_recommended"
    ),
    risk_level = c(
      "low", "high", "high", "low/medium", "medium",
      "medium", "medium", "medium", "medium",
      "not_recommended", "high", "high", "high", "high", "high", "high", "high", "not_recommended"
    ),
    allowed_strategy = c(
      "derive_from_measured", "allow_modeled", "allow_modeled", "derive_from_measured", "allow_modeled",
      "derive_from_measured", "derive_from_measured", "derive_from_measured", "allow_modeled",
      "no filling", "allow_user_defaults", "allow_user_defaults", "allow_user_defaults",
      "allow_user_defaults", "allow_user_defaults", "allow_user_defaults", "allow_user_defaults", "no filling"
    ),
    default_action = rep("inspect_only", 18),
    group = c(
      "radiation", "radiation", "radiation", "soil", "soil",
      "humidity", "humidity", "humidity", "pressure",
      "profiles", "profiles", "profiles", "radiation", "humidity", "humidity", "profiles", "profiles", "profiles"
    ),
    stringsAsFactors = FALSE
  )
}
