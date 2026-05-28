# Latent Heat using Monin-Obukhov length

Calculates the latent heat flux using the Monin-Obukhov length. Positive
flux signifies flux away from the surface, negative values signify flux
towards the surface.

## Usage

``` r
latent_monin(...)

# Default S3 method
latent_monin(
  hum1,
  hum2,
  t1,
  t2,
  v1,
  v2,
  z1 = 2,
  z2 = 10,
  elev,
  cap = NULL,
  surface_type = NULL,
  obs_height = NULL,
  ...
)

# S3 method for class 'weather_station'
latent_monin(weather_station, cap = NULL, ...)
```

## Arguments

- ...:

  Additional arguments.

- hum1:

  Relative humidity at lower height in %.

- hum2:

  Relative humidity at upper height in %.

- t1:

  Air temperature at lower height in °C.

- t2:

  Air temperature at upper height in °C.

- v1:

  Windspeed at lower height (e.g. height of anemometer) in m/s.

- v2:

  Windspeed at upper height in m/s.

- z1:

  Lower height of measurement in m.

- z2:

  Upper height of measurement in m.

- elev:

  Elevation above sea level in m.

- cap:

  The maximum absolute value for the stability parameter \\s_1\\.
  Default is NULL.

- surface_type:

  Surface type, for which a roughness length will be selected.

- obs_height:

  Height of the obstacles (if provided).

- weather_station:

  Object of class weather_station

## Value

Latent heat flux in W/m².

## Details

The latent heat flux (\\Q_e\\) using the Monin-Obukhov method is
calculated as: \$\$Q_e = -\rho \cdot L_v \cdot \frac{k \cdot
u\_\*}{\phi_q} \cdot \frac{\Delta q}{\Delta z}\$\$ where: \\\rho\\ is
the air density, \\L_v\\ is the latent heat of vaporization, \\k\\ is
the von Kármán constant, \\u\_\*\\ is the friction velocity, \\\phi_q\\
is the stability correction function for humidity, \\\Delta q\\ is the
moisture gradient, and \\\Delta z\\ is the height difference between
measurements.

The stability correction function for humidity (\\\phi_q\\) is
calculated using the gradient Richardson number (\\Ri_g\\) and the
stability parameter (\\s_1\\). The stability parameter (\\s_1\\) is the
ratio of the upper measurement height to the Monin-Obukhov length. When
the Monin-Obukhov length close to zero, the ratio can become excessively
large, leading to unrealistic values. To address this, the stability
parameter (\\s_1\\) is capped to a maximum absolute value. The default
cap is set to NULL. \$\$\phi_q = \begin{cases} 0.95 \cdot (1 - 11.6
\cdot s_1)^{-0.5}, & \text{if } Ri_g \leq 0 \\ 0.95 + 7.8 \cdot s_1, &
\text{if } Ri_g \> 0 \end{cases}\$\$

## References

Bendix 2004, p. 77, eq.4.6

Foken 2016, p. 61, Tab. 2.10

## Examples

``` r
# Calculate latent heat flux using Monin-Obukhov length
latent_monin(hum1 = 80, hum2 = 60, t1 = 20, t2 = 15, v1 = 3, v2 = 5, z1 = 2, z2 = 10, elev = 100, surface_type = "forest")
#> Error in turb_roughness_length.default(surface_type = surface_type): Invalid surface type.
```
