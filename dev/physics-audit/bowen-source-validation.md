# Bowen Source And Unit Validation

Scope: source/unit validation for `sensible_bowen()` and `latent_bowen()` only. Inputs were `dev/physics-audit/physics-formula-audit.md`, `dev/physics-audit/physics-fix-plan.md`, `dev/physics-audit/bowen-beta-validation.md`, current implementation, generated Rd, Bowen tests, and Bowen-related vignette text.

## Summary

The exported Bowen functions implement an energy-partition method:

```text
A = Rn - G
H = A * beta / D
LE = A / D
D = 1 + beta, unless cap replaces near-zero D
```

The same `beta` path is used by `sensible_bowen()` and `latent_bowen()`. For finite uncapped denominators, closure is algebraic and confirmed:

```text
H + LE = Rn - G
```

The beta source form remains open. The exported functions use:

```text
beta = gamma_code * (Delta theta / Delta z) / (Delta AH / Delta z)
gamma_code = 0.00066 * (1 + 0.000946 * t1)
```

This can be dimensionally interpreted if `gamma_code` carries units `kg m-3 K-1`, but that unit is inferred rather than source-documented. A package-internal helper, `bowen_ratio()`, is source-referenced to Bendix and instead computes `heat_capacity(t) * dpot / (hum_evap_heat(t) * dah)`. The two coefficient forms are not numerically identical. Because the available package references do not prove which form was intended for the exported functions, this pass did not replace the beta formula.

Minimal numerical hardening was added: non-finite Bowen ratios or denominators now return `NA` for affected elements with a warning. Valid finite beta, cap, and closure behavior are unchanged.

## Implemented Formulas

### `sensible_bowen.default()`

