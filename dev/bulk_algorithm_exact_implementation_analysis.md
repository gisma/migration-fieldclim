# Exact implementation analysis: fieldClim heat-flux algorithms and Bulk variants

This document reports only current implementation, tests, and generated
documentation. It does not use old figures or diagrams as evidence.

## 1. Evidence basis

### Inspected R files

- `R/bulk.R`
- `R/sensible.R`
- `R/latent.R`
- `R/turbulent_flux.R`
- `R/turbulence.R`
- `R/utility_turbulent_flux.R`
- `R/energy_balance_closure.R`
- `R/weather_station.R`
- `R/pressure.R`
- `R/humidity.R`
- `R/temperature.R`
- `R/fieldclim_params.R`
- `R/globals.R`

### Inspected tests

- `tests/testthat/test-bulk.R`
- `tests/testthat/test-bulk-exchange-velocity.R`
- `tests/testthat/test-bulk-stability.R`
- `tests/testthat/test-sensible.R`
- `tests/testthat/test-latent.R`
- `tests/testthat/test-turbulence.R`
- `tests/testthat/test-turbulent-flux-remaining-coverage.R`
- `tests/testthat/test-energy-balance-closure.R`
- `tests/testthat/test-equation-contracts.R`
- `tests/testthat/test-physics-contract.R`
- `tests/testthat/test-weather-station-object-contract.R`

### Inspected Rd/docs files

- `man/sensible_bulk.Rd`
- `man/latent_bulk_residual.Rd`
- `man/turb_flux_bulk_residual.Rd`
- `man/turb_flux_calc.Rd`
- `man/turb_ustar.Rd`
- `man/turb_roughness_length.Rd`
- `man/turb_flux_grad_rich_no.Rd`
- `man/turb_flux_stability.Rd`
- `man/turb_flux_monin.Rd`
- `docs/reference/sensible_bulk.md`
- `docs/reference/latent_bulk_residual.md`
- `docs/reference/turb_flux_bulk_residual.md`
- `docs/reference/turb_flux_calc.md`

### Sources not used

- Existing PNG/SVG/drawio diagrams under `vignettes/figures/`.
- Rendered article plot images under `docs/articles/`.
- Any method assumptions not present in R source, tests, or generated
  documentation.

### Contradictions between code, tests, and documentation

| Topic | Evidence | Contradiction / status |
|---|---|---|
| `turb_flux_bulk_residual()` documentation and exchange-velocity variants | `R/bulk.R` and `tests/testthat/test-bulk-exchange-velocity.R` show `turb_flux_bulk_residual(..., exchange_velocity = "u_star_profile")` is passed through to `sensible_bulk()`. `man/turb_flux_bulk_residual.Rd` still describes the aerodynamic resistance only as the mean-wind formula. | Documentation is incomplete/outdated for the new Bulk exchange-velocity variants. Code/tests are authoritative. |
| `turb_flux_calc()` missing optional inputs | `man/turb_flux_calc.Rd` says unavailable optional inputs produce `NA` values and/or warnings according to the respective method. `R/turbulent_flux.R` calls Bulk, stability, PT, Bowen, Monin before Penman fallback; missing non-Penman fields can abort. `test-turbulent-flux-remaining-coverage.R` explicitly expects incomplete non-Penman inputs to abort. | Generated documentation overstates graceful handling for all optional methods. Tests/code are authoritative: Penman failure is caught; other required-method failures can abort. |
| `sensible_bulk.weather_station()` argument name | S3 method signature is `sensible_bulk.weather_station(t1, ...)`; internally `weather_station <- t1`. | Not a semantic contradiction, but the method argument name is misleading. It is the weather_station object. |
| Bulk stability handling wording | `sensible_bulk.Rd` states `ri_guard` is a screen and not a correction. Tests confirm valid values are unchanged and only invalid/very-stable cases become `NA`. | No contradiction. |
| `build_weather_station()` with `NULL` fields | Assignment `out[[name]] <- NULL` removes the element. Test confirms explicit NULL fields are omitted. | No contradiction. |

## 2. Implemented algorithm families overview

