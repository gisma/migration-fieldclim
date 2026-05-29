# Priestley-Taylor Helper And Source Validation

Scope: `latent_priestley_taylor()`, `sensible_priestley_taylor()`, `sc()`, `gam()`, and the internal `priestley_taylor_coefficient` table. Inputs were `dev/physics-audit/physics-formula-audit.md`, `dev/physics-audit/physics-fix-plan.md`, `dev/physics-audit/soil-thermal-validation.md` for status consistency, implementation, generated Rd, tests, and PT-related vignette text.

## Policy

- PT closure logic is unchanged.
- Package convention remains: `Rn > 0` is net radiative input, `G > 0` is soil heat flux into soil, and PT partitions `Rn - G`.
- Helper formulas and coefficient table values were not replaced.
- `sc()` and `gam()` are commensurable Foken table-scale polynomial coefficients in this package. Their absolute pressure unit scale is not proven as Pa/K, hPa/K, or kPa/K and remains source-open.

## Function Audit Table

| Item | Source/formula category | Implemented formula | Documented formula | Inputs and units | Output and units | Sign convention | Closure invariant | Edge/warning logic | Status |
|---|---|---|---|---|---|---|---|---|---|
| `latent_priestley_taylor()` | Foken / Priestley-Taylor | `LE = alpha * sc(temp) / (sc(temp) + gam(temp)) * (rad_bal - soil_flux)` | `Q_e = alpha_PT * Delta / (Delta + gamma) * (R_n - G)` | `temp` degC; `rad_bal`, `soil_flux` W m-2; `surface_type` table label | latent heat flux W m-2 | positive away from surface; negative toward surface | with matching sensible call, `LE + H = Rn - G` | invalid surface type errors; warns if output > 600 or < -600 W m-2 | `code-ok` for closure/sign; helper/source units `open` |
| `sensible_priestley_taylor()` | Foken / Priestley-Taylor residual form | `H = (((1 - alpha) * sc(temp) + gam(temp)) / (sc(temp) + gam(temp))) * (rad_bal - soil_flux)` | same algebraic partition; documented as sensible PT formula | `temp` degC; `rad_bal`, `soil_flux` W m-2; `surface_type` table label | sensible heat flux W m-2 | positive away from surface; negative toward surface | algebraically equivalent to `(Rn - G) - LE` when inputs match | invalid surface type errors; warns if output > 600 or < -600 W m-2 | `code-ok` for closure/sign; helper/source units `open` |
| `sc()` | Foken table polynomial / implementation-specific scale | `8.5e-7 * (t + 273.15)^2 - 0.0004479 * (t + 273.15) + 0.05919` | internal noRd docs: polynomial fit for Foken table 6 | `t` degC, converted internally to K in polynomial | Foken table-scale slope coefficient; absolute Pa/K/hPa/K/kPa/K scale unclear | not a flux | used only in ratio with `gam()` | finite positive and increasing for normal temperatures; `NA -> NA`; `Inf -> NaN` | `open` for absolute unit/source validation; contract tested |
| `gam()` | Foken table polynomial / implementation-specific scale | `0.0004 + (0.00041491 - 0.0004) / (1 + (299.44 / (t + 273.15))^383.4)` | internal noRd docs: polynomial fit for Foken table 6 | `t` degC, converted internally to K in polynomial | Foken table-scale psychrometric coefficient; absolute Pa/K/hPa/K/kPa/K scale unclear | not a flux | used only in ratio with `sc()` | finite positive for normal temperatures; `NA -> NA`; `Inf -> 0.00041491` | `open` for absolute unit/source validation; contract tested |
| `priestley_taylor_coefficient` | Priestley-Taylor / implementation-specific table | surface table: `field=1.12`, `bare soil=1.04`, `coniferous forest=1.13`, `water=1.26`, `wetland=1.26`, `spruce forest=1.72` | PT docs state coefficient selected from predefined values | `surface_type` string | dimensionless alpha coefficient | not a flux | same alpha must be used by LE and H for closure | invalid scalar surface type errors with allowed values; vectorized surface_type is not supported cleanly by scalar `if` logic | table values/source remain `open`; scalar behavior contract tested |

## Helper Unit Conclusion

`sc()` returns a finite positive slope-like coefficient for typical air temperatures and increases from 0 to 30 degC. At 20 degC it is about `9.344991e-04`. This is not on the usual kPa/K saturation-vapour-pressure slope scale, but it is used only with `gam()` in a dimensionless ratio.

`gam()` returns a positive psychrometric-like coefficient near `4.0e-04` to `4.15e-04` over normal temperatures. It has no explicit pressure dependence. Because `sc()` and `gam()` are both documented as Foken table-polynomial coefficients and used together, the PT partition is internally commensurable. The absolute unit remains `open`.

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

## Remaining Open Items

- Independent source validation of `sc()` and `gam()` polynomial coefficients and their table/unit scale.
- Independent source validation of every alpha value in `priestley_taylor_coefficient`.
- Vectorized `surface_type` handling: current PT methods are scalar-oriented and can fail through scalar `if` logic; no vectorized policy was introduced.
- No water-limitation, advection, canopy resistance, or storage term is implemented in PT; this is expected but should remain explicit in method interpretation.
