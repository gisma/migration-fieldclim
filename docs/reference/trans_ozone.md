# Transmittance due to ozone

Calculates transmittance due to atmospheric ozone.

## Usage

``` r
trans_ozone(...)

# Default S3 method
trans_ozone(datetime, lon, lat, ..., ozone_column = ozone_column_default)

# S3 method for class 'weather_station'
trans_ozone(weather_station, ...)
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

- ozone_column:

  Atmospheric ozone as column in cm, default `ozone_column_default`.

- weather_station:

  A weather_station object.

## Value

Transmittance ratio from 0 to 1, unitless.

## Details

The transmittance due to ozone is calculated using the formula:
\$\$T\_{ozone} = 1 - (0.1611 \cdot x \cdot (1 + 139.48 \cdot
x)^{-0.3035} - 0.002715 \cdot x \cdot (1 + 0.044 \cdot x + 0.0003 \cdot
x^2)^{-1})\$\$ where \\x\\ is the product of the ozone column and the
relative optical air mass.

## References

Bendix 2004, p. 245.

## Examples

``` r
# Calculate transmittance due to ozone
trans_ozone(datetime = as.POSIXlt("2023-08-06 12:00:00", tz = "UTC"), lon = 8.68, lat = 50.77, ozone_column = 0.3)
#> [1] 0.9843997
```