| Family | Implemented functions | H output | LE output | Required fields | Uses A = Q* - B? | Closure behavior | Notes |
|---|---|---|---|---|---|---|---|
| Priestley-Taylor | `sensible_priestley_taylor()`, `latent_priestley_taylor()` | `sensible_priestley_taylor` | `latent_priestley_taylor` | `temp`, `rad_bal`, `soil_flux`, `surface_type` | Yes | Partition closure: H + LE = A when both functions use same inputs. | Tested in `test-equation-contracts.R` and `test-physics-contract.R`. |
| Bulk sensible | `sensible_bulk()` | `sensible_bulk` | none | `t1`, `t2`, `v1`, `z1`, `z2`; optional `v2`; optional roughness inputs for roughness variant | No direct LE closure; computes H only | Not a closure method alone. | Three exchange-velocity paths plus optional `ri_guard`. |
| Bulk-Residual | `latent_bulk_residual()`, `turb_flux_bulk_residual()` | `sensible_bulk` | `latent_bulk_residual` | Bulk sensible fields plus `rad_bal`, `soil_flux` | Yes | Residual closure: `LE_res = A - H_bulk`, so `H_bulk + LE_res = A` by definition. | Formal closure is algebraic, not validation. |
| Bowen | `sensible_bowen()`, `latent_bowen()` | `sensible_bowen` | `latent_bowen` | `t1`, `t2`, `hum1`, `hum2`, `z1`, `z2`, `elev`, `rad_bal`, `soil_flux` | Yes | Partition closure for finite uncapped denominator. | Capped near-singular cases are guarded and may not close exactly. |
| Penman | `latent_penman()` | none | `latent_penman` | `datetime`, `v1`, `temp`, `z1`, `rad_bal`, `elev`, `lat`, `lon`, `soil_flux`, `obs_height`, `surface_type`, plus `hum1` or `rh` | Yes | Latent-only; no paired H. | Closure diagnostics report `unresolved_complement = A - latent_penman`. |
| Monin/Profile | `sensible_monin()`, `latent_monin()`, turbulence helpers | `sensible_monin` | `latent_monin` | `t1`, `t2`, `hum1`, `hum2`, `v1`, `v2`, `z1`, `z2`, `elev`, plus `surface_type` or `obs_height` | No forced use of A in formulas | Diagnostic profile outputs; not forced to close. | Uses roughness/friction velocity/Monin and Richardson helper paths. |
| Closure diagnostics | `energy_balance_closure()`, `plot_energy_balance_closure()` | reads existing H fields | reads existing LE fields | `rad_bal`, `soil_flux`, requested output fields | Yes | Diagnostic only. | Does not compute new fluxes. |

## 3. Core notation used for this analysis

Notation used here:

- `Q* = rad_bal`
- `B = soil_flux`
- `A = Q* - B`
- `H = sensible heat flux`
- `LE = latent heat flux`
- `R_E = Q* - B - H - LE`

Mapping from code/Rd notation:

- R code and Rd often write `R_n` for net radiation. In this analysis,
  `R_n` is mapped to `Q* = rad_bal`.
- R code and Rd often write `G` for soil heat flux. In this analysis,
  `G` is mapped to `B = soil_flux`.
- `energy_balance_closure()` uses `available_energy = rad_bal - soil_flux`,
  i.e. `A = Q* - B`.

## 4. Bulk algorithm: full implementation map

