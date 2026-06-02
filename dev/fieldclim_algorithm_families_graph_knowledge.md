# fieldClim algorithm families - implemented graph knowledge

This document is an implementation-based knowledge base for a new corrected
draw.io graphic. Existing graphics in the repository are not used as evidence.
They are treated only as stale artifacts if they appear in the file inventory.

## 1. Evidence basis

### Sources inspected

Primary implementation evidence:

- `R/weather_station.R`
- `R/radiation.R`
- `R/soil.R`
- `R/sensible.R`
- `R/latent.R`
- `R/bulk.R`
- `R/turbulent_flux.R`
- `R/turbulence.R`
- `R/energy_balance_closure.R`
- `R/missing_inputs.r`
- `R/humidity.R`
- `R/pressure.R`
- `R/transmittance.R`
- `R/solar.R`
- `R/terrain.R`
- `R/boundary_layers.R`
- `R/position.R`
- `R/temperature.R`
- `R/fieldclim_params.R`
- `R/utility.R`
- `R/utility_turbulent_flux.R`
- `R/globals.R`

Contract and regression evidence:

- `tests/testthat/test-energy-balance-closure.R`
- `tests/testthat/test-equation-contracts.R`
- `tests/testthat/test-helper-equation-contracts.R`
- `tests/testthat/test-physics-contract.R`
- `tests/testthat/test-priestley-taylor-contract.R`
- `tests/testthat/test-bulk.R`
- `tests/testthat/test-bulk-exchange-velocity.R`
- `tests/testthat/test-bulk-stability.R`
- `tests/testthat/test-bowen-source.R`
- `tests/testthat/test-monin-obukhov.R`
- `tests/testthat/test-penman.R`
- `tests/testthat/test-penman-source.R`
- `tests/testthat/test-penman-unit-validation.R`
- `tests/testthat/test-radiation-contract.R`
- `tests/testthat/test-soil-contract.R`
- `tests/testthat/test-turbulence.R`
- `tests/testthat/test-turbulent-flux-remaining-coverage.R`
- `tests/testthat/test-weather-station-object-contract.R`
- `tests/testthat/test-weather-station-api-parity.R`

Documentation and context evidence:

- `man/*.Rd`
- `docs/reference/*.md` and rendered reference pages where present
- `README.md`
- `NEWS.md`
- selected vignettes as workflow/context only
- `dev/physics-audit/*.md`
- `dev/physics-formula-audit.md`
- `dev/package-audit/*.md`
- `dev/source-table-audit/*.md`
- `dev/test-audit/*.md`
- `dev/repo-knowledge-state.md`
- `dev/repo-knowledge-state-files.txt`
- `dev/R_CHANGELOG_FUNCTIONAL.md`
- `dev/no-gap-filling-removal-report.md`

Priority rule used here:

1. Tests.
2. Current R implementation.
3. `man/*.Rd` / roxygen-generated reference.
4. Vignettes and README/NEWS.
5. Audit notes and historical dev reports.
6. Existing graphics: no evidentiary value.

### Sources explicitly not used as evidence

The following were not used to derive formulas, method types, stations inputs,
sensor logic, or closure semantics:

- `vignettes/figures/*.png`
- `vignettes/figures/*.svg`
- `vignettes/figures/*.drawio`
- `docs/articles/**/figure-html/*.png`
- `docs/articles/figures/*.png`
- `docs/articles/figures/*.svg`
- `docs/articles/figures/*.drawio`

These old graphics may remain in the repository, but they are not authoritative
for a new draw.io figure.

### Contradictions or stale materials

| Item | Conflict | Current resolution for graphic |
|---|---|---|
| Missing-data completion layer | Historical `dev/repo-knowledge-state.md` and package-audit files describe a strict completion/convenience layer with `*_filled` outputs. Current `R/missing_inputs.r`, README and `dev/no-gap-filling-removal-report.md` state inspection only and no completion. | Treat completion/filling as removed. Do not draw completion, imputation, modeled replacement fields or `*_filled` variables. |
| `complete_weather_station()` | Historical reports mention it. Current live R source no longer exports or implements it. | Do not include in graphic. |
| `rad_net` alias | `inspect_weather_station_inputs()` reports `rad_net` as a radiation field, but no source logic silently maps it to `rad_bal`. | Draw `rad_bal` / `R_n` as the implemented net-radiation field; mention `rad_net` only as an inspected alias, not as an automatic substitute. |
| `sw_in`, `lw_out` legacy names | `as.data.frame.weather_station()` reduced list contains legacy names such as `sw_in`, `lw_out`, while current radiation functions use `rad_sw_in`, `rad_lw_out`, etc. | Use current function/field names in the graphic. Mark legacy names as output/data-frame context only. |
| Surface temperature | `surface_temp` is documented as a common weather-station field and used by `rad_lw_out()`, but no inspected R function calculates it automatically. | Do not draw `surface_temp` / `Ts` as a standard station sensor. Draw it only as a provided/model-assumption input for outgoing longwave radiation. |
| Old diagrams | Several old PNG/SVG/drawio files exist under `vignettes/figures/`. | Ignore for scientific structure. |

## 2. Core object and input ontology

`build_weather_station()` creates a list of class `weather_station`. It stores
named arguments exactly as provided. It does not calculate physical quantities,
does not validate physical consistency, and does not fill missing data. Downstream
methods check availability of the fields they require.

