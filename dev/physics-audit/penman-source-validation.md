# Penman Source-Form And Magnitude Validation

Scope: source-form and magnitude validation for `latent_penman()` and
`latent_penman.weather_station()` only. Inputs were
`dev/physics-audit/physics-formula-audit.md`,
`dev/physics-audit/physics-fix-plan.md`,
`dev/physics-audit/penman-unit-validation.md`, current implementation, Rd,
Penman tests, consolidation tests, and Penman-related vignette text.

## Summary

`latent_penman()` is best classified as a simplified Penman-Monteith-type
latent-heat combination method. It is not a full FAO-56 reference
evapotranspiration implementation and it does not return evaporation depth or a
paired sensible heat flux. The previous hPa/kPa vapour-pressure-deficit mismatch
remains fixed: saturation and actual vapour pressure helpers return hPa, and the
Penman calculation converts them to kPa before forming `vpd_kPa`.

No formula or wrapper-routing change was made in this validation pass. The
remaining Penman source-form and magnitude questions stay open unless a future
source-backed reference case defines the exact intended form.

## Implemented Formula

Source: `R/latent.R`.

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
ra <- (log((z - d) / zom) * log((z - d) / zoh)) / (k^2 * v)
Qe <- (delta * (rad_bal - soil_flux) + gamma * (cp * rho / ra) * vpd_kPa) /
  (delta + gamma * (1 + rs / ra))
out <- (Qe / hum_evap_heat(temp)) * hum_evap_heat(temp)
```

Implemented equation:

\[
LE =
\frac{\Delta (R_n - G) + \gamma (c_p \rho / r_a) VPD_{kPa}}
{\Delta + \gamma (1 + r_s / r_a)}
\]

The latent-heat division and multiplication cancel, so the returned value is the
heat flux `LE` in `W m-2`.

## Source-Form Validation

| Item | Evidence | Finding | Status |
|---|---|---|---|
| Method family | Equation combines an energy term, aerodynamic VPD term, surface resistance, and aerodynamic resistance. Vignette text describes a Penman-type LE-only path. | Closer to a simplified Penman-Monteith-type combination method than original Penman 1948 or full FAO-56 ET0. | `source-form-open` |
| Energy term | Uses `delta * (rad_bal - soil_flux)`. | Matches package convention: `Rn > 0` input at surface, `G > 0` into soil, available energy `Rn - G`. | `code-ok` |
| Aerodynamic term | Uses `gamma * (cp * rho / ra) * vpd_kPa`. | Pressure scale is internally consistent after the VPD kPa fix. Exact source-form/gamma placement remains a source-validation question because this is not a full FAO-56 station-data depth formulation. | `fixed` for units; `source-form-open` for exact source form |
| `rs` and `ra` | `rs` comes from `surface_resistance`; `ra` uses log roughness terms from `z`, displacement height, roughness lengths, and wind. | Dimensions are consistent with `s m-1`. Roughness/source convention and edge-domain policy remain open. | `source-form-open` |
| Output interpretation | Function returns a vector named/used as `latent_penman`; no sensible Penman output exists. | Output represents modeled latent heat flux in `W m-2`, not evaporation depth. | `code-ok` |
| Documentation claim | Prior wording called it the Penman-Monteith equation. | Roxygen now calls it a simplified Penman-Monteith-type equation and states LE-only behavior. | `documentation-mismatch` fixed |

## Variable And Unit Table

| Variable | Producing function or line | Implemented unit | Expected role | Status |
|---|---|---|---|---|
| `Delta` / `delta` | `4098 * es_kPa / ((temp + 237.3)^2)` | kPa K-1 | saturation vapour-pressure curve slope | `code-ok` |
| `gamma` | `0.665e-3 * pres_p(elev, temp)`; `pres_p()` returns hPa | kPa K-1 by magnitude | psychrometric constant | `code-ok` |
| `e_s`, `e_a` | `pres_sat_vapor_p()`, `pres_vapor_p()` | hPa helper output, converted to kPa | saturation and actual vapour pressure | `fixed` |
| `VPD` | `es_kPa - ea_kPa` | kPa | aerodynamic vapour-pressure forcing | `fixed` |
| `Rn`, `G` | `rad_bal`, `soil_flux` | W m-2 | available energy term | `code-ok` |
| `rho` | constant `1.2` | kg m-3 | air density | `source-form-open` |
| `cp` | constant `1004` | J kg-1 K-1 | heat capacity of air | `code-ok` |
| `ra` | roughness/log wind expression | s m-1 | aerodynamic resistance | `source-form-open` |
| `rs` | `surface_resistance` lookup | s m-1 | surface resistance | `source-form-open` for table source |

## Weather-Station Wrapper

| Check | Evidence | Finding | Status |
|---|---|---|---|
| `surface_type = "field"` | `.normalize_penman_surface_type()` maps `field` to `Temperate grassland`, which is present in `surface_resistance`. | Valid Penman resistance class. | `code-ok` |
| `rh` routing | If `hum1` is absent, wrapper passes station `rh` as the default method `rh`. | Works as relative humidity in percent. | `code-ok` |
| `hum1` routing | If `hum1` is present, wrapper prefers it over `rh` and passes it as `rh`. | Current behavior is internally valid only when `hum1` is relative humidity in percent. The preference over station-level `rh` is now documented and tested, but whether `rh` should be preferred remains open. | `wrapper-mismatch` / `open` |
| `z` / `obs_height` | Wrapper passes `z1` as `z` and `obs_height` separately. | Routing is consistent with current argument names. | `code-ok` |

## Magnitude Screening: Caldern Teaching Day

Using the packaged Caldern teaching day with `surface_type = "field"`:

| Metric | Value |
|---|---:|
| Penman mean LE | `13.22542 W m-2` |
| Penman min LE | `-1.67408 W m-2` |
| Penman max LE | `68.89706 W m-2` |
| Penman values `> 600 W m-2` | `0` |
| Penman values `< -600 W m-2` | `0` |
| Penman `NA` values | `0` |
| Priestley-Taylor mean LE | `83.57368 W m-2` |
| Bowen mean LE | `129.81791 W m-2` |
| Bulk-Residual mean LE | `136.16877 W m-2` |

This comparison is a magnitude screen only. It does not imply that Penman should
match Priestley-Taylor, Bowen, or Bulk-Residual, because Penman remains LE-only
and is not forced to close `Rn - G`.

## Tests Added

- `tests/testthat/test-penman-source.R` locks the kPa VPD contract against the
  old hPa-scaled aerodynamic term.
- It checks that increasing relative humidity lowers `LE` and increasing wind
  increases `LE` when VPD is positive.
- It checks that Penman remains LE-only in workflow output.
- It checks both `rh`-only and `hum1`-only weather-station routing.
- It explicitly locks current `hum1`-over-`rh` precedence as current behavior.

## Decision Table

| Decision | Items |
|---|---|
| Safe to document only | LE-only output, W m-2 interpretation, package sign convention, simplified Penman-Monteith-type wording |
| Needs test before fix | Any future change to `hum1` versus `rh` precedence; any change to aerodynamic resistance edge policy |
| Needs formula fix | None identified as unambiguous in this pass |
| Keep open | Exact source-form/gamma placement, roughness/resistance source convention, final source-backed physical magnitude validation, whether wrapper should prefer station `rh` when both `rh` and `hum1` are present |