| Function | File | Role | Formula / logic | Required inputs | Optional inputs | Output | Error/NA guards | Tested by |
|---|---|---|---|---|---|---|---|---|
| `sensible_bulk()` | `R/bulk.R` | S3 generic | Dispatches on first argument. | first argument | `...` | method-specific | none in generic | indirect via all Bulk tests |
| `sensible_bulk.default()` | `R/bulk.R` | Core Bulk H implementation | `Delta T = t1 - t2`; `r_a = log(z2/z1)/(k * velocity_scale)`; `H = rho * cp * Delta T / r_a` | `t1`, `t2`, `v1`, `z1`, `z2` | `v2`, `rho`, `cp`, `k`, `min_wind`, `exchange_velocity`, `min_ustar`, `surface_type`, `obs_height`, `warn_threshold`, `stability_method`, `ri_*`, `min_shear`, `g`, `elev` | numeric H vector | errors for invalid scalar heights, missing required `v2`/roughness by variant; sets invalid velocity or guarded stability rows to `NA`; warns above threshold | `test-bulk.R`, `test-bulk-exchange-velocity.R`, `test-bulk-stability.R`, `test-equation-contracts.R`, `test-physics-contract.R` |
| `sensible_bulk.weather_station()` | `R/bulk.R` | Weather-station wrapper | Checks fields, extracts optional `v2`, `elev`, `surface_type`, `obs_height`, calls default method. | `t1`, `t2`, `v1`, `z1`, `z2` | `v2`, `elev`, `surface_type`, `obs_height`, same method options | numeric H vector | `check_availability()` errors if required fields absent; variant-specific errors from default method | `test-bulk-exchange-velocity.R`, `test-bulk-stability.R` |
| wind_mean exchange path | `R/bulk.R` inside `sensible_bulk.default()` | Default velocity scale | if `v2` missing: `velocity_scale = v1`; else `(v1 + v2)/2` | `v1`; optional `v2` | `min_wind` | velocity scale for `r_a` | non-finite, missing, or `<= min_wind` set to `NA` with warning | `test-bulk.R`, `test-bulk-exchange-velocity.R`, `test-equation-contracts.R` |
| `u_star_profile` exchange path | `R/bulk.R` inside `sensible_bulk.default()` | Profile-derived friction velocity scale | `u* = k * (v2 - v1)/log(z2/z1)`; used as `velocity_scale` in `r_a = log(z2/z1)/(k*u*)` | `v1`, `v2`, `z1`, `z2` | `min_ustar` | velocity scale `u*` | missing `v2` errors; non-finite, missing, non-positive or `<= min_ustar` set to `NA` with warning | `test-bulk-exchange-velocity.R` |
| `u_star_roughness` exchange path | `R/bulk.R` inside `sensible_bulk.default()` | Roughness-derived friction velocity scale | if `v2` present: `v_ref = v2`, `z_ref = z2`; else `v_ref = v1`, `z_ref = z1`; `z0 = turb_roughness_length(obs_height)` or `turb_roughness_length(surface_type)`; `u* = k * v_ref/log(z_ref/z0)` | `v1`, `z1`, `z2`, plus `surface_type` or `obs_height`; optionally `v2` | `min_ustar` | velocity scale `u*` | missing roughness source errors; invalid `z0`, `z_ref <= z0`, invalid or small `u*` set to `NA` with warning | `test-bulk-exchange-velocity.R` |
| `ri_guard` path | `R/bulk.R` inside `sensible_bulk.default()` | Optional stability screen | Calculates `Ri_g = (g/theta_mean) * (dtheta_dz)/(du_dz^2)` after neutral H. Classifies unstable/neutral/stable/very_stable. | `v2` plus Bulk fields | `elev`, `ri_neutral`, `ri_critical`, `min_shear`, `g` | H vector with `bulk_Ri_g` and `bulk_stability` attributes | requires `v2`; invalid profile/weak shear or `Ri_g >= ri_critical` set H to `NA`; does not rescale valid H | `test-bulk-stability.R`, `test-equation-contracts.R` |
| `latent_bulk_residual()` | `R/bulk.R` | S3 generic | Dispatches on `rad_bal`. | first argument | `...` | method-specific | none in generic | indirect |
| `latent_bulk_residual.default()` | `R/bulk.R` | Core residual LE implementation | `LE = rad_bal - soil_flux - sensible` | `rad_bal`, `soil_flux`, `sensible` | `warn_threshold` | numeric LE vector | warns if `abs(LE) > warn_threshold`; no capping | `test-bulk.R`, `test-equation-contracts.R`, `test-physics-contract.R` |
| `latent_bulk_residual.weather_station()` | `R/bulk.R` | Weather-station wrapper for residual LE | Checks `rad_bal`, `soil_flux`; if `sensible` missing, computes `sensible_bulk(weather_station, ...)`; then calls default method. | `rad_bal`, `soil_flux`; Bulk fields if `sensible` omitted | supplied `sensible`, Bulk options via `...` | numeric LE vector | missing required fields error; underlying Bulk errors/NA handling if H computed internally | `test-bulk.R`; indirect in workflow tests |
| `turb_flux_bulk_residual()` | `R/bulk.R` | Combined Bulk-Residual workflow | Checks required fields; computes `h_bulk <- sensible_bulk(weather_station, ...)`; computes `le_residual <- latent_bulk_residual(weather_station, sensible = h_bulk, ...)`; writes both fields. | `t1`, `t2`, `v1`, `z1`, `z2`, `rad_bal`, `soil_flux` | `v2`, `exchange_velocity`, `stability_method`, roughness inputs via object and `...` | weather_station with `sensible_bulk`, `latent_bulk_residual` | missing required fields error; does not catch Bulk errors; preserves class/list structure | `test-bulk.R`, `test-bulk-exchange-velocity.R`, `test-turbulent-flux-remaining-coverage.R` |
| `turb_flux_calc()` | `R/turbulent_flux.R` | Full heat-flux workflow including Bulk | If `pt_only = FALSE`, computes `sensible_blk <- sensible_bulk(weather_station)` and `latent_blk_res <- latent_bulk_residual(weather_station, sensible = sensible_blk)` before adding output fields. | full workflow needs fields required by Bulk, PT, Bowen, Monin; Penman separately | `pt_only` | weather_station with `sensible_bulk`, `latent_bulk_residual` and other method fields | Penman errors caught to `NA`; non-Penman missing/invalid fields can abort | `test-physics-contract.R`, `test-turbulent-flux-remaining-coverage.R` |
| `turb_roughness_length()` | `R/turbulence.R` | Roughness helper used by Bulk roughness path | `z0 = 0.1 * obs_height` or lookup in `surface_properties$roughness_length` | `surface_type` or `obs_height` | none | `z0` | invalid/missing roughness source errors | `test-bulk-exchange-velocity.R`, `test-turbulence.R` |
| `temp_pot_temp()` | `R/temperature.R` | Optional `ri_guard` potential temperature if `elev` supplied | `theta = T_K * (1000/p)^0.286`, returned in deg C | `t`, `elev` | pressure helper constants | potential temperature | pressure modeled through `pres_p()` | `test-equation-contracts.R`, temperature tests |
| `pres_p()` | `R/pressure.R` | Used by `temp_pot_temp()` and pressure helpers; not directly in default Bulk unless `elev` in `ri_guard` | barometric formula | `elev`, `temp` | constants | hPa pressure | no direct Bulk guard | pressure/helper tests |

