# Sensible Heat using Bowen Method

Calculates the sensible heat flux using the Bowen Method. Positive flux
signifies flux away from the surface, negative values signify flux
towards the surface.

## Usage

``` r
sensible_bowen(...)

# Default S3 method
sensible_bowen(
  t1,
  t2,
  hum1,
  hum2,
  z1 = 2,
  z2 = 10,
  elev,
  rad_bal,
  soil_flux,
  cap = NULL,
  ...
)

# S3 method for class 'weather_station'
sensible_bowen(weather_station, cap = NULL, ...)
```

## Arguments

- ...:

  Additional arguments.

- t1:

  Temperature at lower height in °C.

- t2:

  Temperature at upper height in °C.

- hum1:

  Relative humidity at lower height in %.

- hum2:

  Relative humidity at upper height in %.

- z1:

  Lower height of measurement in m.

- z2:

  Upper height of measurement in m.

- elev:

  Elevation above sea level in m.

- rad_bal:

  Radiation balance in W/m².

- soil_flux:

  Soil flux in W/m².

- cap:

  The cap value to prevent division by zero. Default is NULL.

- weather_station:

  Object of class `weather_station`.

## Value

Sensible heat flux in W/m².

## Details

The sensible heat flux (\\Q_h\\) using the Bowen method is calculated
as: \$\$Q_h = \frac{(R_n - G) \cdot B}{1 + B}\$\$ where: \\R_n\\ is the
net radiation, \\G\\ is the soil heat flux, and \\B\\ is the Bowen
ratio.

The Bowen ratio (\\B\\) is calculated as: \$\$B = \frac{\gamma}{L_v}
\cdot \frac{\Delta T}{\Delta q}\$\$ where: \\\gamma\\ is the
psychrometric constant, \\L_v\\ is the latent heat of vaporization,
\\\Delta T\\ is the temperature gradient, and \\\Delta q\\ is the
moisture gradient.

When \\1 + B\\ results in values close to zero, the sensible heat flux
can become unrealistically high. To prevent this, a cap parameter can be
set. The cap parameter ensures that \\1 + B\\ does not get too close to
zero by setting a minimum allowable value.

## References

Bendix 2004, p. 221, eq. 9.21

## Examples

``` r
# Calculate sensible heat flux using the Bowen method
sensible_bowen(t1 = 20, t2 = 15, hum1 = 80, hum2 = 60, z1 = 2, z2 = 10, elev = 100, rad_bal = 200, soil_flux = 50, cap = 1)
#> [1] 52.46608
```
