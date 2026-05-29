# Radiation And Solar Physics Validation

Scope: radiation, solar geometry, transmittance, and terrain helpers used by modeled radiation. Inputs were `dev/physics-audit/physics-formula-audit.md`, `dev/physics-audit/physics-fix-plan.md`, implementation files, generated Rd topics, tests, and radiation-related vignette text.

## Policy

- Confirmed sign convention remains: `K* = K_down - K_up`, `L* = L_down - L_up`, and `Rn = K* + L*`.
- Modeled radiation from `rad_*()` is not treated as automatically equivalent to measured `rad_net` or measured component columns.
- Existing vignettes already distinguish measured `rad_net` from `K* + L*` checks; this audit keeps that distinction.
- Source-uncertain constants and empirical expressions remain `open` unless the package already documents the source clearly.

## Function Audit Table

| Item | Source/formula category | Implemented formula | Documented formula | Source refs | Inputs and units | Output and units | Expected physical bounds | Edge cases | Status |
|---|---|---|---|---|---|---|---|---|---|
| `rad_sw_bal()` | Bendix sign convention | `SW_in - SW_out + D_in - D_out` | `R_sw = SW_in - SW_out + D_in - D_out` | `R/radiation.R:87-119`; `man/rad_sw_bal.Rd` | datetime, lon/lat deg, elev m, temp degC, slope/exposition deg, valley, surface_type | modeled `K*`, W m-2 | exact `K_down - K_up` with direct+diffuse terms | inherits shortwave/albedo edge cases | `code-ok`; contract test added |
| `rad_lw_bal()` | Bendix sign convention | `rad_lw_in(...) - rad_lw_out(...)` | `R_lw = LW_in - LW_out` | `R/radiation.R:421-455`; `man/rad_lw_bal.Rd` | temp/surface_temp degC, RH %, slope deg, valley, surface_type | modeled `L*`, W m-2 | exact `L_down - L_up` | RH/temp/slope not range-validated | `code-ok`; contract test added |
| `rad_bal()` | Bendix sign convention | `rad_sw_bal(...) + rad_lw_bal(...)` | `R_total = R_sw + R_lw` | `R/radiation.R:19-57`; `man/rad_bal.Rd` | all shortwave and longwave inputs | modeled `Rn`, W m-2 | exact `K* + L*` | does not consume measured `rad_net` | `code-ok`; measured equivalence `open` |
| `rad_sw_in()` | Bendix / implementation-specific guard | `SW_toa * 0.9751 * T_total / sin(E) * cos(terrain_angle)`, then negative or below-horizon values become `0` | same | `R/radiation.R:147-182`; trans helpers `R/transmittance.R`; terrain `R/terrain.R:86-99` | datetime, lon/lat deg, elev m, temp degC, slope/exposition deg; transmittance factors unitless | direct incoming shortwave, W m-2 | non-negative for finite physical inputs; zero at night | transmittance helpers may return `NA` below horizon after guard; `rad_sw_in()` still returns `0` at night | `code-ok` for night clamp; source constants `open` |
| `rad_sw_toa()` | Bendix | `sol_const * eccentricity * sin(sol_elevation)`, below horizon `0` | `SW_toa = S * E * sin(E)` | `R/radiation.R:206-232`; `man/rad_sw_toa.Rd` | datetime, lon/lat deg, sol_const W m-2 | top-of-atmosphere shortwave, W m-2 | non-negative, zero below horizon | uses solar timebase | `code-ok`; constants `open` |
| `rad_diffuse_in()` | Bendix / implementation-specific | `0.5 * ((1 - (1 - vapor) - (1 - ozone)) * SW_toa - SW_in) * sky_view * (1 + cos(terrain_angle)^2 * sin(solar_angle)^3)`, below horizon `0` | same | `R/radiation.R:261-302`; `man/rad_diffuse_in.Rd` | same as `rad_sw_in()` plus valley | diffuse incoming shortwave, W m-2 | expected non-negative for normal finite daytime cases; zero below horizon | formula/source constants and possible negative diffuse cases remain unvalidated | `open`; night contract added |
| `rad_sw_out()` | Bendix reflection concept / implementation-specific lookup | `rad_sw_in(...) * albedo(surface_type)` | `SW_out = SW_in * alpha` | `R/radiation.R:331-354`; surface table `R/utility.R:12-68`; `man/rad_sw_out.Rd` | same as direct shortwave plus surface_type | reflected direct shortwave, W m-2 | for valid table albedo `0 <= SW_out <= SW_in` | unknown surface_type returns `numeric(0)` | valid-surface behavior `code-ok`; unknown policy `open` |
| `rad_diffuse_out()` | Bendix reflection concept / implementation-specific lookup | `rad_diffuse_in(...) * albedo(surface_type)` | `D_out = D_in * alpha` | `R/radiation.R:384-407`; surface table `R/utility.R:12-68`; `man/rad_diffuse_out.Rd` | same as diffuse incoming plus surface_type | reflected diffuse shortwave, W m-2 | for valid table albedo `0 <= D_out <= D_in` if `D_in >= 0` | unknown surface_type returns `numeric(0)` | valid-surface behavior `code-ok`; unknown policy `open` |
| Albedo lookup | implementation-specific | exact `surface_properties[surface_type]$albedo` lookup | documented as surface albedo | `R/radiation.R:351-354`, `R/radiation.R:404-407`, `R/utility.R:12-68` | surface_type string | dimensionless albedo | table values are 0.05 to 0.30 | no partial/case-insensitive matching; unknown gives zero-length result | current behavior locked; policy `open` |
| `rad_lw_in()` | Bendix / Brutsaert-style emissivity | `epsilon_air * sigma * c2k(temp)^4 * sky_view` | same | `R/radiation.R:481-505`; `man/rad_lw_in.Rd` | temp degC, RH %, slope deg, valley | incoming longwave, W m-2 | non-negative for physical inputs | no cloud term; invalid RH/temp/slope not guarded | `open` source/domain validation |
| `rad_emissivity_air()` | Bendix / Oke-like emissivity | `(1.24 * vapor_p / c2k(temp))^(1/7)` | same | `R/radiation.R:529-549`; `man/rad_emissivity_air.Rd` | temp degC, RH % via vapor pressure hPa | unitless emissivity | expected mostly 0-1 for physical ranges | invalid RH/temp not guarded | `open` |
| `rad_lw_out()` | Bendix / Stefan-Boltzmann | `emissivity(surface_type) * sigma * c2k(surface_temp)^4` | same | `R/radiation.R:573-594`; `man/rad_lw_out.Rd` | surface_type, surface_temp degC | outgoing longwave, W m-2 | non-negative for physical inputs | unknown surface_type returns `numeric(0)` | `open` for unknown-surface policy |
| `sol_elevation()` | Bendix solar geometry | `asin(sin(lat)*sin(delta) + cos(lat)*cos(delta)*cos(H))` in degrees | same | `R/solar.R:127-164`; `man/sol_elevation.Rd` | datetime POSIXct/POSIXlt, lon/lat deg | solar elevation deg | `[-90, 90]` expected | depends on `sol_hour_angle()` timebase | `code-ok` after POSIXct contract |
| `sol_hour_angle()` | Bendix / implementation-specific timebase | `15 * (local_time_fields + sol_time_formula - 12)`; now converts `datetime` to POSIXlt first | documented `H = 15*(T_m + E_t - 12)` | `R/solar.R:316-349`; `man/sol_hour_angle.Rd` | datetime POSIXct/POSIXlt, lon deg | hour angle deg | finite for valid datetimes | still uses local POSIXlt clock fields, not `sol_medium_suntime()`; timezone/source interpretation remains open | POSIXct bug fixed; timebase source `open` |
| `sol_medium_suntime()` | Bendix / implementation-specific | converts input instant to UTC POSIXlt then `UTC hour + lon/15` | `T_m = T_local + lon/15` | `R/solar.R:364-397`; tests existing | datetime, lon deg | hours | finite | differs from `sol_hour_angle()` implementation | `open` timebase consistency question |
| `sol_azimuth()` | Bendix solar geometry | arccos expression using declination, latitude, hour angle, elevation; morning/afternoon branch from POSIXlt hour | same | `R/solar.R:462-511`; `man/sol_azimuth.Rd` | datetime POSIXct/POSIXlt, lon/lat deg | azimuth deg | 0-360 expected | polar/near-zenith denominator cases not guarded | POSIXct bug fixed; edge domains `open` |
| `trans_air_mass_rel()` | Bendix | `1 / (sin(elevation) + 1.5 * elevation^-0.72)` for `elevation > 0`; otherwise `NA` with warning | same plus guard note | `R/transmittance.R:91-129`; `man/trans_air_mass_rel.Rd` | datetime POSIXct/POSIXlt, lon/lat deg | relative optical air mass, unitless | positive finite for sun above horizon | below horizon previously `NaN`; now controlled `NA` warning | guard `code-ok`; source constants `open` |
| `trans_air_mass_abs()` | Bendix | `M_rel * p / p0` | same | `R/transmittance.R:46-77`; `man/trans_air_mass_abs.Rd` | `M_rel`, elev m, temp degC, pressure hPa | absolute optical air mass | positive finite above horizon | propagates `NA` below horizon | `code-ok` for guard propagation |
| `trans_gas()` | Bendix | `exp(-0.0127 * M_abs^0.26)` | same | `R/transmittance.R:1-30`; `man/trans_gas.Rd` | air mass | transmittance ratio | expected 0-1 above horizon | propagates `NA` below horizon | `open` source/range validation |
| `trans_ozone()` | Bendix | `1 - (0.1611*x*(1+139.48*x)^-0.3035 - 0.002715*x*(1+0.044*x+0.0003*x^2)^-1)` | same | `R/transmittance.R:142-174`; `man/trans_ozone.Rd` | ozone column cm, relative air mass | transmittance ratio | expected 0-1 above horizon | propagates `NA` below horizon | `open` source/range validation |
| `trans_rayleigh()` | Bendix | `exp(-0.0903 * M_abs^0.84 * (1 + M_abs - M_abs^1.01))` | same | `R/transmittance.R:189-218`; `man/trans_rayleigh.Rd` | absolute air mass | transmittance ratio | expected 0-1 above horizon, but expression needs source check | propagates `NA` below horizon | `open` |
| `trans_vapor()` | Bendix | `1 - 2.4959*x / ((1 + 79.034*x)^0.6828 + 6.385*x)` | same | `R/transmittance.R:232-263`; `man/trans_vapor.Rd` | precipitable water, relative air mass | transmittance ratio | expected 0-1 above horizon | propagates `NA` below horizon | `open` |
| `trans_aerosol()` | Bendix / implementation-specific visibility fit | `tau38`, `tau50` fitted from table; `x = 0.2758*tau38 + 0.35*tau50`; `exp(-x^0.873 * (1+x-x^0.7088) * M_abs^0.9108)` | same | `R/transmittance.R:277-317`; `man/trans_aerosol.Rd` | vis km, absolute air mass | transmittance ratio | expected 0-1 above horizon | vis range not guarded; propagates `NA` below horizon | `open` |
| `terr_sky_view()` | Bendix | non-valley `(1 + cos(slope))/2`; valley `cos(slope)` | same | `R/terrain.R:1-38`; `man/terr_sky_view.Rd` | slope deg, valley logical scalar | sky-view factor | 0-1 for normal slopes | vectorized `valley` not handled by scalar `if`; invalid slopes may exceed intended domain | `open` |
| `terr_terrain_angle()` | Bendix | `acos(cos(slope)*sin(elevation) + sin(slope)*cos(elevation)*cos(azimuth-exposition))` | same | `R/terrain.R:54-99`; `man/terr_terrain_angle.Rd` | datetime, lon/lat deg, slope/exposition deg | terrain incidence angle deg | 0-180 expected | acos argument not clamped; invalid geometry can produce `NaN` | `open` |

