# Inspect weather-station inputs for fieldClim workflows

Reports available, missing and partially missing inputs for common
`fieldClim` method families. This function is read-only: it does not
alter, complete, impute, interpolate, model or replace any value in the
supplied `weather_station` object.

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
  include all known groups. Available groups are `"radiation"`,
  `"soil"`, `"humidity"`, `"pressure"`, `"profiles"` and `"heat_flux"`.

- methods:

  Character vector selecting method-readiness checks. Use `"all"` to
  include all known methods. Available methods are `"priestley_taylor"`,
  `"bulk_residual"`, `"bowen"`, `"monin_profile"` and `"penman"`.
  Selecting `"bulk_residual"` also includes the optional
  `"bulk_residual_ri_guard"` readiness check.

## Value

A list of class `fieldclim_input_inspection` with fields: `fields`,
`gaps`, `method_readiness`, `qc_flags`, `guidance`, and `summary`.

## Details

The inspection classifies variable groups, missing-value runs and
selected quality-control issues. It is intended to help users decide
which downstream methods cannot run because inputs are missing and which
variables need external quality-control review. Any treatment of missing
meteorological time-series values must happen outside `fieldClim` in a
documented workflow.

The returned object is a structured inspection report:

- `fields` reports whether known input fields are present, missing or
  partially missing.

- `gaps` reports consecutive missing-value runs in present fields.

- `method_readiness` reports whether selected heat-flux workflows have
  their required inputs available.

- `qc_flags` reports selected physically suspicious values, such as
  relative humidity outside 0..100 percent or negative wind speed.

- `guidance` records the inspection-only policy and the main
  interpretation rules.

- `summary` provides compact counts and lists of ready/blocked methods.

`inspect_weather_station_inputs()` does not decide how missing data
should be treated. The first interpretation step is to classify the
affected variable and the gap length. A one-point gap in a smooth
temperature series has a very different consequence from a long gap in
radiation, wind or soil heat flux. Quality-control problems must also be
reviewed before any external gap-filling workflow is considered.

## Examples

