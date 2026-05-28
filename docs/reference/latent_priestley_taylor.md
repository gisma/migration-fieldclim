# Latent Heat Priestley-Taylor Method

Calculates the latent heat flux using the Priestley-Taylor method.
Positive heat flux signifies flux away from the surface, negative values
signify flux towards the surface.

## Usage

``` r
latent_priestley_taylor(...)

# Default S3 method
latent_priestley_taylor(temp, rad_bal, soil_flux, surface_type, ...)

# S3 method for class 'weather_station'
latent_priestley_taylor(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- temp:

  Air temperature in °C.

- rad_bal:

  Radiation balance in W/m².

- soil_flux:

  Soil flux in W/m².

- surface_type:

  Surface type, for which a Priestley-Taylor coefficient will be
  selected. Options: field, bare soil, coniferous forest, water,
  wetland, spruce forest

- weather_station:

  Object of class weather_station

## Value

Latent heat flux in W/m².

## Details

The latent heat flux (\\Q_e\\) using the Priestley-Taylor method is
calculated as: \$\$Q_e = \alpha\_{PT} \cdot \frac{\Delta}{\Delta +
\gamma} \cdot (R_n - G)\$\$ where: \\\alpha\_{PT}\\ is the
Priestley-Taylor coefficient, \\\Delta\\ is the slope of the saturation
vapor pressure curve, \\\gamma\\ is the psychrometric constant, \\R_n\\
is the net radiation, and \\G\\ is the soil heat flux.

The Priestley-Taylor coefficient depends on the surface type and can be
selected from predefined values.

## References

Foken 2016, p. 220, eq. 5.7.

## Examples

``` r
# Calculate latent heat flux using Priestley-Taylor method
latent_priestley_taylor(temp = 25, rad_bal = 200, soil_flux = 50, surface_type = "bare soil")
#> [1] 117.0206
```
