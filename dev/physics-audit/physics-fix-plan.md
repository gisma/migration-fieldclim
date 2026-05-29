# fieldClim Physics Fix Plan

Input audit: `dev/physics-audit/physics-formula-audit.md`  
Purpose: convert the completed physics audit findings into a scoped fix sequence.  
Edit rule for this plan: do not edit package source, tests, Rd files, or run `devtools::document()` while creating the plan.

## Status Inventory Extracted From Audit

The audit findings use these actionable statuses in the completed sections:

| Status | Functions or topics |
|---|---|
| `code-ok` | `temp_pot_temp()`, `rad_bal()`, `rad_sw_bal()`, `rad_lw_bal()`, package `Rn/G` convention, `Q_star/B` vignette mapping, `soil_flux` workflow convention, available energy `rad_bal - soil_flux`, PT soil-flux consumption, Bulk-Residual soil-flux consumption, Bowen soil-flux consumption, Priestley-Taylor formal closure, `pt_only = TRUE`, `sensible_bulk()` implementation behavior, `latent_bulk_residual()` closure, `turb_flux_bulk_residual()` workflow closure, Bowen formal closure outside capped/singular cases, `turb_flux_calc()` orchestration, `build_weather_station()`, `as.data.frame.weather_station()`. |
| `test expectation wrong` | skipped `temp_pot_temp(25, 270)` test expected `27.7`; audited calculation is `26.520455365680`, rounded to `26.5`. |
| `sign-mismatch` | `soil_heat_flux()` documented equation omits the leading minus sign while implementation and package convention make positive `G` point into the soil. |
| `unit/documentation mismatch` | `soil_attenuation()` Rd equation omits explicit `C_v * 10^6` conversion; `turb_flux_stability()` Rd value text says gradient Richardson number although implementation returns stability labels; Bowen Rd beta/smoothing text differs from implementation. |
| `wrapper-mismatch` | `check_availability()` documentation says it checks required parameters and mentions `NULL`, but implementation checks names only; `latent_penman.weather_station()` routes `hum1` as `rh`, which is only valid if `hum1` is relative humidity in percent. |
| `open` | radiation source helpers and edge domains, albedo validation, solar timebase, modeled-vs-measured radiation equivalence, soil table sources/interpolation domains, PT `alpha`/`sc()`/`gam()` source units, bulk physical adequacy, Bowen beta units and singular/cap behavior, Penman source-form and final magnitude validation, Monin zero-gradient/low-wind behavior, `turb_flux_grad_rich_no()` zero-gradient handling. |
| `diagnostic-only` | Monin-Obukhov sensible/latent fluxes and stability workflow are diagnostic profile-gradient methods and are not expected to close `Rn - G`. |

## A. Immediate Documentation/Test Fixes With No Formula Change

