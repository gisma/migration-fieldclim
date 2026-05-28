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

  Additional arguments.

- datetime:

  Datetime of class `POSIXlt`. See
  [`base::as.POSIXlt()`](https://rdrr.io/r/base/as.POSIXlt.html). Make
  sure to provide the correct timezone information!

- lon:

  Longitude in degree.

- lat:

  Latitude in degree.

- weather_station:

  Object of class `weather_station`.

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
