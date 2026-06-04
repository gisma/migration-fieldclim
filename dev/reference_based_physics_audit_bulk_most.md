# Reference-based physics audit: Bulk, MOST, and heat-flux algorithms in fieldClim

This audit is reference-based but implementation-first. Tests are used as
evidence for code behavior only. They are not treated as proof of physical
adequacy.

Notation used throughout:

- `Q* = rad_bal`
- `B = soil_flux`
- `A = Q* - B`
- `H = sensible heat flux`
- `LE = latent heat flux`
- `R_E = Q* - B - H - LE`

## 1. Executive verdict

- IMPLEMENTED: The Bulk path implements a neutral bulk aerodynamic resistance
  method for sensible heat, followed by an algebraic residual latent heat term
  in the Bulk-Residual workflow.
- TESTED: Tests verify the implemented Bulk formulas, sign behavior, low-wind
  guards, exchange-velocity variants, Richardson guard behavior, wrapper
  pass-through, and formal closure of `H_bulk + LE_res = Q* - B`.
- PHYSICALLY CONSISTENT: The core `H = rho c_p Delta T / r_a` structure is
  consistent with a bulk/aerodynamic-resistance heat-transfer family. The
  `u_star_profile` and `u_star_roughness` paths are consistent with neutral
  log-law style exchange-scale calculations.
- PHYSICALLY SIMPLIFIED: Bulk does not implement full Monin-Obukhov Similarity
  Theory (MOST). It does not apply MOST stability functions to correct H.
- PHYSICS_REFERENCE_MISSING: The package contains canonical bibliography for
  aerodynamic methods and boundary-layer theory, but no source in the current
  Bulk implementation pins each Bulk variant to a specific reference equation
  beyond the package roxygen/Rd description and tests.
- NOT IMPLEMENTED: A full stability-corrected MOST Bulk flux is not implemented.
  Eddy-covariance validation is not implemented.
- DO_NOT_CLAIM: Do not claim that Bulk-Residual closure validates `H_bulk`, that
  `u_star_profile` makes Bulk a MOST method, or that the residual latent term is
  an independent evapotranspiration measurement.

Plain-language verdict:

The implemented Bulk algorithm is a neutral bulk-transfer / aerodynamic
resistance approximation for `H_bulk`. It can be made more profile-like by using
friction velocity from two wind heights or roughness length, but it remains a
neutral approximation. The optional Richardson guard is a diagnostic filter. The
Bulk-Residual workflow is useful as a transparent closure/teaching path and as a
coarse diagnostic comparison, but its closure is algebraic and must not be
presented as physical validation.

## 2. Evidence basis

### Files inspected

Implementation files:

- `R/bulk.R`
- `R/sensible.R`
- `R/latent.R`
- `R/turbulent_flux.R`
- `R/turbulence.R`
- `R/utility_turbulent_flux.R`
- `R/energy_balance_closure.R`
- `R/weather_station.R`
- `R/fieldclim_params.R`
- `R/pressure.R`
- `R/humidity.R`
- `R/temperature.R`
- `R/globals.R`

Tests:

- `tests/testthat/test-bulk.R`
- `tests/testthat/test-bulk-exchange-velocity.R`
- `tests/testthat/test-bulk-stability.R`
- `tests/testthat/test-turbulence.R`
- `tests/testthat/test-monin-obukhov.R`
- `tests/testthat/test-energy-balance-closure.R`
- `tests/testthat/test-equation-contracts.R`
- `tests/testthat/test-physics-contract.R`
- `tests/testthat/test-turbulent-flux-remaining-coverage.R`

Documentation/source context:

- `man/*.Rd`
- `docs/reference/*.md`
- `vignettes/fieldclim_theory.Rmd`
- `vignettes/fieldclim_flux_workflow.Rmd`
- `vignettes/fieldclim_flux_workflow_en.Rmd`
- `vignettes/fieldclim-methods.bib`
- `dev/physics-audit/*.md`
- `dev/physics-formula-audit.md`
- `dev/source-table-audit/*.md`
- `dev/test-audit/*.md`
- `dev/repo-knowledge-state.md`