## 5. Bulk sensible heat: exact formula and variants

`sensible_bulk.default()` computes Bulk sensible heat in three stages:

1. Select an exchange velocity scale.
2. Compute aerodynamic resistance:
   `r_a = log(z2 / z1) / (k * velocity_scale)`.
3. Compute:
   `H_bulk = rho * cp * (t1 - t2) / r_a`.

`Delta T` is exactly `t1 - t2`, lower measurement height minus upper
measurement height. With valid `z1 < z2`, positive `t1 - t2` produces positive
`H_bulk`. Tests explicitly check positive and negative sign behavior.

`z1` and `z2` must be scalar and must satisfy `0 < z1 < z2`. Invalid heights
stop before flux calculation.

The default variant is `exchange_velocity = "wind_mean"`.

### 5.1 wind_mean variant

Formula:

```r
if (is.null(v2)) {
  velocity_scale <- v1
} else {
  velocity_scale <- (v1 + v2) / 2
}

r_a <- log(z2 / z1) / (k * velocity_scale)
H_bulk <- rho * cp * (t1 - t2) / r_a
```

Inputs:

- Required: `t1`, `t2`, `v1`, `z1`, `z2`.
- Optional: `v2`.
- Defaults: `rho = 1.225`, `cp = 1005`, `k = 0.41`, `min_wind = 0.1`.

Behavior with `v1`/`v2`:

- If `v2` is present, mean wind is `(v1 + v2)/2`.
- If `v2` is absent, `v1` alone is used as the velocity scale.
- Missing, non-finite, or `velocity_scale <= min_wind` rows are set to `NA`
  with a warning mentioning wind speed.

Assumptions:

- Neutral bulk-transfer approximation.
- No Monin-Obukhov stability correction.
- `ri_guard` can screen results after calculation but does not change valid H.

Tests:

- `test-bulk.R`: sign behavior, low-wind `NA`.
- `test-bulk-exchange-velocity.R`: default remains wind_mean and exact formula.
- `test-equation-contracts.R`: direct formula for `v1` alone and mean wind.
- `test-physics-contract.R`: sign, closure with residual LE, low-wind control.

### 5.2 u_star_profile variant

Formula:

```r
u_star <- k * (v2 - v1) / log(z2 / z1)
r_a <- log(z2 / z1) / (k * u_star)
H_bulk <- rho * cp * (t1 - t2) / r_a
```

Inputs:

- Required: `t1`, `t2`, `v1`, `v2`, `z1`, `z2`.
- Optional: `min_ustar`, `rho`, `cp`, `k`, `warn_threshold`.

Behavior when `v2 <= v1`:

- The code does not use `abs(v2 - v1)`.
- If `v2 <= v1`, `u_star` is zero or negative.
- Non-finite, missing, non-positive, or `u_star <= min_ustar` rows are set to
  `NA` with a warning mentioning profile-derived friction velocity.

Relation to neutral profile assumptions:

- This path only changes the exchange velocity scale used in the same neutral
  Bulk resistance formula.
- It is profile-like because it uses two wind heights.
- It is not the Monin/Profile method and does not apply the full stability
  functions used by `sensible_monin()` or `latent_monin()`.

