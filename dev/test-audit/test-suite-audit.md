# Test suite circularity audit

## Scope

This audit classifies the current `tests/testthat/` suite by what each file actually verifies. It is an audit of test intent and circularity risk only. It does not validate empirical source tables, does not evaluate physical correctness beyond the stated test contracts, and does not propose package source changes.

The helper file `tests/testthat/helper-physics-fixtures.R` is not counted as a test file. It is a shared fixture provider used by several physics and wrapper tests.

## Categories and strength definitions

Categories used below:

- A. independent equation-contract test
- B. helper equation-contract test
- C. API parity / wrapper consistency test
- D. guard / edge-case behaviour test
- E. smoke / coverage test
- F. potentially circular or weak test

Strength labels:

- Strong: expected value is independently computed from documented equations or explicit constants.
- Acceptable: test verifies wrapper/API parity or guard behaviour and does not claim physical correctness.
- Weak: test only executes code, checks object existence, or compares one wrapper output to another without a clear contract.

## Summary table

| Test file | Category | Strength | Circularity risk | Recommendation |
|---|---|---|---|---|
| `test-equation-contracts.R` | A, B, D | Strong | Low to medium: several expectations use package helpers when the helper is not the function under test. | Keep as primary equation-contract coverage; add comments when helper reuse limits independence. |
| `test-helper-equation-contracts.R` | B, D | Strong | Low to medium: some expected values use upstream helpers such as vapour-pressure or pressure helpers. | Keep; avoid treating upstream-helper-dependent cases as independent validation of those upstream helpers. |
| `test-priestley-taylor-source-table.R` | B | Strong | Low: explicit Foken/Stull table constants are used. | Keep as source-table lock for `sc()` and `gam()`. |
| `test-bulk-stability.R` | A, D, C | Strong | Low: Richardson number and class expectations are independently computed or explicit. | Keep; it is a good contract for optional `ri_guard`. |
| `test-penman-source.R` | A, C, D | Strong | Medium: weather-station routing expectations compare wrapper to direct method. | Keep; separate direct equation checks from wrapper parity in future edits. |
| `test-bowen-source.R` | A, D | Strong | Medium: locks implemented beta path but does not prove source-form correctness. | Keep; label as implementation contract, not source validation. |
| `test-radiation-contract.R` | A, D | Strong | Medium: aggregate radiation tests may use component functions as inputs. | Keep balance-sign tests; do not treat modeled-radiation agreement as empirical validation. |
| `test-temperature.R` | A | Strong | Low: audited numeric expectation is explicit. | Keep. |
| `test-utility_turbulent_flux.R` | B | Strong | Low: helper outputs are checked against explicit expected values. | Keep; ensure expected values remain equation-derived. |
| `test-bulk.R` | C, D | Acceptable | Medium: residual closure is algebraic and can be self-fulfilling. | Keep as behavioural contract; rely on equation-contract tests for independent formula checks. |
| `test-consolidation.R` | C, D, F | Acceptable | Medium to high: workflow outputs and packaged data can confirm integration without proving physics. | Keep as integration smoke/contract; avoid using it as physical validation. |
| `test-helper-edge-coverage.R` | D, E | Acceptable | Low: mostly branch and edge behaviour. | Keep if each assertion checks a documented branch. |
| `test-humidity-datetime.r` | D | Acceptable | Low: POSIXct/POSIXlt equivalence and vector handling. | Keep. |
| `test-humidity.R` | B, D | Acceptable | Medium: short regression-style tests may not independently reconstruct every equation. | Keep; equation-contract file carries the stronger helper validation. |
| `test-latent.R` | D, F | Acceptable | Medium: several checks are regression or closure-like checks. | Keep as legacy behaviour coverage; avoid treating as independent physics validation. |
| `test-monin-obukhov.R` | D | Acceptable | Low: diagnostic-only and edge-case tests do not claim closure. | Keep; this is the right style for MO diagnostic methods. |
| `test-penman.R` | A, C, D | Acceptable | Medium: includes direct expected formula and workflow fallback checks. | Keep; stronger Penman source contracts live in `test-penman-source.R`. |
| `test-physics-contract.R` | A, C, D, F | Acceptable | Medium to high: closure tests are necessary but algebraic closure can be self-fulfilling. | Keep as high-level contract; do not treat closure alone as physical validation. |
| `test-position.R` | A | Acceptable | Low: explicit numeric geometry expectations. | Keep; optionally fold into helper equation contracts later. |
| `test-pressure.R` | C, D | Acceptable | Medium: mostly wrapper/default behaviour. | Keep; helper equation contracts provide stronger pressure formula checks. |
| `test-priestley-taylor-contract.R` | B, C, D | Acceptable | Medium: closure and alpha-path tests do not validate alpha source values. | Keep; source-table validation only applies to `sc()` and `gam()`. |
| `test-radiation-solar-remaining-coverage.R` | D, E | Acceptable | Medium: branch tests and day/night behaviour, not independent solar source validation. | Keep as branch coverage; improve only if expectations can be tied to documented equations. |
| `test-radiation-solar-transmittance-coverage.R` | C, D, E | Acceptable | Medium: weather-station dispatch tests compare wrapper with direct helper. | Keep as parity/guard coverage; do not classify as physics validation. |
| `test-sensible.R` | D, F | Acceptable | Medium: legacy regression expectations and cap checks. | Keep for regression coverage; equation-contract tests carry the stronger formula checks. |
| `test-soil-contract.R` | B, D | Acceptable | Medium: table/domain behaviour is locked but table values are not source-validated. | Keep; do not infer empirical table correctness. |
| `test-solar-contract.R` | C, D | Acceptable | Medium: timebase and class-equivalence tests do not independently validate solar geometry. | Keep as API/timebase contract. |
| `test-solar.R` | C, D | Acceptable | Medium: simple expected values and wrapper checks. | Keep; add stronger independent solar equation tests only if documentation is unambiguous. |
| `test-transmittance-contract.R` | D | Acceptable | Medium: guards and bounds rather than source-form validation. | Keep. |
| `test-transmittance-remaining-coverage.R` | D, E | Acceptable | Medium: branch and vector-local behaviour, not equation validation. | Keep if assertions remain behaviour-specific. |
| `test-turbulence.R` | D | Acceptable | Medium: stability and turbulence helper behaviour, not full source validation. | Keep. |
| `test-turbulent-flux-remaining-coverage.R` | C, D, E | Acceptable | Medium to high: wrapper fields and fallback behaviour can be circular if read as physics. | Keep as workflow contract; avoid comparing outputs from `turb_flux_calc()` to each other as proof. |
| `test-weather-station-api-parity.R` | C, F | Acceptable | High for physics, low for API: direct calls are the oracle for weather-station methods. | Keep as API parity only; never cite as formula validation. |
| `test-weather-station-object-contract.R` | C, D, E | Acceptable | Medium: object preservation is meaningful; plot tests are smoke-level. | Keep object contracts; mark plot checks as smoke only. |
| `test-weather-station-coverage.R` | C, E, F | Weak | High: mostly coverage/object/smoke checks. | Keep only branches that assert documented object behaviour; consider replacing pure smoke checks with output contracts later. |
| `test-turbulence-coverage.R` | D, E, F | Weak | Medium: improves branch coverage but some checks are execution-oriented. | Keep meaningful guard assertions; avoid expanding pure coverage calls. |

