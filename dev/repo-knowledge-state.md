# fieldClim repository knowledge state

## 1. Repository purpose and status

`fieldClim` is an R package for weather-station based microclimate and micrometeorological calculations. The source currently provides tools for:

- organizing station data in a `weather_station` object;
- modeling or combining shortwave, longwave and net radiation components;
- computing solar geometry, terrain and atmospheric transmittance terms;
- computing soil heat flux and soil thermal properties;
- estimating sensible and latent heat fluxes from station-scale inputs;
- comparing Priestley-Taylor, Bulk-Residual, Bowen-ratio, Monin-Obukhov/Profile and Penman-type paths;
- estimating selected boundary-layer and turbulence helper quantities.

This repository is a migration/consolidation repository derived from the original Marburg `fieldClim` code. It should be treated as an active development and audit repository, not as a final public release. R source files are the implementation source of truth. Tests are implementation contracts and regression checks. Files under `dev/` record audit history, rationale and open validation boundaries.

The packaged Caldern file, `inst/extdata/caldern_wiese_2017-06-30.csv`, is a one-day 5-minute teaching dataset with 288 observations. It is used for integration/workflow checks and examples. It is not an empirical benchmark proving flux correctness. The full raw Caldern dataset is intentionally not included.

The package does not implement a full Eddy Covariance workflow. It does not process high-frequency turbulence data, rotate wind vectors, despike, estimate spectral losses, align gas-analyser lags, calculate EC covariance fluxes or perform EC quality control. In this repository, EC references are method background and validation context. A prior decision also records that `EC` in Caldern metadata means electric conductivity, not Eddy Covariance.

## 2. Current sign convention

The consolidated sign convention is:

```text
Rn > 0   net radiative input at the surface
G  > 0   heat flux into the soil
H  > 0   sensible heat flux away from the surface
LE > 0   latent heat flux away from the surface
```

Available turbulent energy is:

```text
Rn - G
```

Energy-balance closing methods in normal finite cases are:

- Priestley-Taylor: `sensible_priestley_taylor() + latent_priestley_taylor() = rad_bal - soil_flux` by construction.
- Bulk-Residual: `sensible_bulk() + latent_bulk_residual() = rad_bal - soil_flux` when `sensible_bulk()` is finite.
- Bowen-ratio: `sensible_bowen() + latent_bowen() = rad_bal - soil_flux` only for finite, uncapped denominators.

Methods not forced to close `Rn - G` are:

- Monin-Obukhov/Profile: diagnostic profile/stability estimates.
- Penman-type latent heat: LE-only path; no paired package Penman sensible heat output.
- Radiation/Solar/Soil helper functions: input/modeling helpers, not turbulent-flux closure methods.

## 3. Implemented heat-flux methods

### Priestley-Taylor

Implemented functions:

- `latent_priestley_taylor()` in `R/latent.R`.
- `sensible_priestley_taylor()` in `R/sensible.R`.
- internal helpers `sc()` and `gam()` in `R/utility_turbulent_flux.R`.
- `priestley_taylor_coefficient` in `R/utility.R`.

Input requirements:

- `temp`, `rad_bal`, `soil_flux`, `surface_type`.
- Weather-station methods require those same fields.

Implemented logic:

```text
LE_PT = alpha_PT * sc(temp) / (sc(temp) + gam(temp)) * (Rn - G)
H_PT  = (((1 - alpha_PT) * sc(temp) + gam(temp)) / (sc(temp) + gam(temp))) * (Rn - G)
```

This is algebraically equivalent to `H_PT = Rn - G - LE_PT` when both methods use the same inputs. `sc()` and `gam()` are documented as Foken/Stull Table 6 scale coefficients in `kg kg-1 K-1`, not FAO-56 kPa-scale constants. Dedicated source-table tests compare `sc()` and `gam()` to Foken Table 6 rounded values.

Formula changed: no recent formula change to PT closure logic. Documentation and helper-unit interpretation were clarified.

Guards:

- invalid `surface_type` stops with listed allowed values.
- warnings for absolute fluxes beyond +/-600 W m-2.

Closure behavior:

- closes `Rn - G` for valid inputs, including negative available energy.

Tests present:

- PT closure and available-energy convention in `test-physics-contract.R` and `test-priestley-taylor-contract.R`.
- PT equation contracts in `test-equation-contracts.R`.
- `sc()`/`gam()` Foken Table 6 source-table tests in `test-priestley-taylor-source-table.R`.
- `pt_only` workflow isolation tests.

