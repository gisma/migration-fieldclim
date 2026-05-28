# Longwave Outgoing Radiation

Calculates the longwave radiation of the surface.

## Usage

``` r
rad_lw_out(...)

# Default S3 method
rad_lw_out(surface_type, surface_temp, ..., sigma = sigma_default)

# S3 method for class 'weather_station'
rad_lw_out(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- surface_type:

  Surface type. Allowed values are: field, acre, lawn, street,
  agriculture, settlement, coniferous forest, deciduous forest, mixed
  forest, city, water, shrub. EXCEPTION: for functions related to
  Priestley-Taylor methods, allowed values are: field, bare soil,
  coniferous forest, water, wetland, spruce forest.

- surface_temp:

  Surface temperature in degree Celcius.

- weather_station:

  Object of class `weather_station`.

## Value

Longwave outgoing radiation in W/m².

## Details

The longwave outgoing radiation (\\LW\_{out}\\) is calculated as:
\$\$LW\_{out} = \epsilon \cdot \sigma \cdot T\_{surface}^4\$\$ where:
\\\epsilon\\ is the emissivity of the surface, \\\sigma\\ is the
Stefan-Boltzmann constant, and \\T\_{surface}\\ is the surface
temperature in Kelvin.

## References

Bendix 2004, p. 66 eq. 3.20.

## Examples

``` r
# Calculate longwave outgoing radiation
rad_lw_out(surface_type = "lawn", surface_temp = 15)
#> [1] 371.3743
```
