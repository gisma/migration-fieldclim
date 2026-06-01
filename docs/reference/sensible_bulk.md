# Sensible heat flux by a simple bulk-transfer approach

Calculates sensible heat flux from a vertical temperature difference,
wind speed and a simplified aerodynamic resistance.

## Usage

``` r
sensible_bulk(t1, ...)

# Default S3 method
sensible_bulk(
  t1,
  t2,
  v1,
  v2 = NULL,
  z1,
  z2,
  rho = 1.225,
  cp = 1005,
  k = 0.41,
  min_wind = 0.1,
  exchange_velocity = c("wind_mean", "u_star_profile", "u_star_roughness"),
  min_ustar = 0.01,
  surface_type = NULL,
  obs_height = NULL,
  warn_threshold = 600,
  stability_method = c("none", "ri_guard"),
  ri_neutral = 0.01,
  ri_critical = 0.25,
  min_shear = 1e-04,
  g = 9.81,
  elev = NULL,
  ...
)

# S3 method for class 'weather_station'
sensible_bulk(
  t1,
  rho = 1.225,
  cp = 1005,
  k = 0.41,
  min_wind = 0.1,
  exchange_velocity = c("wind_mean", "u_star_profile", "u_star_roughness"),
  min_ustar = 0.01,
  warn_threshold = 600,
  stability_method = c("none", "ri_guard"),
  ri_neutral = 0.01,
  ri_critical = 0.25,
  min_shear = 1e-04,
  g = 9.81,
  elev = NULL,
  ...
)
```

## Arguments

- t1:

  Air temperature at lower measurement height in degrees C.

- ...:

  Further arguments passed to methods.

- t2:

  Air temperature at upper measurement height in degrees C.

- v1:

  Wind speed at lower measurement height in m s-1.

- v2:

  Optional wind speed at upper measurement height in m s-1. If missing,
  `v1` is used.

- z1:

  Lower measurement height in m.

- z2:

  Upper measurement height in m.

- rho:

  Air density in kg m-3. Default is 1.225.

- cp:

  Specific heat capacity of air in J kg-1 K-1. Default is 1005.

- k:

  von Karman constant. Default is 0.41.

- min_wind:

  Minimum wind speed in m s-1 for the resistance calculation. Values at
  or below this threshold return `NA`.

- exchange_velocity:

  Character. Velocity scale used for the neutral aerodynamic resistance.
  `"wind_mean"` keeps the original package behaviour. `"u_star_profile"`
  estimates friction velocity from the two-height wind profile using
  `v1`, `v2`, `z1`, and `z2`. `"u_star_roughness"` estimates friction
  velocity from one reference wind speed and roughness length derived
  from `surface_type` or `obs_height`.

- min_ustar:

  Minimum friction velocity in m s-1. Values at or below this threshold
  return `NA` when `exchange_velocity` uses a friction-velocity path.

- surface_type:

  Surface-type label used to estimate roughness length when
  `exchange_velocity = "u_star_roughness"`.

- obs_height:

  Obstacle height in m used to estimate roughness length when
  `exchange_velocity = "u_star_roughness"`.

- warn_threshold:

  Absolute flux threshold in W m-2 for diagnostic warnings.

- stability_method:

  Optional stability screening method. `"none"` keeps the neutral bulk
  estimate unchanged; `"ri_guard"` attaches a gradient Richardson
  diagnostic and returns `NA` for invalid or very stable cases.

- ri_neutral:

  Absolute Richardson-number threshold for neutral class.

- ri_critical:

  Critical Richardson number for very stable guarding.

- min_shear:

  Minimum absolute wind-speed shear in s-1 for Richardson diagnostics.

- g:

  Gravitational acceleration in m s-2.