Known limitations/open items:

- Surface-specific `alpha` table values are package parameters; method background follows Priestley-Taylor/Foken, but the alpha table is not fully source-table validated.
- `sc()`/`gam()` table-scale values are source-table tested, but this does not validate all PT empirical choices.

### Bulk-Residual

Implemented functions:

- `sensible_bulk()`, `latent_bulk_residual()`, `turb_flux_bulk_residual()` in `R/bulk.R`.

Input requirements:

- `sensible_bulk.default()`: `t1`, `t2`, `v1`, optional `v2`, scalar `z1`, scalar `z2`.
- `latent_bulk_residual.default()`: `rad_bal`, `soil_flux`, `sensible`.
- Weather-station workflow: `t1`, `t2`, `v1`, `z1`, `z2`, `rad_bal`, `soil_flux`; optional `v2`; optional `elev` for `ri_guard` potential temperature.

Implemented logic:

```text
r_a    = log(z2 / z1) / (k * u_mean)
H_bulk = rho * cp * (t1 - t2) / r_a
LE_res = rad_bal - soil_flux - H_bulk
```

If `v2` is supplied, `u_mean = (v1 + v2) / 2`; otherwise `v1` is used.

Formula changed: new method/workflow relative to the original package consolidation. Default neutral formula remains unchanged after the optional guard was added.

Guards:

- `z1` and `z2` must be scalar and satisfy `0 < z1 < z2`.
- low or missing mean wind at/below `min_wind` returns `NA` with warning.
- large absolute fluxes warn but are not capped.
- optional `stability_method = "ri_guard"` computes gradient Richardson number and attaches attributes `bulk_Ri_g` and `bulk_stability`; invalid, weak-shear and very stable cases return `NA`.

Closure behavior:

- closes `Rn - G` by residual construction whenever `H_bulk` is finite.
- If `ri_guard` returns `NA` for `H_bulk`, residual LE is also `NA`; this prevents algebraic closure from hiding an invalid sensible estimate.

Tests present:

- neutral formula and residual closure in `test-bulk.R`, `test-equation-contracts.R`, and `test-physics-contract.R`.
- optional Richardson guard behavior in `test-bulk-stability.R` and API parity tests.
- workflow behavior in `test-turbulence-coverage.R`, `test-turbulent-flux-remaining-coverage.R`, and weather-station API parity tests.

Known limitations/open items:

- Default method is a simplified neutral bulk-transfer estimate, not a full stability-corrected flux model.
- Formal closure does not validate physical realism of `H_bulk`.
- `ri_guard` is a screening diagnostic, not a Monin-Obukhov correction.

### Bowen-ratio

Implemented functions:

- `sensible_bowen()` in `R/sensible.R`.
- `latent_bowen()` in `R/latent.R`.
- internal `bowen_ratio()` helper in `R/utility_turbulent_flux.R` documents a Bendix-style helper separately from exported Bowen implementation.

Input requirements:

- `t1`, `t2`, `hum1`, `hum2`, `z1`, `z2`, `elev`, `rad_bal`, `soil_flux`, optional `cap`.
- `hum1` and `hum2` are relative humidity values in percent and are converted internally to absolute humidity.

Implemented logic:

```text
dpot = (temp_pot_temp(t2, elev) - temp_pot_temp(t1, elev)) / (z2 - z1)
dah  = (hum_absolute(hum2, t2) - hum_absolute(hum1, t1)) / (z2 - z1)
gamma_code = 0.00066 * (1 + 0.000946 * t1)
beta = gamma_code * dpot / dah
H  = (Rn - G) * beta / (1 + beta)
LE = (Rn - G) / (1 + beta)
```

Formula changed: no beta formula change. Documentation was changed to describe the implemented `gamma_code * dpot / dah` path honestly instead of claiming proven equivalence to `gamma / Lv * Delta T / Delta q`.

Guards:

- non-finite beta or denominator returns `NA` with warning.
- optional denominator cap guards near-zero `1 + beta` by replacing the denominator with +/- `cap`.
- capped cases are finite guarded outputs but are not exact closure cases.

Closure behavior:

- exact closure only for finite uncapped denominators.
- capped or invalid cases are diagnostic/guarded and may not close.

Tests present:

