# Priestley-Taylor Helper And Source Validation

Scope: `latent_priestley_taylor()`, `sensible_priestley_taylor()`, `sc()`, `gam()`, and the internal `priestley_taylor_coefficient` table. Inputs were `dev/physics-audit/physics-formula-audit.md`, `dev/physics-audit/physics-fix-plan.md`, `dev/physics-audit/soil-thermal-validation.md` for status consistency, implementation, generated Rd, tests, and PT-related vignette text.

## Policy

- PT closure logic is unchanged.
- Package convention remains: `Rn > 0` is net radiative input, `G > 0` is soil heat flux into soil, and PT partitions `Rn - G`.
- Helper formulas and coefficient table values were not replaced.
- `sc()` and `gam()` are commensurable Foken/Stull table-scale polynomial coefficients in this package. Their source scale is specific humidity, `kg kg-1 K-1`; they are not Pa/K, hPa/K, kPa/K, or FAO-56 psychrometric constants.

## Function Audit Table

| Item | Source/formula category | Implemented formula | Documented formula | Inputs and units | Output and units | Sign convention | Closure invariant | Edge/warning logic | Status |
|---|---|---|---|---|---|---|---|---|---|
| `latent_priestley_taylor()` | Foken / Priestley-Taylor | `LE = alpha * sc(temp) / (sc(temp) + gam(temp)) * (rad_bal - soil_flux)` | `Q_e = alpha_PT * Delta / (Delta + gamma) * (R_n - G)` | `temp` degC; `rad_bal`, `soil_flux` W m-2; `surface_type` table label | latent heat flux W m-2 | positive away from surface; negative toward surface | with matching sensible call, `LE + H = Rn - G` | invalid surface type errors; warns if output > 600 or < -600 W m-2 | `code-ok` for closure/sign; helper/source units `open` |
| `sensible_priestley_taylor()` | Foken / Priestley-Taylor residual form | `H = (((1 - alpha) * sc(temp) + gam(temp)) / (sc(temp) + gam(temp))) * (rad_bal - soil_flux)` | same algebraic partition; documented as sensible PT formula | `temp` degC; `rad_bal`, `soil_flux` W m-2; `surface_type` table label | sensible heat flux W m-2 | positive away from surface; negative toward surface | algebraically equivalent to `(Rn - G) - LE` when inputs match | invalid surface type errors; warns if output > 600 or < -600 W m-2 | `code-ok` for closure/sign; helper/source units `open` |
| `sc()` | Foken/Stull Table 6 polynomial | `8.5e-7 * (t + 273.15)^2 - 0.0004479 * (t + 273.15) + 0.05919` | internal noRd docs: Foken/Stull Table 6 specific-humidity-scale slope coefficient | `t` degC, converted internally to K in polynomial | Foken/Stull table-scale slope coefficient, kg kg-1 K-1 | not a flux | used only in ratio with `gam()` | finite positive and increasing for normal temperatures; `NA -> NA`; `Inf -> NaN` | `source-table tested`; FAO-56 equivalence not applicable |
| `gam()` | Foken/Stull Table 6 polynomial | `0.0004 + (0.00041491 - 0.0004) / (1 + (299.44 / (t + 273.15))^383.4)` | internal noRd docs: Foken/Stull Table 6 specific-humidity-scale psychrometric coefficient | `t` degC, converted internally to K in polynomial | Foken/Stull table-scale psychrometric coefficient, kg kg-1 K-1 | not a flux | used only in ratio with `sc()` | finite positive for normal temperatures; `NA -> NA`; `Inf -> 0.00041491` | `source-table tested`; FAO-56 equivalence not applicable |
| `priestley_taylor_coefficient` | Priestley-Taylor / implementation-specific table | surface table: `field=1.12`, `bare soil=1.04`, `coniferous forest=1.13`, `water=1.26`, `wetland=1.26`, `spruce forest=1.72` | PT docs state coefficient selected from predefined values | `surface_type` string | dimensionless alpha coefficient | not a flux | same alpha must be used by LE and H for closure | invalid scalar surface type errors with allowed values; vectorized surface_type is not supported cleanly by scalar `if` logic | table values/source remain `open`; scalar behavior contract tested |

## Helper Unit Conclusion

`sc()` returns a finite positive slope-like coefficient for typical air temperatures and increases from 0 to 30 degC. At 20 degC it is about `9.344991e-04`. Source-table validation against Foken (2013), p. 48, Table 6, after Stull (1988), confirms this is a specific-humidity-scale coefficient in `kg kg-1 K-1`, not the usual kPa/K saturation-vapour-pressure slope scale. It is used only with `gam()` in a dimensionless ratio.

`gam()` returns a positive psychrometric-like coefficient near `4.0e-04` to `4.15e-04` over normal temperatures. It has no explicit pressure dependence because it is not the FAO-56 psychrometric constant in kPa K-1. Source-table validation against Foken (2013), p. 48, Table 6, after Stull (1988), confirms the package helper is on the same specific-humidity scale as `sc()`, in `kg kg-1 K-1`.

| Classification | Value |
|---|---|
| provenance | source-documented |
| source | Foken (2013), p. 48, Table 6, after Stull (1988) |
| unit scale | specific humidity scale, kg kg-1 K-1 |
| FAO-56 equivalence | not applicable; `gam()` is not the FAO-56 psychrometric constant in kPa K-1 |
| status | source-table tested |

## Alpha Table

Available table values from `R/utility.R`:

| surface_type | alpha |
|---|---:|
| field | 1.12 |
| bare soil | 1.04 |
| coniferous forest | 1.13 |
| water | 1.26 |
| wetland | 1.26 |
| spruce forest | 1.72 |

The table is internal package data. The code/Rd references Foken for the PT formula, but this pass did not independently validate every alpha value against Priestley & Taylor, Foken, FAO, or another primary table. Source status remains `open`.

## Tests Added

`tests/testthat/test-priestley-taylor-contract.R` covers:

- `sc()` finite positive increasing output for normal temperatures.
- `sc()` vector length and non-finite behavior.
- `gam()` finite positive vector output for normal temperatures.
- `gam()` magnitude commensurable with `sc()` for normal temperatures without asserting a literature value.
- valid PT surface types produce finite LE/H and close exactly to `rad_bal - soil_flux`.
- invalid surface types error clearly.
- PT closure for positive and negative available energy.
- increasing positive `soil_flux` lowers PT latent heat when all else is fixed.
- `pt_only = TRUE` workflow remains isolated to PT outputs.
- `tests/testthat/test-priestley-taylor-source-table.R` verifies `sc()` and
  `gam()` against Foken (2013), p. 48, Table 6 rounded values and checks that
  their PT ratio is finite, bounded between 0 and 1, and increasing over the
  table temperatures.

## Remaining Open Items

- Independent source validation of every alpha value in `priestley_taylor_coefficient`.
- Vectorized `surface_type` handling: current PT methods are scalar-oriented and can fail through scalar `if` logic; no vectorized policy was introduced.
- No water-limitation, advection, canopy resistance, or storage term is implemented in PT; this is expected but should remain explicit in method interpretation.