Sources not used:

- `vignettes/figures/*.png`
- `vignettes/figures/*.svg`
- `vignettes/figures/*.drawio`
- rendered article figures
- old diagrams of any kind

### Reference/bibliography sources found in the repo

The repository bibliography contains canonical comparison targets and method
families, including:

- Prueger and Kustas (2005), aerodynamic methods for estimating turbulent
  fluxes.
- Foken (2008), Stull (1988), Garratt (1992), Arya (2001), Kaimal and Finnigan
  (1994), Brutsaert (1982), and related boundary-layer/MOST references.
- Penman (1948), Monteith and Unsworth, Allen et al. (1998) for Penman/Penman-
  Monteith family context.
- Priestley and Taylor (1972) for PT family context.
- Foken (2008 closure), Wilson et al. and other energy-balance closure context.
- Bendix (2004), cited heavily in roxygen/Rd for package helper equations.

These references are comparison targets. They do not by themselves prove that
the current code implements every canonical detail.

### Missing references

- PHYSICS_REFERENCE_MISSING: No Bulk-specific source note in `R/bulk.R`,
  `man/sensible_bulk.Rd`, or tests ties the `wind_mean`, `u_star_profile`, and
  `u_star_roughness` variants to exact pages/equations from Prueger, Foken,
  Stull, Garratt, or another canonical source.
- PHYSICS_REFERENCE_MISSING: The optional Bulk `ri_guard` thresholds are
  implementation parameters; no source equation/page for the specific
  `ri_neutral = 0.01`, `ri_critical = 0.25`, `min_shear = 1e-4` choices is
  cited in the Bulk code.
- PHYSICS_REFERENCE_MISSING: Physical validation of Bulk against independent EC,
  lysimeter, or gradient observations is not implemented in the package.

### Contradictions and stale context

| Topic | Evidence | Resolution |
|---|---|---|
| `turb_flux_bulk_residual.Rd` exchange velocity | Current code/tests implement three exchange-velocity paths. `man/turb_flux_bulk_residual.Rd` describes only the mean-wind resistance formula. | Documentation is incomplete for variants. Code/tests are authoritative. |
| `turb_flux_calc.Rd` fallback wording | Rd suggests unavailable optional inputs produce NA/warnings. Tests show non-Penman missing inputs can abort; Penman alone is caught. | Code/tests authoritative: only Penman has explicit non-fatal fallback. |
| Older `dev/physics-formula-audit.md` Monin/Penman sections | Older audit text contains pre-fix concerns about Monin denominator and Penman unit handling. Current R code, tests, NEWS and newer validation reports document current denominator and kPa VPD behavior. | Treat older text as historical/stale where it conflicts with current code/tests. |
| Closure interpretation | Tests confirm Bulk closure residual equals zero when LE is residual. Physics notes repeatedly warn formal closure is not validation. | No contradiction; use formal/algebraic closure wording only. |

## 3. Reference equations ledger

