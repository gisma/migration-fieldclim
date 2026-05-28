# Solar medium anomaly

Calculates the solar medium anomaly, which is the angular distance of
the Earth from its perihelion.

## Usage

``` r
sol_medium_anomaly(...)

# Default S3 method
sol_medium_anomaly(datetime, ...)

# S3 method for class 'weather_station'
sol_medium_anomaly(weather_station, ...)
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

The solar medium anomaly (\\M\\) is calculated as: \$\$M = 356.6 +
0.9856 \cdot J\$\$ where: \\J\\ is the Julian day.

## References

Bendix 2004, p. 243.

## Examples

``` r
# Calculate solar medium anomaly
sol_medium_anomaly(as.POSIXlt("2022-06-21"))
#> [1] 526.1232
```
