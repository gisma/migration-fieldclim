# Sensible and latent heat fluxes

Calculate sensible and latent heat-flux estimates for a
`weather_station` object using the available `fieldClim` method
families: Priestley-Taylor, Bulk-Residual, Bowen-ratio,
Monin-Obukhov/profile and Penman-type latent heat flux.

## Usage

``` r
turb_flux_calc(weather_station, pt_only = FALSE)
```

## Arguments

- weather_station:

  Object of class `weather_station`.

- pt_only:

  If `TRUE`, calculate only the Priestley-Taylor sensible and latent
  heat fluxes. This supports the introductory or robust available-energy
  workflow without requiring inputs for the optional additional methods.
  If `FALSE`, the full workflow attempts the available additional
  methods, including Bulk-Residual, Bowen-ratio, Monin-Obukhov/profile
  and Penman-type latent heat flux. Unavailable optional inputs produce
  `NA` values and/or warnings according to the respective method.

## Value

Object of class `weather_station` with additional heat-flux fields.
Depending on `pt_only` and on available input fields, these may include:
`sensible_priestley_taylor`, `latent_priestley_taylor`, `sensible_bulk`,
`latent_bulk_residual`, `sensible_bowen`, `latent_bowen`,
`sensible_monin`, `latent_monin`, and `latent_penman`.

## Details

The methods are not interchangeable measurements. Priestley-Taylor,
Bulk-Residual and Bowen-ratio are energy-partition or residual
workflows. Penman returns latent heat flux only. Monin-Obukhov/profile
outputs are diagnostic and are not forced to close the available energy.
