# Shortwave Incoming Radiation

Calculates the direct shortwave incoming radiation.

## Usage

``` r
rad_sw_in(...)

# Default S3 method
rad_sw_in(datetime, lon, lat, elev, temp, slope, exposition, ...)

# S3 method for class 'weather_station'
rad_sw_in(weather_station, ...)
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

- weather_station:

  A weather_station object.

## Value

Shortwave incoming radiation in W/m².

## Details

The shortwave incoming radiation (\\SW\_{in}\\) is calculated using the
formula: \$\$SW\_{in} = SW\_{toa} \cdot 0.9751 \cdot T\_{total} /
\sin(E) \cdot \cos(\theta)\$\$ where: \\SW\_{toa}\\ is the shortwave
radiation at the top of the atmosphere, \\T\_{total}\\ is the total
atmospheric transmission, \\E\\ is the solar elevation angle, \\\theta\\
is the terrain angle.

## References

Bendix 2004, p. 46 eq. 3.3, p. 52 eq. 3.8.

## Examples

``` r
# Calculate shortwave incoming radiation
example_time <- as.POSIXlt("2023-08-06 12:00:00", tz = "UTC")
rad_sw_in(datetime = example_time, lon = 10, lat = 50, elev = 100, temp = 15,
          slope = 5, exposition = 180)
#> [1] 687.602
```
