# R-only functional changelog

## Overview
- changed R files: `R/boundary_layers.R`, `R/bulk.R`, `R/fieldclim_params.R`, `R/globals.R`, `R/humidity.R`, `R/latent.R`, `R/pressure.R`, `R/radiation.R`, `R/sensible.R`, `R/soil.R`, `R/solar.R`, `R/temperature.R`, `R/terrain.R`, `R/transmittance.R`, `R/turbulence.R`, `R/turbulent_flux.R`, `R/utility.R`, `R/utility_turbulent_flux.R`, `R/weather_station.R`.
- main functional themes: new Bulk-Residual turbulent-flux workflow; Penman vapour-pressure unit correction and surface-type normalization; elementwise guards for Bowen, Monin-Obukhov/profile, Richardson number, soil depth, solar time handling, and transmittance air mass; broader `weather_station` pass-through behavior; corrected `as.data.frame.weather_station()` fallback for objects without `$measurements`.
- documentation-only themes: roxygen parameter normalization, unit wording, examples, sign-convention clarification, source-validation notes, and package-wide parameter documentation via `fieldclim_params()`.

## Method-level changes

### Penman / latent heat
- files: `R/latent.R`.
- formula changes: formula changed: yes. Old Penman aerodynamic vapour-pressure term used `es - ea` directly from `pres_sat_vapor_p()` / `pres_vapor_p()` in hPa while `delta` and `gamma` were on a kPa scale. New code converts `es` and `ea` to kPa and uses `vpd_kPa = es_kPa - ea_kPa`, keeping the vapour-pressure-deficit term on the same scale as `delta` and `gamma`.
- formula changes: formula changed: no; behavior guard added for aerodynamic resistance. Old code used scalar `max((z - d) / z0, cap_value)`, which could silently force invalid or vector cases through a scalar cap. New code computes `log_arg1`, `log_arg2`, and `ra` elementwise, returns `NA` for non-finite, non-positive, or non-positive-wind aerodynamic states, and warns.
- unit/input changes: `latent_penman.default()` now normalizes `surface_type`, accepting existing Penman resistance classes and mapped fieldClim aliases such as `field`, `lawn`, `agriculture`, `coniferous forest`, `deciduous forest`, `mixed forest`, and `shrub`.
- unit/input changes: `latent_penman.weather_station()` now uses `hum1` when present and otherwise falls back to `rh`; missing both now produces an explicit error. It uses `z1` directly.
- guards/warnings: high/low flux warnings now use `any(out > 600, na.rm = TRUE)` and `any(out < -600, na.rm = TRUE)`, replacing checks against `!is.na(out)`.
- open items: Penman source-form validation remains open for the simplified Penman-Monteith-type implementation and its resistance assumptions; this changelog treats the kPa conversion as a code-level formula correction, not full scientific validation.

### Bowen
- files: `R/sensible.R`, `R/latent.R`.
- beta/source-form status: the implemented Bowen ratio remains `gamma_code * dpot / dah`, with potential-temperature gradient and absolute-humidity gradient. Roxygen now documents that `gamma_code = 0.00066 * (1 + 0.000946 * t1)` has source-form equivalence still open.
- closure/cap/non-finite handling: formula changed: no; behavior guard added. For finite uncapped denominators, sensible and latent Bowen formulas still partition `rad_bal - soil_flux` using `B / (1 + B)` and `1 / (1 + B)`. The `cap` behavior changed from capping `bowen_ratio` in `sensible_bowen()` and directly rewriting small denominators in `latent_bowen()` to guarding the shared denominator `1 + bowen_ratio` with signed `+/- cap`.
- closure/cap/non-finite handling: non-finite Bowen ratios or denominators now return `NA` elementwise with warnings in both sensible and latent Bowen functions.
- formula changes: formula changed: no; behavior guard added for non-finite and near-zero partition denominators. Output can change when `cap` is supplied or when `bowen_ratio`/denominator is non-finite.
- open items: Bowen `gamma_code` source equivalence remains open; capped cases are explicitly diagnostic and may not close available energy exactly.