Tests:

- Exact formula tested in `test-bulk-exchange-velocity.R`.
- Missing `v2` error tested.
- Non-positive profile-derived `u_star` guard tested.
- Weather-station wrapper pass-through tested.
- `turb_flux_bulk_residual(..., exchange_velocity = "u_star_profile")`
  pass-through tested.

### 5.3 u_star_roughness variant

Formula:

```r
if (is.null(v2)) {
  v_ref <- v1
  z_ref <- z1
} else {
  v_ref <- v2
  z_ref <- z2
}

if (!is.null(obs_height)) {
  z0 <- turb_roughness_length(obs_height = obs_height)
} else {
  z0 <- turb_roughness_length(surface_type = surface_type)
}

u_star <- k * v_ref / log(z_ref / z0)
r_a <- log(z2 / z1) / (k * u_star)
H_bulk <- rho * cp * (t1 - t2) / r_a
```

Inputs:

- Required: `t1`, `t2`, `v1`, `z1`, `z2`, and either `surface_type` or
  `obs_height`.
- Optional: `v2`.
- If `v2` is present, the reference is `v2` at `z2`.
- If `v2` is absent, the reference is `v1` at `z1`.

`z0` source:

- `obs_height`: `turb_roughness_length()` returns `0.1 * obs_height`.
- `surface_type`: `turb_roughness_length()` looks up
  `surface_properties$roughness_length`.
- `obs_height` has priority if both are present.

Behavior with missing/invalid roughness input:

- Missing both `surface_type` and `obs_height` causes an error:
  `"exchange_velocity = 'u_star_roughness' requires surface_type or obs_height."`
- Invalid `z0`, non-finite `z0`, `z0 <= 0`, `z_ref <= z0`, or invalid/small
  `u_star` rows become `NA` with warning.

Tests:

- Exact formula tested in `test-bulk-exchange-velocity.R`.
- Missing roughness source error tested.
- Weather-station wrapper pass-through tested.

### 5.4 ri_guard / stability guard

Is `Ri_g` calculated?

- Yes, when `stability_method = "ri_guard"`.
- It requires `v2`; missing `v2` stops with an error.

Formula implemented:

```r
theta_mean <- (theta1 + theta2) / 2
dtheta_dz <- (theta2 - theta1) / (z2 - z1)
du_dz <- (v2 - v1) / (z2 - z1)
Ri_g <- (g / theta_mean) * dtheta_dz / (du_dz^2)
```

Temperature handling:

- If `elev` is supplied, the code computes `theta1` and `theta2` as
  `temp_pot_temp(t, elev) + 273.15`.
- If `elev` is not supplied, it uses `t + 273.15` as a near-surface
  approximation.

Is H corrected or filtered?

- Filtered only.
- The neutral H estimate is computed first.
- Valid unstable, neutral and stable cases are returned unchanged.
- Invalid or very stable cases are set to `NA`.

Thresholds:

- `ri_neutral = 0.01` default.
- `ri_critical = 0.25` default.
- `min_shear = 1e-4` default.
- Classification in `sensible_bulk.default()`:
  - `Ri_g < 0`: `"unstable"`
  - `abs(Ri_g) <= ri_neutral`: `"neutral"`
  - `Ri_g > ri_neutral & Ri_g < ri_critical`: `"stable"`
  - `Ri_g >= ri_critical`: `"very_stable"`

What becomes `NA`?

- Invalid potential-temperature state, invalid gradients, weak shear, non-finite
  `Ri_g`, or `"very_stable"` rows.
- The returned H vector receives attributes `bulk_Ri_g` and `bulk_stability`.

Tests:

- `test-bulk-stability.R`: default unchanged, requires `v2`, classifies
  unstable/neutral/stable, very stable to `NA`, zero shear to `NA`, row-local
  invalid handling, weather-station pass-through.
- `test-equation-contracts.R`: expected Richardson numbers and classes.

## 6. Bulk residual latent heat

The residual latent heat implementation is exactly:

```r
LE_res = rad_bal - soil_flux - sensible
```

Using this document's notation:

```r
LE_res = Q* - B - H_bulk
```

Details:

- `latent_bulk_residual.default(rad_bal, soil_flux, sensible, ...)` computes
  directly from the supplied `sensible` vector.
- `latent_bulk_residual.weather_station(weather_station, sensible = NULL, ...)`
  reads `weather_station$rad_bal` and `weather_station$soil_flux`.
- If `sensible` is supplied, that vector is used.
- If `sensible` is `NULL`, the wrapper computes `sensible_bulk.weather_station()`
  internally using the same `...`.
