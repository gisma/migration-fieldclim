# Solar medium suntime

Calculates the solar medium suntime, which is the mean solar time
adjusted for the observer's longitude.

## Usage

``` r
sol_medium_suntime(...)

# Default S3 method
sol_medium_suntime(datetime, lon, ...)

# S3 method for class 'weather_station'
sol_medium_suntime(weather_station, ...)
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

Hour.

## Details

The solar medium suntime (\\T_m\\) is calculated as: \$\$T_m =
T\_{local} + \frac{lon}{15}\$\$ where: \\T\_{local}\\ is the local time
zone, \\lon\\ is the longitude of the observer.

## References

Bendix 2004, p. 243.

## Examples

``` r
# Calculate solar medium suntime
sol_medium_suntime(as.POSIXlt("2022-06-21 12:00:00"), lon = 10)
#> [1] 10.66667
```
