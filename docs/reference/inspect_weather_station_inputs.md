# Inspect weather-station inputs for fieldClim workflows

Reports available, missing and partially missing inputs for common
`fieldClim` method families. This function is read-only: it does not
fill, derive, model, overwrite or mutate any field in the supplied
`weather_station` object.

## Usage

``` r
inspect_weather_station_inputs(
  weather_station,
  targets = c("all", "radiation", "soil", "humidity", "pressure", "profiles",
    "heat_flux"),
  methods = c("all", "priestley_taylor", "bulk_residual", "bowen", "monin_profile",
    "penman")
)
```

## Arguments

- weather_station:

  Object of class `weather_station`.

- targets:

  Character vector selecting input groups to inspect. Use `"all"` to
  include all known groups.

- methods:

  Character vector selecting method readiness checks. Use `"all"` to
  include all known methods.

## Value

A list of class `fieldclim_input_inspection` with fields: `fields`,
`method_readiness`, `possible_actions`, and `summary`.
