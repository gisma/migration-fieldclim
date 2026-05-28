# Bowen Beta Validation And Minimal Fix Proposal

Scope: Phase 3B validation for `sensible_bowen()` and `latent_bowen()` only.  
Inputs: `dev/physics-audit/physics-formula-audit.md`, `dev/physics-audit/physics-fix-plan.md`, implementation, generated Rd, tests, and Bowen vignette usage.  
Edit rule: no package source, tests, or Rd files changed in this pass.


## Documentation/Test Closure Update

- Documentation/test closure completed for the no-formula Phase 3B scope.
- Roxygen/Rd now describe the implemented beta as a potential-temperature-gradient / absolute-humidity-gradient ratio with empirical coefficient `0.00066 * (1 + 0.000946 * t1)`.
- `latent_bowen()` prose now states that high/low flux values warn and are not smoothed.
- Denominator capping is documented as a numerical safeguard; exact closure is documented only for finite uncapped denominators.
- Tests added in `tests/testthat/test-physics-contract.R` for fixed-gradient partition scaling and capped near-singular denominator behavior.
- Bowen beta source-form validation remains open: equivalence to `gamma / L_v * Delta T / Delta q`, the exact meaning/unit of `Delta q`, and physical magnitude validation still require source-backed validation.

## Summary

The implemented Bowen partition is algebraically consistent between `sensible_bowen()` and `latent_bowen()` when the denominator is not capped: both compute the same `beta`, use `denominator = 1 + beta`, and partition `rad_bal - soil_flux` into `H = A * beta / (1 + beta)` and `LE = A / (1 + beta)`, where `A = Rn - G`.

The open issue is the beta definition and documentation. The code implements an absolute-humidity-gradient form:

```r
t1_pot <- temp_pot_temp(t1, elev)
t2_pot <- temp_pot_temp(t2, elev)
dpot <- (t2_pot - t1_pot) / (z2 - z1)
af1 <- hum_absolute(hum1, t1)
af2 <- hum_absolute(hum2, t2)
dah <- (af2 - af1) / (z2 - z1)
gamma <- 0.00066 * (1 + 0.000946 * t1)
bowen_ratio <- gamma * dpot / dah
denominator <- 1 + bowen_ratio
```

The Rd documents a different-looking source form:

```text
B = gamma / L_v * Delta T / Delta q
```

The current audit cannot prove that these are equivalent without a source-backed unit derivation for `gamma = 0.00066 * (1 + 0.000946 * t1)` and for `Delta q` as absolute humidity rather than vapour pressure or specific humidity. Treat this as `open` / `documentation-mismatch` / `implementation-specific`, not as confirmed `code-ok` physics.

## Implemented Formula

### `sensible_bowen.default()`

Source: `R/sensible.R:244-274`.

```r
t1_pot <- temp_pot_temp(t1, elev)
t2_pot <- temp_pot_temp(t2, elev)
dpot <- (t2_pot - t1_pot) / (z2 - z1)
af1 <- hum_absolute(hum1, t1)
af2 <- hum_absolute(hum2, t2)
dah <- (af2 - af1) / (z2 - z1)
gamma <- 0.00066 * (1 + 0.000946 * t1)
bowen_ratio <- gamma * dpot / dah
denominator <- 1 + bowen_ratio
if (!is.null(cap)) {
  near_zero <- abs(denominator) < cap
  denominator[near_zero] <- ifelse(denominator[near_zero] < 0, -cap, cap)
}
out <- (rad_bal - soil_flux) * bowen_ratio / denominator
```

Implemented mathematical form:

```text
theta1 = temp_pot_temp(t1, elev)
theta2 = temp_pot_temp(t2, elev)
dtheta_dz = (theta2 - theta1) / (z2 - z1)
AH1 = hum_absolute(hum1, t1)
AH2 = hum_absolute(hum2, t2)
dAH_dz = (AH2 - AH1) / (z2 - z1)
gamma_code = 0.00066 * (1 + 0.000946 * t1)
beta = gamma_code * dtheta_dz / dAH_dz
H = (Rn - G) * beta / D
D = 1 + beta, unless cap is supplied and abs(D) < cap
```

### `latent_bowen.default()`

Source: `R/latent.R:539-570`.