Source: `R/sensible.R:300-335`.

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
  near_zero <- !invalid_partition & abs(denominator) < cap
  denominator[near_zero] <- ifelse(denominator[near_zero] < 0, -cap, cap)
}
out <- (rad_bal - soil_flux) * bowen_ratio / denominator
```

### `latent_bowen.default()`

Source: `R/latent.R:605-640`.

`latent_bowen.default()` repeats the same potential-temperature gradient, absolute-humidity gradient, `gamma_code`, `bowen_ratio`, denominator, and optional cap logic, then computes:

```r
out <- (rad_bal - soil_flux) / denominator
```

### Implemented beta

```text
theta1 = temp_pot_temp(t1, elev)
theta2 = temp_pot_temp(t2, elev)
dpot = (theta2 - theta1) / (z2 - z1)
AH1 = hum_absolute(hum1, t1)
AH2 = hum_absolute(hum2, t2)
dah = (AH2 - AH1) / (z2 - z1)
gamma_code = 0.00066 * (1 + 0.000946 * t1)
beta = gamma_code * dpot / dah
D = 1 + beta
```

## Unit Validation

| Quantity | Producing path | Unit | Finding | Status |
|---|---|---:|---|---|
| `theta1`, `theta2` | `temp_pot_temp(t, elev)` | deg C potential temperature; differences equivalent to K | Code uses potential temperature, not raw air temperature. | `implementation-specific` |
| `dpot` | `(theta2 - theta1) / (z2 - z1)` | K m-1 | Upper-minus-lower potential-temperature gradient. | `code-ok` for implementation |
| `AH1`, `AH2` | `hum_absolute(rh, temp)` | kg m-3 | RH inputs are converted to absolute humidity using vapour pressure and Kelvin temperature. | `code-ok` |
| `dah` | `(AH2 - AH1) / (z2 - z1)` | kg m-4 | Upper-minus-lower absolute-humidity gradient. | `implementation-specific` |
| `gamma_code` | `0.00066 * (1 + 0.000946 * t1)` | inferred kg m-3 K-1 if beta is dimensionless | Numeric coefficient is treated as empirical implementation coefficient; source equivalence is not proven. | `source-form-open` |
| `beta` | `gamma_code * dpot / dah` | dimensionless only by inferred `gamma_code` unit | Dimensionally interpretable, but not independently source-confirmed. | `source-form-open` |
| `Rn`, `G`, `H`, `LE` | `rad_bal`, `soil_flux`, output formulas | W m-2 | Package convention: `Rn > 0` radiative input, `G > 0` into soil. | `code-ok` |

With `dpot` in `K m-1` and `dah` in `kg m-4`, `dpot / dah` has units `K m3 kg-1`. To make `beta` dimensionless, `gamma_code` must carry `kg m-3 K-1`. This is physically plausible as a condensed empirical coefficient, but the package does not document a source derivation for the hard-coded expression.

## Source-Form Validation

Known package evidence:

- Current roxygen/Rd for `sensible_bowen()` and `latent_bowen()` describes the implemented formula honestly as a potential-temperature-gradient / absolute-humidity-gradient ratio with empirical `gamma_code`.
- `R/utility_turbulent_flux.R` contains an internal `bowen_ratio(t, dpot, dah)` helper with Bendix reference. It computes:

```r
heat_capacity(t) * dpot / (hum_evap_heat(t) * dah)
```

- `heat_capacity(t) / hum_evap_heat(t)` has units `kg m-3 K-1`, exactly the unit needed to make `dpot / dah` dimensionless.
- The exported Bowen functions do not call this helper and instead use `0.00066 * (1 + 0.000946 * t1)`.
- For representative inputs, the current `gamma_code` beta and helper-form beta are not numerically identical; this behavior is now locked by `tests/testthat/test-bowen-source.R`.

Classification: `source-form-open` with package-internal `code-mismatch` risk. The internal helper is strong evidence that a source-backed coefficient form exists in the package, but this validation pass does not have enough source-backed context to replace the exported formula without changing longstanding numeric behavior.

## Closure And Cap Behavior

| Case | Behavior | Status |
|---|---|---|
| Finite uncapped denominator | `H + LE = Rn - G` exactly within numeric tolerance. | `code-ok` |
| Near-zero denominator without cap | Output can be extreme and warnings may fire if values exceed +/-600 W m-2. | `implementation-specific` |
| Capped denominator | The denominator is replaced with `+/- cap`; `H + LE` is not required to equal `Rn - G`. | `code-ok` for documented guard behavior |
| Non-finite beta or denominator | Affected elements now return `NA` with warning. | `fixed` |

The cap is a numerical safeguard, not a physical event. It protects denominator division but deliberately changes the partition denominator, so exact closure is guaranteed only for finite uncapped denominators.

## Edge Cases

- Zero humidity gradient with zero temperature gradient can produce `0 / 0` in beta. This now returns `NA` with a warning rather than leaking `NaN`.
- Non-finite temperature or humidity inputs produce `NA` for affected vector elements, while valid vector elements remain finite.
- Small humidity gradients remain method-sensitive. If they create very large fluxes, existing high/low flux warnings still apply.
- Negative beta is allowed; it can produce negative sensible heat and latent heat greater than available energy when `-1 < beta < 0`. This is a mathematical consequence of the partition formula and is not by itself treated as a code failure.

## Test Coverage Added

`tests/testthat/test-bowen-source.R` adds contracts for:

1. shared beta pathway between sensible and latent Bowen;
2. finite non-singular closure to `Rn - G`;
3. capped cases being finite but not required to close;
4. zero humidity gradient returning controlled `NA` with warning;
5. sign behavior for positive and negative beta cases;
6. vector-local invalid input handling without uncontrolled `Inf`/`NaN`;
7. current `gamma_code` behavior being distinct from the internal helper form.

## Finding Classification

| Finding | Classification | Rationale |
|---|---|---|
| Shared beta path | `code-ok` | Both exported Bowen functions duplicate the same beta and denominator logic. |
| Uncapped closure | `code-ok` | Algebraic closure holds for finite uncapped denominators. |
| Capped closure exception | `code-ok` / `implementation-specific` | Cap changes denominator by design; closure is not required. |
| Potential-temperature gradient | `implementation-specific` | Code uses `temp_pot_temp()`; docs now state this. |
| Absolute-humidity gradient | `implementation-specific` | Code converts RH to absolute humidity; docs now state this. |
| `gamma_code` unit | `source-form-open` | Dimensionless beta requires inferred `kg m-3 K-1` coefficient units. |
| Exported beta versus internal helper | `source-form-open` / `code-mismatch` risk | Internal source-referenced helper uses `heat_capacity / hum_evap_heat`; exported functions use `gamma_code`. Equivalence is not proven. |
| Non-finite beta/denominator | `fixed` | Guard now returns `NA` with warning. |

## Decision Table

| Decision | Items |
|---|---|
| Safe documentation-only fixes | State the implemented `gamma_code` is empirical and source-form equivalence remains open; state non-finite beta returns `NA`; state cap closure exception. |
| Tests needed before formula fix | A source-backed numeric reference comparing exported beta to the Bendix/helper form. |
| Actual formula fix needed | Not implemented in this pass; potential future fix is to replace exported `gamma_code * dpot / dah` with the source-referenced helper form only if source validation confirms it. |
| Keep open | Whether the intended Bowen beta is `heat_capacity / L_v * dtheta / dAH`, `gamma / L_v * Delta T / Delta q`, vapour-pressure-gradient form, specific-humidity-gradient form, or the current empirical `gamma_code` form. |
