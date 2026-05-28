# Penman Unit And Sign Validation

Scope: Phase 3A validation for `latent_penman()` and `latent_penman.weather_station()` only.  
Inputs: `dev/physics-audit/physics-formula-audit.md`, `dev/physics-audit/physics-fix-plan.md`, implementation, generated Rd, tests, and Penman vignette usage.  
Edit rule for original validation: no package source, tests, or Rd files changed.  
Closure update: the minimal unit fix has now been implemented in `R/latent.R`, with focused tests in `tests/testthat/test-penman.R`.

## Closure Update After Unit Patch

- Changed file: `R/latent.R`.
- Tests added: `tests/testthat/test-penman.R`.
- Old Caldern Penman mean: `62.81968`.
- New Caldern Penman mean: `13.22542`.
- `Delta` / `gamma` versus VPD pressure-scale mismatch: **fixed**. `pres_sat_vapor_p()` and `pres_vapor_p()` remain hPa-returning helpers; `latent_penman.default()` now converts `e_s` and `e_a` to kPa and uses `vpd_kPa` in the aerodynamic term.
- Remaining open items: `hum1`/`rh` routing, aerodynamic resistance edge/source convention, exact Penman source-form validation, and final physical magnitude validation.

## Implemented Formula

`latent_penman.default()` implements the following sequence:

```r
cp <- 1004
rho <- 1.2
gamma <- 0.665 * 10^(-3) * pres_p(elev, temp)
es_hPa <- pres_sat_vapor_p(temp)
ea_hPa <- pres_vapor_p(temp, rh)
es_kPa <- es_hPa / 10
ea_kPa <- ea_hPa / 10
vpd_kPa <- es_kPa - ea_kPa
delta <- 4098 * es_kPa / ((temp + 237.3)^2)
d <- turb_displacement(obs_height, surroundings = "vegetation")
zom <- 0.123 * obs_height
zoh <- 0.1 * zom
ra <- (log(log_arg1) * log(log_arg2)) / (k^2 * v)
Rn <- rad_bal
G <- soil_flux
Qe <- (delta * (Rn - G) + gamma * (cp * rho / ra) * vpd_kPa) /
  (delta + gamma * (1 + rs / ra))
lv <- hum_evap_heat(temp)
out <- (Qe / lv) * lv
```

Formula as implemented:

\[
Q_e = \frac{\Delta (R_n - G) + \gamma \frac{c_p \rho}{r_a}(e_s - e_a)}{\Delta + \gamma(1 + r_s/r_a)}
\]

The `lv` division/multiplication cancels, so the returned value is `Qe` in the implementation. Source references: `R/latent.R:216-254`; documented formula: `R/latent.R:140-153`, `man/latent_penman.Rd`.

## Variable Unit Table

| Variable | Produced by | Expected unit for internally consistent Penman expression | Implemented unit | Scale classification | Status |
|---|---|---|---|---|---|
| `Delta` / `delta` | `delta <- 4098 * es_kPa / ((temp + 237.3)^2)` in `R/latent.R` after explicit hPa-to-kPa conversion | Same pressure scale as `gamma`; if `gamma` is kPa K-1, `Delta` should be kPa K-1 | `es_hPa` is converted to `es_kPa`; `delta` is kPa degC-1 scale | kPa-scale | `code-ok`; pressure-scale mismatch fixed |
| `gamma` | `gamma <- 0.665 * 10^(-3) * pres_p(elev, temp)` at `R/latent.R:219`; `pres_p()` returns hPa at `R/pressure.R:37-41` | Same pressure scale as `Delta`; commonly kPa degC-1 if pressure is kPa | `0.665e-3 * hPa`, numerically equivalent to `0.000665 * hPa = 0.0665` at 1000 hPa, i.e. kPa degC-1 scale | kPa-scale | `code-ok` for kPa-scale magnitude; documentation does not spell out unit interaction |
| `e_s` | `es_hPa <- pres_sat_vapor_p(temp)` followed by `es_kPa <- es_hPa / 10` in `R/latent.R`; helper returns hPa | Vapour-pressure term must use same pressure scale expected by the aerodynamic term | Helper output hPa; Penman internal value kPa | hPa helper, kPa in formula | `code-ok`; conversion fixed |
| `e_a` | `ea_hPa <- pres_vapor_p(temp, rh)` followed by `ea_kPa <- ea_hPa / 10` in `R/latent.R`; helper returns hPa | Same as `e_s` | Helper output hPa; Penman internal value kPa | hPa helper, kPa in formula | `code-ok`; conversion fixed |
| `e_s - e_a` / `vpd_kPa` | `vpd_kPa <- es_kPa - ea_kPa`, then `vpd_kPa` inside `Qe` in `R/latent.R` | Consistent with kPa-scale `Delta` and `gamma` | kPa | kPa-scale | `code-ok`; pressure-scale mismatch fixed |
| `Rn` | `Rn <- rad_bal` at `R/latent.R:242-244` | W m-2 | W m-2 | W m-2 | `code-ok` |
| `G` | `G <- soil_flux` at `R/latent.R:242-244` | W m-2; positive into soil under package convention | W m-2 | W m-2 | `code-ok` |
| `rho` | `rho <- 1.2` at `R/latent.R:218` | kg m-3 | kg m-3 constant | kg m-3 | `code-ok` as fixed constant; physical adequacy open |
| `cp` | `cp <- 1004` at `R/latent.R:217` | J kg-1 K-1 | J kg-1 K-1 constant | J kg-1 K-1 | `code-ok` as fixed constant |
| `ra` | log-resistance calculation at `R/latent.R:228-240` using `z`, `obs_height`, `v`, and `k` | s m-1 | `(dimensionless logs) / (dimensionless * m s-1)` = s m-1 | s m-1 | `code-ok` for unit dimension; vector/scalar guard behavior open |
| `rs` | lookup in `surface_resistance$rs` at `R/latent.R:203-208`; table in `R/utility.R:92-109` | s m-1 | Numeric table values 30-80, used as s m-1 | s m-1 | `code-ok` for valid mapped classes |
| `lv` | `hum_evap_heat(temp)` at `R/latent.R:249-254`; helper at `R/humidity.R:101-105` | J kg-1 | J kg-1 | J kg-1 | Neutral for final output because division and multiplication cancel |