Primary-strength count across 35 test files: 9 strong, 24 acceptable, 2 weak. Several acceptable files contain individual weak smoke tests, listed in the detailed notes below.

## Detailed file audit

### `tests/testthat/test-equation-contracts.R`

- Main functions tested: radiation balances, `soil_heat_flux()`, Priestley-Taylor, Bulk-Residual, Richardson guard, Bowen, Penman, `sensible_monin()`, `latent_monin()`.
- Category: A, B, D.
- Expected values independently computed: mostly yes. Bulk, Bowen, Penman, soil and Richardson expectations are reconstructed from documented equations and constants. Some sections intentionally use helper functions such as `sc()`, `gam()`, `temp_pot_temp()`, `hum_absolute()` and turbulence helpers when those helpers are not the direct function under test.
- Reuses function under test or wrapper: no direct self-comparison. Some aggregate radiation checks use component function outputs to test the aggregate balance.
- Verifies: implemented equation contracts and selected guard behaviour.
- Circularity risk: low to medium. The helper reuse is acceptable for main-method contracts, but it means this file is not independent validation of those helpers.

### `tests/testthat/test-helper-equation-contracts.R`

- Main functions tested: humidity helpers, pressure helpers, temperature helpers, boundary-layer helpers and selected turbulent-flux utilities.
- Category: B, D.
- Expected values independently computed: yes for explicit equations such as `c2k()`, `k2c()`, `hum_evap_heat()`, pressure and boundary-layer equations. Some humidity expectations use upstream package helpers for vapour pressure or pressure, with comments limiting the claim.
- Reuses function under test or wrapper: generally no; upstream helpers are reused only when not the helper under test.
- Verifies: helper equations and structural input behaviour.
- Circularity risk: low to medium for humidity-derived helpers due to upstream helper reuse.