- `turb_flux_bulk_residual()` supplies the just-computed `h_bulk` explicitly, so
  `latent_bulk_residual()` does not recompute H in that workflow.
- `turb_flux_bulk_residual()` writes the output field
  `latent_bulk_residual` into the returned weather_station object.

Formal closure:

```r
H_bulk + LE_res = H_bulk + (Q* - B - H_bulk) = Q* - B = A
```

Therefore:

```r
R_E = Q* - B - H_bulk - LE_res = 0
```

This is formal/algebraic closure only. It does not validate:

- the measured or supplied `Q* = rad_bal`,
- the measured or supplied `B = soil_flux`,
- the selected Bulk exchange-velocity assumption,
- the computed `H_bulk`.

Errors in any of those quantities are absorbed into `LE_res`.

## 7. Bulk combined workflow

### `turb_flux_bulk_residual()`

Implementation order:

1. `check_availability(weather_station, "t1", "t2", "v1", "z1", "z2", "rad_bal", "soil_flux")`.
2. `h_bulk <- sensible_bulk(weather_station, ...)`.
3. `le_residual <- latent_bulk_residual(weather_station, sensible = h_bulk, ...)`.
4. Write `weather_station$sensible_bulk <- h_bulk`.
5. Write `weather_station$latent_bulk_residual <- le_residual`.
6. Return the modified copy.

Outputs:

- `sensible_bulk`
- `latent_bulk_residual`

Existing fields:

- The function mutates the local copy and returns it.
- Existing fields with the names `sensible_bulk` or `latent_bulk_residual` would
  be overwritten in the returned object.
- Tests verify original input fields such as `datetime`, `rad_bal`, and
  `soil_flux` are preserved in the returned object.

NA/missing handling:

- Missing required fields abort through `check_availability()`.
- Invalid Bulk rows can become `NA` according to the selected Bulk path.
- The workflow does not catch Bulk errors.

### `turb_flux_calc()`

`turb_flux_calc(weather_station, pt_only = FALSE)` includes Bulk in the full
workflow:

```r
sensible_blk <- sensible_bulk(weather_station)
latent_blk_res <- latent_bulk_residual(weather_station, sensible = sensible_blk)
...
weather_station$sensible_bulk <- sensible_blk
weather_station$latent_bulk_residual <- latent_blk_res
```

If `pt_only = TRUE`, Bulk is not run and Bulk fields are not added. Tests verify
this.

Full workflow outputs include:

- `stability`
- `sensible_priestley_taylor`
- `latent_priestley_taylor`
- `sensible_bowen`
- `latent_bowen`
- `sensible_monin`
- `latent_monin`
- `latent_penman`
- `sensible_bulk`
- `latent_bulk_residual`

Penman errors are caught and converted to an `NA` vector with warning. Other
missing/invalid required fields can abort before that fallback. Tests explicitly
cover this behavior.

Energy-closure field names:

- `energy_balance_closure(..., methods = "bulk_residual")` expects
  `sensible_bulk` and `latent_bulk_residual`.

## 8. Bulk relation to closure diagnostics

`energy_balance_closure()` recognizes Bulk-Residual through the method spec:

```r
bulk_residual = list(
  closure_type = "residual_closure",
  sensible = "sensible_bulk",
  latent = "latent_bulk_residual",
  penman = FALSE,
  monin = FALSE
)
```

For Bulk:

- H field: `sensible_bulk`
- LE field: `latent_bulk_residual`
- `available_energy = rad_bal - soil_flux = Q* - B`
- `turbulent_sum = sensible_bulk + latent_bulk_residual`
- `closure_residual = available_energy - turbulent_sum`
- `closure_ratio = turbulent_sum / available_energy` when `abs(A) >= min_available`
- `closure_type = "residual_closure"`

Status handling:

- Missing `sensible_bulk` or `latent_bulk_residual` field:
  `status = "missing_fields"` for the method block.
- Non-finite required values:
  `status = "missing"`.
- `abs(available_energy) < min_available`:
  `status = "low_available_energy"` and ratio remains `NA`.
- `abs(closure_residual) > 100`:
  `status = "large_residual"` for paired methods.
- For correct Bulk-Residual outputs produced by the package, the residual should
  be near zero because LE is defined as the residual.

