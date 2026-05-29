# Transmittance due to water vapor

Calculates transmittance due to water vapor.

## Usage

``` r
trans_vapor(...)

# Default S3 method
trans_vapor(datetime, lon, lat, elev, temp, ...)

# S3 method for class 'weather_station'
trans_vapor(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- datetime:

  POSIXlt object, date and time of the observation.

- lon:

  Longitude in decimal degrees.

- lat:

  Latitude in decimal degrees.

- elev:

  Elevation above sea level in meters.

- temp:

  Air temperature in °C.

- weather_station:

  A weather_station object.

## Value

Transmittance ratio from 0 to 1, unitless.

## Details

The transmittance due to water vapor is calculated using the formula:
\$\$T\_{vapor} = 1 - 2.4959 \cdot x \cdot ((1 + 79.034 \cdot
x)^{0.6828} + 6.385 \cdot x)^{-1}\$\$ where \\x\\ is the product of the
precipitable water and the relative optical air mass.

## References

Bendix 2004, p. 245.

## Examples

``` r
# Calculate transmittance due to water vapor
trans_vapor(
  datetime = as.POSIXlt("2023-08-06 12:00:00", tz = "UTC"),
  lon = 8.68, lat = 50.77, elev = 100, temp = 20
)
#> [1] 0.8373115
```
