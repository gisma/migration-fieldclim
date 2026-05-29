# Monin-Obukhov Formula Validation And Numerical Hardening

Scope: Phase MO validation for `sensible_monin()`, `latent_monin()`, `turb_flux_grad_rich_no()`, and `turb_flux_stability()`.  
Inputs: `dev/physics-audit/physics-formula-audit.md`, `dev/physics-audit/physics-fix-plan.md`, implementation, generated Rd, tests, and vignette interpretation.  
Outcome: Monin-Obukhov remains diagnostic-only. No closure to `Rn - G` is enforced.

## Summary

Monin-Obukhov sensible and latent fluxes are profile/stability diagnostic estimates. They do not consume `rad_bal` or `soil_flux`, are not normalized to available energy, and must not be tested against `H_MO + LE_MO = Rn - G`.

Phase MO-2 resolved the `sensible_monin()` denominator mismatch as a local `code-mismatch`. The package documentation, generated Rd, vignette method text, `latent_monin()` profile-gradient logic, and `turb_flux_grad_rich_no()` all support a vertical gradient denominator `z2 - z1`. No local package source supports `log(z2 - z1)`, and a log-profile/MOST denominator would require an explicit term such as `log(z2 / z1)` rather than the logarithm of a dimensional height difference. The implementation was therefore changed from `(theta2 - theta1) / log(z2 - z1)` to `(theta2 - theta1) / (z2 - z1)`.

Numerical hardening was added for invalid heights, invalid wind speeds, weak wind shear in Richardson number, zero gradients, and vector-local invalid rows. Invalid profile rows return `NA` with warnings; valid rows remain valid.

## Function Audit Table

| Function | Source/formula category | Implemented formula after hardening | Documented formula | Inputs | Output | Units | Sign convention | Diagnostic-only? | Edge/warning logic | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| `sensible_monin()` | Foken / MOST / implementation-specific | `H = -rho * cp * (k * ustar * z2 / phi_h) * ((theta2 - theta1) / (z2 - z1))`; `theta = temp_pot_temp(t, elev)`; `s1 = z2 / L`; `phi_h = 0.74 * (1 - 9*s1)^-0.5` for `Ri <= 0`, `0.74 + 4.7*s1` for `Ri > 0` | `Q_h = -rho * cp * (k * u_* * z_2 / phi_h) * Delta theta / Delta z` | `t1`, `t2`, `z1`, `z2`, `v1`, `v2`, `elev`, optional `cap`, `surface_type` or `obs_height` | Sensible heat flux `H_MO`, W m-2 | degC inputs, potential-temperature difference equivalent to K, heights m, wind m s-1, density kg m-3, `cp` J kg-1 K-1 | Leading negative sign means warmer/moister lower profile can produce positive away-from-surface flux depending on gradient | Yes | Invalid heights/winds -> `NA` and warning; invalid numerical state -> `NA`; zero potential-temperature gradient -> `0`; high absolute flux warning remains | `code-ok` for denominator alignment with documented profile gradient; physical source validation remains `open` |
| `latent_monin()` | Foken / MOST / implementation-specific | `LE = -rho * Lv * ((k * ustar) / phi_q) * ((q2 - q1) / (z2 - z1))`; `q` from `hum_specific()`; `s1 = z2 / L`; `phi_q = 0.95 * (1 - 11.6*s1)^-0.5` for `Ri <= 0`, `0.95 + 7.8*s1` for `Ri > 0` | `Q_e = -rho * L_v * (k * u_* / phi_q) * Delta q / Delta z` | `hum1`, `hum2`, `t1`, `t2`, `z1`, `z2`, `v1`, `v2`, `elev`, optional `cap`, `surface_type` or `obs_height` | Latent heat flux `LE_MO`, W m-2 | RH %, degC, specific humidity kg kg-1, heights m, wind m s-1, `Lv` J kg-1 | Leading negative sign means lower-level moister air than upper-level air can produce positive away-from-surface `LE` | Yes | Invalid heights/winds -> `NA` and warning; invalid numerical state -> `NA`; zero moisture gradient -> `0`; high absolute flux warning remains | `code-ok` structurally; physical source validation remains `open` |
| `turb_flux_grad_rich_no()` | Foken / gradient Richardson / diagnostic | `Ri = (g / theta1) * ((theta2 - theta1)/(z2 - z1)) / (((v2 - v1)/(z2 - z1))^2)`; invalid rows become `NA` | Rd documents gradient Richardson number and stable/unstable interpretation | `t1`, `t2`, `z1`, `z2`, `v1`, `v2`, `elev`, `min_shear` | Dimensionless gradient Richardson number or `NA` | potential temperature K, heights m, wind m s-1 | Negative unstable, near-zero neutral, positive stable | Yes | Invalid heights/winds and weak shear warn and return `NA`; no `Inf`/`NaN` leaks | `code-ok` for numerical policy; source constants `open` |
| `turb_flux_stability()` | Foken / Richardson classification / diagnostic | finite `Ri <= -0.005 -> unstable`; `-0.005 < Ri < 0.005 -> neutral`; `Ri >= 0.005 -> stable`; non-finite -> `NA` | Rd documents conversion to stability string | gradient Richardson number | Stability class or `NA` | dimensionless input | Not a heat flux | Yes | Non-finite `Ri` returns `NA`, not silent stable/unstable | `code-ok` |