### Bulk-Residual
- files: `R/bulk.R`, `R/turbulent_flux.R`.
- neutral bulk formula status: formula changed: yes because this is a new method family. New `sensible_bulk()` computes `H_bulk = rho * cp * (t1 - t2) / r_a`, with `r_a = log(z2 / z1) / (k * wind_mean)`. `wind_mean` is `v1` by default and `(v1 + v2) / 2` when `v2` is supplied.
- Richardson guard: formula changed: no; behavior guard added. `stability_method = "ri_guard"` does not rescale valid neutral fluxes. It computes `Ri_g = (g / theta_mean) * dtheta_dz / du_dz^2`, attaches `bulk_Ri_g` and `bulk_stability`, and returns `NA` for invalid or very stable cases.
- default behavior: default behavior was preserved for the neutral estimate within this new method: `stability_method = "none"` returns the unguarded neutral bulk flux except for required height and minimum-wind guards.
- weather_station pass-through: `sensible_bulk.weather_station()` reads `t1`, `t2`, `v1`, `z1`, `z2`, optional `v2`, and optional `elev`. `latent_bulk_residual.weather_station()` reads `rad_bal` and `soil_flux`, computes `sensible_bulk()` when `sensible` is not supplied, and returns `rad_bal - soil_flux - sensible`. `turb_flux_bulk_residual()` adds `sensible_bulk` and `latent_bulk_residual` fields to the object.
- open items: the neutral bulk method is documented as a simplified reference, not a Monin-Obukhov stability-corrected method; physical suitability and source validation remain open beyond the implemented formulas.

### Monin-Obukhov / Profile
- files: `R/sensible.R`, `R/latent.R`, `R/turbulent_flux.R`.
- gradient denominator change: formula changed: yes for `sensible_monin.default()`. Old potential-temperature gradient used `(theta2 - theta1) / log(z2 - z1)`. New code uses `(theta2 - theta1) / (z2 - z1)`, matching the documented height-difference gradient.
- invalid/zero-gradient handling: formula changed: no; behavior guard added. `sensible_monin.default()`, `latent_monin.default()`, and `turb_flux_grad_rich_no.default()` now recycle inputs to common length, guard invalid heights, invalid winds, non-finite profile inputs, weak shear, and invalid numerical states. Affected elements return `NA` with warnings.
- invalid/zero-gradient handling: zero potential-temperature gradient now returns `0` sensible Monin flux; zero moisture gradient now returns `0` latent Monin flux.
- invalid/zero-gradient handling: missing both `obs_height` and `surface_type` now stops in `sensible_monin.default()` instead of printing a message and continuing.
- energy-balance interpretation: roxygen now clarifies that Monin-Obukhov/profile outputs are diagnostic profile/stability estimates and are not expected to close `R_n - G`.
- open items: Monin/profile source validation remains open for the stability correction forms, constants, and physical interpretation; this revision adds guards and one denominator correction but does not fully validate the method scientifically.

### Priestley-Taylor
- files: `R/sensible.R`, `R/latent.R`.
- formula status: formula changed: no; behavior guard added. The Priestley-Taylor sensible and latent formulas remain unchanged, but high/low flux warnings now test `out` with `na.rm = TRUE` instead of testing logical `!is.na(out)`.
- helper/source validation status: roxygen now states that `sc()` and `gam()` are Foken table-scale polynomial coefficients used in ratios and that their absolute pressure unit scale remains source-open.
- open items: validation of `sc()`/`gam()` scale and source equivalence remains open.

### Radiation / Solar / Transmittance
- files: `R/radiation.R`, `R/solar.R`, `R/transmittance.R`.
- POSIXct/POSIXlt handling: formula changed: no; behavior guard added. `sol_hour_angle.default()` and `sol_azimuth.default()` now coerce `datetime` with `as.POSIXlt(datetime)`, allowing POSIXct inputs to access `$hour`, `$min`, `$sec`, and `$mon`-style components reliably.
- invalid solar elevation / transmittance guards: formula changed: no; behavior guard added. `trans_air_mass_rel.default()` now computes relative air mass only for finite positive solar elevation and returns `NA` with a warning otherwise.
- formula status: radiation formulas in `R/radiation.R` are roxygen-only in the provided code-focused patch. `trans_air_mass_rel()` formula is unchanged for valid positive solar elevation.
- open items: radiation and atmospheric transmittance source validation remains open; no generated Rd/vignette/test changes were considered.

