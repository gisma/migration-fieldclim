# Transmittance due to aerosols

Calculates transmittance due to fine particles in the air.

## Usage

``` r
trans_aerosol(...)

# Default S3 method
trans_aerosol(datetime, lon, lat, elev, temp, ..., vis = vis_default)

# S3 method for class 'weather_station'
trans_aerosol(weather_station, ...)
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

- vis:

  Visibility in km, default `vis_default`.

- weather_station:

  A weather_station object.

## Value

Transmittance ratio from 0 to 1, unitless.

## Details

The transmittance due to aerosols is calculated using the formula:
\$\$T\_{aerosol} = \exp(-x^{0.873} \cdot (1 + x - x^{0.7088}) \cdot
M\_{abs}^{0.9108})\$\$ where \\x\\ is a function of the visibility and
\\M\_{abs}\\ is the absolute optical air mass.

## References

Bendix 2004, p. 246.

## Examples

``` r
# Calculate transmittance due to aerosols
trans_aerosol(
  datetime = as.POSIXlt("2023-08-06 12:00:00", tz = "UTC"),
  lon = 8.68, lat = 50.77, elev = 100,
  temp = 20, vis = 50
)
#> [1] 0.865632
```
