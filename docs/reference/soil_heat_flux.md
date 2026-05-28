# Soil Heat Flux

Calculates soil heat flux from measurements in two different depths and
thermal conductivity of the soil. Negative values signify flux towards
the atmosphere, while positive values signify flux into the soil.

## Usage

``` r
soil_heat_flux(...)

# Default S3 method
soil_heat_flux(
  texture,
  moisture,
  soil_temp1,
  soil_temp2,
  soil_depth1,
  soil_depth2,
  ...
)

# S3 method for class 'weather_station'
soil_heat_flux(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- texture:

  Soil texture. Either "sand", "peat" or "clay".

- moisture:

  Soil moisture content in cubic meters per cubic meter.

- soil_temp1:

  Temperature at the first depth in °C.

- soil_temp2:

  Temperature at the second depth in °C.

- soil_depth1:

  Depth of the first measurement in m.

- soil_depth2:

  Depth of the second measurement in m.

- weather_station:

  A weather_station object.

## Value

Soil heat flux in W/m².

## Details

The soil heat flux (\\G\\) is calculated using the formula: \$\$G =
-\lambda \cdot \frac{T_1 - T_2}{z_1 - z_2}\$\$ where: \\\lambda\\ is the
thermal conductivity of the soil (W/m/K), \\T_1\\ and \\T_2\\ are the
temperatures at two different depths (°C), \\z_1\\ and \\z_2\\ are the
depths at which the temperatures are measured (m).

## References

Bendix 2004, p. 71 eq. 4.2.

## Examples

``` r
# Calculate soil heat flux
soil_heat_flux(texture = "sand", moisture = 0.25, soil_temp1 = 15, soil_temp2 = 10, soil_depth1 = 0.1, soil_depth2 = 0.3)
#> [1] 60
```