### `tests/testthat/test-priestley-taylor-source-table.R`

- Main functions tested: `gam()`, `sc()`.
- Category: B.
- Expected values independently computed: yes, from explicit Foken/Stull Table 6 constants supplied in the test.
- Reuses function under test or wrapper: no.
- Verifies: source-table scale lock for `sc()` and `gam()`.
- Circularity risk: low.

### `tests/testthat/test-bulk-stability.R`

- Main functions tested: `sensible_bulk()` direct and weather-station method with `stability_method = "ri_guard"`.
- Category: A, C, D.
- Expected values independently computed: yes for default equivalence, Richardson classifications and attribute behaviour; not a source validation of stability thresholds.
- Reuses function under test or wrapper: weather-station method parity compares wrapper behaviour to default-method contract indirectly.
- Verifies: default unchanged, required `v2`, finite/guarded classifications, vector-local handling and wrapper pass-through.
- Circularity risk: low for guard logic; medium for wrapper pass-through because direct/default behaviour is the oracle.

### `tests/testthat/test-penman-source.R`

- Main functions tested: `latent_penman()`, `latent_penman.weather_station()`, Penman workflow output.
- Category: A, C, D.
- Expected values independently computed: yes for the kPa VPD Penman equation; wrapper routing expectations compare method output against direct calls.
- Reuses function under test or wrapper: wrapper tests use direct calls as oracle; workflow tests inspect `turb_flux_calc()` fields.
- Verifies: VPD unit contract, aerodynamic directionality, LE-only contract and humidity routing.
- Circularity risk: medium in wrapper sections; low for direct equation sections.

### `tests/testthat/test-bowen-source.R`

- Main functions tested: `sensible_bowen()`, `latent_bowen()`.
- Category: A, D.
- Expected values independently computed: yes for the implemented `gamma_code * dpot / dah` beta path and partition equations.
- Reuses function under test or wrapper: no direct self-comparison.
- Verifies: shared beta pathway, uncapped closure, capped guard behaviour, signs and invalid input handling.
- Circularity risk: medium only if interpreted as proof of source-form correctness. It is an implementation contract, not source validation.

### `tests/testthat/test-radiation-contract.R`

- Main functions tested: `rad_sw_bal()`, `rad_lw_bal()`, `rad_bal()`, albedo/radiation edge cases.
- Category: A, D.
- Expected values independently computed: yes for balance identities `K* = K_down - K_up`, `L* = L_down - L_up`, and `Rn = K* + L*`; modeled component tests may use component helpers as inputs.
- Reuses function under test or wrapper: aggregate tests can reuse lower-level radiation functions as components.
- Verifies: sign convention and edge behaviour, not empirical radiation model accuracy.
- Circularity risk: medium for component-composition tests; low for explicit balance identities.