### Soil thermal functions
- files: `R/soil.R`.
- invalid depth handling: formula changed: no; behavior guard added. `soil_heat_flux.default()` still computes `-thermal_cond * (soil_temp1 - soil_temp2) / (soil_depth1 - soil_depth2)` for valid inputs, but now recycles vector inputs and returns `NA` with a warning for non-finite depths, negative depths, or equal depths.
- table/source status: formula changed: yes for `soil_attenuation.default()` call wiring. Old code called `soil_thermal_cond(moisture, texture)` despite the function signature documented/used elsewhere as `(texture, moisture)`. New code calls `soil_thermal_cond(texture, moisture)`.
- formula status: `soil_heat_flux()` formula did not change in executable code, but roxygen now documents the existing leading negative sign.
- open items: soil conductivity/heat-capacity table and attenuation source validation remain open.

### Humidity / pressure / temperature helpers
- files: `R/humidity.R`, `R/pressure.R`, `R/temperature.R`.
- POSIXct month handling in precipitable water: formula changed: no; behavior guard added. `hum_precipitable_water.default()` now coerces `datetime` to POSIXlt once, extracts `month`, preallocates numeric vectors, and loops over `seq_len(n)`. This fixes direct `$mon` access for POSIXct vectors and preserves the seasonal reference-table formula.
- input/unit behavior: humidity, pressure, and temperature helper changes in the visible patches are primarily roxygen parameter/unit clarification, except the precipitable-water POSIXct handling above.
- formula status: no visible helper formula changes beyond precipitable-water input handling in the allowed code-focused patch.
- open items: precipitable-water reference table/source validation remains open.

### weather_station wrappers / globals
- files: `R/weather_station.R`, `R/utility.R`, `R/turbulent_flux.R`, `R/globals.R`, `R/fieldclim_params.R`.
- wrapper behavior: `turb_flux_calc()` now has `pt_only = FALSE`. With `pt_only = TRUE`, it calculates only Priestley-Taylor sensible and latent fluxes and returns early. With the default `FALSE`, it now also calculates and stores `sensible_bulk` and `latent_bulk_residual`.
- wrapper behavior: `turb_flux_calc()` now catches `latent_penman(weather_station)` errors, warns, and fills `latent_penman` with `NA_real_` of the Priestley-Taylor length instead of failing the whole workflow.
- wrapper behavior: `as.data.frame.weather_station()` is now exported and handles objects without `$measurements` by converting `unclass(x)`.
- wrapper behavior: `plot_weather_station()` now calls `graphics::par()` explicitly; labels changed to ASCII unit wording only.
- globalVariables: new `R/globals.R` registers column-like names used by NSE-style code: `datetime`, `elev`, `exposition`, `lat`, `lon`, `moisture`, `rh`, `slope`, `soil_depth1`, `soil_depth2`, `soil_temp1`, `soil_temp2`, `surface_temp`, `surface_type`, `temp`, `texture`, and `valley`.
- formula status: formula changed: yes only insofar as `turb_flux_calc()` now includes new Bulk-Residual outputs by default; wrapper/global changes otherwise do not alter scientific formulas.

## Documentation-only R changes
- `R/boundary_layers.R`: `bound_thermal_avg()` example formatting only.
- `R/fieldclim_params.R`: new no-op internal roxygen parameter-sharing helper; documentation-only, returns `NULL`.
- `R/pressure.R`: roxygen parameter/unit additions for pressure, vapor pressure, saturation vapor pressure, and air density helpers.
- `R/radiation.R`: roxygen parameter/unit/example additions across radiation-balance helpers; no executable formula changes visible in the code-focused patch.
- `R/sensible.R`: roxygen sign-convention, unit, examples, source-open notes, and closure interpretation for Priestley-Taylor, Monin, and Bowen.
- `R/latent.R`: roxygen sign-convention, unit, examples, Penman-type description, Monin interpretation, Bowen denominator/cap explanation, and source-open notes.
- `R/soil.R`: roxygen documents the existing negative sign in `soil_heat_flux()` and invalid-depth behavior added in code.
- `R/weather_station.R`: plot label text changed from symbols to ASCII-style units; this affects displayed labels, not calculations.