## Denominator Decision

Phase MO-2 classifies the previous denominator as a local `code-mismatch`.

Previous implementation:

```r
t_gradient <- (temp_pot_temp(t2, elev) - temp_pot_temp(t1, elev)) / log(z2 - z1)
```

Current implementation:

```r
t_gradient <- (temp_pot_temp(t2, elev) - temp_pot_temp(t1, elev)) / (z2 - z1)
```

Source-backed rationale from local package material:

- The roxygen/Rd formula documents `Delta theta / Delta z` and defines `Delta z` as the height difference between measurements.
- `latent_monin()` uses the analogous profile-gradient denominator `(z2 - z1)` for `Delta q / Delta z`.
- `turb_flux_grad_rich_no()` uses `(z2 - z1)` for both potential-temperature and wind-speed gradients.
- The method vignette describes MO/profile methods as vertical-gradient diagnostics; it does not define `log(z2 - z1)` as a MOST denominator.
- A log-profile/MOST denominator would need a source-backed expression such as `log(z2 / z1)` or another documented similarity term. The previous `log(z2 - z1)` took the logarithm of a dimensional height difference and was not supported by local documentation.

The old diagnostic-extreme behavior test for `sensible_monin(22, 21, 2, 10, 1, 2.3, 270, surface_type = "field")` was updated. With the documented vertical-gradient denominator, the fixture returns about `288.676 W m-2` and no longer triggers the high-flux warning.

## Gradient And Height Use

- `sensible_monin()` uses upper-minus-lower potential-temperature difference divided by `z2 - z1`, matching the documented `Delta theta / Delta z` profile gradient.
- `latent_monin()` uses upper-minus-lower moisture gradient from `hum_moisture_gradient()`: `(q2 - q1) / (z2 - z1)`.
- `turb_flux_grad_rich_no()` uses upper-minus-lower potential-temperature and wind-speed gradients divided by `z2 - z1`.
- `turb_flux_monin()` still supplies Monin-Obukhov length for the MO flux functions. This phase did not rewrite that helper.
- Invalid height conditions are `z1 <= 0`, `z2 <= 0`, `z2 <= z1`, or non-finite heights.

## Edge Policy

| Edge case | New behavior |
|---|---|
| Invalid heights | affected MO/Richardson elements return `NA`; warning once per function call |
| Low/invalid wind | affected MO/Richardson elements return `NA`; warning once per function call |
| Zero wind shear | Richardson returns `NA`; stability returns `NA`; MO functions return `NA` if the numerical state is invalid |
| Zero temperature gradient | `sensible_monin()` returns `0` for valid profile rows |
| Zero humidity gradient | `latent_monin()` returns `0` for valid profile rows |
| Vector-local invalid row | valid rows remain finite; invalid rows become `NA` |
| High absolute MO flux | existing diagnostic warnings remain; no empirical flux cap is applied |

## Test Coverage

Added `tests/testthat/test-monin-obukhov.R` covering:

- MO diagnostic-only contract: no `rad_bal` or `soil_flux` arguments and no closure assertion.
- normal finite `sensible_monin()` case.
- normal finite `latent_monin()` case.
- invalid heights for both MO functions.
- low/invalid wind for both MO functions.
- zero potential-temperature gradient and zero humidity gradient.
- vector-local invalid handling.
- Richardson sign cases, zero wind shear control, and stability classification for finite/non-finite values.

## Remaining Open Items

- Full physical validation of constants and Businger/Foken stability functions remains open.
- `turb_flux_monin()` was not rewritten; its source-form details remain implementation-specific and should be audited separately if future work changes Monin length behavior.
- MO remains a diagnostic method for profile/stability sensitivity. It is not an energy-closure method and should not be normalized to `Rn - G`.
