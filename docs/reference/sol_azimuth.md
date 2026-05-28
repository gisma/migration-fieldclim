# Solar azimuth

Calculates the solar azimuth, which is the compass direction from which
the sunlight is coming at any specific point on the earth's surface.

## Usage

``` r
sol_azimuth(...)

# Default S3 method
sol_azimuth(datetime, lon, lat, ...)

# S3 method for class 'weather_station'
sol_azimuth(weather_station, ...)
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

The solar azimuth (\\A\\) is calculated as: \$\$A =
\arccos\left(\frac{\sin(\delta) \cdot \cos(\phi) - \cos(\delta) \cdot
\sin(\phi) \cdot \cos(H)}{\cos(h)}\right)\$\$ where: \\\delta\\ is the
solar declination, \\\phi\\ is the latitude, \\H\\ is the hour angle,
\\h\\ is the solar elevation angle.

## References

Bendix 2004, p. 243.

## Examples

``` r
# Calculate solar azimuth
sol_azimuth(as.POSIXlt("2022-06-21 12:00:00"), lon = 10, lat = 50)
#> [1] 180.7879
```