| Item | Current audit status | Exact problem | Proposed action | Affected areas | Risk | New test required before fixing? |
|---|---|---|---|---|---|---|
| `temp_pot_temp()` skipped expectation | `test expectation wrong`; implementation `code-ok` | Previous skipped test expected `27.7`, which corresponds to using `1013.25 hPa` as the potential-temperature reference pressure instead of documented `1000 hPa`. | Update the skipped test expectation to `26.520455365680` or rounded `26.5`; optionally add a short note that the second argument is elevation and pressure is derived internally. | Test; possibly Rd or vignette note. | Low | No; the audit already gives the numeric contract. |
| `soil_heat_flux()` equation prose | `sign-mismatch` | Rd/source equation shows `G = lambda * (T1 - T2)/(z1 - z2)` but implementation uses the leading minus sign and matches `G > 0` into soil. | Correct documentation equation to include the implemented sign convention; keep code unchanged unless a later source validation disproves the package convention. | Rd; possibly vignette formula text if present. | Low | Yes, add/keep a sign contract: warmer upper soil layer over cooler deeper layer with positive depths returns positive `G` into soil. |
| `soil_attenuation()` unit notation | `unit/documentation mismatch`; implementation internally consistent | Documentation equation uses `C_v` in MJ m-3 K-1 without showing the `* 10^6` conversion used in code and tests. | Clarify Rd equation either by defining `C_v` in J m-3 K-1 in the equation or explicitly showing conversion from MJ to J. | Rd. | Low | No formula-change test required; existing numeric test can remain. |
| `latent_penman()` sign prose | `fixed` | Previous Rd text said negative heat flux is away from the surface, conflicting with package convention. | Roxygen/Rd updated to state positive `LE` is away from the surface. | Rd. | Low | Done. |
| `turb_flux_stability()` return text | `unit/documentation mismatch` / `open` | Rd value section says the function returns a gradient Richardson number, but implementation returns stability strings. | Correct Rd value text to say it returns `"unstable"`, `"neutral"`, `"stable"`, or `NA`. | Rd. | Low | Yes, add a classification contract for negative, near-zero, and positive Richardson cases. |
| Bowen smoothing/cap documentation | `unit/documentation mismatch` / `open` | Latent Bowen documentation says extreme values are smoothed, but implementation warns and optionally caps denominator only. | Adjust Rd to describe current warning/denominator-cap behavior, unless later physics validation changes the implementation. | Rd; possibly vignette caution text. | Medium | Yes, add tests for uncapped singular behavior and capped denominator behavior before any behavior change. |
| Stale audit path references | `unit/documentation mismatch` in planning material | Some scaffold text refers to the legacy audit-document location instead of the current audit path. | In new planning and future task prompts, use `dev/physics-audit/physics-formula-audit.md`. Do not rewrite the audit file just for this plan. | Audit document or future task prompts only. | Low | No. |

## B. Contract Tests To Add Before Formula Changes

| Item | Current audit status | Exact problem | Proposed action | Affected areas | Risk | New test required before fixing? |
|---|---|---|---|---|---|---|
| Radiation balances | `code-ok` for balance signs; helpers `open` | `rad_bal()`, `rad_sw_bal()`, and `rad_lw_bal()` follow the desired sign convention, but helper edge behavior is not locked. | Add tests for `K* = K_down - K_up`, `L* = L_down - L_up`, and `Rn = K* + L*` using controlled or mocked component values where feasible. | Test. | Low | Yes. |
| Albedo handling | `open` | Unknown/case-mismatched `surface_type` can return `numeric(0)`; albedo range is assumed, not checked. | Add tests for valid surface albedo range, reflected shortwave not exceeding incoming shortwave for valid surfaces, and explicit behavior for unknown surface type. | Test first; later code/Rd depending on chosen behavior. | Medium | Yes. |
| Shortwave and diffuse radiation edge domains | `open` | Low sun, negative solar elevation, terrain shading, and transmittance invalid domains can produce unstable or non-finite intermediate values. | Add day/night and near-horizon tests for non-negative finite modeled shortwave outputs; add a diffuse-radiation contract before changing clipping behavior. | Test. | Medium | Yes. |
| Solar timebase | `open` | `sol_hour_angle()` documentation names `T_m`, but code uses POSIXlt local fields directly and does not call `sol_medium_suntime()`. | Add tests that define expected hour-angle behavior for POSIXlt/POSIXct inputs and time zones before deciding whether code or documentation changes. | Test first; code/Rd later. | High | Yes. |
| Soil available energy | `code-ok` | Package convention is confirmed, but it is central and should be protected before any formula changes. | Add explicit test that increasing positive `soil_flux` decreases `rad_bal - soil_flux`; test closure methods consume `G > 0` into soil consistently. | Test. | Low | Yes. |
| Priestley-Taylor closure | `code-ok` formal closure; helper units `open` | Closure is correct, but `alpha`, `sc()`, and `gam()` source/unit validation remains unresolved. | Add contract tests for `H_PT + LE_PT = Rn - G`, negative available energy sign, and `pt_only = TRUE` isolation. | Test. | Low | Yes. |
| Bulk-Residual closure and low wind | `code-ok`; physical adequacy `open` | Simple bulk formula is implementation-specific; low wind should remain controlled. | Keep/add tests for `T_lower > T_upper` positive `H`, low wind warning with `NA`, and exact `H + LE = Rn - G`. | Test. | Low | Yes. |
| Bowen closure outside singular/capped cases | `code-ok` formal closure; beta units `open` | Closure only holds when both methods use the same unmodified denominator; capped cases deliberately may not close. | Add tests for exact closure in a non-singular case and separate tests for near-zero denominator with and without `cap`. | Test. | Medium | Yes. |
| Penman LE-only contract | `open` | Penman is not an energy-closure pair and should not invent `H`; surface mapping and failure behavior need protection. | Add tests that `surface_type = "field"` maps successfully, output is LE-only, `Rn - G` is used in the energy term, and Penman failure inside `turb_flux_calc()` is non-fatal. | Test. | Medium | Yes. |
| Monin diagnostic safeguards | `diagnostic-only` / `open` | MO does not close `Rn - G`; zero-gradient and low-wind cases can produce unstable outputs. | Add tests that MO is not required to close energy, and that zero-gradient/low-wind cases produce controlled `NA`, warning, or finite bounded behavior as chosen. | Test first; code/Rd later. | High | Yes. |
| Wrapper preservation | `code-ok` / `wrapper-mismatch` for validation helper | Container conversion preserves values, but validation semantics are weak. | Keep/add tests for `build_weather_station()` preserving fields, `as.data.frame.weather_station()` preserving values, and `check_availability()` behavior for missing and `NULL` fields. | Test. | Low | Yes for `NULL` behavior before changing helper. |

