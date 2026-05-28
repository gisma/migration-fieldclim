# Solar ecliptic length

Calculates the solar ecliptic length, which is the angle of the Earth's
orbit around the sun relative to the vernal equinox.

## Usage

``` r
sol_ecliptic_length(...)

# Default S3 method
sol_ecliptic_length(datetime, ...)

# S3 method for class 'weather_station'
sol_ecliptic_length(weather_station, ...)
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

The solar ecliptic length (\\L\\) is calculated as: \$\$L = 279.3 +
0.9856 \cdot J + 1.92 \cdot \sin(M)\$\$ where: \\J\\ is the Julian day,
\\M\\ is the solar medium anomaly in radians.

## References

Bendix 2004, p. 243.

## Examples

``` r
# Calculate solar ecliptic length
sol_ecliptic_length(as.POSIXlt("2022-06-21"))
#> [1] 449.2837
```
