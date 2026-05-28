# Solar elevation angle

Solar elevation angle

## Usage

``` r
sol_elevation(...)

# Default S3 method
sol_elevation(datetime, lon, lat, ...)

# S3 method for class 'weather_station'
sol_elevation(weather_station, ...)
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

- weather_station:

  A weather_station object.

## Value

Degree.

## Details

The solar elevation angle (\\h\\) is the apparent angle of the sun above
the horizon. It is calculated as: \$\$h = \arcsin(\sin(\phi) \cdot
\sin(\delta) + \cos(\phi) \cdot \cos(\delta) \cdot \cos(H))\$\$ where:
\\\phi\\ is the latitude, \\\delta\\ is the solar declination, and \\H\\
is the hour angle.

## References

Bendix 2004, p. 243.

## Examples

``` r
# Calculate solar elevation angle
sol_elevation(as.POSIXlt("2022-06-21"), lon = 10, lat = 50)
#> [1] -16.56115
```
