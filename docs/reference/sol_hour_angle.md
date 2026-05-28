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

  Named station fields, site parameters or model assumptions.

- datetime:

  POSIXlt or POSIXct date-time vector.

- lon:

  Longitude in degrees.

- weather_station:

  A weather_station object.

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
