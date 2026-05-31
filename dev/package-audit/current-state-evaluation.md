# Current fieldClim package state evaluation

## Scope

This document summarizes the current package state from the implementation, tests, vignettes, README/NEWS, and the existing physics-audit notes. It is an evaluation document only. No source code, tests, generated Rd files, vignettes, README, NEWS, DESCRIPTION or NAMESPACE files were changed for this pass.

## Current package scope

fieldClim is currently a weather-station based microclimate and micrometeorological calculation package. The central workflow object is `weather_station`, a list-like S3 container created by `build_weather_station()`. The object stores supplied named fields exactly as provided and does not calculate physical quantities or validate whether downstream formula requirements are satisfied.

The package is not a full Eddy Covariance processing workflow. It does not perform EC coordinate rotation, frequency-response correction, despiking, footprint filtering, storage correction, gap filling, or flux partitioning from high-frequency covariance data. Its implemented heat-flux paths are station-data or profile-gradient methods:

- Priestley-Taylor
- Bulk-Residual
- Bowen-ratio
- Monin-Obukhov/Profile
- Penman-type latent heat

Radiation, solar geometry, transmittance, terrain, soil, humidity, pressure and temperature helpers support those methods and direct station calculations.

## Current sign convention

The package convention is now documented and tested consistently:

- `Rn > 0`: net radiative input at the surface.
- `G > 0`: soil heat flux into the soil.
- `H > 0`: sensible heat flux away from the surface.
- `LE > 0`: latent heat flux away from the surface.
- Available turbulent energy is `Rn - G`, implemented as `rad_bal - soil_flux`.

Priestley-Taylor, Bulk-Residual and finite uncapped Bowen cases use this available-energy convention. Monin-Obukhov/Profile outputs are diagnostic and are not expected to close `Rn - G`. Penman returns latent heat flux only and does not create a paired sensible heat output.

## Method status

| Method area | Implemented input requirements | Output fields / return | Closes `Rn - G`? | Guards and fallback behaviour | Open source-validation items | Tests currently present |
|---|---|---|---|---|---|---|
| Priestley-Taylor | `temp`, `rad_bal`, `soil_flux`, `surface_type`; internal `sc()`, `gam()`, `priestley_taylor_coefficient` table. | `latent_priestley_taylor`, `sensible_priestley_taylor` in workflow; direct functions return W m-2 vectors. | Yes, `LE_PT + H_PT = Rn - G` by formula when inputs match. | Invalid `surface_type` errors; high absolute flux warnings; `pt_only = TRUE` uses only this path. | PT alpha table values remain source-open; `sc()`/`gam()` are now Foken/Stull source-table tested and not FAO-56 gamma. | Equation contracts, source-table tests, PT closure tests, `pt_only` isolation tests, API parity tests. |
| Bulk-Residual | `t1`, `t2`, `v1`, `z1`, `z2`, `rad_bal`, `soil_flux`; optional `v2`; optional `stability_method = "ri_guard"` needs `v2`; optional `elev` for potential-temperature Richardson guard. | `sensible_bulk`, `latent_bulk_residual`; `turb_flux_bulk_residual()` appends both to a `weather_station`. | Yes for finite unguarded or valid guarded sensible values: `H_bulk + LE_res = Rn - G`. If `H_bulk` is `NA`, residual is `NA`. | Low wind returns `NA` with warning; invalid scalar heights stop; `ri_guard` returns `NA` for invalid/very stable/weak-shear cases and attaches `bulk_Ri_g` / `bulk_stability` attributes. | Neutral bulk formula is a reference path, not a full stability-corrected model. Richardson guard is diagnostic screening, not a Monin-Obukhov correction. | Equation contracts, guard tests, stability tests, workflow tests, API parity tests. |
| Bowen | `t1`, `t2`, `hum1`, `hum2`, `z1`, `z2`, `elev`, `rad_bal`, `soil_flux`; optional denominator `cap`. | `sensible_bowen`, `latent_bowen`. | Yes only for finite, uncapped denominators; capped cases may not close by design. | Non-finite beta/denominator returns `NA` with warning; optional cap guards near-zero `1 + beta`; high absolute flux warnings. | Exported beta uses `gamma_code * dpot / dah`; exact source-form and unit equivalence remain open. Capped outputs are guarded diagnostics. | Equation-contract tests, source/implementation tests for beta path, cap tests, invalid-gradient tests, API parity tests. |
| Monin-Obukhov/Profile | `t1`, `t2`, `hum1`, `hum2`, `v1`, `v2`, `z1`, `z2`, `elev`, plus `surface_type` or `obs_height`; related Richardson and stability helpers. | `sensible_monin`, `latent_monin`, `stability`; direct functions return diagnostic flux/profile vectors. | No. Diagnostic-only profile estimates; not normalized to available energy. | Invalid heights/winds return `NA` with warning; zero potential-temperature gradient gives zero sensible heat; zero humidity gradient gives zero latent heat; vector-local invalid handling. | Full physical source validation remains open; constants and profile assumptions are method-background documented. | MO diagnostic-only tests, edge-case tests, Richardson/stability tests, equation denominator tests, workflow tests. |
| Penman | Default: `datetime`, `v`, `temp`, `rh`, `z`, `rad_bal`, `elev`, `lat`, `lon`, `soil_flux`, `obs_height`, `surface_type`. Weather-station method uses `v1`, `z1`, `temp`, `rad_bal`, `elev`, `lat`, `lon`, `soil_flux`, `obs_height`, `surface_type`, and `hum1` if present else `rh`. | `latent_penman` only. No sensible Penman output. | No. It is LE-only and does not enforce closure. | Invalid aerodynamic resistance returns `NA` elementwise with warning; Penman failure inside `turb_flux_calc()` is non-fatal and becomes an `NA` vector. | Exact source-form/magnitude validation open; `hum1`/`rh` routing is internally documented but naming remains open; aerodynamic resistance convention remains open. | VPD kPa unit tests, available-energy sign tests, field mapping tests, vector guard tests, workflow fallback tests, Penman source/magnitude audit. |
| Radiation/Solar/Transmittance | Modeled radiation requires datetime, lon, lat, elev, temp, rh, slope, exposition, valley, surface_type, surface_temp depending on component. | Modeled `rad_sw_*`, `rad_lw_*`, and `rad_bal` components. | Radiation balance follows `K* = K_down - K_up`, `L* = L_down - L_up`, `Rn = K* + L*`. | Night shortwave guarded to zero; transmittance below horizon returns controlled `NA`; unknown surface type currently has open/undesirable zero-length behaviour in some albedo/emissivity lookups. | Solar timebase/source constants, transmittance constants, modeled-vs-measured radiation equivalence, unknown surface policy remain open. | Radiation balance contracts, solar/timebase tests, transmittance guard tests, vector/weather-station coverage tests. |
| Soil | `soil_heat_flux()` uses `texture`, `moisture`, `soil_temp1`, `soil_temp2`, `soil_depth1`, `soil_depth2`; thermal helpers use `texture`, `moisture`. | `soil_flux` or thermal parameters as direct returns; no automatic storage unless user assigns them. | Supplies `G` for `Rn - G`; sign is positive into soil. | Invalid depth pairs return `NA` with warning; invalid texture errors; out-of-domain moisture behavior is documented/tested. | Soil table values and clamp policy remain source-validation open. | Soil sign, vector, invalid-depth, table-domain and attenuation unit-conversion tests. |
| Humidity/Pressure/Temperature helpers | Variables include `rh`, `temp`, `elev`, profile humidity/temperature fields and datetime/lat for precipitable water. | Vapour pressure, absolute/specific humidity, precipitable water, pressure, air density, potential temperature. | Not heat-flux closure methods. | Vector handling and POSIXct/POSIXlt paths are tested; some helpers are formula-contract tested. | Precipitable-water seasonal table values are not independently revalidated; helper units are documented, with `sc()`/`gam()` table-source tested. | Helper equation-contract tests, helper edge tests, API parity tests. |

