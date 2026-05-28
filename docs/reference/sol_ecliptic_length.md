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

  Additional arguments.

- datetime:

  Datetime of class `POSIXlt`. See
  [`base::as.POSIXlt()`](https://rdrr.io/r/base/as.POSIXlt.html). Make
  sure to provide the correct timezone information!

- weather_station:

  Object of class `weather_station`.

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