- non-singular closure, cap behavior, invalid vector-local handling, zero humidity gradient handling, sign behavior, shared partition pathway and gamma-code locking in `test-bowen-source.R`, `test-physics-contract.R`, and `test-equation-contracts.R`.
- weather-station parity tests for non-singular inputs.

Known limitations/open items:

- Source-form and dimensional equivalence of `gamma_code` remain open.
- Existing tests lock implementation behavior; they do not prove literature equivalence of the beta coefficient.

### Monin-Obukhov/Profile

Implemented functions:

- `sensible_monin()` in `R/sensible.R`.
- `latent_monin()` in `R/latent.R`.
- `turb_flux_monin()`, `turb_flux_grad_rich_no()`, `turb_flux_stability()`, `turb_flux_ex_quotient_temp()`, `turb_flux_ex_quotient_imp()`, `turb_flux_imp_exchange()` in `R/turbulent_flux.R`.
- roughness/displacement/friction helpers in `R/turbulence.R`.

Input requirements:

- `t1`, `t2`, `hum1`, `hum2`, `v1`, `v2`, `z1`, `z2`, `elev`, plus either `surface_type` or `obs_height` depending on roughness path.

Implemented logic:

- Sensible MO uses potential-temperature gradient with denominator `z2 - z1`, not `log(z2 - z1)`.
- Latent MO uses specific-humidity gradient from `hum_moisture_gradient()`.
- Both use friction velocity, Monin length, Richardson number and Businger-type stability functions.

Formula changed: yes. `sensible_monin()` denominator was corrected from `log(z2 - z1)` to `z2 - z1` after source/documentation validation.

Guards:

- invalid heights (`z1 <= 0`, `z2 <= 0`, `z2 <= z1`) return `NA` with warning.
- invalid or low wind returns `NA` with warning.
- invalid numerical profile states return `NA` with warning.
- zero temperature gradient returns zero sensible flux.
- zero humidity gradient returns zero latent flux.
- vector-local invalid handling is tested.

Closure behavior:

- diagnostic only; not normalized to `Rn - G`.

Tests present:

- diagnostic-only status, finite normal cases, invalid height/wind guards, zero gradients, vector-local invalid handling and Richardson/stability classifications in `test-monin-obukhov.R`.
- equation contract for `sensible_monin()` denominator and zero-gradient behavior in `test-equation-contracts.R`.

Known limitations/open items:

- Broader MOST/profile source validation remains open for constants, stability functions and physical magnitude.
- The method should not be converted into an energy-balance closure path without a separate design decision.

### Penman-type latent heat

Implemented functions:

- `latent_penman()` in `R/latent.R`.
- `latent_penman.weather_station()` with surface alias mapping and humidity routing.

Input requirements:

- direct method: `datetime`, `v`, `temp`, `rh`, `z`, `rad_bal`, `elev`, `lat`, `lon`, `soil_flux`, `obs_height`, `surface_type`.
- weather-station method: `datetime`, `v1`, `temp`, `z1`, `rad_bal`, `elev`, `lat`, `lon`, `soil_flux`, `obs_height`, `surface_type`, plus either `hum1` or `rh`.

Implemented logic:

```text
es_hPa = pres_sat_vapor_p(temp)
ea_hPa = pres_vapor_p(temp, rh)
es_kPa = es_hPa / 10
ea_kPa = ea_hPa / 10
vpd_kPa = es_kPa - ea_kPa
delta = 4098 * es_kPa / (temp + 237.3)^2
gamma = 0.665e-3 * pres_p(elev, temp)
LE = (delta * (Rn - G) + gamma * (cp * rho / ra) * vpd_kPa) /
     (delta + gamma * (1 + rs / ra))
```

The implementation returns W m-2 LE only. The intermediate divide/multiply by latent heat cancels out.

Formula changed: yes. Vapour pressure deficit was corrected from hPa scale to kPa scale. The gamma placement and simplified Penman-Monteith-type source form remain open/source-form validation items.

Guards:

- invalid aerodynamic log arguments or invalid wind produce elementwise `NA` with warning.
- surface aliases map `field` and `lawn` to `Temperate grassland`, etc.
- weather-station method prefers `hum1` over `rh` and interprets either as relative humidity percent.
- `turb_flux_calc()` catches Penman errors and returns an `NA` vector with warning rather than aborting the whole workflow.

Closure behavior:

- LE-only; no paired H; not forced to close `Rn - G`.

Tests present:

- VPD kPa scale regression, available-energy sign, vector length, invalid aerodynamic vector-local behavior, field surface mapping and non-fatal `turb_flux_calc()` fallback in `test-penman.R` and `test-penman-source.R`.
- equation-contract test for documented Penman formula in `test-equation-contracts.R`.

Known limitations/open items:

- Wrapper humidity routing (`hum1` preferred over `rh`) is documented/tested but remains a scientific/API design question.
- Surface resistance and aerodynamic resistance assumptions are package parameters/mappings; not fully source-table validated.
- Penman source-form and final physical magnitude validation remain open.

## 4. Other functional areas

### Radiation balance

Exists:

- `rad_sw_in()`, `rad_sw_out()`, `rad_diffuse_in()`, `rad_diffuse_out()`, `rad_sw_bal()`, `rad_lw_in()`, `rad_lw_out()`, `rad_lw_bal()`, `rad_bal()`, `rad_sw_toa()`, `rad_emissivity_air()`.

Implemented convention:

```text
K* = K_down - K_up, with direct and diffuse shortwave terms in rad_sw_bal()
L* = L_down - L_up
Rn = K* + L*
```

Fixed/tested:

- radiation balance equations are contract-tested.
- modeled incoming shortwave is controlled at night.
- valid albedo surfaces are bounded for current table values.
- modeled-vs-measured radiation equivalence is not assumed.

Open:

- unknown `surface_type` behavior still returns zero-length style results in some lookup paths; tests mark policy open.
- radiation and transmittance constants are cited but not fully source-validated.
- replacing measured radiation with modeled radiation is high risk and handled only through explicit convenience-layer `*_filled` fields.

### Solar geometry

Exists:

- Julian day, day angle, eccentricity, solar elevation, declination, ecliptic longitude, medium anomaly, hour angle, medium sun time, solar time formula and azimuth helpers.

Fixed/tested:

- POSIXct and POSIXlt handling was corrected/locked for key paths.
- solar wrappers and vector day/night behavior are tested.

Open:

- source-level timebase semantics remain open. `sol_hour_angle()` uses local POSIXlt clock fields plus the solar time formula, while `sol_medium_suntime()` explicitly converts to UTC.
- polar/near-zenith and invalid-domain edge cases remain a source/domain validation area.

### Atmospheric transmittance

Exists:

- `trans_air_mass_rel()`, `trans_air_mass_abs()`, `trans_gas()`, `trans_ozone()`, `trans_rayleigh()`, `trans_vapor()`, `trans_aerosol()`.

Fixed/tested:

- `trans_air_mass_rel()` returns `NA` with warning for non-positive or invalid solar elevation instead of leaking uncontrolled `NaN`.
- near-horizon and vector-local invalid cases are tested.
- POSIXct path through `trans_vapor()` and `hum_precipitable_water()` is tested.

Open:

- Bendix/Iqbal-style constants and aerosol/visibility parameterizations remain source-validation items.

### Soil thermal functions

Exists:

- `soil_heat_flux()`, `soil_thermal_cond()`, `soil_heat_cap()`, `soil_attenuation()`.

Implemented logic:

```text
G = -lambda * (T1 - T2) / (z1 - z2)
```

`soil_attenuation()` uses `C_v * 10^6` to convert MJ m-3 K-1 to J m-3 K-1.

Fixed/tested:

- invalid soil depth pairs return elementwise `NA` with warning.
- `soil_attenuation()` argument order to `soil_thermal_cond(texture, moisture)` was corrected.
- sign convention, vector behavior, valid/invalid texture behavior and moisture-domain behavior are tested.

Open:

- sand/clay/peat thermal conductivity and heat-capacity table values are not fully independently source-table validated.
- high-moisture heat-capacity clamp and conductivity out-of-domain behavior are documented/tested as implementation behavior, not source validated.

### Humidity helpers

Exists:

- `hum_absolute()`, `hum_specific()`, `hum_evap_heat()`, `hum_moisture_gradient()`, `hum_precipitable_water()`.

Fixed/tested:

- POSIXct support for `hum_precipitable_water()` was added for the `rad_sw_in()` -> `trans_vapor()` path.
- helper equation-contract tests cover absolute humidity, specific humidity, latent heat of vaporization and moisture gradient.
- POSIXct/POSIXlt equivalence and vector length are tested for precipitable water.

Open:

- precipitable-water seasonal reference table values are structurally tested but not fully source-table validated.

### Pressure helpers

Exists:

