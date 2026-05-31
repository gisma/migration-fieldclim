# fieldClim 1.2.0

## Heat-flux methods

- Added a Bulk-Residual heat-flux workflow with `sensible_bulk()`, `latent_bulk_residual()` and `turb_flux_bulk_residual()`.
- `sensible_bulk()` estimates sensible heat flux from the temperature difference between two heights and a simplified aerodynamic resistance.
- `latent_bulk_residual()` computes latent heat flux as `rad_bal - soil_flux - sensible`.
- Added optional Richardson-number screening for Bulk-Residual via `stability_method = "ri_guard"`.
- The Richardson guard attaches `bulk_Ri_g` and `bulk_stability` attributes and returns `NA` for invalid, weak-shear or very stable profile cases.
- The default Bulk-Residual behaviour remains the neutral, unguarded estimate with `stability_method = "none"`.

## Penman latent heat

- Corrected the Penman vapour-pressure-deficit term by converting saturation and actual vapour pressure from hPa to kPa before use.
- This fixes a unit mismatch in `latent_penman()` and can substantially change Penman latent-heat estimates.
- Aerodynamic-resistance handling in `latent_penman()` is now elementwise; invalid log arguments, invalid wind and non-finite aerodynamic states return `NA` with a warning.
- `latent_penman.weather_station()` now uses `hum1` when available and falls back to `rh`; missing humidity input produces an explicit failure instead of an unclear downstream error.

## Bowen ratio

- Sensible and latent Bowen paths now use the same guarded denominator logic for `1 + beta`.
- Finite, uncapped Bowen cases still close the available energy `rad_bal - soil_flux`.
- Non-finite Bowen ratios or non-finite denominators now return `NA` elementwise with warnings.
- Near-singular capped cases are treated as guarded outputs and are not interpreted as exact energy-balance closure.
- The exported Bowen implementation remains the documented `fieldClim` beta path based on `gamma_code * dpot / dah`.

## Monin-Obukhov / Profile

- Corrected `sensible_monin()` to use the documented vertical gradient denominator `z2 - z1` instead of `log(z2 - z1)`.
- `sensible_monin()` and `latent_monin()` now return controlled values for critical profile cases: zero temperature gradient gives zero sensible heat flux, and zero moisture gradient gives zero latent heat flux.
- Invalid heights, invalid wind input, weak shear and non-finite profile states return `NA` with warnings.
- Monin-Obukhov/Profile outputs remain profile-based estimates. They are not forced to close `rad_bal - soil_flux`.

## Priestley-Taylor

- Priestley-Taylor sensible and latent heat formulas remain unchanged.
- Warning checks were made more robust for vectors containing `NA`.
- Documentation now clarifies the package implementation and sign convention for Priestley-Taylor outputs.

## Radiation, solar geometry and transmittance

- `sol_hour_angle()` and `sol_azimuth()` now handle POSIXct and POSIXlt datetime inputs consistently.
- `trans_air_mass_rel()` now returns `NA` with a warning for non-positive or invalid solar elevation instead of leaking `NaN`.
- Valid positive-elevation transmittance calculations keep the previous formula.
- Radiation-balance formulas were not changed in this release.

## Soil thermal functions

- `soil_heat_flux()` now returns `NA` with a warning for invalid depth pairs, including non-finite, negative or equal depths.
- Valid `soil_heat_flux()` calculations keep the existing sign convention: positive `soil_flux` means heat flux into the soil.
- Corrected `soil_attenuation()` to call `soil_thermal_cond(texture, moisture)` in the documented argument order.

## Humidity and helper functions

- `hum_precipitable_water()` now handles POSIXct input safely by converting internally to POSIXlt before extracting month information.
- This fixes failures in the `rad_sw_in()` -> `trans_vapor()` -> `hum_precipitable_water()` path when datetime input is POSIXct.
- Existing POSIXlt input remains supported.

## `weather_station` workflows

- `turb_flux_calc()` now includes Bulk-Residual outputs in the full workflow.
- Added `pt_only = TRUE` to compute only the Priestley-Taylor sensible and latent heat fluxes for a restricted workflow.
- Penman failures inside `turb_flux_calc()` are now caught and represented as `NA` output instead of stopping the whole workflow.
- `as.data.frame.weather_station()` is more robust for objects without a `$measurements` field.

## Documentation

- Roxygen documentation was updated for formulas, units, sign conventions, examples, source references and guard behaviour.
- The documentation now separates energy-balance-closing methods from profile-based estimates and latent-heat-only paths.
- Help pages and vignettes document the method-family context and package implementation choices. Remaining scientific validation should be added through benchmark datasets, published numerical examples and explicit table-value audits where needed.

## Tests

- Added method equation-contract tests for radiation balance, soil heat flux, Priestley-Taylor, Bulk-Residual, Bowen, Penman and Monin-Obukhov/Profile equations.
- Added helper equation-contract tests for documented humidity, pressure, temperature, boundary-layer and turbulent-flux helper equations.
- Added `weather_station` API parity tests for direct calls versus `weather_station` methods.
- Added workflow tests for `turb_flux_calc()` including `pt_only`, full workflow output, Penman fallback and Bulk-Residual Richardson-guard pass-through.
- Current validation status: `devtools::test()` passes with 470 tests and one intentional skip; `devtools::check()` passes with 0 errors, 0 warnings and 0 notes.