## C0. Fixed Physics Items

| Item | Previous status | Resolution | Evidence | Remaining open items |
|---|---|---|---|---|
| Penman VPD pressure scale | `fixed` | Fixed by explicit hPa-to-kPa conversion for `e_s`, `e_a`, and `vpd_kPa` in `latent_penman.default()`. | `R/latent.R`; `tests/testthat/test-penman.R`; old Caldern Penman mean `62.81968`, new mean `13.22542`. | Exact Penman source-form validation and final physical magnitude validation. |

## C. Open Physics Validation Questions

| Item | Current audit status | Exact problem | Proposed action | Affected areas | Risk | New test required before fixing? |
|---|---|---|---|---|---|---|
| Radiation source constants and domains | `open` | `rad_sw_in()`, diffuse radiation, transmittance helpers, terrain factors, and `rad_sw_toa()` need independent Bendix/source verification; some constants and defaults differ or are implementation-specific. | Validate constants, input domains, and clipping policy against Bendix/source equations before code changes. | Audit document; later tests/code/Rd if needed. | High | Yes. |
| Modeled vs measured radiation | `open` | Audit confirms measured `rad_net` is not automatically equal to component-derived modeled `K* + L*`. | Keep this as a validation distinction; do not change workflows to silently replace measured `rad_net`. | Vignette/audit; possibly tests to prevent silent substitution. | Medium | Yes, if workflow behavior is touched. |
| Soil thermal property tables | `open` | `soil_thermal_cond()` and `soil_heat_cap()` table values, interpolation range, and clamp policy were not independently source-validated. | Verify table source and decide whether out-of-range moisture should return `NA`, clamp, or warn. | Audit first; later code/Rd/test. | Medium | Yes. |
| PT `alpha`, `sc()`, and `gam()` | `open` | PT closes algebraically, but coefficient table and helper units are not source-validated. | Verify Foken/source values and document helper units; avoid changing formulas until contract tests exist. | Audit/Rd; later code/test if mismatch found. | Medium | Yes. |
| Bulk physical adequacy | `open` | `sensible_bulk()` is a simplified neutral/log-profile estimate, not full stability physics. | Document it as a simple reference method unless source validation shows the formula should change. | Rd/vignette; tests for current contract. | Medium | Yes. |
| Bowen beta units | `open` | Code uses potential-temperature gradient and absolute-humidity gradient with `gamma * dpot / dah`, while Rd describes `gamma / L_v * Delta T / Delta q`. | Validate source formula and units before deciding whether to change code or documentation. | Audit first; later code/Rd/test. | High | Yes. |
| Bowen denominator cap policy | `open` | Capping `1 + beta` changes exact closure; documentation does not clearly distinguish capped from uncapped closure. | Decide whether cap is a numerical safeguard only and document closure exception. | Rd/vignette/test; code only if policy changes. | Medium | Yes. |
| Penman pressure/vapour-pressure units | `fixed` | `Delta` and `gamma` are kPa-scale, while `es - ea` previously remained hPa in the aerodynamic term. | Fixed in `R/latent.R` by converting helper hPa values to kPa and using `vpd_kPa`; covered by `tests/testthat/test-penman.R`. | Code/test. | Medium | Done. |
| Penman vector and warning behavior | `fixed` for local guard/warning mechanics; source edge policy still open | Scalar `max()` guards and logical warning checks were replaced in `latent_penman.default()`. | Keep source-form/aerodynamic edge validation open; current mechanics covered by `tests/testthat/test-penman.R`. | Code/test. | Medium | Done for mechanics. |
| Monin sensible gradient denominator | `fixed` / `diagnostic-only` | Previous `sensible_monin()` denominator used `(theta2 - theta1) / log(z2 - z1)`, while Rd/source context says `Delta theta / Delta z`. | Phase MO-2 changed the denominator to `(z2 - z1)` and kept MO diagnostic-only. | Code/Rd/test/audit. | Medium | Done. |
| Monin stability and zero-gradient behavior | `open` / `diagnostic-only` | `turb_flux_grad_rich_no()` sets `NaN` to zero but can leave `Inf`; low-wind/zero-gradient behavior is not fully controlled. | Define numerical policy for zero wind gradient, zero temperature gradient, and low wind. | Test first; code/Rd later. | High | Yes. |

