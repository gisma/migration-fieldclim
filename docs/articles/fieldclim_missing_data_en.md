# fieldClim: Missing-data inspection and input checks

## Purpose

This tutorial shows how to inspect station data before heat-flux
calculations. The goal is to learn the inspection workflow, not to
repair the dataset.

`fieldClim` does not repair, fill, impute, interpolate or complete the
data. It reports missingness, gap blocks, variable classes,
quality-control flags and method readiness. The first decision is the
variable type and the gap length, because method suitability depends on
what is missing and how the gap is structured. Quality control comes
before any external gap-filling workflow.

The sections below repeat the same tutorial pattern: run a command,
inspect a compact original output, then read a cleaned table and
interpretation.

## Example dataset

The example is based on the packaged Caldern one-day dataset. It
contains one five-minute day. Artificial gaps and obvious sensor
problems were inserted only to demonstrate inspection behavior. The file
is not a meteorological benchmark; it is a controlled tutorial dataset.
The original package dataset is unchanged.

First load the file. The robust file lookup is handled before this
chunk; the visible command is the part users normally need.

``` r

library(fieldClim)

caldern <- read.csv(
  gap_file,
  na.strings = c("NA", "NULL", ""),
  stringsAsFactors = FALSE
)
caldern$datetime <- as.POSIXct(
  caldern$datetime,
  tz = "Europe/Berlin"
)
```

A compact original view is enough to understand the logger columns used
in the tutorial. It shows time, air temperature, humidity, net
radiation, wind speed and soil heat flux.

``` r

head(caldern[, c(
  "datetime", "Ta_2m", "Huma_2m", "rad_net",
  "Windspeed_2m", "heatflux_soil"
)])
#>              datetime Ta_2m Huma_2m rad_net Windspeed_2m heatflux_soil
#> 1 2017-06-30 00:00:00 13.09   100.0 -15.200        0.448      1.551533
#> 2 2017-06-30 00:05:00 13.01   100.0  -8.920        0.380      1.492695
#> 3 2017-06-30 00:10:00 13.02   100.0  -1.965        0.548      1.448708
#> 4 2017-06-30 00:15:00 13.16   100.0  -1.790        0.581      1.390439
#> 5 2017-06-30 00:20:00 13.27   100.0  -2.469        0.764      1.325316
#> 6 2017-06-30 00:25:00 13.69    98.1  -3.857        0.589      1.268762
```

The overview table summarizes the dataset without printing all rows.

| Item                          | Value                    |
|:------------------------------|:-------------------------|
| Rows                          | 288                      |
| First timestamp               | 2017-06-30 00:00:00 CEST |
| Last timestamp                | 2017-06-30 23:55:00 CEST |
| Median timestep               | 300 seconds              |
| Number of variables           | 19                       |
| Variables with missing values | 6                        |

The row count is still the expected 288 records for a five-minute day.
The inspection problem is therefore not a missing file or an incomplete
day. It is that specific variables contain gaps or suspicious values
inside an otherwise regular teaching example.

## Build the weather_station object