### `tests/testthat/test-temperature.R`

- Main functions tested: `c2k()`, `k2c()`, `temp_pot_temp()`.
- Category: A, D.
- Expected values independently computed: yes for simple conversions and audited potential-temperature numeric value.
- Reuses function under test or wrapper: no.
- Verifies: formula/regression behaviour.
- Circularity risk: low.

### `tests/testthat/test-utility_turbulent_flux.R`

- Main functions tested: turbulent-flux utility helpers such as `sc()`, `gam()`, and related scalar utilities.
- Category: B.
- Expected values independently computed: mostly explicit numeric helper expectations.
- Reuses function under test or wrapper: no significant self-comparison observed.
- Verifies: helper behaviour and regression values.
- Circularity risk: low to medium depending on whether expected values are equation-derived or legacy regression constants.

### `tests/testthat/test-bulk.R`

- Main functions tested: `sensible_bulk()`, `latent_bulk_residual()`, `turb_flux_bulk_residual()`.
- Category: C, D.
- Expected values independently computed: partly; sign and low-wind guards are behaviour contracts, residual closure is algebraic.
- Reuses function under test or wrapper: `latent_bulk_residual()` closure uses `sensible_bulk()` output as part of the expected residual relation.
- Verifies: sign convention, residual closure, weather-station method fields and low-wind guard.
- Circularity risk: medium. Closure is useful but self-fulfilling if taken as physical validation.

### `tests/testthat/test-consolidation.R`

- Main functions tested: broad Caldern/workflow integration including flux methods and weather-station workflow.
- Category: C, D, F.
- Expected values independently computed: mixed; many assertions inspect generated workflow fields or packaged-data behaviour.
- Reuses function under test or wrapper: yes, workflow outputs may be used as the reference for integration expectations.
- Verifies: integration, data compatibility and high-level workflow behaviour, not physical correctness.
- Circularity risk: medium to high if used as physics evidence. It is acceptable as an integration suite.

### `tests/testthat/test-helper-edge-coverage.R`

- Main functions tested: helper edge branches across weather, pressure, humidity, utility and availability checks.
- Category: D, E.
- Expected values independently computed: usually explicit output, warning or error expectations rather than equation reconstruction.
- Reuses function under test or wrapper: no major circular pattern.
- Verifies: edge-case and documented branch behaviour.
- Circularity risk: low; strength is behavioural, not physical.

### `tests/testthat/test-humidity-datetime.r`

- Main functions tested: date/time-dependent humidity helper behaviour, especially POSIXct/POSIXlt equivalence.
- Category: D.
- Expected values independently computed: mostly structural equivalence and length checks.
- Reuses function under test or wrapper: compares accepted input classes for the same function.
- Verifies: API/time handling.
- Circularity risk: low for API behaviour, not physics validation.

### `tests/testthat/test-humidity.R`

- Main functions tested: humidity helper functions.
- Category: B, D.
- Expected values independently computed: mixed; legacy helper tests include explicit expectations but may not reconstruct every equation.
- Reuses function under test or wrapper: no major wrapper self-comparison pattern.
- Verifies: helper regression and basic vector/edge behaviour.
- Circularity risk: medium where expected values are legacy numeric outputs rather than independently documented equations.

### `tests/testthat/test-latent.R`

- Main functions tested: latent heat flux functions.
- Category: D, F.
- Expected values independently computed: mixed; some expectations are regression values or closure-related checks.
- Reuses function under test or wrapper: possible closure-style reuse through available-energy partitions.
- Verifies: legacy behaviour and selected warnings/guards.
- Circularity risk: medium. Stronger formula coverage is in equation/source files.

### `tests/testthat/test-monin-obukhov.R`