`latent_bowen.default()` repeats the same `theta1`, `theta2`, `dpot`, `AH1`, `AH2`, `dah`, `gamma`, `bowen_ratio`, and `denominator` logic, then computes:

```r
out <- (rad_bal - soil_flux) / denominator
```

Implemented mathematical form:

```text
LE = (Rn - G) / D
D = 1 + beta, unless cap is supplied and abs(D) < cap
```

## Documented Formula

### `sensible_bowen.Rd`

Source: `man/sensible_bowen.Rd:61-78`, generated from `R/sensible.R:205-222`.

```text
Q_h = ((R_n - G) * B) / (1 + B)
B = gamma / L_v * Delta T / Delta q
```

The Rd says `gamma` is the psychrometric constant, `L_v` is latent heat of vaporization, `Delta T` is the temperature gradient, and `Delta q` is the moisture gradient.

### `latent_bowen.Rd`

Source: `man/latent_bowen.Rd:63-80`, generated from `R/latent.R:510-527`.

```text
Q_e = (R_n - G) / (1 + B)
B = gamma / L_v * Delta T / Delta q
```

The latent Rd also says values above `600 W m-2` and below `-600 W m-2` are recognized as measurement mistakes and smoothed (`man/latent_bowen.Rd:55-60`), but the implementation only warns; it does not smooth or cap output flux values (`R/latent.R:564-570`).

## Variable Table

| Variable | Producing helper/function | Implemented unit | Documented unit | Expected source formula role | Status |
|---|---|---|---|---|---|
| `t1` | User argument; weather-station lower temperature via wrapper | degC, lower height | degC, lower height | Lower-air temperature. Used directly in `gamma_code`, `hum_absolute()`, and `temp_pot_temp()` pressure conversion. | `code-ok` for argument role; source role in `gamma_code` `open` |
| `t2` | User argument; weather-station upper temperature via wrapper | degC, upper height | degC, upper height | Upper-air temperature. Used in potential-temperature and absolute-humidity gradients. | `code-ok` for argument role |
| `hum1` | User argument; lower relative humidity | percent RH | percent RH | Lower moisture input. Code converts to absolute humidity. | `code-ok` for argument role |
| `hum2` | User argument; upper relative humidity | percent RH | percent RH | Upper moisture input. Code converts to absolute humidity. | `code-ok` for argument role |
| `theta1`, `theta2` | `temp_pot_temp(t, elev)` at `R/sensible.R:246-247`, `R/latent.R:542-543`; helper formula at `R/temperature.R:36-41` | degC potential temperature; differences equivalent to K differences | Not documented in Bowen Rd | Potential-temperature gradient, not plain `Delta T`. | `implementation-specific`; documentation should say potential temperature if retained |
| `dpot` | `(t2_pot - t1_pot) / (z2 - z1)` at `R/sensible.R:248`, `R/latent.R:544` | K m-1 or degC m-1 difference | `Delta T` gradient, unspecified whether potential or air temperature | Temperature-gradient numerator of beta. Sign is upper minus lower. | `documentation-mismatch` |
| `AH1`, `AH2` | `hum_absolute(hum, temp)` at `R/sensible.R:251-252`, `R/latent.R:547-548`; helper at `R/humidity.R:66-70` | kg m-3 absolute humidity | Not explicitly documented; Rd only says `Delta q` moisture gradient | Moisture state converted from RH and temperature. | `implementation-specific` |
| `dah` | `(af2 - af1) / (z2 - z1)` at `R/sensible.R:253`, `R/latent.R:549` | kg m-4 | `Delta q` moisture gradient, no unit stated | Humidity-gradient denominator of beta. Sign is upper minus lower. | `documentation-mismatch` / `open` |
| `pres_vapor_p()` | Used by `hum_absolute()` at `R/humidity.R:67`; helper at `R/pressure.R:83-85` | hPa vapour pressure | hPa in pressure Rd | Intermediate only; absolute humidity formula uses hPa and Kelvin. | `code-ok` for helper unit |
| `gamma_code` | `0.00066 * (1 + 0.000946 * t1)` at `R/sensible.R:256`, `R/latent.R:552` | Inferred as approximately kg m-3 K-1 if beta is dimensionless with `dpot/dah`; not documented | Rd says psychrometric constant `gamma`, then divides by `L_v` | Empirical conversion coefficient for potential-temperature gradient over absolute-humidity gradient. | `open`; source/unit derivation needed |
| `L_v` | Not used in Bowen code; `hum_evap_heat()` exists at `R/humidity.R:104-105` but is not called | Not implemented in Bowen beta | latent heat of vaporization | Source formula factor in Rd. | `documentation-mismatch`; actual formula omits explicit `L_v` |
| `beta` / `bowen_ratio` | `gamma_code * dpot / dah` at `R/sensible.R:257`, `R/latent.R:553` | Dimensionless only if `gamma_code` has units kg m-3 K-1 | Dimensionless Bowen ratio | Partitions available energy. | `open` for physical units; `code-ok` for algebraic partition |
| `denominator` / `1 + beta` | `1 + bowen_ratio` at `R/sensible.R:259`, `R/latent.R:556` | Dimensionless if beta is dimensionless | Dimensionless | Partition denominator; singular near `beta = -1`. | `code-ok` algebraically; edge policy `open` |
| `cap` | Optional argument; denominator replacement at `R/sensible.R:260-264`, `R/latent.R:557-560` | dimensionless denominator lower bound | denominator lower bound | Numerical safeguard for near-zero denominator. | `implementation-specific`; docs should state closure exception |
| `rad_bal`, `soil_flux` | Arguments passed directly | W m-2 | W m-2 | Available energy `Rn - G`; package convention: `G > 0` into soil. | `code-ok` |