| Field | Role | Measurement status | Used by | Required/optional | Notes |
|---|---|---|---|---|---|
| `datetime` | Time axis | measured station input / metadata | solar, transmittance, radiation, Penman, missing-data inspection | Required by solar/radiation/Penman; optional for some flux methods | POSIXct and POSIXlt are supported in tested solar/transmittance paths. |
| `lon` | Site coordinate | site metadata | solar geometry, radiation, Penman | Required for modeled radiation and Penman | Longitude in degrees. |
| `lat` | Site coordinate | site metadata | solar geometry, radiation, Penman | Required for modeled radiation and Penman | Latitude in degrees. |
| `elev` | Site elevation | site metadata / pressure helper input | pressure, humidity helpers, Bowen, Monin/Profile, Penman | Required by Bowen, Monin/Profile, Penman; helper-derived pressure | `pres_p()` models pressure from elevation and temperature. |
| `temp` | Standard air temperature | measured station input | Priestley-Taylor, Penman, radiation longwave-in/emissivity, pressure/humidity helpers | Required by PT, Penman and modeled radiation helpers | Air temperature in degrees C. |
| `rh` | Standard relative humidity | measured station input | humidity helpers, Penman fallback, radiation emissivity | Required by radiation longwave-in and Penman when `hum1` missing | Must be 0..100 for QC. |
| `t1` | Lower-profile air temperature | measured station input | Bulk, Bowen, Monin/Profile, Richardson diagnostics | Required by Bulk, Bowen, Monin/Profile | Profile variable; not invented from `temp`. |
| `t2` | Upper-profile air temperature | measured station input | Bulk, Bowen, Monin/Profile, Richardson diagnostics | Required by Bulk, Bowen, Monin/Profile | Profile variable. |
| `hum1` | Lower-profile relative humidity | measured station input | Bowen, Monin/Profile, Penman preferred humidity | Required by Bowen/Monin; alternative to `rh` for Penman | Interpreted as relative humidity percent. |
| `hum2` | Upper-profile relative humidity | measured station input | Bowen, Monin/Profile | Required by Bowen/Monin | Not derived automatically from single-level `rh`. |
| `v1` | Lower wind speed | measured station input | Bulk, Bowen? no, Monin/Profile, Penman, Richardson | Required by Bulk, Monin/Profile, Penman | Negative values flagged by inspection. |
| `v2` | Upper wind speed | measured station input | Bulk mean wind if supplied, Bulk `u_star_profile`, Bulk `ri_guard`, Monin/Profile, turbulence helpers | Optional for default Bulk mean-wind path; required for profile paths and Monin/Profile | Never invented. If `v2 <= v1` in `u_star_profile`, non-positive `u_*` is guarded to `NA`. |
| `z1` | Lower measurement height | site/profile metadata | Bulk, Bowen, Monin/Profile, Penman measurement height, Richardson | Required by profile and aerodynamic methods | Must satisfy method-specific height guards. |
| `z2` | Upper measurement height | site/profile metadata | Bulk, Bowen, Monin/Profile, Richardson | Required by profile methods and Bulk | Bulk requires scalar `0 < z1 < z2`. |
| `rad_bal` | Net radiation `R_n` | measured station input or explicit user-provided modeled value | all energy-balance/turbulent methods, closure diagnostics | Required by PT, Bulk-Residual, Bowen, Penman, closure | Implemented net radiation field. Do not silently substitute modeled radiation. |
| `soil_flux` | Soil heat flux `G` | measured station input or calculated by `soil_heat_flux()` if user calls it | all energy-balance/turbulent methods, closure diagnostics | Required by PT, Bulk-Residual, Bowen, Penman, closure | Sign: `G > 0` into soil. |
| `surface_type` | Surface class | surface/site parameter / model assumption | PT alpha table, radiation albedo/emissivity, roughness, Penman surface resistance alias | Required by PT; required by many modeled/routing paths unless `obs_height` alternative exists | Should not be silently defaulted. |
| `surface_temp` | Surface temperature `Ts` | provided input / assumption; not calculated by package | `rad_lw_out()`, `rad_lw_bal()`, `rad_bal()` modeled radiation chain | Required only when computing outgoing longwave / modeled total radiation | Strict status: not calculated automatically; not proven as a standard weather-station sensor; may be measured externally or assumed by user. Do not draw as a standard station sensor. |
| `moisture` | Soil moisture | measured station input or supplied state | soil thermal conductivity/heat capacity/attenuation; QC | Required by soil helper functions | In m3 m-3; QC flags outside 0..1. |
| `texture` | Soil texture class | site/soil parameter | soil thermal conductivity/heat capacity/attenuation | Required by soil helper functions | Allowed `sand`, `clay`, `peat`; table values require source-validation caution. |
| `soil_temp1` | Soil temperature at first depth | measured station input | `soil_heat_flux()` | Required by soil flux helper | Used with depth pair and thermal conductivity lookup. |
| `soil_temp2` | Soil temperature at second depth | measured station input | `soil_heat_flux()` | Required by soil flux helper | Used with depth pair. |
| `soil_depth1` | First soil depth | site/profile metadata | `soil_heat_flux()` | Required by soil flux helper | Must be finite, non-negative, and not equal to `soil_depth2`. |
| `soil_depth2` | Second soil depth | site/profile metadata | `soil_heat_flux()` | Required by soil flux helper | Same guard as above. |
| `slope` | Terrain slope | site/topographic parameter | terrain angle, sky view, radiation | Required by modeled radiation chain | Not defaulted. |
| `exposition` | Aspect/slope exposition | site/topographic parameter | terrain angle, radiation | Required by shortwave terrain-angle path | Not defaulted. |
| `valley` | Valley flag | site/topographic parameter | sky view, diffuse/longwave radiation | Required by sky-view dependent radiation helpers | Logical. |
| `obs_height` | Obstacle/observation height depending on method | site/surface parameter | roughness length, displacement height, Penman aerodynamic resistance, Monin/Profile alternative | Required by Penman; alternative to `surface_type` for some roughness paths | Ambiguous name by context: obstacle height for roughness/displacement; observation/reference height in Penman docs. |
| `thermal_cond` | Thermal conductivity if present | measured or supplied parameter | missing-data inspection only in current live code | Not consumed by `soil_heat_flux()` current implementation | Current `soil_heat_flux()` derives conductivity from `texture` and `moisture`; `thermal_cond` is not a live source argument. |
| `pressure` | Air pressure | measured input or helper-derived if user calls `pres_p()` | inspection; helpers can use pressure formula indirectly | Not a central weather_station requirement in current workflows | No automatic pressure filling. |
| `rad_sw_in`, `rad_sw_out`, `rad_lw_in`, `rad_lw_out` | Radiation components | measured input if supplied, or modeled helper outputs if user explicitly calls radiation functions | inspection and modeled radiation calculations | Not automatically routed into heat-flux methods | No automatic conversion into `rad_bal`. |
| `albedo` | Surface reflectance | measured/supplied surface parameter | inspection only in current live code | Not consumed by `rad_sw_out()`; code uses `surface_type` table | If used in future graphic, mark as parameter, not live argument to current `rad_sw_out()`. |

### Surface temperature / `Ts` classification

Evidence:

