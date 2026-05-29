# Sensible Heat using Monin-Obukhov length

Calculates the sensible heat flux using the Monin-Obukhov length.
Positive flux signifies flux away from the surface, negative values
signify flux towards the surface. Monin-Obukhov outputs are diagnostic
profile/stability estimates and are not expected to close \\R_n - G\\.

## Usage

``` r
sensible_monin(...)

# Default S3 method
sensible_monin(
  t1,
  t2,
  z1 = 2,
  z2 = 10,
  v1,
  v2,
  elev,
  cap = NULL,
  surface_type = NULL,
  obs_height = NULL,
  ...
)

# S3 method for class 'weather_station'
sensible_monin(weather_station, cap = NULL, ...)
```

## Arguments

- ...:

  Additional arguments.

- t1:

  Air temperature at lower height in °C.

- t2:

  Air temperature at upper height in °C.

- z1:

  Lower height of measurement in m.

- z2:

  Upper height of measurement in m (Use highest point of measurement as
  values are less disturbed).

- v1:

  Windspeed at lower height (e.g. height of anemometer) in m/s.

- v2:

  Windspeed at upper height in m/s.

- elev:

  Elevation above sea level in m.

- cap:

  The maximum absolute value for the stability parameter \\s_1\\.
  Default is NULL.

- surface_type:

  Type of surface. Options: r surface_properties\$surface_type

- obs_height:

  Height of obstacle in meters (m).

- weather_station:

  Object of class weather_station

## Value

Sensible heat flux in W/m².

## Details

The sensible heat flux (\\Q_h\\) using the Monin-Obukhov method is
calculated as: \$\$Q_h = - \rho \cdot c_p \cdot \frac{k \cdot u\_\*
\cdot z_2}{\phi_h} \cdot \frac{\Delta \theta}{\Delta z}\$\$ where:
\\\rho\\ is the air density, \\c_p\\ is the specific heat capacity of
air, \\k\\ is the von Kármán constant, \\u\_\*\\ is the friction
velocity, \\\phi_h\\ is the stability correction function for heat,
\\\Delta \theta\\ is the potential temperature gradient, and \\\Delta
z\\ is the height difference between measurements.

The stability correction function for heat (\\\phi_h\\) is calculated
using the gradient Richardson number (\\Ri_g\\) and the stability
parameter (\\s_1\\). The stability parameter is the ratio of the higher
measurement height and the Monin-Obukhov length. With Monin-Obukhov
length values close to zero, the ratio can result in very high values,
which is why the stability parameter (\\s_1\\) can be capped. The
implemented potential-temperature gradient uses the measurement-height
difference \\z_2 - z_1\\. Invalid heights, invalid wind speeds, and
invalid numerical profile states are guarded elementwise and return `NA`
with a warning. Zero potential-temperature gradient returns zero
sensible heat flux. The default cap is set to NULL.

## References

Bendix 2004, p. 77, eq. 4.6,

Foken 2016, p. 362: Businger

## Examples

``` r
# Calculate sensible heat flux using the Monin-Obukhov method
sensible_monin(t1 = 20, t2 = 15, z1 = 2, z2 = 10, v1 = 3, v2 = 5, elev = 100, surface_type = "lawn")
#> Warning: There are values above 600 W/m^2!
#> [1] 7215.479
```
