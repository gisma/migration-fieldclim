# Shortwave Radiation Balance

Calculates the shortwave radiation balance by summing the shortwave
incoming and outgoing radiation as well as diffused incoming and
outgoing radiation.

## Usage

``` r
rad_sw_bal(...)

# Default S3 method
rad_sw_bal(
  datetime,
  lon,
  lat,
  elev,
  temp,
  slope,
  exposition,
  valley,
  surface_type,
  ...
)

# S3 method for class 'weather_station'
rad_sw_bal(weather_station, ...)
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

- slope:

  Slope in degrees.

- exposition:

  Exposition or aspect in degrees.

- valley:

  Logical value indicating whether the station is in a valley.

- surface_type:

  Surface-type label.

- weather_station:

  A weather_station object.

## Value

Shortwave radiation balance in W/m².

## Details

The shortwave radiation balance (\\R\_{sw}\\) is calculated as:
\$\$R\_{sw} = SW\_{in} - SW\_{out} + D\_{in} - D\_{out}\$\$ where:
\\SW\_{in}\\ is the shortwave incoming radiation, \\SW\_{out}\\ is the
shortwave outgoing radiation, \\D\_{in}\\ is the diffused incoming
radiation, \\D\_{out}\\ is the diffused outgoing radiation.

## References

Bendix 2004, p. 45 eq. 3.1.

## Examples

``` r
# Calculate shortwave radiation balance
example_time <- as.POSIXlt("2023-08-06 12:00:00", tz = "UTC")
rad_sw_bal(datetime = example_time, lon = 10, lat = 50, elev = 100, temp = 15,
           slope = 5, exposition = 180, valley = FALSE, surface_type = "lawn")
#> [1] 598.7045
```