| Bulk field | Meaning | Produced by | Used by closure | Interpretation |
|---|---|---|---|---|
| `rad_bal` | `Q*`, net radiation | user input or external calculation | yes | Radiative input at surface. |
| `soil_flux` | `B`, soil heat flux | user input or external/helper calculation | yes | Positive into soil. |
| `sensible_bulk` | Bulk sensible heat estimate | `sensible_bulk()` / workflows | yes, H | Estimated from temperature gradient and exchange velocity. |
| `latent_bulk_residual` | Residual latent heat | `latent_bulk_residual()` / workflows | yes, LE | Algebraic remainder `Q* - B - H_bulk`. |
| `closure_residual` | Bulk closure check | `energy_balance_closure()` | output diagnostic | Should be zero/near zero when Bulk fields were produced consistently. |
| `closure_ratio` | Formal ratio `(H + LE)/A` | `energy_balance_closure()` | output diagnostic | Should be one/near one except low available energy/NA cases. |

Why Bulk-Residual is `residual_closure`:

- Its LE output is explicitly computed as the remainder after subtracting
  `H_bulk` from available energy.
- Closure is an arithmetic property of the output construction.

## 9. Bulk compared with Monin/Profile

Implementation-level answers:

- Bulk is not equivalent to Monin-Obukhov.
- Bulk does not use the full stability functions implemented in
  `sensible_monin()` and `latent_monin()`.
- `u_star_profile` only provides a profile-derived friction velocity for the
  same neutral Bulk resistance structure.
- `u_star_roughness` only provides a roughness-derived friction velocity for the
  same neutral Bulk resistance structure.
- `ri_guard` does not correct H for stability. It only filters invalid or very
  stable cases to `NA` and attaches Richardson diagnostics.
- Bulk is a neutral transfer approach whenever `stability_method = "none"`,
  which is the default. It remains neutral even with different exchange velocity
  scales.
- Monin/Profile is the implemented stability/profile method. It computes
  `sensible_monin` and `latent_monin` from profile gradients, friction velocity,
  Monin length, and Businger-type stability functions. Its outputs are not
  forced to close `Q* - B`.

## 10. Bulk use cases and limitations

| Use case | Why Bulk fits | Which Bulk variant | Required inputs | Main limitation | Diagnostic check |
|---|---|---|---|---|---|
| Simple standard station with two temperature heights | Computes H from `t1 - t2` and wind without full profile stability method. | `wind_mean` default | `t1`, `t2`, `v1`, `z1`, `z2`; optional `v2` | Neutral approximation; low wind rows become `NA`. | Check warning/NA output and sign of `sensible_bulk`. |
| Comparison of `H_bulk` against available energy | `H_bulk` is an independent H estimate relative to A before residual LE assignment. | any implemented exchange variant | Bulk inputs plus `rad_bal`, `soil_flux` if comparing to A | A may be wrong if `Q*` or `B` are erroneous. | `energy_balance_closure()` after `latent_bulk_residual()` shows formal closure, not H quality. |
| Residual-LE teaching example | `LE_res = Q* - B - H_bulk` is explicit and tested. | usually `wind_mean`; profile variants also work | Bulk workflow fields plus `Q*`, `B` | Residual LE absorbs all errors in H, Q*, and B. | `H_bulk + LE_res == Q* - B`. |
| Coarse energy-balance closure | Output closes by construction. | any H variant | `t1`, `t2`, `v1`, `z1`, `z2`, `rad_bal`, `soil_flux`; plus variant inputs | Closure is algebraic only. | `closure_residual = 0`, `closure_ratio = 1` when finite and A not low. |
| Weak wind | Guards avoid unstable resistance division. | all variants, with path-specific thresholds | wind inputs | Returns `NA` for invalid/small velocity scale. | Warnings and `is.na(sensible_bulk)`. |
| Stable stratification | Optional screen can remove very stable Richardson cases. | `wind_mean` or other exchange variants plus `ri_guard` | `v2` required; Bulk fields; optional `elev` | Guard filters only; no correction. | `attr(H, "bulk_stability")`, `attr(H, "bulk_Ri_g")`. |
| Uncertain roughness | Roughness path can test sensitivity to `z0`. | `u_star_roughness` | `surface_type` or `obs_height` | Depends on table or obstacle-height assumption. | Compare `sensible_bulk` across exchange variants. |
| Wrong heights | Height guards stop invalid geometry. | all variants | scalar `z1`, `z2` with `0 < z1 < z2` | Mismatched real sensor heights cannot be detected beyond values supplied. | Errors from `sensible_bulk.default()`. |
| Erroneous `Q*`/`B` | Residual exposes formal accounting but cannot correct inputs. | Bulk-Residual workflow | `rad_bal`, `soil_flux`, Bulk fields | LE residual inherits energy-input errors. | Closure diagnostics close formally even if inputs are physically wrong. |