- `build_weather_station()` stores `surface_temp` as a conventional field.
- `plot_weather_station()` labels `surface_temp` if present.
- `rad_lw_out.default(surface_type, surface_temp, ...)` computes
  `LW_out = emissivity(surface_type) * sigma * c2k(surface_temp)^4`.
- `rad_lw_bal()` and `rad_bal()` require `surface_temp` when using the modeled
  longwave/total radiation chain.
- No inspected R function calculates `surface_temp` from air temperature,
  radiation, soil state, or any other station field.

Conclusion for the graphic:

- `surface_temp` / `Ts` is a provided input or model assumption for outgoing
  longwave radiation.
- It may be a measured external value if the user supplies it, but the package
  does not establish it as a standard station sensor.
- It must not be drawn as a default climate-balance-station measurement.
- It belongs in "model assumptions and non-measured/provided quantities" unless
  a specific measured `Ts` input is explicitly shown.

## 3. Core energy-balance and sign convention

Package sign convention:

- `R_n > 0`: net radiative input at the surface.
- `G > 0`: soil heat flux into the soil.
- `H > 0`: sensible heat flux away from the surface.
- `LE > 0`: latent heat flux away from the surface.
- Available turbulent energy is `A = R_n - G`.

| Variable | Formula | Source function/test | Interpretation | Graphic label |
|---|---|---|---|---|
| `rad_bal` / `R_n` | `R_n = R_sw + R_lw` | `rad_bal.default()`; radiation tests | Net radiation / radiation balance. Positive is radiative input at surface. | `R_n = R_sw + R_lw` |
| `rad_sw_bal` / `R_sw` | `R_sw = SW_in - SW_out + D_in - D_out` | `rad_sw_bal.default()` | Shortwave balance including direct and diffuse terms. | `R_sw = SW_in - SW_out + D_in - D_out` |
| `rad_lw_bal` / `R_lw` | `R_lw = LW_in - LW_out` | `rad_lw_bal.default()` | Longwave balance. | `R_lw = LW_in - LW_out` |
| `soil_flux` / `G` | Direct input or `G = -lambda * (T1 - T2)/(z1 - z2)` when user calls soil helper | `soil_heat_flux.default()`; soil tests | Positive into soil. | `G > 0 into soil` |
| `available_energy` / `A` | `A = rad_bal - soil_flux` | `energy_balance_closure()`; closure tests | Energy available for turbulent fluxes when storage omitted. | `A = R_n - G` |
| `sensible` / `H` | Method-specific field | sensible methods | Sensible heat flux away from surface when positive. | `H > 0 away from surface` |
| `latent` / `LE` | Method-specific field | latent methods | Latent heat flux away from surface when positive. | `LE > 0 away from surface` |
| `turbulent_sum` | `H + LE` | `energy_balance_closure()` | Sum of paired turbulent fluxes where method provides both. | `H + LE` |
| `closure_residual` | `A - H - LE` | `energy_balance_closure()` | Technical balance residual for paired H/LE outputs. | `closure_residual = A - H - LE` |
| `closure_ratio` | `(H + LE) / A` | `energy_balance_closure()` | Formal closure ratio; unstable near small `A`. | `closure_ratio = (H + LE) / A` |
| `unresolved_complement` | `A - latent_penman` | `energy_balance_closure()` | Penman latent-only open complement. Not sensible heat. | `unresolved_complement = A - LE_penman` |

## 4. Radiation family

| Function | Formula | Inputs | Output | Parameter tables | Assumptions | Caveats | Graphic label |
|---|---|---|---|---|---|---|---|
| `rad_bal()` | `R_total = R_sw + R_lw` | `datetime`, `lon`, `lat`, `elev`, `temp`, `rh`, `slope`, `exposition`, `valley`, `surface_type`, `surface_temp` | Total radiation balance | `surface_properties` via child functions | Computes modeled net radiation only when all inputs are supplied. | Do not treat modeled `rad_bal()` as measured `rad_bal` unless explicitly stated. | `R_n = R_sw + R_lw` |
| `rad_sw_bal()` | `SW_in - SW_out + D_in - D_out` | solar/site/topography/temp/surface fields | Shortwave balance | albedo via `surface_properties` | Direct and diffuse modeled components. | Needs solar/transmittance/terrain chain. | `R_sw = SW_in - SW_out + D_in - D_out` |
| `rad_sw_in()` | `SW_toa * 0.9751 * T_total / sin(E) * cos(theta)` | `datetime`, `lon`, `lat`, `elev`, `temp`, `slope`, `exposition` | Direct incoming shortwave | transmittance helpers | `T_total = gas * ozone * rayleigh * vapor * aerosol`; terrain angle applied. | Output set to 0 when computed value < 0 or sun below horizon. Uses modeled atmosphere. | `SW_in` |
| `rad_sw_toa()` | `S * eccentricity * sin(elevation)` | `datetime`, `lon`, `lat`, optional solar constant | Top-of-atmosphere shortwave | solar constant default | Uses solar geometry. | Returns 0 below horizon. | `SW_toa` |
| `rad_sw_out()` | `SW_out = SW_in * albedo(surface_type)` | same as `rad_sw_in` plus `surface_type` | Reflected direct shortwave | `surface_properties$albedo` | Albedo inferred from surface type table. | `albedo` is not an explicit argument in current code. Unknown surface type may yield empty/invalid behavior. | `SW_out = alpha * SW_in` |
| `rad_diffuse_in()` | `0.5 * ((1 - (1 - vapor) - (1 - ozone)) * SW_toa - SW_in) * sky_view * (1 + cos(terrain_angle)^2 * sin(solar_angle)^3)` | `datetime`, `lon`, `lat`, `elev`, `temp`, `slope`, `exposition`, `valley` | Diffuse incoming shortwave | none directly beyond helpers | Uses vapor/ozone transmittance, terrain angle and sky-view factor. | Returns 0 below horizon. | `D_in` |
| `rad_diffuse_out()` | `D_out = D_in * albedo(surface_type)` | diffuse inputs plus `surface_type` | Reflected diffuse shortwave | `surface_properties$albedo` | Surface-type albedo table. | No measured albedo route in current function. | `D_out = alpha * D_in` |
| `rad_lw_bal()` | `LW_in - LW_out` | `temp`, `rh`, `slope`, `valley`, `surface_type`, `surface_temp` | Longwave balance | emissivity via `surface_properties` for `LW_out` | Uses atmospheric emissivity and surface Stefan-Boltzmann emission. | Requires `surface_temp`; package does not calculate it. | `R_lw = LW_in - LW_out` |
| `rad_lw_in()` | `epsilon_air * sigma * T_air^4 * sky_view` | `temp`, `rh`, `slope`, `valley` | Incoming longwave | none directly | Air temperature converted to Kelvin; sky-view modifies incoming longwave. | Modeled atmospheric longwave, not measured. | `LW_in` |
| `rad_emissivity_air()` | `(1.24 * e / T_air)^(1/7)` | `temp`, `rh` | Atmospheric emissivity | vapor pressure helper | Uses `pres_vapor_p()` and Kelvin temperature. | Source-validation of empirical relation remains a radiation audit item. | `epsilon_air` |
| `rad_lw_out()` | `epsilon(surface_type) * sigma * T_surface^4` | `surface_type`, `surface_temp` | Outgoing longwave | `surface_properties$emissivity` | `surface_temp` is supplied/assumed; emissivity is table-derived. | `surface_temp` is not calculated and must not be drawn as a default station sensor. | `LW_out = epsilon sigma T_s^4` |