## Dimension And Equivalence Check

The code beta is:

```text
beta = gamma_code * (dtheta/dz) / (dAH/dz)
```

With `dtheta/dz` in `K m-1` and `dAH/dz` in `kg m-4`, the gradient ratio has units `K m3 kg-1`. For `beta` to be dimensionless, `gamma_code` must carry units `kg m-3 K-1`. The numeric expression `0.00066 * (1 + 0.000946 * t1)` could plausibly be an empirical coefficient in that unit family, but the code and Rd do not document that. It is not the same as explicitly using a psychrometric constant divided by latent heat.

Therefore:

- Code beta is dimensionless only by an inferred unit for `gamma_code`; this is `open`, not proven.
- The implemented humidity gradient is an absolute-humidity gradient, not a vapour-pressure gradient and not clearly a specific-humidity `Delta q` gradient.
- It may be physically equivalent to a source formula that defines `q` as absolute humidity and folds `L_v` and other constants into `gamma_code`, but that equivalence is not documented or source-validated here.
- The Rd expression `gamma / L_v * Delta T / Delta q` is not a literal description of the current implementation.

## Shared Beta And Denominator Logic

`sensible_bowen.default()` and `latent_bowen.default()` duplicate the same beta sequence:

- potential-temperature gradient: `R/sensible.R:245-248`, `R/latent.R:541-544`
- absolute-humidity gradient: `R/sensible.R:250-253`, `R/latent.R:546-549`
- `gamma_code`: `R/sensible.R:256`, `R/latent.R:552`
- `bowen_ratio`: `R/sensible.R:257`, `R/latent.R:553`
- denominator: `R/sensible.R:259`, `R/latent.R:556`
- optional denominator cap: `R/sensible.R:260-264`, `R/latent.R:557-560`

They therefore use exactly the same formula and denominator policy by duplicated code. Formal closure holds for uncapped finite denominators and is already protected by `tests/testthat/test-physics-contract.R:95-113`.

## Denominator Capping And Closure

Let `A = Rn - G` and `D0 = 1 + beta`.

Without cap:

```text
H + LE = A * beta / D0 + A / D0 = A * (beta + 1) / (1 + beta) = A
```

With cap active, the denominator becomes `Dcap = +/- cap`, while the numerators remain `A * beta` and `A`:

```text
H + LE = A * (beta + 1) / Dcap = A * D0 / Dcap
```

Closure is no longer guaranteed unless `Dcap == D0`. This is best classified as intended numerical safeguarding, not a direct formula mismatch, if the package explicitly documents that capped Bowen outputs are diagnostic/guarded and may not close available energy exactly.

Current documentation is incomplete: it says cap prevents near-zero division, but it does not state that denominator capping can break exact closure. The latent Rd also claims smoothing of extreme values, which is not implemented.