| Topic | Reference equation family | Canonical form | Implemented form | Match level | Notes |
|---|---|---|---|---|---|
| Available energy | Surface energy balance without storage | `A = R_n - G`; here `A = Q* - B` | `available_energy = rad_bal - soil_flux` | PHYSICALLY CONSISTENT | Sign convention: `Q* > 0` input at surface, `B > 0` into soil. |
| Sensible heat by aerodynamic resistance | Bulk/aerodynamic resistance heat transfer | `H = rho c_p (T_surface_or_lower - T_air_or_upper) / r_a` | `H_bulk = rho c_p (t1 - t2) / r_a` | PHYSICALLY SIMPLIFIED | Uses two air levels, not measured surface temperature. |
| Bulk transfer / gradient transfer | Neutral gradient/bulk transfer | heat flux proportional to temperature difference and conductance | `r_a = log(z2/z1)/(k * velocity_scale)` then `H` above | PARTIAL MATCH | No stability correction term in default flux. |
| Neutral log-law `u*` from profile | Neutral log wind profile | `u* = k (u2 - u1)/log(z2/z1)` under neutral assumptions | exactly `k * (v2 - v1)/log(z2/z1)` | PHYSICALLY CONSISTENT AS NEUTRAL | Not absolute value; non-positive `u*` guarded to `NA`. |
| Roughness-derived `u*` | Neutral log-law with roughness | `u* = k u_ref / log(z_ref/z0)` | same using `z0` from `surface_type` or `obs_height` | PHYSICALLY CONSISTENT AS NEUTRAL | `z0` source is table/assumption; no displacement correction in Bulk roughness path. |
| Richardson number guard | Gradient Richardson stability screening | `Ri_g = (g/theta) (dtheta/dz)/(du/dz)^2` | `Ri_g = (g/theta_mean) * dtheta_dz/(du_dz^2)` | PHYSICALLY CONSISTENT AS DIAGNOSTIC | Used only as guard/filter; thresholds are implementation parameters. |
| MOST stability functions | Monin-Obukhov profile-gradient method | fluxes use `u*`, `L`, `phi_h/phi_q`, gradients | Implemented in `sensible_monin()` and `latent_monin()`, not Bulk | IMPLEMENTED ELSEWHERE | Monin/Profile is diagnostic and not forced to close A. |
| Latent heat residual | Energy-balance residual | `LE = A - H` | `latent_bulk_residual = rad_bal - soil_flux - sensible` | PHYSICALLY CONSISTENT AS ALGEBRA | Residual LE is not independent physical measurement. |
| Closure residual | Energy-balance diagnostic | `R_E = A - H - LE` | `closure_residual = available_energy - turbulent_sum` | PHYSICALLY CONSISTENT AS DIAGNOSTIC | Formal closure does not validate physical correctness. |

## 4. Bulk implementation map