Supporting radiation/solar/transmittance features:

- Solar geometry: `sol_julian_day()`, `sol_day_angle()`,
  `sol_eccentricity()`, `sol_declination()`, `sol_hour_angle()`,
  `sol_elevation()`, `sol_azimuth()`, `sol_medium_suntime()`,
  `sol_time_formula()`.
- Terrain modifiers: `terr_sky_view()` and `terr_terrain_angle()`.
- Atmospheric transmittance: `trans_gas()`, `trans_ozone()`,
  `trans_rayleigh()`, `trans_vapor()`, `trans_aerosol()`,
  `trans_air_mass_rel()`, `trans_air_mass_abs()`.
- `trans_air_mass_rel()` guards non-positive solar elevation and returns `NA`
  with warning. Radiation shortwave helpers set night/below-horizon outputs to
  zero where implemented.

## 5. Soil heat flux family

| Function | Formula | Inputs | Output | Measurement/derived status | Features | Caveats | Graphic label |
|---|---|---|---|---|---|---|---|
| `soil_heat_flux()` | `G = -lambda * (soil_temp1 - soil_temp2)/(soil_depth1 - soil_depth2)` | `texture`, `moisture`, `soil_temp1`, `soil_temp2`, `soil_depth1`, `soil_depth2` | Soil heat flux `G` in W m-2 | Calculated helper if user calls it | Conductivity is obtained from `soil_thermal_cond(texture, moisture)`; elementwise invalid-depth guard. | Current function does not accept measured `thermal_cond`; table values remain source-validation items. | `G = -lambda dT/dz` |
| `soil_thermal_cond()` | Linear interpolation in texture/moisture table | `texture`, `moisture` | Thermal conductivity `lambda` | table-derived parameter | Supports `sand`, `clay`, `peat`; moisture converted from m3 m-3 to volume percent. | Outside table domain returns `NA`; empirical table validation open. | `lambda(texture, moisture)` |
| `soil_heat_cap()` | Linear interpolation in texture/moisture table | `texture`, `moisture` | Volumetric heat capacity `C_v` | table-derived parameter | Supports same textures. | Values below domain return `NA`; above domain uses highest tabulated heat capacity. | `C_v(texture, moisture)` |
| `soil_attenuation()` | `L = sqrt(lambda / (C_v * 10^6 * pi) * 86400)` | `texture`, `moisture` | Soil attenuation length | derived helper | Uses conductivity and heat-capacity lookups. | Depends on table values; no heat-flux closure role directly. | `L_soil` |

Graphic rule:

- Draw `G / soil_flux` as a measured/provided station input if supplied.
- Draw `soil_heat_flux()` as an optional calculated helper from soil
  temperature gradients and soil thermal properties.
- Draw `texture` as parameter/assumption; `moisture` as measured/supplied soil
  state; not a universal substitute for measured `G`.

## 6. Sensible heat families

| Family | Functions | Formula | Required inputs | Output field | Closure behaviour | Features | Pros | Cons | Extension points | Graphic box text |
|---|---|---|---|---|---|---|---|---|---|---|
| Priestley-Taylor partition | `sensible_priestley_taylor()` | `H_PT = (((1 - alpha_PT) * sc + gam)/(sc + gam)) * (R_n - G)` | `temp`, `rad_bal`, `soil_flux`, `surface_type` | `sensible_priestley_taylor` | Partitions available energy with `latent_priestley_taylor()` when inputs match. | Surface-specific `alpha_PT`; `sc()` and `gam()` on Foken/Stull table scale. | Transparent energy partition; robust entry workflow. | Depends on alpha table and coefficient scale; not profile-based. | Alpha/source validation; surface-class policy. | `H_PT: partition of A = R_n - G` |
| Bulk transfer | `sensible_bulk()` | `H_bulk = rho * cp * (t1 - t2)/r_a` | `t1`, `t2`, `v1`, `z1`, `z2`; optional `v2`, `surface_type`, `obs_height` depending exchange path | `sensible_bulk` | H estimate only; closure occurs later through `latent_bulk_residual()`. | `exchange_velocity = wind_mean`, `u_star_profile`, `u_star_roughness`; optional `ri_guard`. | Transparent neutral approximation; can use profile-derived or roughness-derived velocity scale. | No Monin-Obukhov stability correction; sensitive to wind/height assumptions. | Stability corrections could be external/future, but not implemented here. | `H_bulk: neutral exchange estimate` |
| Bowen ratio | `sensible_bowen()` | `H = A * B/(1 + B)` with `B = gamma_code * (Delta theta / Delta z)/(Delta AH / Delta z)` | `t1`, `t2`, `hum1`, `hum2`, `z1`, `z2`, `elev`, `rad_bal`, `soil_flux` | `sensible_bowen` | Paired partition with `latent_bowen()` for finite uncapped denominator. | Uses potential temperature and absolute humidity gradients. | Uses measured profile gradients and available energy. | Near-zero denominator unstable; capped cases may not close exactly; gamma source form open. | Source-form validation of `gamma_code`. | `H_Bowen = A * beta/(1 + beta)` |
| Monin/Profile diagnostic | `sensible_monin()` | `H = -rho * cp * (k * u_* * z2 / phi_h) * (Delta theta / Delta z)` | `t1`, `t2`, `z1`, `z2`, `v1`, `v2`, `elev`, plus `surface_type` or `obs_height` | `sensible_monin` | Not forced to close `R_n - G`; closure residual is diagnostic. | Uses profile gradients, roughness/friction velocity, Richardson/Monin diagnostics, Businger-type stability terms. | Profile/stability-based diagnostic estimate. | Requires full profile inputs; numerical guards; constants/source-validation open. | Broader MOST validation/constants review. | `H_monin: profile/stability diagnostic` |