## D. Wrapper/Check Hygiene

| Item | Current audit status | Exact problem | Proposed action | Affected areas | Risk | New test required before fixing? |
|---|---|---|---|---|---|---|
| `check_availability()` | `wrapper-mismatch` / `open` | Checks only whether required names exist, not whether values are `NULL`, wrong length, or physically usable. | Add tests for missing, present-`NULL`, and wrong-length fields; then decide whether helper should enforce non-`NULL` only or remain a name-check with corrected docs. | Test; code or Rd depending on decision. | Medium | Yes. |
| `latent_penman.weather_station()` humidity routing | `wrapper-mismatch` / `open` | Wrapper prefers `hum1` over `rh` and passes it as `rh`; this is only valid if `hum1` is lower-profile RH percent, not another humidity quantity. | Add test documenting this routing; then decide whether Rd should state `hum1` must be RH percent or wrapper should prefer station-level `rh` for Penman. | Test first; Rd/code later. | Medium | Yes. |
| `turb_flux_calc()` full workflow requirements | `code-ok` for orchestration; inherited `open` | Full workflow can fail if non-Penman fields are missing; Penman failure alone is non-fatal. | Keep orchestration scoped; add tests that `pt_only = TRUE` avoids Bulk/Bowen/MO/Penman requirements and that Penman failure remains non-fatal in full workflow. | Test. | Low | Yes. |
| `build_weather_station()` | `code-ok` | Stores fields without physics validation by design. | Do not add physics validation here; keep it as a plain container. Add preservation tests if missing. | Test only unless docs unclear. | Low | No before code, because no code change proposed. |
| `as.data.frame.weather_station()` | `code-ok` | Preserves values; `unit = TRUE` renames columns only. | Do not change behavior. Add regression tests only if future wrapper changes touch object structure. | Test only if touched. | Low | No. |