- `pres_sat_vapor_p()`, `pres_vapor_p()`, `pres_p()`, `pres_air_density()`.

Fixed/tested:

- documented equations are covered by helper equation-contract tests.
- vector and RH edge cases are covered.
- `temp_pot_temp()` audit clarified that its second argument is elevation in m, internally converted to pressure by `pres_p()`.

Open:

- standard-atmosphere pressure estimates are modeled values, not measured pressure. The convenience layer records this distinction for `pressure_filled`.

### Temperature helpers

Exists:

- `c2k()`, `k2c()`, `temp_pot_temp()`.

Fixed/tested:

- `temp_pot_temp(25, 270)` expected value was corrected to `26.520455365680` after audit.
- helper equation-contract tests cover conversion and potential-temperature equations.

Open:

- none currently identified beyond standard pressure-estimation assumptions inherited through `pres_p()`.

### Boundary-layer helpers

Exists:

- mechanical and thermal boundary-layer helpers in `R/boundary_layers.R`.
- turbulence roughness, displacement and friction velocity helpers in `R/turbulence.R`.

Fixed/tested:

- documented helper equations are contract-tested where explicit.
- roughness/displacement/ustar branches and wrapper behavior are covered.

Open:

- roughness/displacement surface-class lookup values are package parameters with method-background citations; full source-table validation is open.

### weather_station object and wrappers

Exists:

- `build_weather_station()`, `as.data.frame.weather_station()`, `plot_weather_station()`, `check_availability()`.
- S3 weather-station methods for many helpers and flux functions.
- strict missing-input convenience layer: `inspect_weather_station_inputs()` and `complete_weather_station()` in `R/convenience_missing_inputs.R`.

Fixed/tested:

- `build_weather_station()` is a plain container and does not validate physics.
- `as.data.frame.weather_station()` handles flat and legacy `$measurements` objects.
- `check_availability()` singular/plural error messages are tested.
- API parity tests compare direct and weather-station methods where implemented.
- convenience layer default is inspection-only. Implemented explicit actions are:
  - `rad_bal_filled` from measured radiation components under `derive_from_measured`;
  - `soil_flux_filled` from measured gradient plus explicit `thermal_cond` under `derive_from_measured`;
  - `pressure_filled` from `pres_p(elev, temp)` under `allow_modeled`;
  - modeled radiation `*_filled` fields under `allow_modeled`, high-risk provenance.
- row-local `*_filled` behavior is now tested for all modeled radiation outputs.

Open:

- no user-default filling is implemented.
- no automatic routing from `*_filled` fields into heat-flux workflows is implemented.
- modeled radiation remains high risk and not equivalent to measurement.

## 5. Major implemented fixes