## Potentially breaking changes
- `latent_penman()` outputs can change materially because vapour pressure deficit is now converted from hPa to kPa before entering the Penman equation.
- `latent_penman.weather_station()` may now stop when neither `rh` nor `hum1` exists; it may also produce different output by preferring `hum1` when available and accepting mapped surface types.
- `sensible_monin()` outputs can change because the potential-temperature gradient denominator changed from `log(z2 - z1)` to `z2 - z1`.
- Monin/Profile, Richardson, Bowen, soil, transmittance, and Penman functions now return `NA` with warnings for invalid states that previously could produce `Inf`, `NaN`, scalar-capped values, or misleading finite output.
- `sensible_bowen(cap = ...)` behavior changed from capping `bowen_ratio` to guarding the partition denominator `1 + B`.
- `turb_flux_calc()` now calculates Bulk-Residual outputs by default and catches Penman failures instead of stopping the whole workflow.
- `soil_attenuation.default()` can change because `soil_thermal_cond()` arguments are now passed as `texture, moisture`.

## Backward-compatible changes
- Default Priestley-Taylor formulas are preserved; warning checks were corrected without changing valid finite outputs.
- Default neutral `sensible_bulk()` behavior uses `stability_method = "none"`; Richardson screening is opt-in.
- `latent_bulk_residual()` is algebraic and preserves `LE = R_n - G - H` for supplied sensible heat flux.
- Valid positive `trans_air_mass_rel()` inputs keep the same formula.
- Valid `soil_heat_flux()` inputs keep the same executable formula.
- `turb_flux_calc(pt_only = TRUE)` provides a narrower workflow that avoids optional method requirements while preserving Priestley-Taylor output fields.
- POSIXlt inputs for solar and precipitable-water helpers remain supported; POSIXct support is improved.

## Remaining audit-open items
- Penman-Monteith-type source-form validation, including resistance assumptions and simplified output interpretation.
- Bowen `gamma_code` source equivalence and exact scientific mapping to a published beta/Bowen formulation.
- Monin-Obukhov/profile stability-correction constants, sign convention, and source equivalence.
- Priestley-Taylor `sc()` and `gam()` absolute unit scale/source validation.
- Radiation/transmittance atmospheric formulas and reference consistency.
- Soil thermal conductivity, heat capacity, and attenuation table/source validation.
- Precipitable-water seasonal reference table/source validation.

## Suggested NEWS.md entry

### fieldClim 1.2.0

- Added a Bulk-Residual turbulent-flux workflow with `sensible_bulk()`, `latent_bulk_residual()`, and `turb_flux_bulk_residual()`, including optional Richardson-number guarding and `weather_station` methods.
- Corrected Penman latent-heat vapour-pressure scaling by converting saturation and actual vapour pressure from hPa to kPa before use in the aerodynamic VPD term.
- Improved elementwise guards and warnings for Penman aerodynamic resistance, Bowen partition denominators, Monin/Profile invalid states, Richardson weak shear, invalid soil depths, and invalid solar elevation in relative air-mass calculations.
- Corrected the Monin sensible-heat potential-temperature gradient denominator from `log(z2 - z1)` to `z2 - z1`.
- Added POSIXct-safe datetime handling in solar hour-angle/azimuth and precipitable-water helpers.
- Extended `turb_flux_calc()` with Bulk-Residual outputs, a `pt_only` mode, and graceful Penman fallback to `NA` when required inputs are unavailable.
- Updated roxygen documentation to separate implemented formulas, sign conventions, guard behavior, and remaining source-validation items.