Bulk-specific findings:

- Bulk does not use `surface_temp`.
- Default Bulk uses `t1`, `t2`, `v1`, optional `v2`, `z1`, `z2`.
- `u_star_profile` uses `v1`, `v2`, `z1`, `z2`.
- `u_star_roughness` uses a reference wind speed (`v2/z2` if `v2` exists,
  otherwise `v1/z1`) and `z0` from `surface_type` or `obs_height`.
- `ri_guard` screens invalid/very stable Richardson cases but does not correct
  valid neutral fluxes.

## 7. Latent heat families

| Family | Functions | Formula | Required inputs | Output field | Closure behaviour | Features | Pros | Cons | Extension points | Graphic box text |
|---|---|---|---|---|---|---|---|---|---|---|
| Priestley-Taylor partition | `latent_priestley_taylor()` | `LE_PT = alpha_PT * sc/(sc + gam) * (R_n - G)` | `temp`, `rad_bal`, `soil_flux`, `surface_type` | `latent_priestley_taylor` | Paired with `H_PT` to close available energy algebraically. | Surface-specific alpha; package-scale `sc/gam`. | Simple energy partition. | Alpha/source assumptions; not profile-resolved. | Source/parameter validation. | `LE_PT = alpha * sc/(sc + gam) * A` |
| Bulk residual | `latent_bulk_residual()` | `LE_res = rad_bal - soil_flux - sensible` | `rad_bal`, `soil_flux`, `sensible` or weather station fields for `sensible_bulk()` | `latent_bulk_residual` | Residual closure by construction when `sensible_bulk` finite. | Explicit residual term after H estimate. | Makes available-energy closure transparent. | Inherits errors from `R_n`, `G`, and `H_bulk`; formal closure is not validation. | Alternative H exchange scales already implemented; no further completion. | `LE_bulk = A - H_bulk` |
| Bowen ratio | `latent_bowen()` | `LE = A/(1 + B)` | same as Bowen sensible | `latent_bowen` | Paired partition for finite uncapped denominator. | Uses same beta as sensible Bowen. | Energy partition from profile gradients. | Capped/invalid denominator can break exact closure or return `NA`. | Bowen source-form validation. | `LE_Bowen = A/(1 + beta)` |
| Penman latent-only | `latent_penman()` | `LE = [Delta*A + gamma*(cp*rho/ra)*(e_s - e_a)]/[Delta + gamma*(1 + r_s/ra)]` | `datetime`, `v1`, `temp`, `z1`, `rad_bal`, `elev`, `lat`, `lon`, `soil_flux`, `obs_height`, `surface_type`, plus `hum1` or `rh` | `latent_penman` | Open latent-only method; no paired sensible heat output. | Surface resistance table; fieldClim surface aliases; hPa-to-kPa VPD correction. | Combination-equation latent estimate. | Simplified resistance assumptions; does not close energy balance; no fake H. | Penman resistance/source validation. | `LE_penman only; complement = A - LE_penman` |
| Monin/Profile diagnostic | `latent_monin()` | `LE = -rho * L_v * (k * u_*/phi_q) * (Delta q / Delta z)` | `hum1`, `hum2`, `t1`, `t2`, `v1`, `v2`, `z1`, `z2`, `elev`, plus `surface_type` or `obs_height` | `latent_monin` | Not forced to close `R_n - G`; residual diagnostic. | Humidity gradient via specific humidity; stability correction terms. | Profile/stability latent estimate. | Requires complete profiles; numerical guards and constants validation open. | MOST/profile validation. | `LE_monin: profile/stability diagnostic` |

Formal closure summary:

- Priestley-Taylor: partition closure.
- Bulk-Residual: residual closure.
- Bowen: partition closure only for finite uncapped cases.
- Penman: latent-only open complement.
- Monin/Profile: diagnostic profile output, not balance-normalized.

## 8. Turbulence / profile diagnostics

| Function | Role | Inputs | Formula / logic | Outputs | Relevance | Restrictions |
|---|---|---|---|---|---|---|
| `turb_flux_monin()` | Monin-Obukhov length helper | `z1`, `z2`, `v1`, `v2`, `t1`, `t2`, `elev`, plus `surface_type` or `obs_height` | Branches by gradient Richardson number; unstable/neutral/stable formulas use shear, temperature gradient, `u_*`, `z0`. | Monin-Obukhov length | Used by `sensible_monin()`, `latent_monin()`, exchange quotients. | Requires profile inputs; warning on `NA` Monin states; source constants open. |
| `turb_flux_grad_rich_no()` | Stability diagnostic | `t1`, `t2`, `z1`, `z2`, `v1`, `v2`, `elev` | `Ri_g = (g/theta1) * (Delta theta / Delta z)/(Delta u / Delta z)^2` | Gradient Richardson number | Used in Monin/Profile and Bulk `ri_guard`. | Invalid heights/wind/weak shear return `NA`. |
| `turb_flux_stability()` | Stability class | `Ri_g` or weather station | `unstable <= -0.005`, `neutral -0.005..0.005`, `stable >= 0.005` | Stability string | Workflow diagnostic output in `turb_flux_calc()`. | Classification only; not closure. |
| `turb_ustar()` | Friction velocity | `v`, `z`, plus `surface_type` or `obs_height` | `u_* = v * 0.4/log(z/z0)` | Friction velocity | Monin/Profile and roughness-based Bulk path. | Infinite values set to `NA`; requires valid roughness source. |
| `turb_roughness_length()` | Roughness length | `surface_type` or `obs_height` | `z0 = 0.1 * obs_height` or lookup from `surface_properties` | `z0` | Bulk roughness path, Monin/Profile, boundary helpers. | Table parameter; invalid surface type errors. |
| `turb_displacement()` | Displacement height | `obs_height`, `surroundings` | vegetation `2/3 * obs_height`; city `0.8 * obs_height` | displacement height `d` | Penman aerodynamic resistance; boundary layer helpers. | `surroundings` must be `vegetation` or `city`. |
| `turb_flux_ex_quotient_temp()` | Heat exchange quotient | profile inputs plus roughness source | Businger-type branch by `Ri_g`; uses `u_*`, Monin length and air density | heat exchange quotient | Diagnostic/helper for profile flux context. | Requires full profiles and roughness source. |
| `turb_flux_ex_quotient_imp()` | Momentum exchange quotient | profile inputs plus roughness source | Businger-type branch by `Ri_g`; uses `u_*`, Monin length and air density | momentum exchange quotient | Diagnostic/helper. | Requires full profiles and roughness source. |
| `turb_flux_imp_exchange()` | Turbulent impulse exchange | profile inputs plus roughness source | exchange quotient * `(v2 - v1)/(z2 - z1)` | momentum exchange | Profile diagnostic helper. | Not a heat-flux method. |
| `sc()` / `gam()` | PT coefficient helpers | air temperature | polynomial/table-scale helper formulas | coefficients | Priestley-Taylor ratios. | Foken/Stull table scale; not FAO-56 psychrometric constant. |
| `bowen_ratio()` | Internal alternate Bowen helper | `t`, `dpot`, `dah` | `(heat_capacity(t) * dpot)/(hum_evap_heat(t) * dah)` | Bowen ratio | Separate from current exported Bowen implementation. | Do not use as source of exported Bowen formula unless explicitly referenced. |

