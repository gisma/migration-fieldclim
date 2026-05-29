# Transmittance due to gas

Calculates transmittance due to O\\\_2\\ and CO\\\_2\\.

## Usage

``` r
trans_gas(...)

# Default S3 method
trans_gas(datetime, lon, lat, elev, temp, ...)

# S3 method for class 'weather_station'
trans_gas(weather_station, ...)
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

The transmittance due to gases is calculated using the formula:
\$\$T\_{gas} = \exp(-0.0127 \cdot M\_{abs}^{0.26})\$\$ where
\\M\_{abs}\\ is the absolute optical air mass.

## References

Bendix 2004, p. 246.

## Examples

``` r
# Calculate transmittance due to gas
trans_gas(
  datetime = as.POSIXlt("2023-08-06 12:00:00", tz = "UTC"),
  lon = 8.68, lat = 50.77, elev = 100, temp = 20
)
#> [1] 0.9871164
```
