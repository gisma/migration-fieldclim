# Changelog

## fieldClim 1.2.0

### Functional changes

- Added a Bulk-Residual heat-flux workflow with
  [`sensible_bulk()`](https://gisma.github.io/migration-fieldclim/reference/sensible_bulk.md),
  [`latent_bulk_residual()`](https://gisma.github.io/migration-fieldclim/reference/latent_bulk_residual.md),
  and
  [`turb_flux_bulk_residual()`](https://gisma.github.io/migration-fieldclim/reference/turb_flux_bulk_residual.md).
- Added optional Richardson-number screening for Bulk-Residual via
  `stability_method = "ri_guard"`; the default remains the neutral bulk
  estimate.
- Corrected Penman vapour-pressure scaling by converting saturation and
  actual vapour pressure from hPa to kPa before using the aerodynamic
  vapour-pressure-deficit term.
- Corrected the Monin-Obukhov sensible-heat gradient denominator from
  `log(z2 - z1)` to `z2 - z1`.
- Added elementwise guards for invalid or non-finite Bowen,
  Monin-Obukhov/Profile, Penman, soil, Richardson-number and
  transmittance states.
- Improved POSIXct/POSIXlt datetime handling in solar and
  humidity-related paths, including precipitable-water calculations.
- Extended
  [`turb_flux_calc()`](https://gisma.github.io/migration-fieldclim/reference/turb_flux_calc.md)
  with Bulk-Residual outputs, a `pt_only` mode, and graceful Penman
  fallback to `NA` when required inputs are unavailable.
- Improved `weather_station` handling, including a more robust
  [`as.data.frame.weather_station()`](https://gisma.github.io/migration-fieldclim/reference/as.data.frame.weather_station.md)
  fallback.

### Documentation

- Updated Roxygen documentation for formulas, units, sign conventions,
  guard behaviour and remaining source-validation items.
- Clarified that Monin-Obukhov/Profile outputs are profile-based
  estimates and are not forced to close `rad_bal - soil_flux`.
- Clarified that Bowen closure is guaranteed only for finite, uncapped
  denominator cases.
- Clarified that Penman is a latent-heat-only comparison path in the
  package workflow.

### Notes

- Priestley-Taylor formulas remain unchanged.
- The Bulk-Residual Richardson guard is opt-in; existing default neutral
  bulk behaviour is preserved.
- Several source-form validation questions remain open, especially for
  Bowen `gamma_code`, simplified Penman resistance assumptions,
  Monin-Obukhov/Profile stability forms, Priestley-Taylor helper
  coefficient scales, radiation/transmittance references and soil table
  values.
