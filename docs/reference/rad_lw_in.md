# Longwave Incoming Radiation

Calculates the longwave radiation of the atmosphere.

## Usage

``` r
rad_lw_in(...)

# Default S3 method
rad_lw_in(temp, rh, slope, valley, ..., sigma = sigma_default)

# S3 method for class 'weather_station'
rad_lw_in(weather_station, ...)
```

## Arguments

- ...:

  Named station fields, site parameters or model assumptions.

- temp:

  Air temperature in degrees C.

- rh:

  Relative humidity in percent.

- slope:

  Slope in degrees.

- valley:

  Logical value indicating whether the station is in a valley.

- sigma:

  Stefan-Boltzmann constant in W m-2 K-4.

- weather_station:

  A weather_station object.

## Value

Longwave incoming radiation in W/m².

## Details

The longwave incoming radiation (\\LW\_{in}\\) is calculated as:
\$\$LW\_{in} = \epsilon\_{air} \cdot \sigma \cdot T\_{air}^4 \cdot
\text{sky\\view}\$\$ where: \\\epsilon\_{air}\\ is the emissivity of the
air, \\\sigma\\ is the Stefan-Boltzmann constant, \\T\_{air}\\ is the
air temperature in Kelvin, and \\\text{sky\\view}\\ is the sky view
factor.

## References

Bendix 2004, p. 68 eq. 3.24.

## Examples

``` r
# Calculate longwave incoming radiation
rad_lw_in(temp = 15, rh = 60, slope = 5, valley = FALSE)
#> [1] 250.0894
```