## 11. Exact formula set for graphics

Bulk sensible:

```text
H_bulk = rho c_p * Delta T / r_a
Delta T = t1 - t2
r_a = log(z2 / z1) / (k * velocity_scale)
```

Bulk residual:

```text
LE_res = Q* - B - H_bulk
```

Available energy:

```text
A = Q* - B
```

Closure:

```text
R_E = Q* - B - H_bulk - LE_res = 0 by definition
```

`wind_mean`:

```text
velocity_scale = v1              if v2 is missing
velocity_scale = (v1 + v2) / 2   if v2 is supplied
```

`u_star_profile`:

```text
u* = k (v2 - v1) / log(z2 / z1)
velocity_scale = u*
```

`u_star_roughness`:

```text
z0 = 0.1 obs_height
or
z0 = roughness_length(surface_type)

u* = k u_ref / log(z_ref / z0)
velocity_scale = u*
```

`ri_guard`:

```text
Ri_g = (g / theta_mean) * (Delta theta / Delta z) / (Delta u / Delta z)^2
filter only: invalid or very_stable -> H_bulk = NA
not a stability correction
```

## 12. Exact wording for graphics

### Bulk-Residual

Method equation:

```text
H_bulk = rho c_p (t1 - t2) / r_a
LE_res = Q* - B - H_bulk
```

Use:

```text
Neutral Bulk estimate of sensible heat, followed by residual latent heat.
Exchange velocity can be mean wind, profile-derived u*, or roughness-derived u*.
```

Limitations:

```text
No full Monin-Obukhov stability correction. ri_guard filters invalid or very
stable cases only. LE_res absorbs errors in Q*, B, and H_bulk.
```

Closure:

```text
H_bulk + LE_res = Q* - B by construction. This is formal closure, not physical validation.
```

### Monin/Profile

Method equation:

```text
H_monin and LE_monin are profile/stability flux estimates from gradients,
u*, Monin length, and Businger-type stability functions.
```

Use:

```text
Profile-based diagnostic flux estimates from two heights.
```

Limitations:

```text
Requires complete temperature, humidity and wind profiles plus roughness source.
Numerical profile states can return NA.
```

Closure:

```text
Not forced to close Q* - B. R_E is diagnostic.
```

### Penman

Method equation:

```text
LE_penman = combination-equation latent heat flux.
```

Use:

```text
Latent-heat-only estimate using radiation, soil heat flux, temperature,
humidity, wind, site metadata, aerodynamic resistance and surface resistance.
```

Limitations:

```text
No paired sensible heat output.
```

Closure:

```text
unresolved_complement = Q* - B - LE_penman.
This complement is not H.
```

### Priestley-Taylor

Method equation:

```text
LE_PT = alpha sc/(sc + gam) * (Q* - B)
H_PT = (Q* - B) - LE_PT
```

Use:

```text
Available-energy partition using temperature and surface-type alpha.
```

Limitations:

```text
Depends on package coefficient tables and surface_type.
```

Closure:

```text
Formal partition closure when H_PT and LE_PT use the same inputs.
```

### Bowen

Method equation:

```text
beta = gamma_code * (Delta theta / Delta z) / (Delta AH / Delta z)
H_Bowen = A beta/(1 + beta)
LE_Bowen = A/(1 + beta)
```

Use:

```text
Partitions available energy using temperature and humidity gradients.
```

Limitations:

```text
Near-zero or invalid denominator can produce NA or capped diagnostic output.
```

Closure:

```text
Formal closure for finite uncapped denominator cases.
```

## 13. Do-not-say list

- Do not say Bulk residual closure validates `H_bulk`.
- Do not use `latent_bulk_residual` as the only explanatory text without the
  explicit formula `LE_res = Q* - B - H_bulk`.
- Do not say Bulk equals Monin-Obukhov.
- Do not say `u_star_profile` makes Bulk a Monin-Obukhov method.
- Do not say `ri_guard` is a full stability correction; it is only a guard/filter.
- Do not call the Penman complement `H`.
- Do not imply Monin/Profile residuals should be closed or rescaled to zero.
- Do not mix `R_n/G` and `Q*/B` notation in the same figure without explicit
  mapping. For the requested figure use `Q* = rad_bal` and `B = soil_flux`.
- Do not present formal closure as empirical physical validation.
- Do not imply missing profile, wind, roughness, `Q*`, or `B` values are filled
  by Bulk workflows.

