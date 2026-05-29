# Latent Heat using Bowen Method

Calculates the latent heat flux using the Bowen Method. Positive flux
signifies flux away from the surface, negative values signify flux
towards the surface. Values above 600 W m-2 and below -600 W m-2 trigger
warnings. Output flux values are not smoothed; only the optional
denominator cap guards near-zero partition denominators.

## Usage

``` r
latent_bowen(...)

# Default S3 method
latent_bowen(
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
latent_bowen(weather_station, cap = NULL, ...)
```

## Arguments

- ...:

  Additional arguments.

- t1:

  Temperature at lower height in degrees C.

- t2:

  Temperature at upper height in degrees C.

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

  Radiation balance in W m-2.

- soil_flux:

  Soil flux in W m-2.

- cap:

  A positive denominator guard for near-zero \\1 + B\\. Default is NULL.

- weather_station:

  A weather_station object.

## Value

Latent heat flux in W m-2.

## Details

The latent heat flux (\\Q_e\\) using the Bowen method is calculated as:
\$\$Q_e = \frac{R_n - G}{1 + B}\$\$ where: \\R_n\\ is the net radiation,
\\G\\ is the soil heat flux, and \\B\\ is the Bowen ratio.

The implemented Bowen ratio (\\B\\) is calculated from a
potential-temperature gradient and an absolute-humidity gradient: \$\$B
= \gamma\_{code} \cdot \frac{\Delta \theta / \Delta z}{\Delta AH /
\Delta z}\$\$ where: \\\gamma\_{code} = 0.00066 \cdot (1 + 0.000946
\cdot t_1)\\ is the empirical implementation coefficient; its exact
source-form equivalence remains source-open, \\\theta\\ is potential
temperature, and \\AH\\ is absolute humidity. The inputs `t1` and `t2`
are converted to potential temperature before the temperature gradient
is formed. The inputs `hum1` and `hum2` are relative humidity values
that are converted internally to absolute humidity before the humidity
gradient is formed.

When \\1 + B\\ is close to zero, the latent heat flux can become
unrealistically high. The `cap` parameter is a numerical safeguard that
replaces near-zero denominators with `+/- cap`. Exact closure with
[`sensible_bowen()`](https://gisma.github.io/migration-fieldclim/reference/sensible_bowen.md)
is guaranteed only for finite uncapped denominators; capped cases are
guarded diagnostic outputs and may not close `rad_bal - soil_flux`
exactly. Non-finite Bowen ratios or denominators return `NA` for
affected elements with a warning.

## References

Bendix 2004, p. 221, eq. 9.21

## Examples

``` r
# Calculate latent heat flux using Bowen method
latent_bowen(
  t1 = 20, t2 = 15, hum1 = 80, hum2 = 60,
  z1 = 2, z2 = 10, elev = 100,
  rad_bal = 200, soil_flux = 50
)
#> [1] 97.53392
```