| Area | File(s) | Change | Formula changed? | Test coverage | Remaining open issue |
|---|---|---|---|---|---|
| Penman VPD units | `R/latent.R` | Convert `pres_sat_vapor_p()`/`pres_vapor_p()` hPa outputs to kPa before VPD and delta term. | yes | `test-penman.R`, `test-penman-source.R`, `test-equation-contracts.R` | source form, resistance assumptions, final magnitude validation |
| Monin denominator | `R/sensible.R` | `sensible_monin()` uses `z2 - z1` for potential-temperature gradient, not `log(z2 - z1)`. | yes | `test-monin-obukhov.R`, `test-equation-contracts.R` | broader MOST constants/source validation |
| Bulk-Residual workflow | `R/bulk.R`, `R/turbulent_flux.R` | Added `sensible_bulk()`, `latent_bulk_residual()`, `turb_flux_bulk_residual()` and full-workflow outputs. | new method | `test-bulk.R`, `test-equation-contracts.R`, workflow/API tests | physical adequacy of simple neutral bulk estimate |
| Bulk Richardson guard | `R/bulk.R` | Optional `stability_method = "ri_guard"`, attributes `bulk_Ri_g`/`bulk_stability`, guard invalid/very stable cases. | new optional guard | `test-bulk-stability.R`, API parity | guard only; not a stability correction |
| Bowen guards | `R/sensible.R`, `R/latent.R` | Shared denominator handling, invalid beta/denominator `NA`, optional cap for near-zero denominator. | guard change, formula unchanged | `test-bowen-source.R`, `test-physics-contract.R` | `gamma_code` source-form equivalence open |
| Soil heat flux depth guard | `R/soil.R` | Invalid/non-finite/negative/equal depth pairs return elementwise `NA` with warning. | guard change | `test-soil-contract.R` | table source validation open |
| Soil attenuation argument order | `R/soil.R` | Corrected `soil_attenuation()` conductivity call to documented `soil_thermal_cond(texture, moisture)` order. | implementation fix | `test-consolidation.R`, `test-soil-contract.R` | table values open |
| Solar POSIX handling | `R/solar.R` | POSIXct/POSIXlt consistency for hour angle/azimuth paths. | no physics formula change | `test-solar-contract.R`, radiation/solar coverage tests | astronomical timebase semantics open |
| Humidity POSIXct handling | `R/humidity.R` | `hum_precipitable_water()` handles POSIXct by converting internally before month extraction. | no | `test-humidity-datetime.r`, helper tests | seasonal table source validation open |
| Air mass guard | `R/transmittance.R` | `trans_air_mass_rel()` returns `NA`/warning for non-positive or invalid solar elevation. | guard change | `test-transmittance-contract.R`, coverage tests | transmittance constants open |
| `turb_flux_calc()` PT-only | `R/turbulent_flux.R` | `pt_only = TRUE` computes only PT fields and avoids optional method requirements. | workflow behavior | `test-physics-contract.R`, `test-priestley-taylor-contract.R`, workflow tests | none beyond PT inputs |
| `turb_flux_calc()` Bulk outputs | `R/turbulent_flux.R` | Full workflow adds Bulk-Residual fields. | workflow behavior | workflow/API tests | full workflow still requires non-Penman optional fields |
| Penman fallback | `R/turbulent_flux.R` | Penman failure inside full workflow returns `NA` vector with warning. | workflow guard | `test-penman.R`, API/workflow tests | only Penman is non-fatal this way |
| `as.data.frame.weather_station()` fallback | `R/weather_station.R` | Handles flat objects and missing/legacy `$measurements`. | no formula | object/coverage tests | none identified |
| R CMD check globals | `R/globals.R` | Added global variables for station field names. | no | check hygiene | none identified |
| Convenience layer | `R/convenience_missing_inputs.R` | Added read-only inspection and explicit limited completion actions with provenance/logging. | new layer, no physics formula change | convenience tests, row-local modeled-radiation tests | no user-defaults; modeled replacements high risk |

## 6. Test architecture

The test suite is intentionally mixed. It includes:

- smoke/availability tests inherited from older package behavior;
- wrapper/API parity tests comparing direct and `weather_station` method calls;
- guard and edge-case tests for invalid inputs, vector-local behavior and warning policy;
- closure tests for PT, Bulk-Residual and finite uncapped Bowen cases;
- equation-contract tests reconstructing documented equations independently;
- helper equation-contract tests for documented humidity, pressure, temperature, boundary-layer and turbulent helper equations;
- source-form/regression tests for Penman VPD units, Bowen implemented beta behavior and PT `sc()`/`gam()` Foken table values;
- convenience-layer tests for no mutation, explicit strategy behavior, row-local filling, provenance and logs;
- R CMD check note cleanup support through `R/globals.R` and documentation fixes.

Important boundary: tests verify implementation contracts, documented equations, wrapper behavior, unit fixes and edge-case policy. They do not constitute full empirical physical validation against independent Eddy Covariance, sonic-anemometer, lysimeter or field-intercomparison data.

The test-audit reports under `dev/test-audit/` classify individual test blocks by strength and circularity. API parity tests are acceptable but not independent physics validation. Closure tests are useful but can be medium-circularity unless the partition formula is independently reconstructed. Coverage tests with `expect_no_error()` are support tests, not scientific proof.

Latest observed local run after the convenience row-local tests: `devtools::test()` passed with 1061 pass, 0 fail, 0 warnings, 4 intentional skips. `NEWS.md` still reports an older count of 688 passed; that count is stale and should not be used as current test status.

## 7. Documentation and vignette state

Current source vignettes:

- `vignettes/fieldclim_method_background.Rmd`: current scientific/method-family background. It documents weather-station scope, EC boundary, method families, closure behavior and evidence context.
- `vignettes/fieldclim_convenience_layer.Rmd`: current strict convenience-layer vignette source added during this consolidation. It documents inspection-only default, explicit strategies, row-local `*_filled` behavior, provenance/logging and high-risk modeled radiation.
- `vignettes/fieldclim_workflow_steps.Rmd`: core workflow vignette, marked in `_pkgdown.yml` under German workflows.
- `vignettes/fieldclim_additional_workflow_steps.Rmd`: additional workflow vignette, also under German workflows.
- `vignettes/fieldclim_update2024.Rmd` and `vignettes/fieldclim_check_rad_soil.Rmd`: listed as Deprecated in `_pkgdown.yml`. Treat as historical/archive context unless explicitly refreshed.
- `vignettes/fieldClim.R`: generated vignette support file, not primary source documentation.

