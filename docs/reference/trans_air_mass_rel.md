# Relative optical air mass

Calculates the relative optical air mass.

## Usage

``` r
trans_air_mass_rel(...)

# Default S3 method
trans_air_mass_rel(datetime, lon, lat, ...)

# S3 method for class 'weather_station'
trans_air_mass_rel(weather_station, ...)
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

- weather_station:

  A weather_station object.

## Value

Relative optical air mass, unitless.

## Details

The relative optical air mass is calculated using the formula:
\$\$M\_{rel} = \frac{1}{\sin(elevation) + 1.5 \cdot
elevation^{-0.72}}\$\$ where \\elevation\\ is the solar elevation angle
in degrees.

## References

Bendix 2004, p. 246.

## Examples

``` r
# Calculate relative optical air mass
trans_air_mass_rel(datetime = as.POSIXlt("2023-08-06 12:00:00", tz = "UTC"), lon = 8.68, lat = 50.77)
#> [1] 1.096104
```