## E. Deferred Or Diagnostic-Only Methods

| Item | Current audit status | Exact problem | Proposed action | Affected areas | Risk | New test required before fixing? |
|---|---|---|---|---|---|---|
| `sensible_monin()` | `diagnostic-only`; denominator `fixed`; physical validation `open` | Profile-gradient method is not energy-closing; Phase MO-2 aligned the potential-temperature gradient denominator with documented `Delta z`. | Keep diagnostic-only. Do not normalize it to `Rn - G`; validate broader MOST source constants separately. | Audit/test first; code/Rd later only if needed. | High | Yes for future physical changes. |
| `latent_monin()` | `diagnostic-only` / `open` | Profile-gradient method is not energy-closing; humidity-gradient and stability behavior need validation. | Keep diagnostic-only. Do not force `H_MO + LE_MO = Rn - G`. | Audit/test first; code/Rd later only if needed. | High | Yes. |
| `turb_flux_stability()` and `turb_flux_grad_rich_no()` | `diagnostic-only` / `open` | Stability classification is diagnostic; zero-gradient and infinite Richardson cases need defined behavior. | Add classification and edge-case tests; correct documentation return type. | Test/Rd; code if edge policy changes. | Medium | Yes. |
| Modeled radiation helper physics | `open` | Helper formulas can be valuable but are not the primary measured-energy workflow; edge domains need source validation. | Defer formula changes until radiation contract tests and source checks are complete. | Audit/test first. | Medium | Yes. |
| Bulk physical realism | `code-ok` implementation; physical adequacy `open` | Bulk-Residual closes formally by construction but simple bulk `H` may be crude. | Retain as simplified reference/residual workflow; do not broaden into a full stability-corrected method in this fix sequence. | Rd/vignette/test. | Medium | Yes if documentation or behavior changes. |
| Bowen physical plausibility | `code-ok` formal closure outside singular cases; `open` physics | Formal closure does not validate unstable gradients, beta units, or near-singular denominator behavior. | Keep partition method, document limits, and handle singular cases explicitly after tests. | Test/Rd/code if policy changes. | High | Yes. |

## Sequencing Recommendation

1. Add contract tests for confirmed invariants first: `temp_pot_temp()`, `Rn/G` available energy, PT closure, Bulk-Residual closure, Bowen non-singular closure, wrapper preservation, and `pt_only` isolation.
2. Apply no-formula documentation/test fixes: `temp_pot_temp()` skipped expectation, `soil_heat_flux()` documented sign, `soil_attenuation()` unit notation, `turb_flux_stability()` return text, and stale path references in future planning material.
3. Resolve high-risk physics questions before code changes: Penman source-form and final magnitude validation, Bowen beta units, Monin sensible-gradient denominator, solar timebase.
4. Add wrapper hygiene tests, then decide whether `check_availability()` should enforce non-`NULL` values or whether documentation should describe it as a name-presence check only.
5. Keep Monin-Obukhov diagnostic-only unless the code is explicitly changed in a future scoped task to enforce closure. No current fix should normalize all methods to one result.


## Optional Bulk Richardson Guard Update

- `sensible_bulk()` now supports optional `stability_method = "ri_guard"`.
- Default `stability_method = "none"` preserves the neutral bulk-transfer calculation unchanged.
- The guard computes a gradient Richardson number from two-height temperature and wind-speed profiles, attaches `bulk_Ri_g` and `bulk_stability` attributes, and returns `NA` for invalid or very stable cases.
- This is diagnostic stability screening only, not a Monin-Obukhov correction and not a stability-corrected flux model.
- In the Bulk-Residual workflow, an `NA` guarded sensible heat estimate propagates to residual `LE`, preventing algebraic closure from hiding invalid `H_bulk`.
