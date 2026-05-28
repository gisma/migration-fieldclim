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

  Named station fields, site parameters or model assumptions.

- surface_type:

  Surface-type label.

- surface_temp:

  Surface temperature in degrees C.

- sigma:

  Stefan-Boltzmann constant in W m-2 K-4.

- weather_station:

  A weather_station object.

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
