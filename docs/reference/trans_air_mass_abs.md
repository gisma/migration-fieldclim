# Absolute optical air mass

Calculates the absolute optical air mass.

## Usage

``` r
trans_air_mass_abs(...)

# Default S3 method
trans_air_mass_abs(datetime, lon, lat, elev, temp, ...)

# S3 method for class 'weather_station'
trans_air_mass_abs(weather_station, ...)
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

Absolute optical air mass, unitless.

## Details

The absolute optical air mass is calculated using the formula:
\$\$M\_{abs} = M\_{rel} \cdot \frac{p}{p_0}\$\$ where \\M\_{rel}\\ is
the relative optical air mass, \\p\\ is the local air pressure, and
\\p_0\\ is the standard pressure (1013.25 hPa).

## References

Bendix 2004, p. 247.

## Examples

``` r
# Calculate absolute optical air mass
trans_air_mass_abs(
  datetime = as.POSIXlt("2023-08-06 12:00:00", tz = "UTC"),
  lon = 8.68, lat = 50.77, elev = 100, temp = 20
)
#> [1] 1.0834
```
