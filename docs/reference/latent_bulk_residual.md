# Latent heat flux as residual of the surface energy balance

Calculates latent heat flux as residual from net radiation, soil heat
flux and sensible heat flux.

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

  Net radiation `Rn` in W m-2.

- ...:

  Further arguments passed to methods.

- soil_flux:

  Soil heat flux `G` in W m-2.

- sensible:

  Sensible heat flux `H` in W m-2.

- warn_threshold:

  Absolute flux threshold for diagnostic warnings.

- rho:

  Air density in kg m-3.

- cp:

  Specific heat capacity of air in J kg-1 K-1.

- k:

  von Karman constant.

- min_wind:

  Minimum wind speed used by the internal bulk calculation.

## Value

Latent heat flux in W m-2.

## Details

The sign convention is:

`Rn > 0`: radiative energy input at the surface

`G > 0`: heat flux into the soil

`H > 0`: sensible heat flux away from the surface

`LE > 0`: latent heat flux away from the surface

Therefore:

`LE = Rn - G - H`