## Weather-station and wrapper state

`build_weather_station()` stores all named fields exactly as supplied and assigns class `weather_station`. Unknown fields are allowed. The function does not fill missing values, derive physical inputs, check units, check vector lengths, or verify physical consistency. This is a deliberate current object-container design.

`check_availability()` checks required field names only. A field that exists with `NULL`, wrong units, wrong physical meaning or inconsistent length can still pass name availability. Method-specific functions then either compute, warn, return `NA`, or fail depending on their own guards.

`turb_flux_calc()` orchestrates methods and appends output fields. With `pt_only = TRUE`, it computes only Priestley-Taylor fields and returns before Bulk, Bowen, Monin or Penman are attempted. In full workflow, non-Penman methods are called directly; Penman alone is wrapped in `tryCatch()` and becomes an `NA` vector if it fails.

## Test status

The current suite is broad and includes several different kinds of tests:

- Implementation-contract tests: method formula paths, denominator/cap policy, optional Richardson guard, Penman VPD kPa conversion, weather-station object preservation, `turb_flux_calc()` orchestration.
- Guard/edge-case tests: invalid heights, low wind, zero gradients, invalid aerodynamic resistance, invalid texture, invalid radiation/transmittance domains, missing fields, singular/plural availability errors.
- Equation-contract tests: radiation balances, soil heat flux, Priestley-Taylor, Bulk-Residual, Bowen, Penman, Monin/Profile denominator and helper equations.
- Source-table tests: Foken/Stull Table 6 checks for `sc()` and `gam()`.
- API parity tests: direct method calls versus `weather_station` methods.
- Workflow/integration tests: Caldern teaching day, `pt_only`, full workflow fields, Penman fallback, Bulk-Residual guard pass-through.

Known gaps remain:

- Empirical validation against independent field observations remains outside the current tests.
- Several lookup tables and empirical coefficients are documented but not independently source-table validated.
- Closure tests prove algebraic consistency, not physical correctness.
- Direct-vs-`weather_station` parity tests are API tests, not formula validation.

## Documentation status

- README: describes station-data scope, sign convention, method families, `pt_only`, Bulk-Residual, Penman and testing status. It distinguishes Monin/Profile diagnostic output and Penman LE-only output.
- NEWS.md: records recent physics audit corrections and guards: Bulk-Residual, Penman VPD unit fix, Bowen denominator guard, Monin/Profile hardening, sign convention and expanded tests.
- Vignettes: include workflow examples, radiation/soil checks, method background and interpretation. They discuss measured versus modeled radiation and stress that modeled values are not equivalent to direct measurements.
- Roxygen/reference documentation: documents current formulas, sign conventions, guards and method-specific limitations. Some source validation remains explicitly open in development audit files, especially empirical tables, Bowen beta source equivalence, Penman final source/magnitude, solar/transmittance constants and some domain policies.

## Current-state conclusion

fieldClim is currently strongest as a transparent, tested station-data calculation package with explicit formulas, object wrappers and guard behaviour. Its weakest areas are not basic arithmetic contracts, but provenance, measured-versus-modeled forcing distinction, empirical source-table validation and missing-input preparation. Any convenience layer for missing fields should therefore sit in front of the current methods as explicit preprocessing and inspection. It must not change the current `weather_station` container semantics by default.