## 9. Closure implementation

`energy_balance_closure()` inspects existing output fields in a
`weather_station` object. It does not compute new turbulent fluxes. It requires
`rad_bal` and `soil_flux`, then creates a long data frame.

| Method | `closure_type` | Required H field | Required LE field | Available energy equation | Closure equation | Status logic | Interpretation | Caveat |
|---|---|---|---|---|---|---|---|---|
| `priestley_taylor` | `partition_closure` | `sensible_priestley_taylor` | `latent_priestley_taylor` | `A = rad_bal - soil_flux` | `closure_residual = A - H - LE`; `closure_ratio = (H + LE)/A` | Missing fields -> `missing_fields`; low `A` -> `low_available_energy`; large residual -> `large_residual` | Technical closure check for PT partition outputs. | Near-zero residual confirms algebraic partition, not physical validation. |
| `bulk_residual` | `residual_closure` | `sensible_bulk` | `latent_bulk_residual` | same | same | same | Bulk H estimate plus residual LE. | Near-zero closure is by construction and does not validate exchange velocity. |
| `bowen` | `partition_closure` | `sensible_bowen` | `latent_bowen` | same | same | same | Bowen partition outputs. | Capped/invalid denominator cases may not close exactly or may be `NA`. |
| `penman` | `le_only_open` | none | `latent_penman` | same | no paired closure residual; `unresolved_complement = A - latent_penman` | finite values -> `open_complement`; low `A` -> `low_available_energy`; missing/NA -> `missing` | Latent-only method. Open complement remains unresolved. | Complement must not be called sensible heat. Penman excluded from closure check and ratio plots. |
| `monin` | `profile_diagnostic` | `sensible_monin` | `latent_monin` | same | `closure_residual = A - H - LE`; ratio where valid | finite non-low values -> `diagnostic_residual`; missing/low as above | Profile/stability estimate compared with available energy. | Non-zero residual is diagnostic, not automatic error and not force-closed. |

Plot semantics in current `plot_energy_balance_closure()`:

- `type = "open_terms"` (default): plots the explicit open/residualized term:
  `latent_bulk_residual` for Bulk-Residual, `unresolved_complement` for
  Penman, and `closure_residual` for Monin/Profile. PT and Bowen are omitted.
- `type = "closure_check"`: plots `A - H - LE` for paired methods only:
  PT, Bulk-Residual, Bowen and Monin/Profile. Penman is excluded.
- `type = "ratio"`: plots `(H + LE)/A` for paired methods only and excludes
  Penman and `low_available_energy` rows.
- Deprecated `type = "residual"` maps to `closure_check` with warning.

## 10. Pros / Cons / Features matrix for final draw.io

| Family | Core idea | Minimal formula | Required measured inputs | Required model assumptions | Outputs | Strengths | Weaknesses | Best use | Failure mode |
|---|---|---|---|---|---|---|---|---|---|
| Radiation balance | Compute or use net radiation | `R_n = R_sw + R_lw` | If measured: `rad_bal`; if modeled: time/site/temp/RH/topography/surface inputs | Surface albedo/emissivity, atmospheric transmittance, sky view; `surface_temp` for LW_out | `rad_bal`, components | Makes radiative input explicit | Modeled radiation is not measured radiation; many assumptions | Radiation/available-energy context | Missing `surface_temp`, terrain, or surface assumptions; invalid sun geometry |
| Soil heat flux | Provide or compute `G` | `G = -lambda dT/dz` | `soil_flux` if measured; or soil temp/depth/moisture | soil texture table and conductivity lookup | `soil_flux` | Clear sign convention | Table-derived conductivity; empirical validation open | Available energy `A = R_n - G` | Invalid depths, missing soil data |
| Priestley-Taylor partition | Partition available energy by PT alpha and coefficients | `LE = alpha sc/(sc+gam) A`; `H = A - LE` | `temp`, `rad_bal`, `soil_flux` | `surface_type` alpha table; `sc/gam` scale | `sensible_priestley_taylor`, `latent_priestley_taylor` | Robust teaching/entry method | Coefficient/source assumptions | Simple available-energy partition | Invalid/missing surface type or energy inputs |
| Bulk transfer | Estimate `H` from temperature gradient and velocity scale | `H = rho cp (t1 - t2)/r_a` | `t1`, `t2`, `v1`, heights; optional `v2` | neutral aerodynamic resistance; optional roughness assumptions | `sensible_bulk` | Transparent H estimate; exchange-velocity variants | No full stability correction | Sensitivity/testing of H exchange assumptions | Low wind, invalid heights, non-positive `u_*` |
| Bulk residual | Assign latent heat as residual after Bulk H | `LE = A - H_bulk` | `rad_bal`, `soil_flux`, Bulk inputs | Same as Bulk H estimate | `latent_bulk_residual` | Formal balance closure | Residual inherits errors in A and H | Teaching residual closure | Formal closure can be misread as validation |
| Bowen ratio | Partition A using temperature/humidity gradients | `H = A beta/(1+beta)`, `LE = A/(1+beta)` | two-level T/RH profiles, heights, elevation, `R_n`, `G` | `gamma_code` implementation coefficient | `sensible_bowen`, `latent_bowen` | Uses measured gradients | Near-zero denominator instability | Gradient-based partition | Invalid humidity gradient, capped denominator |
| Penman latent-only | Combination equation for LE | `LE = [Delta A + gamma cp rho VPD/ra]/[Delta + gamma(1+rs/ra)]` | time, wind, temp, humidity, site, `R_n`, `G` | aerodynamic and surface resistance assumptions | `latent_penman` | Latent flux estimate without profile humidity gradient | No paired H; resistance assumptions simplified | LE-only comparison/diagnostic | Invalid aerodynamic resistance, missing humidity/site fields |
| Monin/Profile diagnostic | Profile/stability turbulent flux estimates | `H` and `LE` from `u_*`, stability functions and gradients | two-level T/RH/wind, heights, elevation | roughness or obstacle height, Businger/Foken constants | `sensible_monin`, `latent_monin` | Profile/stability logic | Input-heavy, not closed to A | Diagnostic profile comparison | Invalid profiles, weak shear, numerical stability |
| Closure diagnostics | Inspect existing flux outputs vs A | `A - H - LE`; `(H+LE)/A`; `A - LE_penman` | Existing flux outputs plus `rad_bal`, `soil_flux` | None beyond method output semantics | long diagnostic data frame, plots | Separates formal closure, open terms and diagnostics | Not a flux model; does not validate physics | Figure footer/diagnostic layer | Missing output fields, low available energy |