Pkgdown structure in `_pkgdown.yml` currently lists:

- Theory: `fieldclim_method_background`.
- Workflows (German only): `fieldclim_workflow_steps`, `fieldclim_additional_workflow_steps`.
- Deprecated: `fieldclim_update2024`, `fieldclim_check_rad_soil`.

Potential drift/staleness:

- Rendered `docs/`/pkgdown HTML may be stale and should not be used as source of truth.
- `_pkgdown.yml` did not yet list `fieldclim_convenience_layer` at the time inspected, while generated docs contained an older article. This is inconsistent and needs a packaging/documentation decision if pkgdown articles are regenerated.
- `NEWS.md` test count is stale relative to the latest observed test run.

## 8. NEWS and README state

README state:

- Accurately states package scope as weather-station based microclimate/micrometeorology.
- Correctly states this is an active private migration/consolidation repository.
- Correctly separates energy-closing methods from diagnostic/profile and Penman LE-only methods.
- Correctly warns that tests are internal consistency tests, not empirical validation.
- Does not yet describe the final modeled-radiation convenience-layer phase in detail.

NEWS state:

- Captures the major 1.2.0 consolidation changes: Bulk-Residual, Penman VPD fix, Bowen guards, Monin denominator fix, PT documentation, solar/transmittance/humidity guards, weather_station workflow updates and documentation/test expansion.
- Contains stale validation counts (`688 passed`) relative to latest observed `1061 passed`.
- Mentions convenience layer through Phase 3c pressure, but not necessarily the final modeled-radiation phase and row-local tests. Treat as partly stale.

Remaining wording risks:

- README/NEWS should not imply empirical validation.
- NEWS count should be refreshed only in a scoped documentation update.
- Convenience-layer docs should clearly state modeled radiation is high risk and not measured radiation.

## 9. Open scientific/source-validation items

### Bowen `gamma_code` source form and literature equivalence

Implemented:

- `beta = gamma_code * dpot / dah`, with `gamma_code = 0.00066 * (1 + 0.000946 * t1)`.
- shared sensible/latent partition and cap/invalid guards.

Tested:

- implemented beta behavior, non-singular closure, cap behavior, invalid cases and sign behavior.

Unvalidated:

- whether `gamma_code` is a proven one-to-one equivalent to a literature `C_a / L_v` or psychrometric Bowen formulation.

Classification:

- source-form-open, not currently classified as a code bug.

### Penman simplified resistance assumptions

Implemented:

- simplified Penman-Monteith-type LE-only equation with kPa VPD fix, aerodynamic resistance guard and surface resistance lookup/mapping.

Tested:

- VPD kPa scale, available-energy sign, wind/RH response, vector-local aerodynamic guards, field mapping and workflow fallback.

Unvalidated:

- full Penman/Penman-Monteith source-form equivalence, resistance assumptions, physical magnitude across datasets.

Classification:

- fixed for VPD unit mismatch; remaining source-form-open/magnitude-open.

### Monin-Obukhov/Profile stability functions and constants

Implemented:

- profile-gradient diagnostic formulas with Richardson/stability helpers and Businger-type constants.
- sensible denominator correction to `z2 - z1`.

Tested:

- diagnostic-only behavior, invalid profile guards, zero gradients, vector-local invalid rows, classification behavior.

Unvalidated:

- complete MOST source-form validation of all constants and branch logic.

Classification:

- diagnostic-only with source-form-open items; denominator bug fixed.

### Priestley-Taylor `sc()`/`gam()` coefficient scale

Implemented:

- polynomial fits on Foken/Stull specific-humidity table scale.

Tested:

- Foken Table 6 values for `sc()` and `gam()` are source-table tested.

Unvalidated:

- alpha table values and all PT empirical parameter choices.

Classification:

- `sc()`/`gam()` source-table tested; alpha table source values not revalidated.

### Radiation/transmittance references

Implemented:

- Bendix/Iqbal-style radiation and transmittance equations with guards for night/non-positive solar elevation.

