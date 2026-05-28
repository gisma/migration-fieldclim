# Solar hour angle

Calculates the solar hour angle, which is the measure of time since
solar noon in degrees.

## Usage

``` r
sol_hour_angle(...)

# Default S3 method
sol_hour_angle(datetime, lon, ...)

# S3 method for class 'weather_station'
sol_hour_angle(weather_station, ...)
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

- weather_station:

  Object of class `weather_station`.

## Value

Degree.

## Details

The solar hour angle (\\H\\) is calculated as: \$\$H = 15 \cdot (T_m +
E_t - 12)\$\$ where: \\T_m\\ is the solar medium suntime, \\E_t\\ is the
solar time formula.

## References

Bendix 2004, p. 243.

## Examples

``` r
# Calculate solar hour angle
sol_hour_angle(as.POSIXlt("2022-06-21 12:00:00"), lon = 10)
#> [1] 0.3840178
```