## Specific Checks

### Delta and Gamma scale

`Delta` is kPa-scale because `pres_sat_vapor_p()` returns hPa and the implementation divides `es` by `10` before applying the saturation-curve slope formula (`R/latent.R:222`, `R/latent.R:225-226`; helper at `R/pressure.R:130-131`).

`gamma` is also kPa-scale by magnitude. `pres_p()` returns hPa (`R/pressure.R:37-41`), and multiplying by `0.665e-3` gives the standard kPa degC-1 magnitude when pressure is supplied in hPa (`R/latent.R:219`).

Classification: `code-ok` for both being kPa-scale relative to each other.

### Vapour-pressure deficit scale

`e_s` and `e_a` are hPa-scale by helper documentation and implementation: `pres_sat_vapor_p()` returns hPa and `pres_vapor_p()` multiplies that hPa value by `rh / 100` (`R/pressure.R:83-85`, `R/pressure.R:130-131`, `man/latent_penman.Rd`). After the unit patch, `latent_penman.default()` converts both helper outputs to kPa and uses `vpd_kPa` in the implemented `Qe` formula.

Classification: `code-ok` after patch. `Delta`, `gamma`, and VPD are now all kPa-scale inside `latent_penman.default()`.

### Aerodynamic term

The aerodynamic numerator term is:

\[
\gamma \frac{c_p \rho}{r_a}(e_s - e_a)
\]

The implementation now combines kPa-scale `gamma` with kPa-scale `vpd_kPa` after explicit hPa-to-kPa conversion. The pressure scale in the aerodynamic term is therefore internally consistent with `Delta`/`gamma`.

Classification: `code-ok` for pressure-scale consistency after patch. The patch keeps the existing Penman structure and gamma factor unchanged; exact source-form validation remains open.

### Energy term and sign convention

The energy term uses `Rn - G` exactly: `Rn <- rad_bal`, `G <- soil_flux`, and `delta * (Rn - G)` (`R/latent.R:242-247`). This matches the package convention from the audit: `Rn > 0` is net radiative input at the surface, `G > 0` is heat flux into the soil, and `Rn - G` is available turbulent energy.

Classification: `code-ok` for package sign convention in the energy term.

### Output unit and sign

`Qe` is already the returned numerical value because `out <- Qe / lv` followed by `out <- out * lv` cancels (`R/latent.R:249-254`). Therefore the implementation returns a heat-flux-like value in W m-2 if the formula terms are made unit-consistent. The current contract tests require vector length and at least one finite value, not physical magnitude.

The Penman roxygen documentation has been updated to the package convention: positive `LE` is flux away from the surface, while negative `LE` indicates flux toward the surface or a condensation-like direction depending on context.

Classification: `code-ok` for sign documentation after roxygen update; final physical magnitude validation remains open.

## Weather-Station Wrapper Check