## 11. New draw.io box specification

Recommended layout:

- Left column: measured/provided station inputs.
- Middle top: radiation and available energy.
- Middle bottom: soil and surface/site parameters.
- Right column: algorithm families.
- Bottom: closure diagnostics.
- Separate box: model assumptions and non-measured quantities.

| Box ID | Box title | Lines inside box | Formula lines | Position group | Arrows from | Arrows to | Notes |
|---|---|---|---|---|---|---|---|
| IN_2M | 2 m station profile inputs | `T_air_2m -> t1/temp`; `RH_2m -> hum1/rh`; `u_2m -> v1`; `z1 = 2 m` | none | Left column | station | Bulk, Bowen, Monin, Penman, humidity helpers | Do not imply fixed 2 m if user supplies another `z1`; label as example. |
| IN_10M | Upper profile inputs | `T_air_10m -> t2`; `RH_10m -> hum2`; `u_10m -> v2`; `z2 = 10 m` | none | Left column | station | Bulk `u_star_profile`, Bowen, Monin, Richardson | `v2` optional for default Bulk but required for profile/guard paths. |
| IN_RAD | Measured net radiation | `rad_bal / R_n / Q*` | `R_n measured or explicitly supplied` | Left column | radiometer or data source | Available energy, methods, closure | Do not silently derive from components in graphic. |
| IN_SOIL_G | Soil heat flux | `soil_flux / G` | `G > 0 into soil` | Left column | soil heat flux plate or user-calculated helper | Available energy, methods, closure | May be measured or calculated by soil helper if user did it. |
| IN_SITE | Site metadata | `datetime`; `lon`; `lat`; `elev`; `slope`; `exposition`; `valley` | none | Left column | station metadata | solar/radiation, Penman, pressure, terrain | No defaults shown. |
| IN_SOIL | Soil state/parameters | `soil_temp1/2`; `soil_depth1/2`; `moisture`; `texture` | none | Middle bottom | soil sensors/site parameter | `soil_heat_flux`, soil thermal helpers | `texture` is parameter; `moisture` measured/supplied state. |
| ASSUMP | Model assumptions and non-measured quantities | `surface_type`; `obs_height`; `albedo/emissivity tables`; `surface_temp / Ts if supplied`; `roughness z0`; `surface resistance rs` | `z0 = lookup or 0.1 obs_height` | Separate assumptions box | user/model tables | radiation, Bulk roughness, Monin, Penman, PT | `Ts` only as LW_out input, not standard station sensor. |
| RAD_SOLAR | Solar + transmittance + terrain | `solar geometry`; `air mass`; `T_gas T_ozone T_rayleigh T_vapor T_aerosol`; `terrain angle`; `sky view` | `T_total = product(transmittance)` | Middle top | IN_SITE, temp, assumptions | radiation components | Mark modeled chain. |
| RAD_COMPONENTS | Radiation components | `SW_in`; `SW_out`; `D_in`; `D_out`; `LW_in`; `LW_out` | `SW_out = alpha SW_in`; `LW_out = epsilon sigma T_s^4` | Middle top | RAD_SOLAR, ASSUMP, temp/rh | Net radiation | Components may be measured externally or modeled by helpers; no automatic completion. |
| RAD_NET | Net radiation | `rad_bal / R_n` | `R_n = R_sw + R_lw`; `R_sw = SW_in - SW_out + D_in - D_out`; `R_lw = LW_in - LW_out` | Middle top | IN_RAD or RAD_COMPONENTS | Available energy, algorithms, closure | If measured `rad_bal` exists, show it as primary. |
| SOIL_HELPER | Soil heat flux helper | `soil_heat_flux()`; `soil_thermal_cond()`; `soil_heat_cap()` | `G = -lambda (T1 - T2)/(z1 - z2)` | Middle bottom | IN_SOIL | Available energy | Optional helper, not automatic. |
| A_ENERGY | Available energy | `A`; `available_energy` | `A = R_n - G` | Center | RAD_NET, IN_SOIL_G/SOIL_HELPER | PT, Bulk-Residual, Bowen, Penman, closure | Central energy balance node. |
| PT | Priestley-Taylor partition | `sensible_priestley_taylor`; `latent_priestley_taylor`; `alpha(surface_type)` | `LE_PT = alpha sc/(sc+gam) A`; `H_PT = A - LE_PT` | Right column | A_ENERGY, temp, surface_type | closure diagnostics | Partition closure; not profile method. |
| BULK_H | Bulk sensible heat estimate | `sensible_bulk`; `exchange_velocity: wind_mean / u_star_profile / u_star_roughness`; optional `ri_guard` | `H_bulk = rho cp (t1 - t2)/r_a` | Right column | IN_2M, IN_10M, ASSUMP | Bulk residual LE | No `surface_temp`. Neutral approximation. |
| BULK_LE | Bulk-Residual latent heat | `latent_bulk_residual` | `LE_res = A - H_bulk` | Right column | A_ENERGY, BULK_H | closure diagnostics | Residual closure by construction. |
| BOWEN | Bowen ratio | `sensible_bowen`; `latent_bowen`; `beta` | `beta = gamma_code (Delta theta/Delta z)/(Delta AH/Delta z)`; `H = A beta/(1+beta)`; `LE = A/(1+beta)` | Right column | A_ENERGY, IN_2M, IN_10M, elev | closure diagnostics | Capped/invalid denominator caveat. |
| PENMAN | Penman latent-only | `latent_penman`; `hum1 or rh`; `ra`; `rs` | `LE_penman = combination equation` | Right column | A_ENERGY, IN_2M, IN_SITE, ASSUMP | closure diagnostics open complement | No paired sensible heat. |
| MONIN | Monin/Profile diagnostic | `sensible_monin`; `latent_monin`; `Ri_g`; `u_*`; `L` | `H_monin`, `LE_monin` from profile gradients/stability functions | Right column | IN_2M, IN_10M, ASSUMP, elev | closure diagnostics | Not forced to close. |
| TURB_HELP | Turbulence/profile helpers | `Ri_g`; `stability`; `u_*`; `z0`; `d`; exchange quotients | `Ri_g = (g/theta) dtheta/dz / (du/dz)^2` | Middle/right support | profile inputs, assumptions | Bulk guard, Monin, Penman | Diagnostic/helper functions, not method family by themselves. |
| CLOSURE | Energy-balance closure diagnostics | `energy_balance_closure()`; `plot_energy_balance_closure()` | `closure_check = A - H - LE`; `closure_ratio = (H+LE)/A`; `unresolved_complement = A - LE_penman` | Bottom | all method outputs, A_ENERGY | graph footer/report | Diagnostic only; not a flux model. |
| MISSING | Inspection / QC only | `inspect_weather_station_inputs()`; missing fields; gap runs; QC flags; method readiness | none | Bottom/side utility | weather_station object | user decision | No fill, impute, interpolate, complete, model or `*_filled` outputs. |

