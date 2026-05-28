# Total Radiation Balance

Calculates the total radiation balance by summing the shortwave and
longwave radiation balances.

## Usage

``` r
rad_bal(...)

# Default S3 method
rad_bal(
  datetime,
  lon,
  lat,
  elev,
  temp,
  rh,
  slope,
  exposition,
  valley,
  surface_type,
  surface_temp,
  ...
)

# S3 method for class 'weather_station'
rad_bal(weather_station, ...)
```

## Arguments

- ...:

  Named station fields, site parameters or model assumptions.

- datetime:

  POSIXlt or POSIXct date-time vector.

- lon:

  Longitude in degrees.

- lat:

  Latitude in degrees.

- elev:

  Elevation above sea level in m.

- temp:

  Air temperature in degrees C.

- rh:

  Relative humidity in percent.

- slope:

  Slope in degrees.

- exposition:

  Exposition or aspect in degrees.

- valley:

  Logical value indicating whether the station is in a valley.

- surface_type:

  Surface-type label.

- surface_temp:

  Surface temperature in degrees C.

- weather_station:

  A weather_station object.

## Value

Total radiation balance in W/m².

## Details

The total radiation balance (\\R\_{total}\\) is calculated as:
\$\$R\_{total} = R\_{sw} + R\_{lw}\$\$ where: \\R\_{sw}\\ is the
shortwave radiation balance, \\R\_{lw}\\ is the longwave radiation
balance.

## References

Bendix 2004, p. 45 eq. 3.1.

## Examples

``` r
# Calculate total radiation balance
example_time <- as.POSIXlt(
 "2023-08-06 12:00:00",
 tz = "UTC"
)

rad_bal(
 datetime = example_time,
 lon = 10,
 lat = 50,
 elev = 100,
 temp = 15,
 rh = 60,
 slope = 5,
 exposition = 180,
 valley = FALSE,
 surface_type = "lawn",
 surface_temp = 15
)
#> [1] 477.4196
```