[`build_weather_station()`](https://gisma.github.io/migration-fieldclim/reference/build_weather_station.md)
is only a container step. It stores station variables under names
expected by `fieldClim` functions. It does not check physics, repair
missing values or calculate replacement fields.

``` r

ws <- build_weather_station(
  datetime = caldern$datetime,
  temp = caldern$Ta_2m,
  rh = caldern$Huma_2m,
  t1 = caldern$Ta_2m,
  t2 = caldern$Ta_10m,
  hum1 = caldern$Huma_2m,
  hum2 = caldern$Huma_10m,
  v1 = caldern$Windspeed_2m,
  v2 = caldern$Windspeed_10m,
  rad_bal = caldern$rad_net,
  soil_flux = caldern$heatflux_soil,
  lat = 50.8405,
  lon = 8.6832,
  elev = 270,
  z1 = 2,
  z2 = 10,
  surface_type = "field"
)
```

The compact object structure shows that `ws` is a named weather-station
object. The vector lengths identify which fields are time series and
which are station metadata.

``` r

names(ws)
#>  [1] "datetime"     "temp"         "rh"           "t1"           "t2"          
#>  [6] "hum1"         "hum2"         "v1"           "v2"           "rad_bal"     
#> [11] "soil_flux"    "lat"          "lon"          "elev"         "z1"          
#> [16] "z2"           "surface_type"
sapply(ws, length)
#>     datetime         temp           rh           t1           t2         hum1 
#>          288          288          288          288          288          288 
#>         hum2           v1           v2      rad_bal    soil_flux          lat 
#>          288          288          288          288          288            1 
#>          lon         elev           z1           z2 surface_type 
#>            1            1            1            1            1
```

The important names for later checks are `temp`, `rh`, `rad_bal`,
`soil_flux`, `v1`, `v2`, `t1`, `t2`, `hum1` and `hum2`. Those are the
names downstream functions use, regardless of the original logger column
names.

## Run the inspection

Now run the inspection function. It returns a structured report, not
modified station data.

``` r

inspection <- inspect_weather_station_inputs(ws)
```

The first compact original output is simply the object structure: the
returned list contains field-level status, gap blocks, method readiness,
quality-control flags, guidance text and a summary.

``` r

names(inspection)
#> [1] "fields"           "gaps"             "method_readiness" "qc_flags"        
#> [5] "guidance"         "summary"
sapply(inspection, function(x) {
  if (is.data.frame(x)) {
    paste(nrow(x), "rows x", ncol(x), "columns")
  } else {
    paste(class(x), collapse = ", ")
  }
})
#>                 fields                   gaps       method_readiness 
#> "42 rows x 10 columns"   "7 rows x 9 columns"   "6 rows x 7 columns" 
#>               qc_flags               guidance                summary 
#>   "6 rows x 5 columns"   "5 rows x 2 columns"                 "list"
```

Read these components as follows. `fields` has one row per expected
station field. `gaps` reports consecutive missing blocks, not just total
`NA` counts. `qc_flags` identifies existing values that are suspicious
or physically impossible. `method_readiness` reports which heat-flux
methods have their required input fields.

## Inspect variable-level missingness

This step asks: which station fields contain missing values, and which
variable classes do those fields represent?

The compact original output below is a filtered view of
`inspection$fields`. It shows only fields that are present and have at
least one missing value.

``` r

subset(
  inspection$fields,
  present & n_missing > 0,
  select = c(field, variable_type, group, n_missing, n_total, missing_fraction)
)
#>        field  variable_type     group n_missing n_total missing_fraction
#> 5    rad_bal      radiation radiation        12     288      0.041666667
#> 17 soil_flux soil heat flux      soil        72     288      0.250000000
#> 25        rh       humidity  humidity         5     288      0.017361111
#> 26      hum1       humidity  humidity         5     288      0.017361111
#> 33      temp    temperature  profiles         1     288      0.003472222
#> 34        t1    temperature  profiles         1     288      0.003472222
#> 37        v1     wind speed  profiles        12     288      0.041666667
```

The same result is easier to read as a compact interpretation table.

|  | Field | Variable class | Group | Missing values | Missing fraction | First missing row | Largest gap (steps) |
|:---|:---|:---|:---|---:|---:|---:|---:|
| 1 | hum1 | humidity | humidity | 5 | 1.7% | 40 | 5 |
| 3 | rh | humidity | humidity | 5 | 1.7% | 40 | 5 |
| 5 | t1 | temperature | profiles | 1 | 0.3% | 20 | 1 |
| 6 | temp | temperature | profiles | 1 | 0.3% | 20 | 1 |
| 7 | v1 | wind speed | profiles | 12 | 4.2% | 130 | 12 |
| 2 | rad_bal | radiation | radiation | 12 | 4.2% | 100 | 12 |
| 4 | soil_flux | soil heat flux | soil | 72 | 25.0% | 180 | 72 |

In this dataset, the affected fields are `temp`, `t1`, `rh`, `hum1`,
`rad_bal`, `v1` and `soil_flux`. The most consequential fields for
heat-flux calculations are `rad_bal` and `soil_flux`, because together
they define available energy as `Rn - G`. Missing `v1` affects
aerodynamic and profile-related methods. Missing `hum1` affects
humidity-gradient and Penman-type calculations. Missing `t1` affects
profile methods and Bulk-Residual sensible heat.

## Inspect gap blocks

Total missing counts are not enough. This step asks whether the missing
values are isolated or form continuous blocks.

The compact original output sorts the gap table by length and shows the
most important gaps first.

``` r

inspection$gaps[order(-inspection$gaps$n_timesteps), ][1:10, ]
#>          field  variable_type gap_start_index gap_end_index n_timesteps
#> 2    soil_flux soil heat flux             180           251          72
#> 1      rad_bal      radiation             100           111          12
#> 7           v1     wind speed             130           141          12
#> 3           rh       humidity              40            44           5
#> 4         hum1       humidity              40            44           5
#> 5         temp    temperature              20            20           1
#> 6           t1    temperature              20            20           1
#> NA        <NA>           <NA>              NA            NA          NA
#> NA.1      <NA>           <NA>              NA            NA          NA
#> NA.2      <NA>           <NA>              NA            NA          NA
#>               start_time            end_time duration_seconds gap_class
#> 2    2017-06-30 14:55:00 2017-06-30 20:50:00            21600      long
#> 1    2017-06-30 08:15:00 2017-06-30 09:10:00             3600    medium
#> 7    2017-06-30 10:45:00 2017-06-30 11:40:00             3600    medium
#> 3    2017-06-30 03:15:00 2017-06-30 03:35:00             1500    medium
#> 4    2017-06-30 03:15:00 2017-06-30 03:35:00             1500    medium
#> 5    2017-06-30 01:35:00 2017-06-30 01:35:00              300     short
#> 6    2017-06-30 01:35:00 2017-06-30 01:35:00              300     short
#> NA                  <NA>                <NA>               NA      <NA>
#> NA.1                <NA>                <NA>               NA      <NA>
#> NA.2                <NA>                <NA>               NA      <NA>
```

The interpreted table keeps the same information but formats timestamps
and duration for reading.

|     | Field     | Variable class | Gap start | Gap end | Steps | Duration | Gap class |
|:----|:----------|:---------------|:----------|:--------|------:|---------:|:----------|
| 2   | soil_flux | soil heat flux | 14:55     | 20:50   |    72 |      6 h | long      |
| 1   | rad_bal   | radiation      | 08:15     | 09:10   |    12 |      1 h | medium    |
| 7   | v1        | wind speed     | 10:45     | 11:40   |    12 |      1 h | medium    |
| 4   | hum1      | humidity       | 03:15     | 03:35   |     5 |   25 min | medium    |
| 3   | rh        | humidity       | 03:15     | 03:35   |     5 |   25 min | medium    |
| 6   | t1        | temperature    | 01:35     | 01:35   |     1 |    5 min | short     |
| 5   | temp      | temperature    | 01:35     | 01:35   |     1 |    5 min | short     |

A single missing five-minute value is a row-level interruption. A 30-60
minute gap starts to affect subdaily interpretation. The multi-hour
`soil_flux` gap is more serious because it affects available energy
`Rn - G`. Wind gaps can affect Bulk-Residual, Penman and profile-based
methods. Humidity gaps affect Bowen, Monin-Obukhov/Profile and
Penman-type paths.

## Entry matrix: variable type and gap length

The inspection table tells us where values are missing. The entry matrix
explains why the consequence differs by variable type.

| Variable type | Fields in this example | What the inspection shows | Why this matters | What fieldClim does |
|:---|:---|:---|:---|:---|
| Temperature | `temp`, `t1` | An isolated missing air-temperature value. | Temperature enters profile gradients and helper calculations. | Reports this gap and affected methods. It does not repair the value. |
| Humidity | `rh`, `hum1` | A short humidity gap and one invalid relative-humidity value. | Humidity affects Bowen, Monin-Obukhov/Profile and Penman-type inputs. | Reports the gap and QC flag. It does not correct humidity values. |
| Radiation | `rad_bal` | A medium net-radiation gap and a suspicious shortwave value in the source data. | Radiation controls available energy for energy-balance methods. | Reports affected radiation fields. It does not substitute modeled radiation. |
| Wind speed | `v1` | A medium wind-speed gap and one negative wind-speed value. | Wind controls aerodynamic and profile-based methods. | Reports the gap and negative-wind flag. It does not invent wind speed. |
| Soil heat flux | `soil_flux` | A long continuous soil heat-flux gap. | Soil heat flux is subtracted from net radiation in `Rn - G`. | Reports the long gap and affected energy-balance methods. It does not replace soil heat flux. |

This table is not a ranking of filling methods. It is a reading guide
for the inspection output. The key research-based point is that variable
type, gap length and QC status determine the next external decision more
than any universal method ranking.

## Quality-control flags

Missing values are not the only problem. Some values are present but
should not be accepted without review.

The compact original output below is the actual `qc_flags` table
returned by
[`inspect_weather_station_inputs()`](https://gisma.github.io/migration-fieldclim/reference/inspect_weather_station_inputs.md).

``` r

inspection$qc_flags
#>       field row_index                   flag severity
#> 1        rh        60 humidity_outside_0_100    error
#> 2      hum1        60 humidity_outside_0_100    error
#> 3        v1        70    negative_wind_speed    error
#> 4  datetime        80   duplicated_timestamp  warning
#> 5  datetime        NA     irregular_timestep  warning
#> 6 soil_flux       180               long_gap  warning
#>                                                                                    message
#> 1                 Relative humidity should be within 0..100 percent before downstream use.
#> 2                 Relative humidity should be within 0..100 percent before downstream use.
#> 3                                                       Wind speed should not be negative.
#> 4             Duplicated timestamps can invalidate gap-length and workflow interpretation.
#> 5           Datetime spacing is irregular; inspect timebase before external gap treatment.
#> 6 Long missing-data run; variable type and gap length should guide any external treatment.
```

The formatted table adds timestamps and values where they are available.

| Field | Timestamp | Value | Flag type | Explanation |
|:---|:---|---:|:---|:---|
| rh | 2017-06-30 04:55 | 105.0 | humidity_outside_0_100 | Relative humidity should be within 0..100 percent before downstream use. |
| hum1 | 2017-06-30 04:55 | 105.0 | humidity_outside_0_100 | Relative humidity should be within 0..100 percent before downstream use. |
| v1 | 2017-06-30 05:45 | -0.5 | negative_wind_speed | Wind speed should not be negative. |
| datetime | 2017-06-30 06:30 | NA | duplicated_timestamp | Duplicated timestamps can invalidate gap-length and workflow interpretation. |
| datetime | NA | NA | irregular_timestep | Datetime spacing is irregular; inspect timebase before external gap treatment. |
| soil_flux | 2017-06-30 14:55 | NA | long_gap | Long missing-data run; variable type and gap length should guide any external treatment. |

In this dataset, relative humidity above 100 percent is invalid.
Negative wind speed is invalid. Duplicated or irregular timestamps
affect gap-length interpretation. A suspicious radiation value should be
checked against time of day and expected physical range. The value is
still present in the data; the inspection warns that it should not be
accepted without review.

The synthetic source data also include two intentionally obvious spike
examples that are useful for manual review.

| Field | Timestamp | Value | Interpretation |
|:---|:---|---:|:---|
| rad_sw_in | 2017-06-30 15:45 | 5000 | Check shortwave radiation against time of day and expected range. |
| Ta_2m | 2017-06-30 16:35 | 45 | Check whether the temperature spike is a sensor artefact. |

## Method readiness

This step connects the inspection to downstream heat-flux workflows. It
asks which methods have their required fields and which required fields
contain missing values.

The compact original output keeps the relevant readiness columns
visible.

``` r

inspection$method_readiness[, c(
  "method", "missing_fields", "partial_fields", "ready"
)]
#>                   method missing_fields                     partial_fields
#> 1       priestley_taylor                          temp, rad_bal, soil_flux
#> 2          bulk_residual                        t1, v1, rad_bal, soil_flux
#> 3 bulk_residual_ri_guard                        t1, v1, rad_bal, soil_flux
#> 4                  bowen                      t1, hum1, rad_bal, soil_flux
#> 5          monin_profile                                      t1, hum1, v1
#> 6                 penman     obs_height v1, temp, rad_bal, soil_flux, hum1
#>   ready
#> 1  TRUE
#> 2  TRUE
#> 3  TRUE
#> 4  TRUE
#> 5  TRUE
#> 6 FALSE
```

The interpreted method table translates that result into method-level
consequences for this dataset.

| Method | Required field groups | Structurally available? | Fields with gaps | What this means for this dataset |
|:---|:---|:---|:---|:---|
| Bowen-ratio | temperature and humidity gradients, heights, `rad_bal`, `soil_flux` | Yes | t1, hum1, rad_bal, soil_flux | If `rad_bal`, `soil_flux` or `temp` is missing at a timestep, `Rn - G` or temperature input is unavailable. |
| Bulk-Residual | temperature difference, wind, heights, `rad_bal`, `soil_flux` | Yes | t1, v1, rad_bal, soil_flux | Gaps in `t1`, `v1`, `rad_bal` or `soil_flux` affect `H_bulk` or residual `LE` at those rows. |
| Bulk-Residual with Richardson guard | Bulk-Residual inputs plus two wind heights | Yes | t1, v1, rad_bal, soil_flux | Two wind heights exist, but the same wind and energy-input gaps still matter row by row. |
| Monin-Obukhov/Profile | temperature, humidity and wind profiles plus site metadata | Yes | t1, hum1, v1 | Missing or invalid humidity affects the gradient ratio; energy-input gaps also affect partitioning. |
| Penman-type latent heat | radiation, soil heat flux, temperature, humidity, wind and site metadata | No | v1, temp, rad_bal, soil_flux, hum1 | Missing or invalid profile values directly affect the diagnostic profile calculation. |
| Priestley-Taylor | `rad_bal`, `soil_flux`, `temp`, `surface_type` | Yes | temp, rad_bal, soil_flux | Penman uses radiation, soil heat flux, temperature, humidity, wind and site metadata; it returns latent heat only. |

Priestley-Taylor uses `rad_bal`, `soil_flux`, `temp` and `surface_type`.
If `rad_bal` or `soil_flux` is missing at a timestep, `Rn - G` is
unavailable.

Bulk-Residual uses temperature difference, wind and heights for
`H_bulk`, plus `rad_bal` and `soil_flux` for residual `LE`. With the
optional Richardson guard, two wind heights are needed.

Bowen uses temperature and humidity gradients. Missing or invalid
humidity affects the gradient ratio.

Monin-Obukhov/Profile uses temperature, humidity and wind profiles.
Missing or invalid profile values directly affect the profile
calculation.

Penman uses radiation, soil heat flux, temperature, humidity, wind and
site metadata. It returns latent heat only.

## External continuation boundary

If gaps or suspicious values are found, the next step depends on the
variable type, gap length and analysis goal. A short temperature gap, a
radiation gap during changing cloud conditions and a missing wind
profile do not have the same meaning for later heat-flux calculations.
This is why the inspection first reports variable classes, gap blocks,
QC flags and method readiness instead of ranking algorithms.

| Package | Main_focus | Strength_for_this_task | Limitation_for_this_task | Best_fit_in_this_vignette |
|:---|:---|:---|:---|:---|
| [climatol](https://cran.r-project.org/package=climatol) | Climatological station series: quality control, homogenization, missing-data workflows and derived climate products. | Most relevant when a station series is longer than the one-day example and the problem is not only a short local gap, but consistency of a climatological record. It can support QC, homogenization and documented reconstruction of standard climate variables. | Not designed as an automatic row-level repair step inside a heat-flux calculation. Its assumptions, homogenization choices and reconstructed values would have to be documented before re-importing data into fieldClim. | Longer temperature, humidity, radiation or other climate-station series after fieldClim has shown where the gaps and QC problems are. |
| [dataresqc](https://cran.r-project.org/package=dataresqc) | Quality control and formatting of historical daily and sub-daily climate observations. | Most relevant before any later reconstruction step when the main question is whether the observed series is technically and physically trustworthy. It is useful for systematic QC, formatting and flagging of daily or sub-daily climate observations. | Primarily a QC and data-rescue tool, not a heat-flux or microclimate modelling package. It helps decide whether observations are trustworthy; it does not make fieldClim methods run on missing inputs. | Checking whether suspicious values such as impossible humidity, negative wind speed or inconsistent time structure should be flagged before any further processing. |
| [meteo](https://cran.r-project.org/package=meteo) | Spatial and spatio-temporal prediction for meteorological and environmental station variables. | Most relevant when local inspection shows that gaps cannot be interpreted from the target station alone. It can use neighbouring stations, coordinates, time and covariates for spatial or spatio-temporal prediction. | Requires a spatial prediction setup with stations, coordinates and validation. It is not a replacement for measured radiation, wind or soil-flux inputs unless that external modelling decision is explicitly justified. | Situations where fieldClim inspection shows that a variable is missing for too long to interpret locally and neighbouring stations or spatial covariates are available. |

## Summary

This tutorial demonstrated how
[`inspect_weather_station_inputs()`](https://gisma.github.io/migration-fieldclim/reference/inspect_weather_station_inputs.md)
can be used before running `fieldClim` heat-flux methods. The function
returns a structured inspection report with variable-level availability,
missing-value runs, quality-control flags and method-readiness
information.

The example shows why missing data must be interpreted by variable type
and gap length. A short temperature gap, a radiation gap, a missing wind
profile and a long soil-flux gap do not have the same consequences for
later calculations. The inspection output therefore helps identify which
variables require review and which method families are affected.

`fieldClim` does not fill, impute, interpolate, complete or replace
missing values. It reports the problem. Any decision to repair or
reconstruct data must be made outside `fieldClim`, documented
separately, and followed by a new inspection before heat-flux
calculations are interpreted.