## Test And Vignette Evidence

- `tests/testthat/test-physics-contract.R:95-113` checks `sensible_bowen() + latent_bowen() = rad_bal - soil_flux` only for a non-singular uncapped case.
- `dev/physics-audit/physics-formula-audit.md:940-941` records both Bowen functions as formally closing outside capped/singular cases but open for beta definition and units.
- `dev/physics-audit/physics-formula-audit.md:961-967` records the same beta mismatch and cap/closure caveat.
- `dev/physics-audit/physics-fix-plan.md:64-65` keeps Bowen beta units and denominator cap policy open.
- The vignette describes Bowen as a gradient-ratio partition method and warns about near-zero `1 + beta` and gradient sensitivity (`vignettes/fieldclim_usecase.Rmd:626-644`). This is consistent with the implementation at a conceptual level but does not validate the exact beta units.

## Finding Classification

| Finding | Classification | Rationale |
|---|---|---|
| Energy partition formulas `H = A * beta / (1 + beta)` and `LE = A / (1 + beta)` | `code-ok` | Implemented and documented consistently for uncapped denominator. |
| Shared beta/denominator logic across sensible and latent Bowen | `code-ok` | Both functions duplicate the same beta and denominator computation. |
| Formal closure when cap is inactive and denominator finite | `code-ok` | Algebraic closure holds and is tested. |
| Potential-temperature gradient used instead of plain air-temperature gradient | `implementation-specific` / `documentation-mismatch` | Code uses `temp_pot_temp()`, while Rd says only `Delta T`. |
| Absolute-humidity gradient used for `Delta q` | `implementation-specific` / `open` | Code uses `hum_absolute()` in kg m-3; Rd does not define `q` or units. |
| Omission of explicit `L_v` in code beta | `documentation-mismatch` / `open` | Rd says `gamma / L_v`; code uses a single empirical `gamma_code`. Source equivalence is not proven. |
| Dimensionless beta | `open` | Dimensionless only if `gamma_code` is interpreted as kg m-3 K-1; this is not documented or source-validated. |
| Denominator capping | `implementation-specific` | Cap is a numerical safeguard; it can break exact closure and should be documented/tested explicitly. |
| Latent Bowen smoothing prose | `documentation-mismatch` | Implementation warns for high/low flux but does not smooth output values. |

## Minimal Fix Proposal

Do not change the formula until source validation resolves `gamma_code`, absolute humidity, and the intended `Delta q` definition.

Minimal no-formula fix after tests:

1. Add tests for denominator-cap behavior: one uncapped non-singular closure case already exists; add a near-singular capped case that asserts finite guarded output and explicitly does not assert closure.
2. Add a test that `sensible_bowen()` and `latent_bowen()` use the same beta/denominator logic for a representative case, preferably by comparing closure and sign behavior rather than duplicating private internals.
3. Update Rd wording to describe the implemented beta as potential-temperature gradient divided by absolute-humidity gradient with empirical coefficient `0.00066 * (1 + 0.000946 * t1)`, unless source validation proves the documented `gamma / L_v * Delta T / Delta q` form is exactly equivalent.
4. Remove or correct the latent Bowen smoothing prose: current behavior is warning only plus optional denominator cap, not smoothing of flux values.
5. Document that denominator capping is a numerical safeguard and exact closure is guaranteed only for finite uncapped denominators.

## Decision Table

| Decision | Items | Minimal next action |
|---|---|---|
| Safe documentation-only fixes | Latent smoothing prose; explicit statement that cap changes denominator only and may break exact closure; `Delta T` should be described as potential-temperature gradient if formula is retained | Update roxygen/Rd after adding cap-behavior tests or as a low-risk doc correction. |
| Tests needed before code fix | Near-singular/capped denominator behavior; same-beta partition behavior; sign behavior for representative gradients | Add focused tests before changing formula or cap policy. |
| Actual formula fix needed | None confirmed in this pass | No code fix is justified without source-backed validation of the intended Bowen beta units. |
| Keep open | Whether `gamma_code * dpot / dah` is source-equivalent to `gamma / L_v * Delta T / Delta q`; whether `Delta q` should be absolute humidity, specific humidity, or vapour pressure; physical magnitude validation | Resolve against Bendix/source equation and a numeric reference case before formula changes. |