Tested:

- balance equations, day/night behavior, POSIX handling, vector wrappers, bounded albedo for valid surfaces.

Unvalidated:

- all constants/exponents and modeled-vs-measured equivalence.
- unknown surface_type policy remains open.

Classification:

- implementation behavior tested; source values not fully revalidated.

### Soil table values

Implemented:

- sand/clay/peat conductivity and heat-capacity lookup/interpolation tables.
- attenuation equation with explicit MJ-to-J conversion.

Tested:

- valid/invalid texture behavior, moisture-domain behavior, attenuation unit conversion, soil heat flux sign/guards.

Unvalidated:

- exact table values against source pages and clamp/interpolation policy.

Classification:

- behavior tested; source-table validation open.

### Precipitable-water seasonal reference table

Implemented:

- seasonal reference table/path in `hum_precipitable_water()`.

Tested:

- POSIXct/POSIXlt behavior, vector length, northern/southern hemisphere behavior.

Unvalidated:

- exact seasonal table values against source table.

Classification:

- structural/input tested; source-table validation open.

## 10. Deprecated assumptions / decisions already made

Do not reopen these accidentally without new evidence:

- The package does not implement full Eddy Covariance processing.
- `EC` in Caldern metadata means electric conductivity, not Eddy Covariance.
- Priestley-Taylor is a stable entry workflow, not the only workflow.
- Bulk-Residual is now an implemented package workflow, not just a manual reference workflow.
- `ri_guard` is optional and not default.
- Monin-Obukhov/Profile is profile-based and not balance-normalized.
- Bowen capped cases are not exact closure cases.
- Penman is latent-heat-only in the package workflow.
- Measured radiation and modeled radiation are not interchangeable.
- The convenience layer must not silently fill, model, overwrite, route or mutate by default.
- Empirical tables are not yet fully source-validated unless a specific test/report says otherwise.

## 11. Recommended next actions

### Must not redo

These are already audited/fixed/tested and should not be restarted from scratch:

- Potential temperature test expectation for `temp_pot_temp(25, 270)`.
- Penman hPa-to-kPa VPD correction.
- Monin sensible denominator correction to `z2 - z1`.
- Bulk-Residual workflow and optional Richardson guard.
- PT closure and `pt_only` isolation.
- Bowen finite uncapped closure and capped-case non-closure policy.
- Available-energy convention `Rn - G` with `G > 0` into soil.
- Soil heat flux sign and invalid-depth guard.
- POSIXct/POSIXlt fixes for solar/humidity/transmittance paths.
- Penman non-fatal fallback in `turb_flux_calc()`.
- strict convenience-layer no-mutation default, explicit filling strategies and row-local `*_filled` behavior.

### Safe next technical steps

- Refresh README/NEWS counts and convenience-layer wording in a documentation-only pass.
- Decide whether `_pkgdown.yml` should include `fieldclim_convenience_layer` as a current article.
- Review deprecated vignettes and decide whether to archive, remove from pkgdown, or update their warnings.
- Continue adding equation-contract tests only where documented equations are explicit and expected values can be independently reconstructed.
- Keep source-code changes scoped to clearly audited bugs or guard policies.

### Scientific validation backlog

- Bowen `gamma_code` literature/source-form validation.
- Penman/Penman-Monteith source-form and resistance parameter validation.
- Monin-Obukhov/Profile constants and stability-function validation.
- Radiation/transmittance constants and solar timebase validation.
- Soil thermal and precipitable-water source-table validation.
- Empirical comparison against independent flux observations, if suitable datasets and validation targets are defined.

Do not normalize all methods to one result. Do not add broad refactors as a substitute for source validation.

## 12. File inventory

A companion inventory was created at:

```text
dev/repo-knowledge-state-files.txt
```

It lists R source files, test files, dev reports, vignettes and root metadata considered for this repository knowledge state. Obvious stale/deprecated materials detected during this pass:

- `docs/` rendered pkgdown output: generated, possibly stale, not source of truth.
- `vignettes/fieldclim_update2024.Rmd` and `vignettes/fieldclim_check_rad_soil.Rmd`: listed as Deprecated in `_pkgdown.yml`.
- `dev/physics-formula-audit.md`: appears to be an older root-level audit path alongside the current `dev/physics-audit/physics-formula-audit.md`; use the latter for current physics audit history.
- `NEWS.md`: current conceptually, but test counts are stale relative to the latest observed local test run.
