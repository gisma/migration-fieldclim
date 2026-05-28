# Friction velocity

Calculates the friction velocity of the surface.

## Usage

``` r
turb_ustar(...)

# Default S3 method
turb_ustar(v, z, surface_type = NULL, obs_height = NULL, ...)

# S3 method for class 'weather_station'
turb_ustar(weather_station, obs_height = NULL, ...)
```

## Arguments

- ...:

  Additional arguments.

- v:

  Numeric. Windspeed at the height of the anemometer in meters per
  second (m/s).

- z:

  Numeric. Height of the anemometer in meters (m).

- surface_type:

  Character. Type of surface. Options: "field", "acre", "lawn",
  "street", "agriculture", "settlement", "coniferous forest", "deciduous
  forest", "mixed forest", "city", "water", "shrub".

- obs_height:

  Numeric. Height of obstacle in meters (m).

- weather_station:

  Object of class `weather_station`.

## Value

Numeric. Friction velocity in meters per second (m/s).

Numeric. Friction velocity in meters per second (m/s).

## Details

This function calculates the friction velocity (\\u\_\*\\) of the
surface, which is a measure of the shear stress exerted by the wind on
the surface. The friction velocity is important in boundary layer
meteorology for understanding momentum transfer.

The friction velocity is calculated using the formula: \$\$u\_\* =
\frac{v \cdot 0.4}{\log(z / z_0)}\$\$ where \\v\\ is the windspeed at
the height of the anemometer, \\z\\ is the height of the anemometer, and
\\z_0\\ is the roughness length.

The roughness length (\\z_0\\) can be determined based on the obstacle
height (`obs_height`) or the type of surface (`surface_type`).

## References

Bendix 2004, p. 239

## Examples

``` r
# Calculate friction velocity based on obstacle height
turb_ustar(v = 5, z = 10, obs_height = 1)
#> [1] 0.4342945

# Calculate friction velocity based on surface type
turb_ustar(v = 5, z = 10, surface_type = "lawn")
#> [1] 0.5112444
```