- Main functions tested: `sensible_monin()`, `latent_monin()`, `turb_flux_grad_rich_no()`, `turb_flux_stability()`.
- Category: D.
- Expected values independently computed: mostly explicit signs, finite/NA controls and class expectations.
- Reuses function under test or wrapper: no closure oracle; deliberately avoids `Rn - G` closure.
- Verifies: diagnostic-only status, normal finite cases, zero-gradient behaviour, invalid-height/low-wind guards and vector-local handling.
- Circularity risk: low. It does not overclaim physical closure.

### `tests/testthat/test-penman.R`

- Main functions tested: `latent_penman()`, weather-station method and `turb_flux_calc()` Penman fallback.
- Category: A, C, D.
- Expected values independently computed: yes for a direct kPa-VPD equation case; workflow tests are behavioural.
- Reuses function under test or wrapper: workflow fallback checks inspect `turb_flux_calc()` output fields.
- Verifies: VPD scale, available-energy sign, field mapping, vector-local invalid handling and non-fatal workflow fallback.
- Circularity risk: medium in workflow sections; low in direct equation section.

### `tests/testthat/test-physics-contract.R`

- Main functions tested: available energy convention, PT, Bulk-Residual, Bowen, Penman weather-station method, weather-station preservation and MO diagnostic workflow.
- Category: A, C, D, F.
- Expected values independently computed: mixed. Available-energy arithmetic is independent; closure tests are algebraic; wrapper tests inspect fields.
- Reuses function under test or wrapper: yes, several tests combine paired method outputs or inspect `turb_flux_calc()` output.
- Verifies: package-level contracts and guard behaviour.
- Circularity risk: medium to high if closure is read as physical validation. Closure remains necessary but not sufficient.

### `tests/testthat/test-position.R`

- Main functions tested: position/geometry helpers such as `pos_min_dist()`, `pos_max_dist()`, `pos_anemometer_height()`.
- Category: A.
- Expected values independently computed: appears to use explicit numeric expectations.
- Reuses function under test or wrapper: no.
- Verifies: deterministic helper equations or regressions.
- Circularity risk: low.

### `tests/testthat/test-pressure.R`

- Main functions tested: pressure helpers and weather-station method dispatch.
- Category: C, D.
- Expected values independently computed: mixed; one visible test checks wrapper forwarding with an override argument.
- Reuses function under test or wrapper: weather-station method uses default helper as oracle.
- Verifies: wrapper/API behaviour more than pressure physics.
- Circularity risk: medium for physics, acceptable for API parity.

### `tests/testthat/test-priestley-taylor-contract.R`

- Main functions tested: `sc()`, `gam()`, PT fluxes, PT `pt_only` workflow.
- Category: B, C, D.
- Expected values independently computed: behaviour and closure oriented; not a source-table test except through separate source-table file.
- Reuses function under test or wrapper: `turb_flux_calc(pt_only = TRUE)` is checked by output fields; closure combines paired PT functions.
- Verifies: helper monotonicity, invalid surface type behaviour, closure and workflow isolation.
- Circularity risk: medium. Alpha-table values and source provenance are not independently validated here.

### `tests/testthat/test-radiation-solar-remaining-coverage.R`

- Main functions tested: remaining radiation/solar branches including vectorized date and night cases.
- Category: D, E.
- Expected values independently computed: mostly explicit finite/zero/length expectations.
- Reuses function under test or wrapper: may compare equivalent input classes and wrappers.
- Verifies: branch and guard behaviour.
- Circularity risk: medium if treated as solar-geometry source validation; acceptable as coverage/guard testing.

### `tests/testthat/test-radiation-solar-transmittance-coverage.R`

- Main functions tested: solar, radiation and transmittance weather-station wrappers and day/night guards.
- Category: C, D, E.
- Expected values independently computed: mostly class equivalence, length, finite and zero-at-night contracts.
- Reuses function under test or wrapper: yes, weather-station methods are compared to direct helpers.
- Verifies: API parity, vector behaviour and guard behaviour.
- Circularity risk: medium. It is not independent physics validation.

### `tests/testthat/test-sensible.R`