| Function | File | Role | Actual formula / logic | Required inputs | Optional inputs | Output | Guard behavior | Tests | Physics classification |
|---|---|---|---|---|---|---|---|---|---|
| `sensible_bulk()` | `R/bulk.R` | S3 generic | Dispatches to default/weather_station methods. | first argument | `...` | method-specific | none | indirect | IMPLEMENTED |
| `sensible_bulk.default()` | `R/bulk.R` | Core H_bulk formula | `Delta T = t1 - t2`; `r_a = log(z2/z1)/(k velocity_scale)`; `H = rho cp Delta T/r_a` | `t1`, `t2`, `v1`, `z1`, `z2` | `v2`, `rho`, `cp`, `k`, `exchange_velocity`, thresholds, roughness inputs, `ri_guard`, `elev` | H vector | invalid heights stop; invalid velocities become `NA`; high absolute H warns | Bulk tests and equation contracts | PHYSICALLY SIMPLIFIED neutral bulk transfer |
| `sensible_bulk.weather_station()` | `R/bulk.R` | Wrapper | Checks field names; extracts optional fields; calls default method. | `t1`, `t2`, `v1`, `z1`, `z2` | `v2`, `elev`, `surface_type`, `obs_height` | H vector | missing required names stop | wrapper tests | IMPLEMENTED wrapper |
| `latent_bulk_residual()` | `R/bulk.R` | S3 generic | Dispatches to default/weather_station. | first argument | `...` | method-specific | none | indirect | IMPLEMENTED |
| `latent_bulk_residual.default()` | `R/bulk.R` | Residual LE formula | `LE = rad_bal - soil_flux - sensible` | `rad_bal`, `soil_flux`, `sensible` | `warn_threshold` | LE vector | high absolute LE warns only | Bulk tests, equation contracts | PHYSICALLY CONSISTENT AS ALGEBRA |
| `latent_bulk_residual.weather_station()` | `R/bulk.R` | Wrapper | Reads `rad_bal`, `soil_flux`; uses supplied sensible or computes `sensible_bulk()`. | `rad_bal`, `soil_flux`; Bulk fields if H not supplied | supplied `sensible`, Bulk options | LE vector | missing names stop; Bulk guards inherited | workflow tests | IMPLEMENTED wrapper |
| `turb_flux_bulk_residual()` | `R/bulk.R` | Combined Bulk workflow | Computes `sensible_bulk`; computes residual LE; writes both fields. | `t1`, `t2`, `v1`, `z1`, `z2`, `rad_bal`, `soil_flux` | all Bulk options via `...` | weather_station with Bulk outputs | missing names stop; no catch | Bulk workflow tests | Residual closure workflow |
| `turb_flux_calc()` | `R/turbulent_flux.R` | Full workflow includes Bulk | Full workflow calculates Bulk H and residual LE, then writes output fields. | all fields required by non-PT full methods | `pt_only` | weather_station with multiple methods | Penman error caught; others can abort | physics/workflow tests | Orchestration; physics inherited |
| `wind_mean` path | `R/bulk.R` | Default velocity scale | `v1` if `v2` absent; `(v1+v2)/2` if present | `v1` | `v2`, `min_wind` | velocity scale | `<= min_wind`, missing, non-finite -> `NA` | Bulk tests | PHYSICALLY SIMPLIFIED neutral conductance |
| `u_star_profile` path | `R/bulk.R` | Profile-derived `u*` | `u* = k(v2-v1)/log(z2/z1)` | `v1`, `v2`, `z1`, `z2` | `min_ustar` | velocity scale | missing `v2` stops; non-positive/small `u*` -> `NA` | exchange tests | Neutral log-law profile-like, not full MOST |
| `u_star_roughness` path | `R/bulk.R` | Roughness-derived `u*` | `u* = k u_ref/log(z_ref/z0)` | Bulk fields plus `surface_type` or `obs_height` | `v2`, `min_ustar` | velocity scale | missing roughness stops; invalid `z0`/`z_ref` -> `NA` | exchange tests | Neutral log-law roughness path |
| `ri_guard` path | `R/bulk.R` | Stability filter | computes `Ri_g`, classifies, filters invalid/very stable | Bulk fields plus `v2` | `elev`, thresholds | H vector with attributes | invalid/very_stable -> `NA`; valid H unchanged | stability tests | Diagnostic guard, not correction |
| roughness / obs_height path | `R/turbulence.R` | `z0` helper | `z0 = 0.1 obs_height` or surface lookup | `obs_height` or `surface_type` | none | roughness length | invalid surface errors | turbulence/exchange tests | Parameterized roughness assumption |

## 5. Bulk base physics

Exact implemented `H_bulk`:

```text
Delta T = t1 - t2
r_a = log(z2 / z1) / (k * velocity_scale)
H_bulk = rho * cp * Delta T / r_a
```

Best classification:

- a) bulk aerodynamic resistance method: TRUE.
- b) neutral gradient-transfer approximation: TRUE.
- c) MOST method: FALSE.
- d) hybrid didactic approximation: TRUE for Bulk-Residual workflow, because H
  is a simplified transfer estimate and LE is an algebraic residual.

Specific implementation answers:

- `Delta T` is lower-height air temperature minus upper-height air temperature:
  `t1 - t2`.
- `r_a` uses `log(z2/z1)` and a selected exchange velocity scale.
- Air density is assumed by default (`rho = 1.225`) in Bulk. It is not
  calculated unless the user overrides `rho`.
- `cp` is fixed by default (`cp = 1005`) in Bulk. It is not calculated.
- Bulk does not use `surface_temp`.
- Bulk sensible heat does not use available energy `A` directly.
- Bulk sensible heat knows nothing about LE before residual closure.

| Claim | True/False | Evidence | Explanation |
|---|---|---|---|
| Bulk computes H from a temperature gradient. | True | `sensible_bulk.default()` and tests | Uses `t1 - t2` over heights `z1`, `z2` through resistance. |
| Bulk computes LE independently. | False | `latent_bulk_residual.default()` | LE is residual: `Q* - B - H`. |
| Bulk uses MOST stability correction. | False | `sensible_bulk.Rd`, code | No `phi_h`, `phi_q`, or Monin length in Bulk H. |
| Bulk can use profile-derived `u*`. | True | `exchange_velocity = "u_star_profile"` tests | Only exchange scale changes. |
| Bulk is equivalent to Monin/Profile. | False | `test-monin-obukhov.R`, code | Monin/Profile has separate H/LE functions using stability/profile helpers. |
| Bulk residual closure validates `H_bulk`. | False | closure docs/tests | Closure is by residual LE construction. |
| Bulk residual closure only defines `LE_res`. | True | `latent_bulk_residual.default()` | `LE_res = A - H_bulk`. |