- elev:

  Optional elevation above sea level in m. If supplied, near-surface
  potential temperature is estimated with
  [`temp_pot_temp()`](https://gisma.github.io/migration-fieldclim/reference/temp_pot_temp.md);
  otherwise Kelvin air temperature is used as a near-surface
  approximation.

## Value

Sensible heat flux in W m-2.

## Details

The implemented sensible heat flux is:

\$\$ H\_{bulk} = \rho c_p \frac{T_1 - T_2}{r_a} \$\$

where \\H\_{bulk}\\ is the sensible heat flux in W m-2, \\\rho\\ is air
density in kg m-3, \\c_p\\ is the specific heat capacity of air in J
kg-1 K-1, \\T_1\\ is the air temperature at the lower measurement
height, \\T_2\\ is the air temperature at the upper measurement height,
and \\r_a\\ is the aerodynamic resistance in s m-1.

The aerodynamic resistance is calculated as:

\$\$ r_a = \frac{\log(z_2 / z_1)}{k \bar{u}} \$\$

where \\z_1\\ is the lower measurement height in m, \\z_2\\ is the upper
measurement height in m, \\k\\ is the von Karman constant, and
\\\bar{u}\\ is the mean wind speed in m s-1. If `v2` is supplied,
\\\bar{u}\\ is calculated as the mean of `v1` and `v2`. If `v2` is not
supplied, `v1` is used as \\\bar{u}\\.

This mean-wind path is selected by the default
`exchange_velocity = "wind_mean"`. With
`exchange_velocity = "u_star_profile"`, friction velocity is estimated
from the two-height wind profile:

\$\$ u\_\* = \frac{k (v_2 - v_1)}{\log(z_2 / z_1)} \$\$

and resistance is calculated as:

\$\$ r_a = \frac{\log(z_2 / z_1)}{k u\_\*} \$\$

With `exchange_velocity = "u_star_roughness"`, friction velocity is
estimated from one reference wind speed and roughness length:

\$\$ u\_\* = \frac{k u\_{ref}}{\log(z\_{ref} / z_0)} \$\$

and the same \\u\_\*\\-based resistance is used. `u_star_profile`
requires `v2`. `u_star_roughness` requires `surface_type` or
`obs_height`. All three paths are neutral approximations and do not
apply Monin-Obukhov stability corrections.

The sign convention follows the package energy-balance convention:

\$\$ H \> 0 \$\$

means sensible heat flux away from the surface. Therefore, with
`z1 < z2`, a positive lower-minus-upper temperature difference `t1 - t2`
produces positive \\H\_{bulk}\\.

This is a simplified neutral bulk-transfer reference. It is not a full
Monin-Obukhov stability-corrected profile method. Stability corrections,
roughness sublayer effects and explicit surface-layer similarity
functions are not applied here.

If `stability_method = "ri_guard"`, the neutral estimate is screened
with a gradient Richardson number diagnostic: \$\$ Ri_g =
\frac{g}{\bar{\theta}} \frac{\Delta \theta / \Delta z}{(\Delta u /
\Delta z)^2} \$\$ The guard does not rescale valid neutral fluxes. It
only returns `NA` for invalid or very stable Richardson cases and
attaches `bulk_Ri_g` and `bulk_stability` attributes to the returned
vector.

Very low wind speeds make the aerodynamic resistance numerically
unstable. Values at or below `min_wind` are therefore returned as `NA`
with a warning. Large absolute fluxes are warned about using
`warn_threshold`, but they are not capped.

## Examples

``` r
sensible_bulk(
  t1 = 20,
  t2 = 19.5,
  v1 = 1,
  v2 = 2,
  z1 = 2,
  z2 = 10
)
#> [1] 235.2193

h <- sensible_bulk(
  t1 = c(20, 19, 18),
  t2 = c(19.5, 19, 18.1),
  v1 = c(1, 1, 1),
  v2 = c(2, 2, 2),
  z1 = 2,
  z2 = 10,
  stability_method = "ri_guard"
)

h
#> [1] 235.21935   0.00000 -47.04387
#> attr(,"bulk_Ri_g")
#> [1] -0.13397064  0.00000000  0.02695055
#> attr(,"bulk_stability")
#> [1] "unstable" "neutral"  "stable"  
attr(h, "bulk_stability")
#> [1] "unstable" "neutral"  "stable"  
attr(h, "bulk_Ri_g")
#> [1] -0.13397064  0.00000000  0.02695055
```
