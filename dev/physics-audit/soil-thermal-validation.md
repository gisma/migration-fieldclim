# Soil Thermal Property Validation And Domain Policy

Scope: `soil_heat_flux()`, `soil_thermal_cond()`, `soil_heat_cap()`, and `soil_attenuation()`. Inputs were `dev/physics-audit/physics-formula-audit.md`, `dev/physics-audit/physics-fix-plan.md`, `dev/physics-audit/radiation-solar-validation.md` for status consistency, implementation, generated Rd, tests, and soil-related vignette text.

## Policy

- Package convention remains: `soil_flux` / `G > 0` means heat flux into the soil.
- The `soil_heat_flux()` sign formula was not changed.
- Soil thermal table values are retained as implemented and documented from Bendix 2004 p. 254, but independent table-source validation remains open.
- Moisture domain behavior is now explicitly documented and tested instead of inferred.

## Function Audit Table

| Function | Source category | Implemented formula | Documented formula | Inputs and units | Output and units | Valid input domain | Current behavior outside domain | Edge cases | Status |
|---|---|---|---|---|---|---|---|---|---|
| `soil_heat_flux()` | Bendix / package sign convention | `G = -lambda * (T1 - T2) / (z1 - z2)` with `lambda = soil_thermal_cond(texture, moisture)` | same | `texture` one of `sand`, `peat`, `clay`; `moisture` m3 m-3; `soil_temp1`, `soil_temp2` degC; `soil_depth1`, `soil_depth2` m | soil heat flux `G`, W m-2 | finite non-negative depths, non-equal depth pair, texture valid, moisture in conductivity table domain | invalid depths now return `NA` with warning elementwise; invalid texture errors through conductivity helper; out-of-domain moisture propagates `NA` from conductivity | valid vector rows remain finite if neighboring rows have invalid depths | `code-ok` for sign convention and local depth guard; table/domain source remains `open` |
| `soil_thermal_cond()` | Bendix table / implementation-specific interpolation | converts `moisture * 100`, selects texture table, returns `approx(x, y, moisture)$y` | thermal conductivity interpolated from measured data | `texture`; `moisture` m3 m-3 converted to vol-% | thermal conductivity `lambda`, W m-1 K-1 | sand/clay: 0 to 0.43 m3 m-3; peat: 0 to 0.90 m3 m-3, based on table `x` values | invalid texture stops; moisture below/above table domain returns `NA` from `approx()` | vector moisture works for scalar texture; vector texture not supported by scalar `if` logic | `open` for independent table validation; current domain policy documented/tested |
| `soil_heat_cap()` | Bendix table / implementation-specific interpolation | converts `moisture * 100`, selects texture table, `approx(x, y, xout = moisture, yleft = NA, yright = y[7])$y` | volumetric heat capacity interpolated from measured data | `moisture` m3 m-3 converted to vol-%; `texture` | volumetric heat capacity `C_v`, MJ m-3 K-1 | sand/clay: 0 to 0.43 m3 m-3; peat: 0 to 0.90 m3 m-3, based on table `x` values | invalid texture stops; below table domain returns `NA`; above table domain returns highest tabulated heat capacity | high-moisture clamp is implemented only for heat capacity, not conductivity | `open` for clamp-policy validation; units `code-ok` after documentation |
| `soil_attenuation()` | Bendix / thermal diffusivity damping length | `sqrt(lambda / (C_v * 10^6 * pi) * 86400)` | same, with `10^6` conversion | `moisture` m3 m-3; `texture`; uses `lambda` W m-1 K-1 and `C_v` MJ m-3 K-1 | attenuation length, m | valid texture; moisture where both conductivity and heat capacity are finite | invalid texture errors; out-of-domain conductivity/heat capacity propagates `NA` | unit conversion is explicit; no silent MJ/J ambiguity | `code-ok` for unit conversion; source/table validation remains `open` |

## Source And Table Status

- Tables for conductivity and volumetric heat capacity are embedded in `R/soil.R` at lines 101-109 and 162-170.
- Roxygen references Bendix 2004 p. 254 for both tables and Bendix 2004 p. 253 for attenuation.
- This pass did not independently verify every table value against the printed source; table/source status remains `open`.
- No table values, interpolation points, or formulas were replaced.

## Domain Policy

- Valid textures are `sand`, `clay`, and `peat`.
- Invalid texture is an error for `soil_thermal_cond()` and `soil_heat_cap()`; this behavior is locked by tests.
- Moisture is supplied as m3 m-3 and converted internally to volume percent.
- `soil_thermal_cond()` returns `NA` outside the tabulated moisture domain.
- `soil_heat_cap()` returns `NA` below the tabulated moisture domain and uses the highest tabulated heat capacity above the tabulated domain.
- This asymmetric high-moisture behavior is current implementation behavior, not yet physically validated.
- `soil_heat_flux()` now guards invalid depths: non-finite, negative, or equal depths return `NA` with a warning for affected elements.

## Tests Added

`tests/testthat/test-soil-contract.R` covers:

- positive `G` for `z1 < z2` and `T1 > T2`, matching the package convention of heat flux into soil.
- vector-local depth handling for `soil_heat_flux()`.
- finite non-negative conductivity for valid textures.
- invalid texture error behavior.
- finite positive MJ-scale heat capacity for valid textures.
- attenuation formula with explicit `C_v * 10^6` conversion.
- current moisture-domain behavior at 0, normal moisture, high moisture, and negative moisture.

## Remaining Open Items

- Independent source validation of all soil thermal table values.
- Whether high moisture should be clamped, return `NA`, or warn consistently across conductivity and heat capacity.
- Whether vector `texture` should be supported or explicitly rejected.
- Whether negative or physically impossible moisture should warn rather than returning `NA` through interpolation.