Arrow notes for draw.io:

- `IN_RAD -> A_ENERGY` should be visually primary if net radiation is measured.
- `RAD_COMPONENTS -> RAD_NET` should be labeled "modeled or component balance if explicitly calculated".
- `IN_SOIL_G -> A_ENERGY` should be primary if soil heat flux is measured.
- `SOIL_HELPER -> A_ENERGY` should be optional.
- `BULK_H -> BULK_LE` must show the two-level logic: H estimate first, LE residual second.
- `PENMAN -> CLOSURE` arrow should go to "unresolved complement", not closure ratio.
- `MONIN -> CLOSURE` arrow should go to "diagnostic residual", not forced closure.

## 12. Formula labels for graphic

Use short labels, not long derivations:

- `A = R_n - G`
- `R_n = R_sw + R_lw`
- `R_sw = SW_in - SW_out + D_in - D_out`
- `R_lw = LW_in - LW_out`
- `SW_out = alpha SW_in`
- `D_out = alpha D_in`
- `LW_in = epsilon_air sigma T_air^4 sky_view`
- `LW_out = epsilon_surface sigma T_s^4`
- `G = -lambda (T1 - T2)/(z1 - z2)`
- `lambda = table(texture, moisture)`
- `H_PT = (((1 - alpha) sc + gam)/(sc + gam)) A`
- `LE_PT = alpha sc/(sc + gam) A`
- `H_bulk = rho cp (t1 - t2)/r_a`
- `r_a(wind_mean) = log(z2/z1)/(k u_mean)`
- `u_star_profile = k (v2 - v1)/log(z2/z1)`
- `u_star_roughness = k u_ref/log(z_ref/z0)`
- `LE_bulk_residual = A - H_bulk`
- `Bowen beta = gamma_code (Delta theta/Delta z)/(Delta AH/Delta z)`
- `H_Bowen = A beta/(1 + beta)`
- `LE_Bowen = A/(1 + beta)`
- `LE_penman = [Delta A + gamma cp rho VPD/ra]/[Delta + gamma(1 + rs/ra)]`
- `H_monin = -rho cp (k u_* z2/phi_h) (Delta theta/Delta z)`
- `LE_monin = -rho L_v (k u_*/phi_q) (Delta q/Delta z)`
- `Ri_g = (g/theta) (Delta theta/Delta z)/(Delta u/Delta z)^2`
- `closure_check = A - H - LE`
- `closure_ratio = (H + LE)/A`
- `unresolved_complement = A - LE_penman`

## 13. Do-not-misrepresent list

Hard prohibitions for the new graphic:

- Do not draw `Ts` / `surface_temp` as a standard measured climate-balance
  station variable. It is only a provided/model-assumption input for `LW_out`
  unless a specific external measurement is explicitly shown.
- Do not show Penman as a complete `H + LE` closure family.
- Do not call the Penman `unresolved_complement` sensible heat.
- Do not show Monin/Profile as forced to close the energy balance.
- Do not show `weather_station` as a calculator. It is a container for fields,
  metadata, assumptions and method outputs.
- Do not present Bulk-Residual formal closure as independent physical
  validation.
- Do not collapse Bulk-Residual into one level: it has `sensible_bulk`
  estimation and residual `latent_bulk_residual` closure.
- Do not state that `u_star_profile` makes Bulk equivalent to
  Monin-Obukhov/Profile. It is only a neutral profile-like exchange velocity
  for the Bulk sensible-heat estimate.
- Do not show old PNG/SVG/drawio graphics as source evidence.
- Do not invent sensors or fields beyond implemented weather_station
  conventions.
- Do not draw missing-data filling, imputation, interpolation, modeled
  replacement or `*_filled` columns as package functionality.
- Do not imply that `surface_type`, `slope`, `exposition`, `valley` or
  `obs_height` are silently defaulted.
- Do not imply that measured `rad_bal` is automatically reconstructed from
  radiation components.
- Do not use `rad_net` as a silent alias for `rad_bal` in method routing.
- Do not present empirical lookup tables as fully source-validated beyond the
  documented current implementation status.

