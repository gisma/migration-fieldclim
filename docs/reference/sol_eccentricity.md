# Eccentricity factor

The track of Earth around the Sun is not a circle, but more like an
ellipse.

## Usage

``` r
sol_eccentricity(...)

# Default S3 method
sol_eccentricity(datetime, ...)

# S3 method for class 'weather_station'
sol_eccentricity(weather_station, ...)
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

Unitless.

## Details

The eccentricity factor (\\E\\) accounts for the elliptical shape of
Earth's orbit around the Sun. It is calculated as: \$\$E = 1.00011 +
0.034221 \cdot \cos(D) + 0.00128 \cdot \sin(D) + 0.000719 \cdot
\cos(2D) + 0.000719 \cdot \sin(2D)\$\$ where: \\D\\ is the day angle in
radians.

## References

Bendix 2004, p. 243.

## Examples

``` r
# Calculate eccentricity factor
sol_eccentricity(as.POSIXlt("2022-06-21"))
#> [1] 0.9671952
```
