# Incoming Diffused Radiation

Calculates the diffused shortwave incoming radiation.

## Usage

``` r
rad_diffuse_in(...)

# Default S3 method
rad_diffuse_in(datetime, lon, lat, elev, temp, slope, exposition, valley, ...)

# S3 method for class 'weather_station'
rad_diffuse_in(weather_station, ...)
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

- weather_station:

  A weather_station object.

## Value

Diffused shortwave incoming radiation in W/m².

## Details

The diffused shortwave incoming radiation (\\D\_{in}\\) is calculated
using the formula: \$\$D\_{in} = 0.5 \cdot \[(1 - (1 - \text{vapor}) -
(1 - \text{ozone})) \cdot SW\_{toa} - SW\_{in}\] \cdot \text{sky\\view}
\cdot (1 + \cos(\theta)^2 \cdot \sin(\phi)^3)\$\$ where:
\\\text{vapor}\\ is the vapor transmission, \\\text{ozone}\\ is the
ozone transmission, \\SW\_{toa}\\ is the shortwave radiation at the top
of the atmosphere, \\SW\_{in}\\ is the shortwave incoming radiation,
\\\text{sky\\view}\\ is the sky view factor, \\\theta\\ is the terrain
angle, and \\\phi\\ is the solar angle.

## References

Bendix 2004, p. 58 eq. 3.14, p. 55 eq. 3.9.

## Examples

``` r
# Calculate diffused shortwave incoming radiation
example_time <- as.POSIXlt("2023-08-06 12:00:00", tz = "UTC")
rad_diffuse_in(datetime = example_time, lon = 10, lat = 50, elev = 100, temp = 15,
               slope = 5, exposition = 180, valley = FALSE)
#> [1] 121.4581
```