## 6. Bulk variants in detail

### 6.1 wind_mean variant

Exact formula:

```text
velocity_scale = v1                         if v2 missing
velocity_scale = (v1 + v2) / 2              if v2 supplied
r_a = log(z2/z1)/(k velocity_scale)
H_bulk = rho cp (t1 - t2)/r_a
```

Default behavior:

- This is the default `exchange_velocity`.
- If `v2` is missing, `v1` is used.
- Non-finite, missing, or `velocity_scale <= min_wind` rows become `NA`.

Physical interpretation:

- Neutral bulk/aerodynamic-resistance approximation.
- Physically defensible as a simple bulk conductance estimate when station
  heights and wind data are credible and stability effects are not dominant.
- Weak when stable stratification, weak wind, canopy/roughness effects, or
  advection dominate.

Tests:

- Default formula, sign, low wind and residual closure are tested.

### 6.2 u_star_profile variant

Exact formula:

```text
u* = k (v2 - v1) / log(z2/z1)
r_a = log(z2/z1)/(k u*)
H_bulk = rho cp (t1 - t2)/r_a
```

Required inputs:

- `v1`, `v2`, `z1`, `z2`, `t1`, `t2`.

Relation to neutral log-law:

- This is close to the neutral log-law profile expression for friction velocity.
- It is not full MOST because no Monin length or stability functions are applied
  to correct the heat flux.

Behavior when `v2 <= v1`:

- `u* <= 0`.
- Code sets the affected row to `NA` with a profile-derived friction velocity
  warning.

Tests:

- Formula, missing `v2`, non-positive `u*`, weather-station pass-through and
  workflow pass-through are tested.

### 6.3 u_star_roughness variant

Exact formula:

```text
z0 = turb_roughness_length(obs_height)
or
z0 = turb_roughness_length(surface_type)

u* = k u_ref / log(z_ref/z0)
r_a = log(z2/z1)/(k u*)
H_bulk = rho cp (t1 - t2)/r_a
```

`z0` source:

- `obs_height`: `z0 = 0.1 * obs_height`.
- `surface_type`: table lookup from `surface_properties$roughness_length`.
- If both are present in the wrapper object, `obs_height` is used.

Physical interpretation:

- Neutral log-law roughness path.
- Depends on roughness parameter assumptions.
- No displacement height correction is applied in this Bulk roughness path.

Missing/invalid behavior:

- Missing both `surface_type` and `obs_height` stops.
- Invalid `z0`, non-finite `z0`, `z0 <= 0`, `z_ref <= z0`, or invalid/small
  `u*` rows become `NA`.

Tests:

- Formula, missing roughness source, and weather-station pass-through are tested.

### 6.4 ri_guard / stability guard

`Ri_g` is calculated when `stability_method = "ri_guard"`.

Formula:

```text
Ri_g = (g / theta_mean) * (Delta theta / Delta z) / (Delta u / Delta z)^2
```

Thresholds:

- `ri_neutral = 0.01`.
- `ri_critical = 0.25`.
- `Ri_g < 0`: unstable.
- `abs(Ri_g) <= ri_neutral`: neutral.
- `ri_neutral < Ri_g < ri_critical`: stable.
- `Ri_g >= ri_critical`: very stable.

Correction or filter?

- Filter only.
- The neutral H estimate is not rescaled for valid cases.
- Invalid or very stable cases become `NA`.
- `bulk_Ri_g` and `bulk_stability` attributes are attached.

Stability functions:

- No MOST stability functions are applied in Bulk `ri_guard`.

Tests:

- Tests verify `ri_guard` requires `v2`, valid classes remain finite, very
  stable/zero shear become `NA`, invalid rows are local, and attributes are
  present.

Bulk stability verdict:

- correction? No.
- guard? Yes.
- diagnostic? Yes.
- not MOST? Yes.

## 7. Bulk versus MOST

| Aspect | Bulk implementation | MOST / Monin-Obukhov implementation | Consequence |
|---|---|---|---|
| Governing assumption | Neutral bulk transfer / aerodynamic resistance. | Profile-gradient stability framework with Monin length and stability functions. | Bulk is simpler and not full MOST. |
| Wind profile | Mean wind, profile-derived `u*`, or roughness-derived `u*`. | `u*`, `z0`, Monin length and stability-dependent terms. | `u_star_profile` is closest to neutral log-law. |
| Temperature gradient | `t1 - t2` in Bulk H formula. | Potential-temperature gradient `(theta2 - theta1)/(z2 - z1)`. | Monin/Profile treats profile gradient explicitly. |
| Humidity gradient | Not used in Bulk H; LE is residual. | `latent_monin()` uses specific-humidity gradient. | Bulk does not estimate LE from humidity gradient. |
| `u*` | Optional exchange velocity scale. | Central profile/stability quantity. | Same symbol can appear, but role differs. |
| `z0` | Used only in roughness-derived `u*` path. | Used in roughness/friction and Monin helper paths. | Bulk roughness path is neutral. |
| Stability functions | Not used. | `phi_h`, `phi_q` implemented in `sensible_monin()`/`latent_monin()`. | Bulk should not be described as stability-corrected. |
| Monin-Obukhov length | Not used in Bulk. | `turb_flux_monin()` supplies Monin length. | Full profile/stability method is separate. |
| Richardson number | Optional guard/filter only. | Used as diagnostic/classification and in Monin helper logic. | Bulk `ri_guard` does not correct flux. |
| Closure behavior | Bulk-Residual closes by residual LE. | Monin/Profile not forced to close `A`. | Different closure semantics. |
| Required inputs | Minimal: `t1`, `t2`, `v1`, heights; plus energy for residual LE. | Requires temperature, humidity, wind profiles, heights, elevation and roughness source. | Monin/Profile is input-heavier. |
| Expected robustness | More transparent, less physically complete. | More physically structured but numerically/input demanding. | Bulk is useful for simple diagnostics/teaching, not as full MOST. |
| Valid use range | Neutral/coarse estimates, sensitivity comparisons, teaching residual closure. | Profile/stability diagnostic where profile inputs are credible. | Choose wording accordingly. |

Explicit answers:

- Bulk is close to neutral MOST only in the log-law-style exchange-velocity
  variants, especially `u_star_profile`.
- Bulk departs from MOST by not using Monin length, stability correction
  functions, displacement/roughness sublayer terms in Bulk H, or humidity
  gradients for LE.
- `u_star_profile` is the most profile-like Bulk variant.
- `wind_mean` is the most empirical/simple Bulk variant.
- `u_star_roughness` is neutral roughness/log-law based and depends on `z0`.
- Monin/Profile is the actual profile/stability method in the package.
- Bulk should not be described as MOST because the core stability machinery of
  MOST is not applied to Bulk H or LE.

## 8. Bulk-Residual closure

Implemented equation:

```text
LE_res = Q* - B - H_bulk
```

Therefore:

```text
R_E = Q* - B - H_bulk - LE_res
    = Q* - B - H_bulk - (Q* - B - H_bulk)
    = 0
```

Why this is algebraic closure:

- `LE_res` is defined as the remainder.
- The closure residual is forced by construction if all fields are finite and
  are computed consistently.

Why this is not physical validation:

- If `Q*` is biased, `LE_res` inherits that bias.
- If `B` is wrong, `LE_res` inherits that error.
- If `H_bulk` is physically inappropriate for the conditions, `LE_res` absorbs
  that error.
- `LE_res` is not independently constrained by humidity, vapor pressure,
  lysimeter, EC, or Penman data in this workflow.

Correct wording:

