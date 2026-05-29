# Changelog

## fieldClim 1.2.0

### Heat-flux methods

- Added a Bulk-Residual workflow with
  [`sensible_bulk()`](https://gisma.github.io/migration-fieldclim/reference/sensible_bulk.md),
  [`latent_bulk_residual()`](https://gisma.github.io/migration-fieldclim/reference/latent_bulk_residual.md)
  and
  [`turb_flux_bulk_residual()`](https://gisma.github.io/migration-fieldclim/reference/turb_flux_bulk_residual.md).
- [`sensible_bulk()`](https://gisma.github.io/migration-fieldclim/reference/sensible_bulk.md)
  estimates sensible heat flux from the temperature difference between
  two heights and a simplified aerodynamic resistance.
- [`latent_bulk_residual()`](https://gisma.github.io/migration-fieldclim/reference/latent_bulk_residual.md)
  computes latent heat flux as `rad_bal - soil_flux - sensible`.
- Added optional Richardson-number screening for Bulk-Residual via
  `stability_method = "ri_guard"`.
- The Richardson guard attaches `bulk_Ri_g` and `bulk_stability`
  attributes and returns `NA` for invalid, weak-shear or very stable
  profile cases.
- The default Bulk-Residual behaviour remains the neutral, unguarded
  estimate with `stability_method = "none"`.

### Penman latent heat

- Corrected the Penman vapour-pressure-deficit term by converting
  saturation and actual vapour pressure from hPa to kPa before use.
- This fixes a unit mismatch in
  [`latent_penman()`](https://gisma.github.io/migration-fieldclim/reference/latent_penman.md)
  and can substantially change Penman latent-heat estimates.
- Aerodynamic-resistance handling in
  [`latent_penman()`](https://gisma.github.io/migration-fieldclim/reference/latent_penman.md)
  is now elementwise; invalid log arguments, invalid wind and non-finite
  aerodynamic states return `NA` with a warning.
- [`latent_penman.weather_station()`](https://gisma.github.io/migration-fieldclim/reference/latent_penman.md)
  now uses `hum1` when available and falls back to `rh`; missing
  humidity input produces an explicit failure instead of an unclear
  downstream error.

### Bowen ratio

- Sensible and latent Bowen paths now use the same guarded denominator
  logic for `1 + beta`.
- Finite, uncapped Bowen cases still close the available energy
  `rad_bal - soil_flux`.
- Non-finite Bowen ratios or non-finite denominators now return `NA`
  elementwise with warnings.
- Near-singular capped cases are treated as guarded outputs and are not
  interpreted as exact energy-balance closure.
- The implemented beta form remains `gamma_code * dpot / dah`;
  source-form equivalence to a textbook Bowen-ratio formulation remains
  open.

### Monin-Obukhov / Profile

- Corrected
  [`sensible_monin()`](https://gisma.github.io/migration-fieldclim/reference/sensible_monin.md)
  to use the documented vertical gradient denominator `z2 - z1` instead
  of `log(z2 - z1)`.
- [`sensible_monin()`](https://gisma.github.io/migration-fieldclim/reference/sensible_monin.md)
  and
  [`latent_monin()`](https://gisma.github.io/migration-fieldclim/reference/latent_monin.md)
  now return controlled values for critical profile cases: zero
  temperature gradient gives zero sensible heat flux, and zero moisture
  gradient gives zero latent heat flux.
- Invalid heights, invalid wind input, weak shear and non-finite profile
  states return `NA` with warnings.
- Monin-Obukhov/Profile outputs remain profile-based estimates. They are
  not forced to close `rad_bal - soil_flux`.

### Priestley-Taylor

- Priestley-Taylor sensible and latent heat formulas remain unchanged.
- Warning checks were made more robust for vectors containing `NA`.
- Documentation now clarifies that `sc()` and `gam()` are used as
  compatible table-scale coefficients in the package implementation;
  their absolute source-unit scale remains an open validation item.

### Radiation, solar geometry and transmittance

- [`sol_hour_angle()`](https://gisma.github.io/migration-fieldclim/reference/sol_hour_angle.md)
  and
  [`sol_azimuth()`](https://gisma.github.io/migration-fieldclim/reference/sol_azimuth.md)
  now handle POSIXct and POSIXlt datetime inputs consistently.
- [`trans_air_mass_rel()`](https://gisma.github.io/migration-fieldclim/reference/trans_air_mass_rel.md)
  now returns `NA` with a warning for non-positive or invalid solar
  elevation instead of leaking `NaN`.
- Valid positive-elevation transmittance calculations keep the previous
  formula.
- Radiation-balance formulas were not changed in this release.

### Soil thermal functions

- [`soil_heat_flux()`](https://gisma.github.io/migration-fieldclim/reference/soil_heat_flux.md)
  now returns `NA` with a warning for invalid depth pairs, including
  non-finite, negative or equal depths.
- Valid
  [`soil_heat_flux()`](https://gisma.github.io/migration-fieldclim/reference/soil_heat_flux.md)
  calculations keep the existing sign convention: positive `soil_flux`
  means heat flux into the soil.
- Corrected
  [`soil_attenuation()`](https://gisma.github.io/migration-fieldclim/reference/soil_attenuation.md)
  to call `soil_thermal_cond(texture, moisture)` in the documented
  argument order.
- Soil table values and source validation remain unchanged.

### Humidity and helper functions

- [`hum_precipitable_water()`](https://gisma.github.io/migration-fieldclim/reference/hum_precipitable_water.md)
  now handles POSIXct input safely by converting internally to POSIXlt
  before extracting month information.
- This fixes failures in the
  [`rad_sw_in()`](https://gisma.github.io/migration-fieldclim/reference/rad_sw_in.md)
  -\>
  [`trans_vapor()`](https://gisma.github.io/migration-fieldclim/reference/trans_vapor.md)
  -\>
  [`hum_precipitable_water()`](https://gisma.github.io/migration-fieldclim/reference/hum_precipitable_water.md)
  path when datetime input is POSIXct.
- Existing POSIXlt input remains supported.

### `weather_station` workflows

- [`turb_flux_calc()`](https://gisma.github.io/migration-fieldclim/reference/turb_flux_calc.md)
  now includes Bulk-Residual outputs in the full workflow.
- Added `pt_only = TRUE` to compute only the Priestley-Taylor sensible
  and latent heat fluxes for a narrower, robust entry workflow.
- Penman failures inside
  [`turb_flux_calc()`](https://gisma.github.io/migration-fieldclim/reference/turb_flux_calc.md)
  are now caught and represented as `NA` output instead of stopping the
  whole workflow.
- [`as.data.frame.weather_station()`](https://gisma.github.io/migration-fieldclim/reference/as.data.frame.weather_station.md)
  is more robust for objects without a `$measurements` field.

### Documentation and validation notes

- Roxygen documentation was updated for formulas, units, sign
  conventions, examples, guard behaviour and remaining source-validation
  items.
- The documentation now separates energy-balance-closing methods from
  profile-based estimates and latent-heat-only paths.
- Remaining open validation items include the exact Penman source form,
  Bowen `gamma_code` equivalence, Monin-Obukhov/Profile stability forms,
  Priestley-Taylor helper coefficient scales, radiation/transmittance
  references, soil table values and precipitable-water reference tables.
