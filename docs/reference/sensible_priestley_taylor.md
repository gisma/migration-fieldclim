# Sensible Heat Priestley-Taylor Method

Calculates the sensible heat flux using the Priestley-Taylor method.
Positive heat flux signifies flux away from the surface, negative values
signify flux towards the surface.

## Usage

``` r
sensible_priestley_taylor(...)

# Default S3 method
sensible_priestley_taylor(temp, rad_bal, soil_flux, surface_type, ...)

# S3 method for class 'weather_station'
sensible_priestley_taylor(weather_station, ...)
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
  selected. Options: `surface_type options`

- weather_station:

  Object of class `weather_station`.

## Value

Sensible heat flux in W/m².

## Details

The sensible heat flux (\\Q_h\\) using the Priestley-Taylor method is
calculated as: \$\$Q_h = \frac{(1 - \alpha) \cdot s + \gamma}{s +
\gamma} \cdot (R_n - G)\$\$ where: \\\alpha\\ is the Priestley-Taylor
coefficient specific to the surface type, \\s\\ is the slope of the
saturation vapor pressure curve, \\\gamma\\ is the psychrometric
constant, \\R_n\\ is the net radiation, and \\G\\ is the soil heat flux.

## References

Foken 2016, p. 220, eq. 5.6

## Examples

``` r
# Calculate sensible heat flux using the Priestley-Taylor method
sensible_priestley_taylor(temp = 20, rad_bal = 200, soil_flux = 50, surface_type = "lawn")
#> Error in sensible_priestley_taylor.default(temp = 20, rad_bal = 200, soil_flux = 50,     surface_type = "lawn"): 'surface_type' must be one of the following: field , bare soil , coniferous forest , water , wetland , spruce forest
```