| Wrapper item | Evidence | Finding | Status |
|---|---|---|---|
| `surface_type = "field"` mapping | `.normalize_penman_surface_type()` maps `"field"` to `"Temperate grassland"` at `R/latent.R:88-106`; `"Temperate grassland"` exists in `surface_resistance` at `R/utility.R:92-109`; tests cover finite output for field surface at `tests/testthat/test-consolidation.R:160-192` and `tests/testthat/test-physics-contract.R:116-123` | Valid mapped Penman resistance class | `code-ok` |
| `hum1` / `rh` routing | wrapper requires `rh` or `hum1`, prefers `hum1`, and passes selected value as `rh` to the default method at `R/latent.R:285-302`, `R/latent.R:315-329` | Internally valid only when `hum1` is relative humidity in percent. This matches Monin/profile naming in current package usage, but the wrapper name can be ambiguous outside that convention | `wrapper-mismatch` / `open` |
| `z` / `obs_height` routing | wrapper passes `z <- weather_station$z1` as measurement height and `obs_height <- weather_station$obs_height` separately at `R/latent.R:304-310`, then forwards both at `R/latent.R:315-329` | Routing is explicit and consistent with argument names. The local vector guard now returns `NA` for invalid aerodynamic-resistance elements; source-backed edge convention remains outside this validation | `code-ok` for routing and local guard behavior; source edge convention `open` |
| Required fields | wrapper calls `check_availability()` for `datetime`, `v1`, `temp`, `z1`, `rad_bal`, `elev`, `lat`, `lon`, `soil_flux`, `obs_height`, `surface_type` at `R/latent.R:270-283` | Required field names match the default method inputs after wrapper mapping. No unit validation is performed | `code-ok` for name routing; unit validation `open` |

## Vignette And Test Interpretation

- Contract tests treat Penman as LE-only: `tests/testthat/test-physics-contract.R:116-123` checks `latent_penman(ws)` length and finite values and does not expect a paired sensible Penman field.
- Consolidation tests check `surface_type = "field"` mapping and finite output, not unit-correct magnitude: `tests/testthat/test-consolidation.R:160-192`.
- The use-case vignette describes Penman as a combination approach for latent heat only and uses `Q_star - B` as the energy term (`vignettes/fieldclim_usecase.Rmd:672-690`, `vignettes/fieldclim_usecase.Rmd:903-908`, `vignettes/fieldclim_usecase.Rmd:945`). This interpretation is consistent with LE-only behavior; final physical magnitude validation remains open after the hPa/kPa aerodynamic-term fix.

## Finding Classification

| Finding | Classification | Rationale |
|---|---|---|
| `Rn - G` energy term | `code-ok` | Directly implemented with `rad_bal - soil_flux` and matches package convention. |
| `surface_type = "field"` | `code-ok` | Maps to `Temperate grassland`, which has a valid `rs`. |
| LE-only behavior | `code-ok` | Function returns only latent heat flux; tests and vignettes do not expect Penman `H`. |
| Penman sign prose | `code-ok` after documentation update | Roxygen now follows the package convention: positive `LE` away from the surface. |
| `Delta`/`gamma` versus VPD pressure scale | `fixed` | `Delta`, `gamma`, and `vpd_kPa` are kPa-scale inside `latent_penman.default()`. |
| `hum1` passed as `rh` | `wrapper-mismatch` / `open` | Correct only under the current convention that `hum1` is relative humidity in percent. Needs explicit contract before changing wrapper or docs. |
| `z` and `obs_height` routing | `code-ok` for routing; `open` for edge behavior | Wrapper passes distinct fields consistently; aerodynamic resistance edge/vector handling remains separate. |
| Output magnitude | `open` | Pressure-scale mismatch is fixed, but final physical magnitude still requires source-backed reference validation. |

## Minimal Decision Table

| Decision | Items | Next action |
|---|---|---|
| Safe to document only | LE-only Penman behavior; `field` maps to `Temperate grassland`; energy term uses `Rn - G`; sign prose after unit patch | Documentation can state LE-only behavior, package sign convention, and kPa-scale internal VPD handling. |
| Needs test before fix | `hum1` versus `rh` routing; remaining aerodynamic resistance source/edge behavior | Add focused tests for wrapper humidity precedence and source-backed aerodynamic resistance behavior before further changes. |
| Fixed | Aerodynamic VPD pressure scale | Implemented explicit hPa-to-kPa conversion and `vpd_kPa` in `R/latent.R`; covered by `tests/testthat/test-penman.R`. |
| Keep open | Exact Penman-Monteith source convention for the numerator form with `gamma * cp * rho / ra`; aerodynamic resistance edge cases; final expected magnitude | Resolve with source-backed formula decision and numeric reference case. |