> Bulk-Residual estimates `H_bulk` with a neutral bulk-transfer approximation
> and assigns `LE_res` as the remaining available energy, `Q* - B - H_bulk`.
> The pair closes the balance algebraically. This formal closure does not
> validate the Bulk exchange assumption or the input energy terms.

## 9. Physically defensible use of Bulk

| Use case | Defensible? | Best Bulk variant | Reason | Main risk | Diagnostic check |
|---|---|---|---|---|---|
| Teaching energy partitioning | GOOD_USE | `wind_mean` or any variant | Algebraic residual closure is transparent. | Users may confuse closure with validation. | Show `R_E = 0 by definition`. |
| Quick H estimate from two-level station | ACCEPTABLE_WITH_CAUTION | `wind_mean` if only simple wind data; `u_star_profile` if two wind heights credible | Implementation needs only T gradient, wind and heights. | Stability/canopy/advection not corrected. | Warnings, `ri_guard`, compare with Monin/Profile. |
| Residual LE as closure demonstration | GOOD_USE | any finite Bulk H variant | `LE_res = A - H_bulk` is explicit. | Not independent evapotranspiration. | Closure diagnostic and text caveat. |
| Comparison against PT/Bowen/Monin | DIAGNOSTIC_ONLY | all variants can be compared | Differences reveal method sensitivity. | Not a ranking or validation. | `energy_balance_closure()` plus method-output inspection. |
| Stable nighttime conditions | NOT_RECOMMENDED unless screened | `ri_guard` if used | Very stable cases can be filtered. | Neutral Bulk invalid under strong stability; guard is not correction. | `bulk_stability`, `bulk_Ri_g`, `NA` rows. |
| Weak wind | NOT_RECOMMENDED | none | Aerodynamic resistance unstable; code returns `NA` for small velocity. | Division instability and weak turbulence. | low-wind warnings, `NA`. |
| Strong advection | DIAGNOSTIC_ONLY | none specifically | Bulk may not represent advective conditions. | Energy balance assumptions incomplete. | Compare against independent data if available; out of package. |
| Rough canopy / forest edge | ACCEPTABLE_WITH_CAUTION | `u_star_roughness` only if roughness assumption credible | Uses roughness table or obstacle height. | `z0` assumption, displacement and roughness sublayer not fully handled. | Sensitivity across variants. |
| Poor height metadata | NOT_RECOMMENDED | none | Formula depends directly on `z1`, `z2`, `log(z2/z1)`. | Wrong `r_a` and gradients. | Height guard only catches invalid values, not wrong metadata. |
| Uncertain `Q*` or `B` | DIAGNOSTIC_ONLY | any | H can still be computed, but residual LE and closure depend on A. | LE_res absorbs energy-input errors. | Inspect `Q*`, `B`; closure alone not enough. |
| Missing `v2` | ACCEPTABLE_WITH_CAUTION | `wind_mean` with `v1` only | Default supports `v1` alone. | No profile wind information; `ri_guard` and `u_star_profile` unavailable. | Document missing `v2`; compare if later available. |
| No roughness information | ACCEPTABLE_WITH_CAUTION | `wind_mean` or `u_star_profile` if `v2` exists | Roughness path not needed unless selected. | Cannot run `u_star_roughness`. | Do not invent `surface_type`/`obs_height`. |

## 10. Other algorithms: reference-based classification