- Main functions tested: sensible heat methods including Bowen, Priestley-Taylor and Monin/Profile behaviour.
- Category: D, F.
- Expected values independently computed: mixed; some regression numeric expectations, cap behaviour and no-warning checks.
- Reuses function under test or wrapper: no major direct wrapper oracle, but some tests are regression locks.
- Verifies: legacy behaviour and guard/cap policy.
- Circularity risk: medium. Stronger formula checks live in source/equation-contract tests.

### `tests/testthat/test-soil-contract.R`

- Main functions tested: `soil_heat_flux()`, `soil_thermal_cond()`, `soil_heat_cap()`, `soil_attenuation()`.
- Category: B, D.
- Expected values independently computed: yes for sign convention and attenuation unit conversion; table value assertions are deliberately behavioural rather than source validation.
- Reuses function under test or wrapper: may use soil helper outputs in downstream soil attenuation expectations.
- Verifies: sign convention, vector behaviour, valid/invalid texture behaviour and moisture-domain behaviour.
- Circularity risk: medium for helper-composition cases; low for explicit sign/unit conversion checks.

### `tests/testthat/test-solar-contract.R`

- Main functions tested: solar functions and timebase behaviour.
- Category: C, D.
- Expected values independently computed: mainly POSIXct/POSIXlt and timezone/API behaviour rather than full independent solar equations.
- Reuses function under test or wrapper: compares accepted input representations.
- Verifies: timebase and API consistency.
- Circularity risk: medium for physics, acceptable for API contract.

### `tests/testthat/test-solar.R`

- Main functions tested: basic solar helpers and weather-station dispatch.
- Category: C, D.
- Expected values independently computed: some explicit numeric expectations; wrapper tests use direct/default behaviour.
- Reuses function under test or wrapper: yes for weather-station method parity.
- Verifies: basic deterministic behaviour and wrapper dispatch.
- Circularity risk: medium for source validation; acceptable for regression/API testing.

### `tests/testthat/test-transmittance-contract.R`

- Main functions tested: transmittance helpers and non-positive/near-horizon solar elevation behaviour.
- Category: D.
- Expected values independently computed: mostly bounds, finite/NA controls and vector-local behaviour.
- Reuses function under test or wrapper: no major self-comparison pattern.
- Verifies: guard and physical-bound contracts, not source equation validation.
- Circularity risk: low to medium.

### `tests/testthat/test-transmittance-remaining-coverage.R`

- Main functions tested: remaining transmittance branches including invalid and low positive solar elevation cases.
- Category: D, E.
- Expected values independently computed: mostly finite/NA/warning expectations.
- Reuses function under test or wrapper: possible equivalent input-class comparisons.
- Verifies: vector-local and guard behaviour.
- Circularity risk: medium only if read as source validation.

### `tests/testthat/test-turbulence.R`

- Main functions tested: turbulence/profile helpers and stability classification.
- Category: D.
- Expected values independently computed: mainly explicit signs, classifications and finite/NA controls.
- Reuses function under test or wrapper: no major circular pattern.
- Verifies: guard and classification behaviour.
- Circularity risk: medium for source correctness, low for behaviour.

### `tests/testthat/test-turbulent-flux-remaining-coverage.R`

- Main functions tested: `turb_flux_calc()`, `turb_flux_bulk_residual()` and workflow fallback branches.
- Category: C, D, E.
- Expected values independently computed: mostly field presence, preservation, warning and NA fallback expectations.
- Reuses function under test or wrapper: yes, workflow output is the main object under inspection.
- Verifies: orchestration and graceful fallback, not formula correctness.
- Circularity risk: medium to high if used as physics evidence; acceptable as wrapper coverage.

### `tests/testthat/test-weather-station-api-parity.R`