``` r
dt <- as.POSIXct(
  "2017-06-30 00:00:00",
  tz = "Europe/Berlin"
) + seq(0, by = 300, length.out = 6)

ws <- build_weather_station(
  datetime = dt,
  temp = c(15, 16, NA, 18, 19, 20),
  rh = c(80, 78, 105, 73, NA, 68),
  t1 = c(15, 16, NA, 18, 19, 20),
  t2 = c(14, 15, 16, 17, 18, 19),
  hum1 = c(80, 78, 105, 73, NA, 68),
  hum2 = c(82, 80, 77, 75, 72, 70),
  v1 = c(1.2, -1, 1.1, NA, 1.5, 1.6),
  v2 = c(2.0, 2.1, 2.2, 2.0, 2.3, 2.4),
  rad_bal = c(0, 20, NA, NA, 150, 160),
  soil_flux = c(0, 5, 10, 15, 20, 20),
  lat = 50.8405,
  lon = 8.6832,
  elev = 270,
  z1 = 2,
  z2 = 10,
  surface_type = "field"
)

inspection <- inspect_weather_station_inputs(ws)

names(inspection)
#> [1] "fields"           "gaps"             "method_readiness" "qc_flags"        
#> [5] "guidance"         "summary"         
inspection$summary
#> $n_fields
#> [1] 42
#> 
#> $n_missing_fields
#> [1] 25
#> 
#> $n_partial_fields
#> [1] 6
#> 
#> $n_gaps
#> [1] 6
#> 
#> $n_qc_flags
#> [1] 3
#> 
#> $ready_methods
#> [1] "priestley_taylor"       "bulk_residual"          "bulk_residual_ri_guard"
#> [4] "bowen"                  "monin_profile"         
#> 
#> $blocked_methods
#> [1] "penman"
#> 
#> $unsafe_missing_fields
#> character(0)
#> 
inspection$fields
#>                    field present all_missing any_missing n_missing n_total
#> 1               datetime    TRUE       FALSE       FALSE         0       6
#> 2                    lat    TRUE       FALSE       FALSE         0       1
#> 3                    lon    TRUE       FALSE       FALSE         0       1
#> 4                   elev    TRUE       FALSE       FALSE         0       1
#> 5                rad_bal    TRUE       FALSE        TRUE         2       6
#> 6                rad_net   FALSE        TRUE        TRUE         0       0
#> 7              rad_sw_in   FALSE        TRUE        TRUE         0       0
#> 8             rad_sw_out   FALSE        TRUE        TRUE         0       0
#> 9              rad_lw_in   FALSE        TRUE        TRUE         0       0
#> 10            rad_lw_out   FALSE        TRUE        TRUE         0       0
#> 11                albedo   FALSE        TRUE        TRUE         0       0
#> 12          surface_type    TRUE       FALSE       FALSE         0       1
#> 13          surface_temp   FALSE        TRUE        TRUE         0       0
#> 14                 slope   FALSE        TRUE        TRUE         0       0
#> 15            exposition   FALSE        TRUE        TRUE         0       0
#> 16                valley   FALSE        TRUE        TRUE         0       0
#> 17             soil_flux    TRUE       FALSE       FALSE         0       6
#> 18            soil_temp1   FALSE        TRUE        TRUE         0       0
#> 19            soil_temp2   FALSE        TRUE        TRUE         0       0
#> 20           soil_depth1   FALSE        TRUE        TRUE         0       0
#> 21           soil_depth2   FALSE        TRUE        TRUE         0       0
#> 22          thermal_cond   FALSE        TRUE        TRUE         0       0
#> 23               texture   FALSE        TRUE        TRUE         0       0
#> 24              moisture   FALSE        TRUE        TRUE         0       0
#> 25                    rh    TRUE       FALSE        TRUE         1       6
#> 26                  hum1    TRUE       FALSE        TRUE         1       6
#> 27                  hum2    TRUE       FALSE       FALSE         0       6
#> 28       vapour_pressure   FALSE        TRUE        TRUE         0       0
#> 29        vapor_pressure   FALSE        TRUE        TRUE         0       0
#> 30     absolute_humidity   FALSE        TRUE        TRUE         0       0
#> 31     specific_humidity   FALSE        TRUE        TRUE         0       0
#> 32              pressure   FALSE        TRUE        TRUE         0       0
#> 33                  temp    TRUE       FALSE        TRUE         1       6
#> 34                    t1    TRUE       FALSE        TRUE         1       6
#> 35                    t2    TRUE       FALSE       FALSE         0       6
#> 36 potential_temperature   FALSE        TRUE        TRUE         0       0
#> 37                    v1    TRUE       FALSE        TRUE         1       6
#> 38                    v2    TRUE       FALSE       FALSE         0       6
#> 39              wind_dir   FALSE        TRUE        TRUE         0       0
#> 40                    z1    TRUE       FALSE       FALSE         0       1
#> 41                    z2    TRUE       FALSE       FALSE         0       1
#> 42            obs_height   FALSE        TRUE        TRUE         0       0
#>    missing_fraction source_status     group         variable_type
#> 1         0.0000000       present  metadata              metadata
#> 2         0.0000000       present  metadata              metadata
#> 3         0.0000000       present  metadata              metadata
#> 4         0.0000000       present  metadata              metadata
#> 5         0.3333333       partial radiation             radiation
#> 6                NA       missing radiation             radiation
#> 7                NA       missing radiation             radiation
#> 8                NA       missing radiation             radiation
#> 9                NA       missing radiation             radiation
#> 10               NA       missing radiation             radiation
#> 11               NA       missing radiation             radiation
#> 12        0.0000000       present radiation               surface
#> 13               NA       missing radiation           temperature
#> 14               NA       missing radiation              metadata
#> 15               NA       missing radiation              metadata
#> 16               NA       missing radiation              metadata
#> 17        0.0000000       present      soil        soil heat flux
#> 18               NA       missing      soil      soil temperature
#> 19               NA       missing      soil      soil temperature
#> 20               NA       missing      soil              metadata
#> 21               NA       missing      soil              metadata
#> 22               NA       missing      soil soil thermal property
#> 23               NA       missing      soil          soil texture
#> 24               NA       missing      soil         soil moisture
#> 25        0.1666667       partial  humidity              humidity
#> 26        0.1666667       partial  humidity              humidity
#> 27        0.0000000       present  humidity              humidity
#> 28               NA       missing  humidity              humidity
#> 29               NA       missing  humidity              humidity
#> 30               NA       missing  humidity              humidity
#> 31               NA       missing  humidity              humidity
#> 32               NA       missing  pressure              pressure
#> 33        0.1666667       partial  profiles           temperature
#> 34        0.1666667       partial  profiles           temperature
#> 35        0.0000000       present  profiles           temperature
#> 36               NA       missing  profiles           temperature
#> 37        0.1666667       partial  profiles            wind speed
#> 38        0.0000000       present  profiles            wind speed
#> 39               NA       missing  profiles        wind direction
#> 40        0.0000000       present  profiles              metadata
#> 41        0.0000000       present  profiles              metadata
#> 42               NA       missing  profiles              metadata
inspection$gaps
#>     field variable_type gap_start_index gap_end_index n_timesteps
#> 1 rad_bal     radiation               3             4           2
#> 2      rh      humidity               5             5           1
#> 3    hum1      humidity               5             5           1
#> 4    temp   temperature               3             3           1
#> 5      t1   temperature               3             3           1
#> 6      v1    wind speed               4             4           1
#>            start_time            end_time duration_seconds gap_class
#> 1 2017-06-30 00:10:00 2017-06-30 00:15:00              600     short
#> 2 2017-06-30 00:20:00 2017-06-30 00:20:00              300     short
#> 3 2017-06-30 00:20:00 2017-06-30 00:20:00              300     short
#> 4 2017-06-30 00:10:00 2017-06-30 00:10:00              300     short
#> 5 2017-06-30 00:10:00 2017-06-30 00:10:00              300     short
#> 6 2017-06-30 00:15:00 2017-06-30 00:15:00              300     short
inspection$qc_flags
#>   field row_index                   flag severity
#> 1    rh         3 humidity_outside_0_100    error
#> 2  hum1         3 humidity_outside_0_100    error
#> 3    v1         2    negative_wind_speed    error
#>                                                                    message
#> 1 Relative humidity should be within 0..100 percent before downstream use.
#> 2 Relative humidity should be within 0..100 percent before downstream use.
#> 3                                       Wind speed should not be negative.
inspection$method_readiness
#>                   method
#> 1       priestley_taylor
#> 2          bulk_residual
#> 3 bulk_residual_ri_guard
#> 4                  bowen
#> 5          monin_profile
#> 6                 penman
#>                                                                                required_fields
#> 1                                                       temp, rad_bal, soil_flux, surface_type
#> 2                                                       t1, t2, v1, z1, z2, rad_bal, soil_flux
#> 3                                                   t1, t2, v1, v2, z1, z2, rad_bal, soil_flux
#> 4                                         t1, t2, hum1, hum2, z1, z2, elev, rad_bal, soil_flux
#> 5                         t1, t2, hum1, hum2, v1, v2, z1, z2, elev, surface_type_or_obs_height
#> 6 datetime, v1, temp, rad_bal, elev, lat, lon, soil_flux, obs_height, surface_type, hum1_or_rh
#>                                                               present_fields
#> 1                                     temp, rad_bal, soil_flux, surface_type
#> 2                                     t1, t2, v1, z1, z2, rad_bal, soil_flux
#> 3                                 t1, t2, v1, v2, z1, z2, rad_bal, soil_flux
#> 4                       t1, t2, hum1, hum2, z1, z2, elev, rad_bal, soil_flux
#> 5                     t1, t2, hum1, hum2, v1, v2, z1, z2, elev, surface_type
#> 6 datetime, v1, temp, rad_bal, elev, lat, lon, soil_flux, surface_type, hum1
#>   missing_fields          partial_fields ready
#> 1                          temp, rad_bal  TRUE
#> 2                        t1, v1, rad_bal  TRUE
#> 3                        t1, v1, rad_bal  TRUE
#> 4                      t1, hum1, rad_bal  TRUE
#> 5                           t1, hum1, v1  TRUE
#> 6     obs_height v1, temp, rad_bal, hum1 FALSE
#>                                                                                                       notes
#> 1 Requires available measured input fields for temperature, net radiation, soil heat flux and surface type.
#> 2                                          Neutral bulk path can use v1 only; v2 is optional for mean wind.
#> 3                         Optional Richardson guard requires v2 and remains unavailable when v2 is missing.
#> 4                                                     Requires two-level temperature and humidity profiles.
#> 5                                           Requires profile inputs plus either surface_type or obs_height.
#> 6                  Uses hum1 when present, otherwise rh; both are interpreted as relative humidity percent.

# The function reports missingness and quality-control flags only.
# It does not fill, impute, interpolate, model or replace values.

inspect_weather_station_inputs(
  ws,
  targets = c("radiation", "soil", "profiles"),
  methods = c("priestley_taylor", "bulk_residual", "bowen")
)
#> $fields
#>                    field present all_missing any_missing n_missing n_total
#> 1               datetime    TRUE       FALSE       FALSE         0       6
#> 2                    lat    TRUE       FALSE       FALSE         0       1
#> 3                    lon    TRUE       FALSE       FALSE         0       1
#> 4                   elev    TRUE       FALSE       FALSE         0       1
#> 5                rad_bal    TRUE       FALSE        TRUE         2       6
#> 6                rad_net   FALSE        TRUE        TRUE         0       0
#> 7              rad_sw_in   FALSE        TRUE        TRUE         0       0
#> 8             rad_sw_out   FALSE        TRUE        TRUE         0       0
#> 9              rad_lw_in   FALSE        TRUE        TRUE         0       0
#> 10            rad_lw_out   FALSE        TRUE        TRUE         0       0
#> 11                albedo   FALSE        TRUE        TRUE         0       0
#> 12          surface_type    TRUE       FALSE       FALSE         0       1
#> 13          surface_temp   FALSE        TRUE        TRUE         0       0
#> 14                 slope   FALSE        TRUE        TRUE         0       0
#> 15            exposition   FALSE        TRUE        TRUE         0       0
#> 16                valley   FALSE        TRUE        TRUE         0       0
#> 17             soil_flux    TRUE       FALSE       FALSE         0       6
#> 18            soil_temp1   FALSE        TRUE        TRUE         0       0
#> 19            soil_temp2   FALSE        TRUE        TRUE         0       0
#> 20           soil_depth1   FALSE        TRUE        TRUE         0       0
#> 21           soil_depth2   FALSE        TRUE        TRUE         0       0
#> 22          thermal_cond   FALSE        TRUE        TRUE         0       0
#> 23               texture   FALSE        TRUE        TRUE         0       0
#> 24              moisture   FALSE        TRUE        TRUE         0       0
#> 25                  temp    TRUE       FALSE        TRUE         1       6
#> 26                    t1    TRUE       FALSE        TRUE         1       6
#> 27                    t2    TRUE       FALSE       FALSE         0       6
#> 28 potential_temperature   FALSE        TRUE        TRUE         0       0
#> 29                    v1    TRUE       FALSE        TRUE         1       6
#> 30                    v2    TRUE       FALSE       FALSE         0       6
#> 31              wind_dir   FALSE        TRUE        TRUE         0       0
#> 32                    z1    TRUE       FALSE       FALSE         0       1
#> 33                    z2    TRUE       FALSE       FALSE         0       1
#> 34            obs_height   FALSE        TRUE        TRUE         0       0
#>    missing_fraction source_status     group         variable_type
#> 1         0.0000000       present  metadata              metadata
#> 2         0.0000000       present  metadata              metadata
#> 3         0.0000000       present  metadata              metadata
#> 4         0.0000000       present  metadata              metadata
#> 5         0.3333333       partial radiation             radiation
#> 6                NA       missing radiation             radiation
#> 7                NA       missing radiation             radiation
#> 8                NA       missing radiation             radiation
#> 9                NA       missing radiation             radiation
#> 10               NA       missing radiation             radiation
#> 11               NA       missing radiation             radiation
#> 12        0.0000000       present radiation               surface
#> 13               NA       missing radiation           temperature
#> 14               NA       missing radiation              metadata
#> 15               NA       missing radiation              metadata
#> 16               NA       missing radiation              metadata
#> 17        0.0000000       present      soil        soil heat flux
#> 18               NA       missing      soil      soil temperature
#> 19               NA       missing      soil      soil temperature
#> 20               NA       missing      soil              metadata
#> 21               NA       missing      soil              metadata
#> 22               NA       missing      soil soil thermal property
#> 23               NA       missing      soil          soil texture
#> 24               NA       missing      soil         soil moisture
#> 25        0.1666667       partial  profiles           temperature
#> 26        0.1666667       partial  profiles           temperature
#> 27        0.0000000       present  profiles           temperature
#> 28               NA       missing  profiles           temperature
#> 29        0.1666667       partial  profiles            wind speed
#> 30        0.0000000       present  profiles            wind speed
#> 31               NA       missing  profiles        wind direction
#> 32        0.0000000       present  profiles              metadata
#> 33        0.0000000       present  profiles              metadata
#> 34               NA       missing  profiles              metadata
#> 
#> $gaps
#>     field variable_type gap_start_index gap_end_index n_timesteps
#> 1 rad_bal     radiation               3             4           2
#> 2    temp   temperature               3             3           1
#> 3      t1   temperature               3             3           1
#> 4      v1    wind speed               4             4           1
#>            start_time            end_time duration_seconds gap_class
#> 1 2017-06-30 00:10:00 2017-06-30 00:15:00              600     short
#> 2 2017-06-30 00:10:00 2017-06-30 00:10:00              300     short
#> 3 2017-06-30 00:10:00 2017-06-30 00:10:00              300     short
#> 4 2017-06-30 00:15:00 2017-06-30 00:15:00              300     short
#> 
#> $method_readiness
#>                   method                                      required_fields
#> 1       priestley_taylor               temp, rad_bal, soil_flux, surface_type
#> 2          bulk_residual               t1, t2, v1, z1, z2, rad_bal, soil_flux
#> 3                  bowen t1, t2, hum1, hum2, z1, z2, elev, rad_bal, soil_flux
#> 4 bulk_residual_ri_guard           t1, t2, v1, v2, z1, z2, rad_bal, soil_flux
#>                               present_fields missing_fields  partial_fields
#> 1     temp, rad_bal, soil_flux, surface_type                  temp, rad_bal
#> 2     t1, t2, v1, z1, z2, rad_bal, soil_flux                t1, v1, rad_bal
#> 3   t1, t2, z1, z2, elev, rad_bal, soil_flux     hum1, hum2     t1, rad_bal
#> 4 t1, t2, v1, v2, z1, z2, rad_bal, soil_flux                t1, v1, rad_bal
#>   ready
#> 1  TRUE
#> 2  TRUE
#> 3 FALSE
#> 4  TRUE
#>                                                                                                       notes
#> 1 Requires available measured input fields for temperature, net radiation, soil heat flux and surface type.
#> 2                                          Neutral bulk path can use v1 only; v2 is optional for mean wind.
#> 3                                                     Requires two-level temperature and humidity profiles.
#> 4                         Optional Richardson guard requires v2 and remains unavailable when v2 is missing.
#> 
#> $qc_flags
#>   field row_index                   flag severity
#> 1    rh         3 humidity_outside_0_100    error
#> 2  hum1         3 humidity_outside_0_100    error
#> 3    v1         2    negative_wind_speed    error
#>                                                                    message
#> 1 Relative humidity should be within 0..100 percent before downstream use.
#> 2 Relative humidity should be within 0..100 percent before downstream use.
#> 3                                       Wind speed should not be negative.
#> 
#> $guidance
#>                 topic
#> 1       variable_type
#> 2          gap_length
#> 3     quality_control
#> 4 method_availability
#> 5   external_workflow
#>                                                                                                                             guidance
#> 1   Classify the variable first; temperature, humidity, wind, radiation, soil and pressure variables have different treatment risks.
#> 2                             Classify gap length before choosing an external data workflow; short and long gaps are not equivalent.
#> 3 Apply quality control before external missing-data treatment; flag physically impossible values, spikes and sensor failures first.
#> 4                            fieldClim reports which heat-flux methods lack required inputs; it does not make missing inputs usable.
#> 5                                         Any missing-data treatment must be performed outside fieldClim with documented provenance.
#> 
#> $summary
#> $summary$n_fields
#> [1] 34
#> 
#> $summary$n_missing_fields
#> [1] 20
#> 
#> $summary$n_partial_fields
#> [1] 4
#> 
#> $summary$n_gaps
#> [1] 4
#> 
#> $summary$n_qc_flags
#> [1] 3
#> 
#> $summary$ready_methods
#> [1] "priestley_taylor"       "bulk_residual"          "bulk_residual_ri_guard"
#> 
#> $summary$blocked_methods
#> [1] "bowen"
#> 
#> $summary$unsafe_missing_fields
#> character(0)
#> 
#> 
#> attr(,"class")
#> [1] "fieldclim_input_inspection"
```
