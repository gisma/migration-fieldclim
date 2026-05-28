# Sky View Factor

Calculates the sky view factor, which represents how much sky can be
seen from a given point.

## Usage

``` r
terr_sky_view(...)

# Default S3 method
terr_sky_view(slope, valley, ...)

# S3 method for class 'weather_station'
terr_sky_view(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments passed to other methods.

- slope:

  Slope of the terrain in degrees.

- valley:

  Logical value indicating if the location is in a valley (TRUE) or not
  (FALSE).

- weather_station:

  Object of class `weather_station`.

## Value

Ratio from 0 to 1, unitless, representing the sky view factor.

## Details

The sky view factor (\\SVF\\) is calculated as: \$\$SVF = \frac{1 +
\cos(\theta)}{2}\$\$ for non-valley locations, and \$\$SVF =
\cos(\theta)\$\$ for valley locations, where \\\theta\\ is the slope
angle.

The terrain view factor can be calculated by `1 - terr_sky_view()`,
which represents how much terrain can be seen from the point.

## References

Bendix 2004, p. 63 eq. 3.15.

## Examples

``` r
# Sky view factor for a slope of 30 degrees not in a valley
terr_sky_view(slope = 30, valley = FALSE)
#> [1] 0.9330127

# Sky view factor for a slope of 30 degrees in a valley
terr_sky_view(slope = 30, valley = TRUE)
#> [1] 0.8660254
```
