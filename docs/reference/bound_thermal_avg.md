# Thermal internal boundary layer.

This function calculates the average height of the thermal internal
boundary layer (TIBL). The TIBL height is calculated based on various
meteorological parameters such as windspeed, height of the anemometer,
type of surface, distance to the point of temperature change, potential
temperatures, and lapse rate, following the method described by Bendix
(2004, p. 242).

## Usage

``` r
bound_thermal_avg(
  v,
  z,
  temp_change_dist,
  t_pot_upwind,
  t_pot,
  lapse_rate,
  surface_type = NULL,
  obs_height = NULL
)
```

## Arguments

- v:

  Numeric. The windspeed at the height of the anemometer in meters per
  second (m/s).

- z:

  Numeric. The height of the anemometer in meters (m).

- temp_change_dist:

  Numeric. The distance to the point of temperature change in meters
  (m).

- t_pot_upwind:

  Numeric. The potential temperature in the upwind direction in degrees
  Celsius (°C).

- t_pot:

  Numeric. The potential temperature at the site in degrees Celsius
  (°C).

- lapse_rate:

  Numeric. The lapse rate in degrees Celsius per meter (°C/m).

- surface_type:

  Character. The type of surface. Options: "field", "acre", "lawn",
  "street", "agriculture", "settlement", "coniferous forest", "deciduous
  forest", "mixed forest", "city", "water", "shrub". Either
  `surface_type` or `obs_height` must be provided.

- obs_height:

  Numeric. The observation height for roughness length calculation in
  meters (m). Either `obs_height` or `surface_type` must be provided.

## Value

Numeric. The average height of the thermal boundary layer in meters (m).

## Details

The thermal internal boundary layer (TIBL) forms as air flows over a
surface with a different temperature, causing thermal stratification.
This function computes the average height of the TIBL, which is
influenced by windspeed, temperature differences, and the atmospheric
lapse rate.

The function uses the formula: \$\$height = \frac{u\_\*}{v}
\sqrt{\frac{d \Delta \theta}{\gamma}}\$\$ where \\u\_\*\\ is the
friction velocity, \\v\\ is the windspeed, \\d\\ is the distance to the
temperature change point, \\\Delta \theta\\ is the potential temperature
difference, and \\\gamma\\ is the lapse rate.

## References

Bendix, J. (2004). Weather and Climate: An Introduction. Springer.

## Examples

``` r
# Calculate the average height of the TIBL with given parameters
bound_thermal_avg(
  v = 5, z = 10, temp_change_dist = 500,
  t_pot_upwind = 15, t_pot = 20,
  lapse_rate = 0.0065, surface_type = "lawn"
)
#> [1] 63.41207
```