## Contract Tests Added

- `tests/testthat/test-radiation-contract.R`
  - `rad_sw_bal() == rad_sw_in() + rad_diffuse_in() - rad_sw_out() - rad_diffuse_out()`.
  - `rad_lw_bal() == rad_lw_in() - rad_lw_out()`.
  - `rad_bal() == rad_sw_bal() + rad_lw_bal()`.
  - valid table albedo gives reflected shortwave between zero and incoming direct shortwave.
  - unknown `surface_type` currently returns `numeric(0)` for reflected shortwave helpers; this is locked as current behavior and remains undesirable/open.
  - modeled incoming direct/diffuse/top-of-atmosphere shortwave is zero or controlled at night.
- `tests/testthat/test-solar-contract.R`
  - `sol_hour_angle()`, `sol_elevation()`, and `sol_azimuth()` behave consistently for POSIXct and POSIXlt representations of the same instant.
- `tests/testthat/test-transmittance-contract.R`
  - near-horizon positive solar elevation gives finite air mass/transmittance helper values.
  - below-horizon relative air mass returns `NA` with warning, not `NaN`/`Inf`, while valid vector elements remain finite.

## Changes Made After Tests

- `R/solar.R`: `sol_hour_angle.default()` and `sol_azimuth.default()` now coerce `datetime` to POSIXlt before reading `$hour`, `$min`, and `$sec`. This makes the documented POSIXct/POSIXlt support true for those functions.
- `R/transmittance.R`: `trans_air_mass_rel.default()` now evaluates the air-mass formula only for positive finite solar elevation. Invalid or below-horizon elements return `NA` with one warning.
- Roxygen for `trans_air_mass_rel()` now states the positive-elevation domain and controlled `NA` behavior.

No radiation balance sign formulas were changed. No measured `rad_bal`/`rad_net` replacement behavior was added.

## Remaining Open Items

- Independent source validation of all Bendix constants and empirical transmittance exponents.
- Solar timebase semantics: `sol_hour_angle()` still uses local clock fields plus `sol_time_formula()`, while `sol_medium_suntime()` performs an explicit UTC conversion. This is now tested for POSIX class consistency, but the astronomical timebase remains an open validation question.
- Unknown `surface_type` policy for albedo/emissivity helpers. Current `numeric(0)` behavior is locked by contract tests but should be replaced only after policy is chosen.
- Terrain vectorization/domain guards for `terr_sky_view()` and `terr_terrain_angle()`.
- Modeled-vs-measured radiation equivalence. Vignettes correctly treat this as a validation question; no package invariant should force equality.
