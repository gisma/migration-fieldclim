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

  Named station fields, site parameters or model assumptions.

- datetime:

  POSIXlt or POSIXct date-time vector.

- lon:

  Longitude in degrees.

- weather_station:

  A weather_station object.

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
