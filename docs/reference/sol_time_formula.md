# Solar time formula

Calculates the solar time formula, which corrects the solar medium
suntime to account for the Earth's elliptical orbit and axial tilt.

## Usage

``` r
sol_time_formula(...)

# Default S3 method
sol_time_formula(datetime, lon, ...)

# S3 method for class 'weather_station'
sol_time_formula(weather_station, ...)
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

The solar time formula (\\E_t\\) is calculated as: \$\$E_t = 0.1644
\cdot \sin(2L) - 0.1277 \cdot \sin(M)\$\$ where: \\L\\ is the ecliptic
longitude, \\M\\ is the solar medium anomaly.

## References

Bendix 2004, p. 243.

## Examples

``` r
# Calculate solar time formula
sol_time_formula(as.POSIXlt("2022-06-21 12:00:00"), lon = 10)
#> [1] 0.02560119
```