- Main functions tested: many direct methods and corresponding `weather_station` methods across humidity, soil, heat-flux and workflow APIs.
- Category: C, F.
- Expected values independently computed: no. Direct function calls are intentionally used as the oracle for `weather_station` methods.
- Reuses function under test or wrapper: yes, by design. It compares wrapper dispatch to direct calls.
- Verifies: API parity and field routing only.
- Circularity risk: high for physics, acceptable for wrapper consistency. Do not use as formula validation.

### `tests/testthat/test-weather-station-object-contract.R`

- Main functions tested: `build_weather_station()`, `as.data.frame.weather_station()`, `plot_weather_station()`, `check_availability()`.
- Category: C, D, E.
- Expected values independently computed: object fields and error strings are explicit; plot calls are smoke-level.
- Reuses function under test or wrapper: no circular physics pattern.
- Verifies: object storage, flat/legacy conversion, data-frame recycling behaviour, plot dispatch and availability errors.
- Circularity risk: medium due to smoke tests, low for object-field contracts.

### `tests/testthat/test-weather-station-coverage.R`

- Main functions tested: weather-station object helpers and plotting/coverage branches.
- Category: C, E, F.
- Expected values independently computed: limited; several checks are execution or object-existence oriented.
- Reuses function under test or wrapper: not usually circular, but weak as an oracle.
- Verifies: coverage and smoke behaviour more than a documented contract.
- Circularity risk: high for correctness claims. Keep only as coverage/smoke support unless strengthened by explicit contracts.

### `tests/testthat/test-turbulence-coverage.R`

- Main functions tested: remaining turbulence branch paths.
- Category: D, E, F.
- Expected values independently computed: limited; mostly finite/guard/branch expectations.
- Reuses function under test or wrapper: no major direct self-oracle pattern.
- Verifies: edge branches and coverage.
- Circularity risk: medium. Useful branch coverage, weak as physical validation.

## Cross-cutting circularity findings

1. Weather-station parity tests are intentionally circular for physics. They are valid API tests because direct calls are the oracle for method dispatch, but they cannot validate the direct method formulas.
2. `turb_flux_calc()` tests mostly verify orchestration, field preservation, fallback and method isolation. They should not be treated as independent validation of PT, Penman, Bowen, Bulk or MO formulas.
3. Closure tests for PT, Bulk-Residual and Bowen are necessary contracts but can be self-fulfilling because paired functions may share the same available-energy term or partition denominator. They prove algebraic consistency, not source-form correctness.
4. Helper reuse in expected-value calculations is acceptable only when the reused helper is not the function under test. This pattern appears in the main equation-contract tests and should remain explicitly documented in comments.
5. Coverage files contain some meaningful branch contracts but also smoke checks such as `expect_no_error()` and field-existence checks. These are weak correctness evidence but acceptable when labelled as coverage/guard tests.
6. Empirical lookup tables are generally not validated by the main contracts, except `sc()`/`gam()` in the Foken/Stull source-table test. Tests that exercise soil, albedo, resistance or surface mappings should not be read as table source validation.

## Concrete test-improvement ideas for later

These are test-suite recommendations only, not source-code changes:

- Add short comments to parity files stating that direct-vs-weather-station equality is API validation only.
- Split mixed files where practical: keep equation-contract assertions separate from workflow and coverage assertions.
- For coverage-oriented tests, prefer explicit output/error/warning contracts over bare `expect_no_error()` calls.
- When a test uses a helper in an expected-value calculation, add one-line comments naming which function is under test and why the helper is allowed.
- Keep closure tests, but pair them with source or equation-contract tests where the underlying partition formula can be reconstructed independently.

## Audit counts

- Test files inspected: 35.
- Helper fixture files inspected but not counted as tests: 1.
- Primary strong test files: 9.
- Primary acceptable test files: 24.
- Primary weak test files: 2.
- Files with notable circularity risk: `test-weather-station-api-parity.R`, `test-turbulent-flux-remaining-coverage.R`, `test-consolidation.R`, `test-physics-contract.R`, `test-weather-station-coverage.R`, and closure-heavy sections of `test-bulk.R` and `test-priestley-taylor-contract.R`.
