# Transmittance due to rayleigh scattering

Calculates transmittance due to Rayleigh scattering.

## Usage

``` r
trans_rayleigh(...)

# Default S3 method
trans_rayleigh(datetime, lon, lat, elev, temp, ...)

# S3 method for class 'weather_station'
trans_rayleigh(weather_station, ...)
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

## Value

Transmittance ratio from 0 to 1, unitless.

## Details

The transmittance due to Rayleigh scattering is calculated using the
formula: \$\$T\_{rayleigh} = \exp(-0.0903 \cdot M\_{abs}^{0.84} \cdot
(1 + M\_{abs} - M\_{abs}^{1.01}))\$\$ where \\M\_{abs}\\ is the absolute
optical air mass.

## References

Bendix 2004, p. 245.

## Examples

``` r
# Calculate transmittance due to rayleigh scattering
trans_rayleigh(datetime = as.POSIXlt("2023-08-06 12:00:00", tz = "UTC"), lon = 8.68, lat = 50.77, elev = 100, temp = 20)
#> [1] 0.9080087
```
