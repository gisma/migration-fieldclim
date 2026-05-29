# Latent heat flux as residual of the surface energy balance

Calculates latent heat flux as the residual of the available turbulent
energy after subtracting sensible heat flux.

## Usage

``` r
latent_bulk_residual(rad_bal, ...)

# Default S3 method
latent_bulk_residual(rad_bal, soil_flux, sensible, warn_threshold = 600, ...)

# S3 method for class 'weather_station'
latent_bulk_residual(
  rad_bal,
  sensible = NULL,
  rho = 1.225,
  cp = 1005,
  k = 0.41,
  min_wind = 0.1,
  warn_threshold = 600,
  ...
)
```

## Arguments

- rad_bal:

  Net radiation \\R_n\\ in W m-2.

- ...:

  Further arguments passed to methods.

- soil_flux:

  Soil heat flux \\G\\ in W m-2.

- sensible:

  Sensible heat flux \\H\\ in W m-2.

- warn_threshold:

  Absolute flux threshold in W m-2 for diagnostic warnings.

- rho:

  Air density in kg m-3, used by the weather-station method when
  `sensible` is not supplied and
  [`sensible_bulk()`](https://gisma.github.io/migration-fieldclim/reference/sensible_bulk.md)
  is calculated internally.

- cp:

  Specific heat capacity of air in J kg-1 K-1, used by the
  weather-station method when `sensible` is not supplied.

- k:

  von Karman constant, used by the weather-station method when
  `sensible` is not supplied.

- min_wind:

  Minimum wind speed in m s-1 used by the internal bulk calculation in
  the weather-station method.

## Value

Latent heat flux in W m-2.

## Details

The package energy-balance convention is:

\$\$ R_n = G + H + LE \$\$

when storage is omitted. Here \\R_n\\ is net radiation, \\G\\ is soil
heat flux, \\H\\ is sensible heat flux, and \\LE\\ is latent heat flux.

The implemented residual is:

\$\$ LE\_{res} = R_n - G - H \$\$

where \\LE\_{res}\\ is latent heat flux in W m-2, \\R_n\\ is net
radiation in W m-2, \\G\\ is soil heat flux in W m-2, and \\H\\ is
sensible heat flux in W m-2.

The sign convention is:

- \\R_n \> 0\\: radiative energy input at the surface.

- \\G \> 0\\: heat flux into the soil.

- \\H \> 0\\: sensible heat flux away from the surface.

- \\LE \> 0\\: latent heat flux away from the surface.

In the Bulk-Residual workflow,
[`sensible_bulk()`](https://gisma.github.io/migration-fieldclim/reference/sensible_bulk.md)
first estimates \\H\_{bulk}\\. The latent heat flux is then calculated
as:

\$\$ LE\_{res} = R_n - G - H\_{bulk} \$\$

Therefore the Bulk-Residual workflow closes the available energy by
construction:

\$\$ H\_{bulk} + LE\_{res} = R_n - G \$\$

This closure is algebraic. It does not prove that \\H\_{bulk}\\ is a
physically perfect sensible-heat estimate. Any error in \\R_n\\, \\G\\,
or \\H\_{bulk}\\ is inherited by the residual latent heat flux.

Large absolute residuals are warned about using `warn_threshold`, but
they are not capped.
