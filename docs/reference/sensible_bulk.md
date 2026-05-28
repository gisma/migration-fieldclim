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
  warn_threshold = 600,
  ...
)

# S3 method for class 'weather_station'
sensible_bulk(
  t1,
  rho = 1.225,
  cp = 1005,
  k = 0.41,
  min_wind = 0.1,
  warn_threshold = 600,
  ...
)
```

## Arguments

- t1:

  Air temperature at lower measurement height.

- ...:

  Further arguments passed to methods.

- t2:

  Air temperature at upper measurement height.

- v1:

  Wind speed at lower measurement height.

- v2:

  Optional wind speed at upper measurement height. If missing, `v1` is
  used.

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

  Minimum wind speed for the resistance calculation. Values at or below
  this threshold return `NA`.

- warn_threshold:

  Absolute flux threshold for diagnostic warnings.

## Value

Sensible heat flux in W m-2.

## Details

The sign convention follows the package energy-balance convention:

`H > 0` means sensible heat flux away from the surface.

Therefore, with `t1` as lower air temperature and `t2` as upper air
temperature, positive `t1 - t2` produces positive sensible heat flux.