| Method | Implemented formula | Reference family | Match level | Use | Limitation | Closure behavior |
|---|---|---|---|---|---|---|
| Priestley-Taylor | `LE = alpha sc/(sc+gam) A`; `H = A - LE` equivalent form | Priestley-Taylor available-energy partition | PHYSICALLY CONSISTENT structure; coefficient tables/source scale documented but alpha values remain table-validation open | Simple available-energy partition | Depends on surface alpha and package `sc/gam` table scale | Partition closure |
| Bowen Ratio | `beta = gamma_code * (Delta theta/Delta z)/(Delta AH/Delta z)`; `H=A beta/(1+beta)`, `LE=A/(1+beta)` | Bowen ratio energy partition | PHYSICALLY SIMPLIFIED / source-form-open for `gamma_code` | Gradient partition from T/RH profiles | Near-singular denominators; capped cases not exact closure | Formal closure only for finite uncapped denominator |
| Penman | Simplified Penman-Monteith-type LE combination equation | Penman/Penman-Monteith family | PHYSICALLY SIMPLIFIED; LE-only | Latent heat estimate | Resistance assumptions; no paired H | Open complement `A - LE_penman` |
| Monin/Profile | `H` and `LE` from profile gradients, `u*`, Monin length and Businger-type functions | MOST/profile-gradient family | IMPLEMENTED as profile/stability diagnostic; broader constants/source validation open | Diagnostic profile fluxes | Input-heavy, numerical guards, not energy-closed | Not forced to close; residual diagnostic |
| Closure diagnostics | `R_E = A - H - LE`; ratio; Penman complement | Energy-balance diagnostics | PHYSICALLY CONSISTENT as diagnostics | Make closure semantics explicit | Not a flux model, no validation | Reports formal closure/open complement/profile residual |

## 11. Exact wording for figure and documentation

### Bulk-Residual

Method equation:

```text
H_bulk = rho c_p (t1 - t2) / r_a
LE_res = Q* - B - H_bulk
```

Use:

```text
Neutral Bulk sensible-heat estimate followed by residual latent heat.
Exchange velocity can be mean wind, profile-derived u*, or roughness-derived u*.
```

Limitations:

```text
Not full MOST. No stability functions are applied to correct H_bulk. ri_guard
filters invalid or very stable cases only. LE_res absorbs errors in Q*, B and H_bulk.
```

Closure:

```text
H_bulk + LE_res = Q* - B by construction. Formal closure is not physical validation.
```

### Bulk vs MOST warning

```text
Bulk can use neutral log-law-style exchange scales, but it is not a full
Monin-Obukhov Similarity Theory method.
```

### Monin/Profile

```text
Monin/Profile uses two-height temperature, humidity and wind profiles with u*,
Monin length and stability functions. It is diagnostic and is not forced to
close Q* - B.
```

### Penman

```text
Penman returns latent heat only. The open complement Q* - B - LE_penman is not
sensible heat.
```

### Priestley-Taylor

```text
Priestley-Taylor partitions available energy A = Q* - B into H and LE using
surface-type alpha and package sc/gam coefficients.
```

### Bowen Ratio

```text
Bowen partitions A = Q* - B with beta from temperature and humidity gradients.
Finite uncapped cases close formally; singular/capped cases are guarded.
```

## 12. Do-not-say list

- Bulk equals MOST.
- `u_star_profile` makes Bulk a full MOST method.
- `ri_guard` is a full stability correction if it only filters.
- Bulk residual closure validates `H_bulk`.
- `LE_res` is an independent latent heat estimate.
- Penman complement is H.
- Monin/Profile should be forced to close.
- Passing tests prove physical correctness.
- Mixed `R_n/G` and `Q*/B` notation in the same figure.
- Closure residual zero proves physical adequacy.
- Bulk-Residual is equivalent to eddy covariance or empirical validation.

## 13. Final short verdict

1. The implemented Bulk algorithm estimates `H_bulk` from a two-level air
   temperature difference and a neutral exchange velocity scale.
2. The default exchange scale is mean wind; optional variants use
   profile-derived or roughness-derived friction velocity.
3. These variants are neutral/profile-like exchange-scale choices, not full
   MOST.
4. The optional Richardson guard calculates stability diagnostics and filters
   invalid or very stable rows; it does not correct valid fluxes.
5. Bulk does not compute LE independently.
6. Bulk-Residual defines `LE_res = Q* - B - H_bulk`.
7. Therefore Bulk-Residual closes algebraically by construction.
8. That closure does not validate `H_bulk`, `Q*`, `B`, or `LE_res`.
9. Physically, Bulk is useful for transparent neutral estimates, teaching, and
   diagnostics under documented caution.
10. It is not suitable to claim as MOST, EC validation, or independent latent
    heat estimation.

