# Day angle

See a year as a circle. The first day of a (leap) year is 0 degree and
the last day 360 degrees.

## Usage

``` r
sol_day_angle(...)

# Default S3 method
sol_day_angle(datetime, ...)

# S3 method for class 'weather_station'
sol_day_angle(weather_station, ...)
```

## Arguments

- ...:

  Named station fields, site parameters or model assumptions.

- datetime:

  POSIXlt or POSIXct date-time vector.

- weather_station:

  A weather_station object.

## Value

Degree.

## Details

The day angle (\\D\\) is calculated as: \$\$D = \frac{2\pi(J -
1)}{365}\$\$ where: \\J\\ is the Julian day.

## References

Bendix 2004, p. 243.

## Examples

``` r
# Calculate day angle
sol_day_angle(as.POSIXlt("2022-06-21"))
#> [1] 168.6575
```
