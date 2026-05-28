# fieldClim physics formula audit

Status: working audit scaffold v0.1  
Scope: formula, sign-convention, unit and wrapper audit for the `fieldClim` package  
Primary package objective: reproducible microclimate energy-balance and heat-flux workflows from weather-station data

This document is the control document for the physics audit. It is not a general package vignette and not a bug-fix log. Its purpose is to check every physical formula used by `fieldClim` against explicit source references and against the implemented R code.

The audit must keep five questions separate:

1. Is the source formula correct for the intended method?
2. Is the formula implemented correctly in the R code?
3. Is the sign convention consistent?
4. Are the units and input variables consistent?
5. Does the wrapper or workflow pass the right fields to the formula?

No package source code should be changed while filling this document. Fixes come only after the audit table identifies a specific mismatch.

---

## 1. Source hierarchy

The audit uses the following hierarchy.

| Level | Source | Role in the audit |
|---|---|---|
| 1 | Bendix, *Geländeklimatologie* | Geländeklima framing, radiation balance, albedo, longwave radiation, soil heat flux, surface energy balance and sign convention |
| 2 | Foken, *Angewandte Meteorologie: Mikrometeorologische Methoden* | Micrometeorological reference for flux-gradient similarity, profile methods, Monin-Obukhov similarity, Bowen-ratio logic, turbulent exchange and measurement-method logic |
| 3 | Oke / Oke et al. | Surface-energy-balance terminology and plausibility frame for `Rn`, `G`, `H`, `LE` and storage |
| 4 | `fieldClim` package code | Implementation to be checked; not the source of truth |

The package code is therefore audited against the sources. It is not allowed to use the current implementation as its own justification.

---

## 2. Master sign convention

The working sign convention for the package audit is:

| Package symbol | Teaching symbol | Meaning | Positive direction |
|---|---|---|---|
| `Rn` | `Q_star` / `Q*` | net radiation / radiation balance | energy input at the surface |
| `G` | `B` | soil heat flux | into the soil |
| `H` | `L` | sensible heat flux | away from the surface |
| `LE` | `V` | latent heat flux | away from the surface |
| `S` | `S` | storage term | positive storage in the control volume, if explicitly used |

Bendix uses the surface heat-balance notation:

$$
0 = Q^{*} - B - L - V
$$

with `Q*` as radiation balance, `B` as soil heat flux, `L` as sensible heat flux and `V` as latent heat flux, all in W m-2. The audit adopts the same teaching notation and maps it to the package notation.

Therefore:

$$
Q^{*} = B + L + V
$$

when the storage term is omitted.

In package notation this becomes:

$$
Rn = G + H + LE
$$

If the storage term is explicitly included:

$$
Rn = G + H + LE + S
$$

For the teaching workflow used in the current vignettes:

$$
S \approx 0
$$

Therefore the available turbulent energy is:

$$
Rn - G = H + LE
$$

or equivalently:

$$
Q^{*} - B = L + V
$$

The residual latent heat flux is:

$$
LE = Rn - G - H
$$

or:

$$
V = Q^{*} - B - L
$$

Audit requirement: every function that consumes or returns `Rn`, `G`, `H`, `LE`, `Q_star`, `B`, `L` or `V` must explicitly match this sign convention or must document a deliberate exception.

---

## 3. Audit order

The audit must follow this order. Do not start with Monin-Obukhov.

1. Master sign convention: `Q*`/`B`/`L`/`V` mapped to `Rn`/`G`/`H`/`LE`.
2. Radiation: `K*`, `L*`, `Rn`.
3. Soil heat flux: `G` / `B`.
4. Available energy: `Rn - G`.
5. Priestley-Taylor closure.
6. Bulk and residual workflow.
7. Bowen partitioning and singular cases.
8. Penman latent-heat path.
9. Monin-Obukhov profile and stability path.
10. `weather_station` and `turb_flux_calc()` wrapper logic.

Rationale: if `Rn`, `G` or their signs are unclear, the later heat-flux methods cannot be interpreted.

---

## 4. Audit status codes

Use only these status values.

| Status | Meaning |
|---|---|
| `open` | not yet checked against code and source |
| `source-ok-code-open` | source formula identified; implementation not yet checked |
| `code-ok` | code matches source formula and sign convention |
| `code-mismatch` | implementation differs from source or package convention |
| `sign-mismatch` | formula may be mathematically related, but sign convention is inconsistent |
| `unit-mismatch` | units or conversion factors are inconsistent |
| `wrapper-mismatch` | formula may be correct, but the S3/weather_station/workflow wrapper passes wrong fields |
| `implementation-specific` | deliberate implementation choice; must be documented and tested |
| `diagnostic-only` | function is not expected to close the energy balance, but must be plausibility-checked |
| `deprecated-or-historical` | historical output; not a current numerical reference |

---

## 5. Formula audit matrix

### 5.1 Radiation

| Group | Function / variable | Source formula | Code formula | Sign convention | Unit check | Closure / invariant | Source role | Status | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Shortwave radiation | `rad_sw_bal()` | $$K^{*}=K_{\downarrow}-K_{\uparrow}$$ | tbd | incoming positive, reflected outgoing subtracted | W m-2 | component check | Bendix/Oke | open | Check argument names and whether upward component is passed as positive magnitude. |
| Albedo | albedo calculation | $$\alpha=\frac{K_{\uparrow}}{K_{\downarrow}}$$ | tbd | ratio; no flux direction | dimensionless | expected range 0-1 for normal cases | Bendix | open | Must handle low `K_down` threshold to avoid unstable ratios. |
| Longwave radiation | `rad_lw_bal()` | $$L^{*}=L_{\downarrow}-L_{\uparrow}$$ | tbd | downward positive, upward subtracted | W m-2 | component check | Bendix/Oke | open | Check if code uses `L_down - L_up` or the opposite convention. |
| Net radiation | `rad_bal()` | $$Rn=K^{*}+L^{*}$$ | tbd | net radiative input positive | W m-2 | `Rn` equals sum of components if same processing level | Bendix/Oke | open | Must not silently replace measured `rad_net` when component series are on another processing level. |
| Solar geometry | `sol_hour_angle()` | astronomical hour-angle relation | tbd | local solar time required | radians or degrees, must be documented | expected diurnal symmetry | Bendix/Foken/Oke | open | Known risk: POSIXct/POSIXlt handling and local time zone. |
| Solar elevation | `sol_elevation()` | solar elevation from latitude, declination, hour angle | tbd | positive above horizon | degrees or radians, must be documented | night/day plausibility | Bendix/Oke | open | Check whether return unit is documented and consistently used downstream. |
| Atmospheric transmission | `trans_*()` | transmission as attenuation of extraterrestrial/direct radiation | tbd | transmission factor positive | dimensionless | range mostly 0-1 for simple cases | Bendix | open | Check air-mass and elevation handling. |
| Terrain geometry | `terr_*()` | slope, aspect, sky-view or terrain factors | tbd | geometry convention must be explicit | degrees/radians or dimensionless | geometric range checks | Bendix | open | Check aspect convention and radiation-facing convention. |

### 5.2 Soil heat flux and soil parameters

| Group | Function / variable | Source formula | Code formula | Sign convention | Unit check | Closure / invariant | Source role | Status | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Soil heat flux | `soil_heat_flux()` / `soil_flux` | $$B=\lambda\frac{dT}{dz}$$ | tbd | positive into the soil | W m-2 | `Rn - G` decreases when `G` increases | Bendix/Oke | open | Bendix uses molecular heat conduction as mechanism for `B`; check sign of vertical coordinate in code. |
| Soil attenuation | `soil_attenuation()` | attenuation with depth from thermal diffusivity / damping depth | tbd | amplitude decays with depth | dimensionless or W m-2 depending implementation | deeper layer lower amplitude | Bendix/Foken | open | Argument forwarding was previously corrected; audit formula and order of arguments. |
| Soil thermal conductivity | `soil_thermal_cond()` | conductivity as function of texture / moisture / material | tbd | positive material property | W m-1 K-1 | positive finite values | Bendix | open | Check units and valid texture/moisture ranges. |
| Volumetric heat capacity | soil heat capacity helper, if present | $$C_v=\rho c$$ or package-specific parameterization | tbd | positive material property | J m-3 K-1 | positive finite values | Bendix/Foken | open | Needed for storage or attenuation if used. |
| Available energy | derived variable | $$Rn-G$$ | tbd | energy available for `H + LE` | W m-2 | `H + LE = Rn - G` for partition methods | Bendix/Oke | open | Central invariant for PT, Bowen, Bulk-Residual. |

### 5.3 Humidity, pressure and temperature helper formulas

| Group | Function / variable | Source formula | Code formula | Sign convention | Unit check | Closure / invariant | Source role | Status | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Saturation vapour pressure | `hum_*()` / saturation helper | Clausius-Clapeyron / Magnus-type relation | tbd | positive scalar | Pa or hPa must be explicit | monotonic increase with temperature | Foken/Oke/FAO-type reference if used | open | Check Celsius/Kelvin handling. |
| Actual vapour pressure | humidity helper | from relative humidity and saturation vapour pressure | tbd | positive scalar | Pa or hPa | `e <= e_s` for RH <= 100% | Foken/Oke | open | Check percent vs fraction. |
| Vapour pressure deficit | humidity helper | $$VPD=e_s-e_a$$ | tbd | positive when air is unsaturated | Pa or hPa | zero at saturation | Foken/Oke | open | Used by Penman-like formulas. |
| Psychrometric constant | pressure / evap helper | $$\gamma = c_p p / (\epsilon \lambda)$$ | tbd | positive scalar | kPa K-1 or Pa K-1 | unit consistency with `Delta` | Foken/Oke/FAO-type reference if used | open | Crucial for PT and Penman. |
| Slope of saturation curve | temperature / evap helper | $$\Delta = \frac{d e_s}{dT}$$ | tbd | positive scalar | kPa K-1 or Pa K-1 | positive and temp-dependent | Foken/Oke/FAO-type reference if used | open | Must use same pressure units as `gamma`. |
| Air density | pressure/temp helper | ideal gas relation or package constant | tbd | positive scalar | kg m-3 | plausible range near 1.2 kg m-3 | Foken/Oke | open | Used by bulk and other turbulent formulas. |
| Potential temperature | `temp_*()`, if used | standard potential temperature relation | tbd | scalar | K | increases/decreases by pressure level | Foken | open | Only audit if used in flux/stability logic. |

### 5.4 Energy balance and closure

| Group | Function / variable | Source formula | Code formula | Sign convention | Unit check | Closure / invariant | Source role | Status | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Surface energy balance | package convention | $$Rn=G+H+LE+S$$ | tbd | package convention | W m-2 | master invariant | Bendix/Oke | source-ok-code-open | Teaching workflow omits `S`; check every method against this. |
| Teaching closure | PT/Bowen/Bulk | $$Rn-G=H+LE$$ | tbd | `G` positive into soil | W m-2 | exact for partition/residual methods | Bendix/Oke | source-ok-code-open | Does not apply as hard closure to MO path. |
| Residual latent heat | residual methods | $$LE=Rn-G-H$$ | tbd | `LE` positive away | W m-2 | exact closure by construction | Bendix/Oke | source-ok-code-open | Residual inherits errors from `Rn`, `G`, and `H`. |

### 5.5 Heat-flux methods

| Group | Function / variable | Source formula | Code formula | Sign convention | Unit check | Closure / invariant | Source role | Status | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Bulk sensible heat | `sensible_bulk()` | $$H_{bulk}=\rho c_p \frac{\Delta T}{r_a}$$ | implemented, audit required | `H > 0` away; expected `Delta T = T_lower - T_upper` | W m-2 | no direct closure alone | Bendix/Foken/Oke | open | Check that `t1`, `t2`, `z1`, `z2` order is lower/upper and documented. |
| Bulk aerodynamic resistance | internal to `sensible_bulk()` | $$r_a=\frac{\ln(z_2/z_1)}{k\bar{u}}$$ | implemented, audit required | resistance positive | s m-1 | finite positive for valid wind | Foken | open | Simplified neutral/log-profile resistance; not full MO stability correction. |
| Bulk residual latent heat | `latent_bulk_residual()` | $$LE_{res}=Rn-G-H_{bulk}$$ | implemented, audit required | `LE > 0` away | W m-2 | exact closure | Bendix/Oke | open | Check exact equality within numeric tolerance. |
| Bulk workflow | `turb_flux_bulk_residual()` | first `H_bulk`, then `LE_res` | implemented, audit required | follows package convention | W m-2 | exact closure | Bendix/Foken/Oke | open | Check fields added to `weather_station`. |
| Priestley-Taylor latent heat | `latent_priestley_taylor()` | $$LE_{PT}=\alpha\frac{\Delta}{\Delta+\gamma}(Rn-G)$$ | tbd | `LE > 0` away | W m-2 | with `H_PT`, exact closure expected | Foken/Oke | open | PT formula reportedly unchanged; documentation/tests were aligned to `Rn-G`. |
| Priestley-Taylor sensible heat | `sensible_priestley_taylor()` | $$H_{PT}=(Rn-G)-LE_{PT}$$ | tbd | `H > 0` away | W m-2 | exact closure | Foken/Oke | open | Must verify sign of `H` and closure. |
| Bowen ratio | internal beta | $$\beta=\frac{H}{LE}$$ | tbd | dimensionless | dimensionless | partition depends on denominator | Foken | open | Source/code may use psychrometric terms and gradients; audit exact implementation. |
| Bowen sensible heat | `sensible_bowen()` | $$H_{Bowen}=\frac{\beta}{1+\beta}(Rn-G)$$ | tbd | `H > 0` away | W m-2 | exact closure except singular/capped cases | Foken/Oke | open | Check denominator handling when `1 + beta` approaches zero. |
| Bowen latent heat | `latent_bowen()` | $$LE_{Bowen}=\frac{1}{1+\beta}(Rn-G)$$ | tbd | `LE > 0` away | W m-2 | exact closure except singular/capped cases | Foken/Oke | open | Check cap policy, warnings, and equality with sensible path. |
| Penman latent heat | `latent_penman()` | energy term plus aerodynamic term | tbd | `LE > 0` away | W m-2 | LE only, no `H` closure | Foken/Oke | open | Must audit surface resistance mapping, humidity fallback and units. |
| Penman weather-station method | `latent_penman.weather_station()` | wrapper for `latent_penman()` | tbd | inherited | W m-2 | length and finite values | package wrapper | open | Known risk: `surface_type`, `rh` vs `hum1`, and obs height. |
| Monin sensible heat | `sensible_monin()` | profile/stability flux using MO similarity | tbd | must be explicit | W m-2 | diagnostic only, not forced closure | Foken | open | Check zero-gradient, low-wind and stability singular behaviour. |
| Monin latent heat | `latent_monin()` | profile/stability flux using MO similarity | tbd | must be explicit | W m-2 | diagnostic only, not forced closure | Foken | open | Check humidity gradient units, cap and stability sign. |
| Stability | `turb_flux_stability()` / `turb_flux_grad_rich_no()` | gradient Richardson / stability classification | tbd | stable/unstable convention explicit | dimensionless | classification plausible | Foken | open | Must not silently fail if `t1`, `t2` missing. |

### 5.6 Object and workflow wrappers

| Group | Function / variable | Source formula | Code formula | Sign convention | Unit check | Closure / invariant | Source role | Status | Notes |
|---|---|---|---|---|---|---|---|---|---|
| Station object | `build_weather_station()` | not a physics formula | tbd | must preserve semantic field names | mixed | required fields available | package wrapper | open | Check `temp`, `rh`, `t1`, `t2`, `hum1`, `hum2`, `v1`, `v2`, `z1`, `z2`, `rad_bal`, `soil_flux`. |
| Data frame output | `as.data.frame.weather_station()` | not a physics formula | tbd | no sign change allowed | mixed | values unchanged | package wrapper | open | Current flat object structure must be preserved. |
| Availability check | `check_availability()` | not a physics formula | tbd | no sign change | none | meaningful error messages | package wrapper | open | Ensure method-specific requirements match the actual formulas. |
| Full workflow | `turb_flux_calc()` | orchestration | tbd | no sign change allowed | W m-2 | PT/Bowen/Bulk closures, MO diagnostic | package wrapper | open | Check `pt_only=TRUE` remains PT-only. |
| Bulk workflow | `turb_flux_bulk_residual()` | orchestration | implemented, audit required | no sign change allowed | W m-2 | exact closure | package wrapper | open | New regular package path. |
| Plotting | `plot_weather_station()` | no formula | tbd | no sign change | mixed | no data mutation | package wrapper | open | Plotting must not mutate fields. |

---


## Gate 0: temp_pot_temp()

Source file and line references:

- `R/temperature.R:1-20` documents `temp_pot_temp()` as potential temperature and states the potential-temperature formula.
- `R/temperature.R:27-35` defines `temp_pot_temp.default(t, elev, ...)`, documents `t` as temperature in degC and `elev` as elevation above sea level in m, computes pressure with `pres_p(elev, t, ...)`, converts `t` to Kelvin, and returns Celsius.
- `R/temperature.R:42-52` defines the `weather_station` method and passes `weather_station$elev` as the second argument.
- `R/pressure.R:12-19` documents the pressure helper formula and units.
- `R/pressure.R:34-38` implements `pres_p.default(elev, temp, ..., p0 = p0_default, g = g_default, rl = rl_default)`.
- `R/utility.R:2-5` defines `p0_default = 1013.25`, `g_default = 9.81`, `rl_default = 287.05`, and `c2k_default = 273.15`.
- `R/utility.R:294-305` defines `c2k()` and `k2c()`.
- `man/temp_pot_temp.Rd:18-20` documents `t` and `elev`.
- `man/temp_pot_temp.Rd:31-38` documents the potential-temperature formula.
- `tests/testthat/test-temperature.R:2-4` skips the test but shows the previous expected value `temp_pot_temp(25, 270) == 27.7`.

Implemented formula:

The default method implements a two-step calculation:

$$
p = 1013.25 \cdot \exp\left(-\frac{9.81 \cdot elev}{287.05 \cdot (t + 273.15)}\right)
$$

where `p` is in hPa, `elev` is in m, and `t` is in degC before conversion.

Then:

$$
\theta_C = (t + 273.15)\left(\frac{1000}{p}\right)^{0.286} - 273.15
$$

where `theta_C` is returned in degC. The implemented exponent `0.286` is the rounded ratio `R / c_p`.

Documented formula:

`man/temp_pot_temp.Rd` documents:

$$
\theta = T \left(\frac{p_0}{p}\right)^{R/c_p}
$$

with `T` in K, `p0 = 1000 hPa`, `p` as actual pressure, `R = 287 J kg-1 K-1`, and `c_p = 1004 J kg-1 K-1`.

Unit interpretation:

- `t`: air temperature in degC; converted internally to K for the formula.
- `elev`: elevation above sea level in m. This is the second argument. It is not pressure.
- `...`: forwarded to `pres_p()`, allowing pressure-helper constants such as `p0`, `g`, and `rl` to be overridden.
- Internal `p`: actual air pressure in hPa, derived from `elev` and `t` by `pres_p()`.
- Internal `p0` in `temp_pot_temp.default()`: potential-temperature reference pressure, fixed at `1000 hPa`.
- Return value: potential temperature in degC.

Expected numeric calculation for `temp_pot_temp(25, 270)`:

First compute actual pressure from elevation:

$$
p = 1013.25 \cdot \exp\left(-\frac{9.81 \cdot 270}{287.05 \cdot 298.15}\right)
  = 982.371659115193\ \text{hPa}
$$

Then compute potential temperature:

$$
\theta_C = 298.15 \left(\frac{1000}{982.371659115193}\right)^{0.286} - 273.15
  = 26.520455365680^\circ C
$$

Rounded to one decimal place, this is `26.5`, explaining why `temp_pot_temp(25, 270)` returns `26.5`.

Why the previous test expected `27.7`:

The skipped test expected `27.7`. That value is consistent with using `1013.25 hPa` as the potential-temperature reference pressure in the numerator instead of the documented and implemented `1000 hPa`:

$$
298.15 \left(\frac{1013.25}{982.371659115193}\right)^{0.286} - 273.15
  = 27.650725^\circ C
$$

Rounded to one decimal place, this gives `27.7`. Therefore the previous expectation appears to have used sea-level standard pressure `1013.25 hPa` as the potential-temperature reference pressure. The current implementation instead uses `1013.25 hPa` only inside `pres_p()` as the sea-level pressure for deriving actual pressure from elevation, and uses `1000 hPa` as the potential-temperature reference pressure.

Mismatch classification:

`test expectation wrong`.

The second argument is clearly documented and implemented as elevation, not pressure. The implemented potential-temperature formula matches the documented formula if `p` is interpreted as pressure derived from elevation and if `p0 = 1000 hPa` is the reference pressure. The skipped test expectation `27.7` conflicts with that documented reference pressure.

Audit status:

`code-ok` for `temp_pot_temp.default()` against the currently documented formula and argument units. Test expectation is inconsistent with the implementation and documentation.

Recommended next action:

After the audit gate, update the skipped test expectation to the implemented/documented value, preferably checking the unrounded value `26.520455365680` with a tolerance or explicitly checking one-decimal rounding to `26.5`. Consider adding a short documentation note that `elev` is converted internally to actual pressure with `pres_p()`, and that the `1013.25 hPa` constant in `pres_p()` is not the same as the `1000 hPa` potential-temperature reference pressure.

---

## 6. Specific checks to perform in code

### 6.1 Radiation checks

For `rad_sw_bal()`:

- Does the implementation compute `incoming - outgoing`?
- Does it assume `K_up` is positive magnitude or already negative?
- Are units documented as W m-2?
- Does the function accept vectors?
- Does it preserve `NA` positions?

Expected invariant:

$$
K^{*} = K_{\downarrow} - K_{\uparrow}
$$

For `rad_lw_bal()`:

- Does the implementation compute `L_down - L_up`?
- Are longwave components documented by direction?
- Is the result normally negative at night over a cooling surface?

Expected invariant:

$$
L^{*} = L_{\downarrow} - L_{\uparrow}
$$

For `rad_bal()`:

- Does the implementation compute `K_star + L_star`?
- Does it recompute components internally or accept already balanced components?
- Does it mix measured `rad_net` with derived component balances?

Expected invariant:

$$
Rn = K^{*} + L^{*}
$$

### 6.2 Soil checks

For soil heat flux:

- Is `G > 0` into the soil?
- Is the sign of `dT/dz` consistent with the vertical coordinate used in the code?
- Does a positive daytime soil heat flux reduce available energy?
- Does the function handle depth units consistently?

Expected invariant:

$$
Rn-G < Rn
$$

when:

$$
G>0
$$

For attenuation:

- Does amplitude decrease with depth?
- Is phase shift documented?
- Are thermal diffusivity and conductivity units consistent?

### 6.3 Priestley-Taylor checks

For `latent_priestley_taylor()` and `sensible_priestley_taylor()`:

- Does `latent_priestley_taylor()` use `Rn - G` and not `Rn + G`?
- Are `Delta` and `gamma` in the same pressure units?
- Does `sensible_priestley_taylor()` close the remaining energy?
- Does `pt_only=TRUE` produce only PT fields?

Expected invariant:

$$
H_{PT}+LE_{PT}=Rn-G
$$

### 6.4 Bulk-Residual checks

For `sensible_bulk()`:

- Does `Delta T` use lower minus upper air temperature?
- Is the sign of positive `H` away from surface?
- Does higher wind lower `r_a`?
- Are low wind cases controlled by `NA` or warning?
- Are extreme values warned but not silently capped?

Expected formulas:

$$
H_{bulk}=\rho c_p \frac{T_{lower}-T_{upper}}{r_a}
$$

$$
r_a=\frac{\ln(z_2/z_1)}{k\bar{u}}
$$

For `latent_bulk_residual()`:

- Does it compute exactly `Rn - G - H_bulk`?
- Does it preserve vector length?
- Does it not recompute `H_bulk` unless explicitly used as a weather-station method?
- Does it warn for extreme residuals?

Expected invariant:

$$
H_{bulk}+LE_{res}=Rn-G
$$

### 6.5 Bowen checks

For Bowen:

- Is `beta` defined consistently with `H/LE`?
- Are temperature and humidity gradient signs consistent with flux direction?
- Are units of humidity/dampfdruck converted correctly?
- Does the cap apply to `1 + beta`, not to an unrelated value?
- Are singular cases warned and traceable?

Expected invariant outside singular/capped cases:

$$
H_{Bowen}+LE_{Bowen}=Rn-G
$$

### 6.6 Penman checks

For Penman:

- Does the formula combine an energy term and an aerodynamic term?
- Does it use `Rn - G` as the energy term?
- Are `Delta`, `gamma`, vapour-pressure terms and wind functions in compatible units?
- Does `latent_penman.weather_station()` use profile humidity if available, otherwise `rh`?
- Does `surface_type = "field"` map to a valid resistance class?
- Does Penman return `LE` only and not a paired `H`?

Expected classification:

$$
\text{Penman path} = LE\text{-only}
$$

### 6.7 Monin-Obukhov checks

For Monin-Obukhov:

- Is the stability parameter sign convention explicit?
- Is neutral stratification represented by a stability parameter near zero?
- Does stable/unstable classification match source convention?
- Are zero-gradient cases controlled?
- Are low-wind and near-zero Monin-Obukhov length cases controlled?
- Are caps documented as numerical safeguards, not physical corrections?
- Is the method explicitly diagnostic against `Rn - G`, not forced to close it?

Expected diagnostic principle:

$$
H_{MO}+LE_{MO}
$$

is not required to equal:

$$
Rn-G
$$

but values must be checked against available energy for plausibility.

---

## 7. Synthetic tests required after audit

These are not the audit itself. They are the tests to write after the audit table has been filled.

### 7.1 Fixture set

Create `tests/testthat/helper-physics-fixtures.R`.

Required fixtures:

| Fixture | Purpose |
|---|---|
| standard daytime case | positive `Rn`, positive `G`, plausible positive gradients |
| zero-gradient case | no temperature or humidity gradient |
| inverted temperature-gradient case | negative sensible heat expected |
| small humidity-gradient case | Bowen denominator risk |
| low-wind case | bulk and Monin stability risk |
| high-soil-flux case | available energy decreases |
| missing optional Penman case | Penman non-fatal behaviour |
| surface-type mapping case | `surface_type = "field"` accepted |

### 7.2 Contract tests

Create `tests/testthat/test-physics-contract.R`.

Required tests:

| Test | Expected result |
|---|---|
| PT closure | `H_PT + LE_PT = Rn - G` |
| Bulk closure | `H_bulk + LE_res = Rn - G` |
| Bowen closure outside singular cases | `H_bowen + LE_bowen = Rn - G` |
| Positive soil heat flux | increasing `G` lowers `Rn - G` |
| Bulk sign | `T_lower > T_upper` gives positive `H_bulk` |
| Bulk low wind | returns `NA` or warning, no infinite flux |
| Penman field surface | `surface_type = "field"` accepted |
| Penman LE-only | no fake `H` output |
| Monin zero gradient | no uncontrolled extreme output |
| Monin low wind | controlled warning or `NA`, not silent absurd values |
| Wrapper preservation | `as.data.frame.weather_station()` does not change values |
| `pt_only` path | only PT fields required; no Penman/Bowen/MO requirements |

---

## 8. Codex task sequence

### Task 1: Audit only

```text
Create dev/physics-audit/physics-formula-audit.md from the package source.

Read:
- dev/physics-audit/physics-formula-audit.md
- R/*.R
- man/*.Rd
- vignettes/*.Rmd
- tests/testthat/*.R

Do not edit package source.
Do not change tests.
Do not refactor.

For every physical formula, fill:
- source formula
- implemented formula
- file and line reference
- sign convention
- unit assumptions
- input variables
- output variable
- closure invariant
- edge cases
- warning/cap logic
- status

Use Bendix, Foken and Oke as source hierarchy. If a formula cannot be verified from the available sources, mark `source-open`, not `ok`.
```

### Task 2: Contract tests only

```text
Add tests only. Do not change package source.

Add:
- tests/testthat/helper-physics-fixtures.R
- tests/testthat/test-physics-contract.R

Test the invariants listed in dev/physics-audit/physics-formula-audit.md:
- radiation component signs
- soil heat flux sign
- available energy
- Priestley-Taylor closure
- Bulk-Residual closure
- Bowen closure outside singular cases
- Penman field surface handling
- Monin zero-gradient and low-wind safeguards
- wrapper preservation
- pt_only isolation

Do not update reference values just to make tests pass.
```

### Task 3: Fix one subsystem at a time

```text
Fix only the failing tests for the selected subsystem.

Allowed subsystem for this run:
[ radiation | soil | humidity-pressure-temperature | Priestley-Taylor | Bulk | Bowen | Penman | Monin-Obukhov | wrappers ]

Do not change unrelated formulas.
Do not refactor.
Do not rename exported functions.
Do not change vignettes unless the fix changes documented behaviour.

Report:
- files changed
- formula changed or unchanged
- sign convention impact
- tests run
- tests passed/failed
```

---

## 9. Known starting points from current consolidation

These are known from the current package consolidation and must be verified, not assumed.

1. `pt_only = TRUE` in `turb_flux_calc()` is intended to compute only `sensible_priestley_taylor` and `latent_priestley_taylor`.
2. Priestley-Taylor is intended to close `Rn - G`.
3. Penman failures inside `turb_flux_calc()` are intended to be non-fatal.
4. Penman surface-type handling is intended to map common package surface types such as `field`.
5. `as.data.frame.weather_station()` is intended to support the current flat `weather_station` object.
6. Bowen denominator handling was made more robust, but the exact denominator logic must be audited.
7. Monin-Obukhov may be diagnostic-only and not energy-closing, but its sign, stability logic, caps and extreme outputs must be audited.
8. The new Bulk-Residual path is implemented and must be audited as a regular package method.

---

## 10. Non-goals during audit

The audit must not:

- silently repair code;
- rewrite formulas;
- normalize all methods to one answer;
- use Caldern as a truth dataset;
- treat historical rendered HTML outputs as current reference values;
- treat warnings as proof of error;
- treat formal energy closure as proof of physical plausibility;
- mix Eddy Covariance processing into this package audit.

Caldern is a real-data diagnostic case. It is not the source of formula truth.

---

## 11. Expected final audit outputs

After the audit is completed, the repository should contain:

```text
dev/physics-audit/physics-formula-audit.md
tests/testthat/helper-physics-fixtures.R
tests/testthat/test-physics-contract.R
```

Optional follow-up documents:

```text
docs/physics-fix-log.md
docs/physics-known-limitations.md
```

The final state should distinguish:

- formula confirmed;
- formula mismatch;
- sign mismatch;
- unit mismatch;
- wrapper mismatch;
- documented implementation-specific behaviour;
- method retained as diagnostic-only;
- method unsuitable as beginner default.

# fieldClim physics formula audit

Status: Physics Audit 1 completed for master sign convention and radiation only.  
Scope of this pass: `rad_*`, `sol_hour_angle()`, `sol_elevation()`, and `trans_*` functions directly used by radiation.  
Edit rule for this pass: package source, tests, and Rd files were not changed.

## Audit 1: Master Sign Convention And Radiation

### Source Material Read

- `R/radiation.R`: radiation balance, direct and diffuse shortwave, longwave, emissivity helpers.
- `R/solar.R`: solar elevation and hour-angle dependencies.
- `R/terrain.R`: terrain angle and sky-view factors used by radiation.
- `R/transmittance.R`: package file corresponding to the requested `R/transmission.R`; used directly by `rad_sw_in()` and `rad_diffuse_in()`.
- `man/rad_*.Rd` and `man/sol_*.Rd`: generated documentation for audited functions.
- `tests/testthat/test-solar.R`: only covers Julian day and `sol_medium_suntime()` timezone conversion.
- `tests/testthat/test-consolidation.R`: uses measured `rad_net` for flux workflows and checks packaged radiation columns, but does not assert modeled radiation formulas.
- `vignettes/*.Rmd`: radiation usage was checked where `rad_*`, `sol_*`, measured shortwave/longwave variables, or `rad_net` are used.

### Master Radiation Sign Convention

Target convention for this audit:

$$
Q^* = K^* + L^*
$$

$$
K^* = K_{down} - K_{up}
$$

$$
L^* = L_{down} - L_{up}
$$

Package mapping:

| Teaching symbol | Package/model variable | Meaning | Positive contribution |
|---|---|---|---|
| `Q*` | `rad_bal()` / measured `rad_net` | net all-wave radiation | net energy input to surface |
| `K_down` | `rad_sw_in() + rad_diffuse_in()` when modeled; `rad_sw_in` measured column in Caldern data | incoming shortwave | positive incoming magnitude |
| `K_up` | `rad_sw_out() + rad_diffuse_out()` when modeled; `rad_sw_out` measured column in Caldern data | reflected shortwave | positive outgoing magnitude, subtracted in balance |
| `K*` | `rad_sw_bal()` / measured `RsNet` | net shortwave radiation | `K_down - K_up` |
| `L_down` | `rad_lw_in()` / measured `LDnCo` | atmospheric longwave to surface | positive incoming magnitude |
| `L_up` | `rad_lw_out()` / measured `LUpCo` | surface longwave emission | positive outgoing magnitude, subtracted in balance |
| `L*` | `rad_lw_bal()` / measured `RlNet` | net longwave radiation | `L_down - L_up` |

Explicit check:

- `rad_sw_bal.default()` computes `sw_in - sw_out + diffuse_in - diffuse_out` at `R/radiation.R:87-98`, so the modeled shortwave balance follows `K* = K_down - K_up` if `K_down = SW_in + D_in` and `K_up = SW_out + D_out`.
- `rad_lw_bal.default()` computes `lw_in - lw_out` at `R/radiation.R:383-386`, so modeled longwave balance follows `L* = L_down - L_up`.
- `rad_bal.default()` computes `sw_bal + lw_bal` at `R/radiation.R:42-45`, so modeled net radiation follows `Q* = K* + L*`.
- Vignettes distinguish modeled/component checks from the working measured energy-balance series. In `vignettes/fieldclim_usecase.Rmd:335-439`, the text says `rad_net` and `K_down - K_up + L_down - L_up` are not automatically identical for the Caldern data. In `vignettes/fieldclim_additional.Rmd:269-280`, the workflow keeps `rad_net` as the working energy-balance series after validation.

### Function Audit Rows

| Function / item | Source formula category | Implemented formula | Documented formula | References | Input variables | Output variable | Unit assumptions | Sign convention | Expected invariant | Edge cases | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `rad_bal()` | Bendix | `rad_sw_bal(...) + rad_lw_bal(...)` | `R_total = R_sw + R_lw` | Code: `R/radiation.R:42-45`; docs: `R/radiation.R:7-13`, `man/rad_bal.Rd:37-39`; vignettes: `fieldclim_usecase.Rmd:335-439` | `datetime`, `lon`, `lat`, `elev`, `temp`, `rh`, `slope`, `exposition`, `valley`, `surface_type`, `surface_temp`; wrapper copies fields from `weather_station` | total modeled radiation balance, W m-2 | component balances are W m-2; `datetime` must expose POSIXlt fields for solar helpers | positive net radiation is net input; `Q* = K* + L*` | equals `rad_sw_bal() + rad_lw_bal()` exactly for same arguments | Does not consume measured `rad_net`; modeled `Q*` may differ from measured/component data; missing station fields fail only when accessed; no validation of vector length compatibility | `code-ok` for implemented/documented sign convention; measured-data equivalence remains `open` |
| `rad_sw_bal()` | Bendix | `sw_in - sw_out + diffuse_in - diffuse_out` | `R_sw = SW_in - SW_out + D_in - D_out` | Code: `R/radiation.R:87-98`; docs: `R/radiation.R:65-79`, `man/rad_sw_bal.Rd:35-37`; vignette call tree: `fieldclim_check_rad_soil.Rmd:52-81` | `datetime`, `lon`, `lat`, `elev`, `temp`, `slope`, `exposition`, `valley`, `surface_type` | modeled shortwave balance, W m-2 | direct/diffuse terms are positive magnitudes in W m-2; albedo dimensionless | incoming terms positive; reflected outgoing magnitudes subtracted; `K* = K_down - K_up` with diffuse included | `rad_sw_bal() == rad_sw_in() + rad_diffuse_in() - rad_sw_out() - rad_diffuse_out()` | At night direct/diffuse functions return 0 by solar-elevation guard; unknown `surface_type` can yield zero-length albedo; low sun and terrain shading depend on helper behavior | `code-ok` for balance sign; physical source/edge validation `open` |
| albedo handling | Implementation-specific using Bendix shortwave reflection concept | `albedo <- surface_properties[surface_type, ]$albedo`; `rad_sw_out = rad_sw_in * albedo`; `rad_diffuse_out = rad_diffuse_in * albedo` | `SW_out = SW_in * alpha`; `D_out = D_in * alpha`; measured-use vignettes compute effective albedo as `K_up / K_down` after filtering low `K_down` | Code: `R/radiation.R:299-302`, `R/radiation.R:342-345`, `R/utility.R:12-68`; docs: `R/radiation.R:278-291`, `R/radiation.R:321-334`, `man/rad_sw_out.Rd:34-36`; vignettes: `fieldclim_usecase.Rmd:155-227` | `surface_type`; internally modeled `SW_in` or `D_in`; surface table values | reflected direct or diffuse shortwave, W m-2 | albedo is dimensionless; table range appears intended as 0-1; no user-supplied numeric albedo argument | outgoing reflected shortwave is positive magnitude and is subtracted by `rad_sw_bal()` | for valid albedo, `0 <= SW_out <= SW_in` and `0 <= D_out <= D_in` | unknown or case-mismatched `surface_type` returns `numeric(0)`; no range validation; measured effective albedo is not a package helper and is unstable at low irradiance | `open` |
| `rad_sw_in()` | Bendix | `rad_sw_toa * 0.9751 * (trans_gas * trans_ozone * trans_rayleigh * trans_vapor * trans_aerosol) / sin(sol_elevation) * cos(terrain_angle)`, then `ifelse(out < 0 | elevation < 0, 0, out)` after degree-to-radian conversion | `SW_in = SW_toa * 0.9751 * T_total / sin(E) * cos(theta)` | Code: `R/radiation.R:139-155`; docs: `R/radiation.R:117-131`, `man/rad_sw_in.Rd:24-26`; terrain: `R/terrain.R:85-100`; trans: `R/transmittance.R:27-288` | `datetime`, `lon`, `lat`, `elev`, `temp`, `slope`, `exposition`; indirect `vis`, `ozone_column`, pressure constants through `...` | direct incoming shortwave, W m-2 | angles documented and returned in degrees, converted to radians internally; transmittances dimensionless; `elev` m; `temp` degC | incoming shortwave positive; negative/night values clipped to 0 | non-negative output for normal finite inputs; output should be 0 when solar elevation is below horizon | Uses `datetime$hour` through solar helpers, so POSIXct is risky unless converted; near-zero solar elevation can divide by zero; transmittance helpers can produce non-finite values for invalid/negative elevation angles before clipping; terrain angle can shade via negative cosine clipped to 0 | `open` |
| `rad_sw_out()` | Bendix | `rad_sw_in(...) * alpha(surface_type)` | `SW_out = SW_in * alpha` | Code: `R/radiation.R:299-302`; docs: `R/radiation.R:278-291`, `man/rad_sw_out.Rd:34-36`; albedo table: `R/utility.R:12-68` | same as `rad_sw_in()` plus `surface_type` | reflected direct shortwave, W m-2 | `alpha` dimensionless table lookup; `SW_in` W m-2 | outgoing reflected shortwave is positive magnitude, subtracted by `rad_sw_bal()` | valid `alpha` in 0-1 gives `SW_out <= SW_in` | No explicit albedo validation; no fallback for unknown `surface_type`; `...` is not forwarded to `rad_sw_in()` in implementation at `R/radiation.R:300` | `open` |
| `rad_lw_bal()` | Bendix | `rad_lw_in(temp, rh, slope, valley, ...) - rad_lw_out(surface_type, surface_temp, ...)` | `R_lw = LW_in - LW_out` | Code: `R/radiation.R:383-386`; docs: `R/radiation.R:365-375`, `man/rad_lw_bal.Rd:24-26`; vignette comparisons: `fieldclim_additional.Rmd:209-222` | `temp`, `rh`, `slope`, `valley`, `surface_type`, `surface_temp` | modeled longwave balance, W m-2 | temperatures are degC then converted to K; fluxes W m-2; RH percent through vapor pressure helper | incoming longwave positive; outgoing longwave positive magnitude subtracted; `L* = L_down - L_up` | equals `rad_lw_in() - rad_lw_out()` exactly for same arguments | Usually negative in clear-sky surface cooling cases, but can vary; no cloud term apparent; measured `RlNet` sign convention must be checked before comparison | `code-ok` for balance sign; source/measurement equivalence `open` |
| `rad_lw_in()` | Bendix | `rad_emissivity_air(temp, rh, ...) * sigma * c2k(temp)^4 * terr_sky_view(slope, valley)` | `LW_in = epsilon_air * sigma * T_air^4 * sky_view` | Code: `R/radiation.R:427-431`; docs: `R/radiation.R:406-419`, `man/rad_lw_in.Rd:26-28`; emissivity: `R/radiation.R:469-473`; sky view: `R/terrain.R:30-39`; `sigma_default`: `R/utility.R:6` | `temp`, `rh`, `slope`, `valley`; indirect `sigma`, vapor-pressure args | atmospheric longwave incoming, W m-2 | `temp` degC to K; `rh` percent; `sigma` W m-2 K-4; sky view dimensionless | positive incoming longwave magnitude | non-negative for physical emissivity, positive Kelvin temperature, and sky view in 0-1 | RH/temp outside physical ranges not validated; sky-view function can produce values outside 0-1 for invalid slopes; no cloud enhancement | `open` |
| `rad_lw_out()` | Bendix | `epsilon(surface_type) * sigma * c2k(surface_temp)^4` | `LW_out = epsilon * sigma * T_surface^4` | Code: `R/radiation.R:511-514`; docs: `R/radiation.R:492-503`, `man/rad_lw_out.Rd:26-28`; emissivity table: `R/utility.R:12-54`; `sigma_default`: `R/utility.R:6` | `surface_type`, `surface_temp`; optional `sigma` | surface longwave outgoing, W m-2 | `surface_temp` degC to K; emissivity dimensionless; `sigma` W m-2 K-4 | positive outgoing longwave magnitude, subtracted by `rad_lw_bal()` | positive finite output for valid emissivity and Kelvin temperature | unknown `surface_type` returns zero-length emissivity; no emissivity range validation; impossible temperatures not checked | `open` |
| `sol_hour_angle()` | Bendix / implementation-specific time handling | `15 * (datetime$hour + datetime$min / 60 + datetime$sec / 3600 + sol_time_formula(datetime, lon) - 12)` | `H = 15 * (T_m + E_t - 12)` where docs define `T_m` as solar medium suntime | Code: `R/solar.R:326-331`; docs: `R/solar.R:307-314`, `man/sol_hour_angle.Rd:24-26`; `sol_medium_suntime()` docs/code: `R/solar.R:351-373`; tests: `tests/testthat/test-solar.R:11-16`; update vignette: `fieldclim_update2024.Rmd:277-284` | `datetime`, `lon`; indirect day/solar anomaly helpers | solar hour angle, degrees | datetime must behave like POSIXlt with local hour/min/sec fields; longitude degrees | negative before local solar noon, positive after, based on implemented time basis | around implemented solar noon, hour angle near 0 | Documentation says `T_m`, but code does not call `sol_medium_suntime()` and uses local POSIXlt fields directly; POSIXct input may fail; timezone convention is explicitly historically sensitive | `open` / documentation-timebase mismatch |
| `sol_elevation()` | Bendix | `asin(sin(lat) * sin(declination) + cos(lat) * cos(declination) * cos(hour_angle))`, returned in degrees | same formula | Code: `R/solar.R:146-157`; docs: `R/solar.R:126-134`, `man/sol_elevation.Rd:24-26`; used by `rad_sw_toa()`, `rad_sw_in()`, `terr_terrain_angle()`, transmittance air mass | `datetime`, `lon`, `lat`; indirect declination and hour angle | solar elevation angle, degrees | input latitude/hour/declination are degrees, converted internally to radians | positive above horizon, negative below horizon | bounded approximately `[-90, 90]` degrees for valid inputs; drives night clipping in shortwave functions | inherits `sol_hour_angle()` timebase ambiguity; no clipping of asin argument for numerical drift; no explicit timezone validation | `open` |
| `trans_gas()` | Bendix | `exp(-0.0127 * M_abs^0.26)` | same | Code: `R/transmittance.R:27-29`; docs: `R/transmittance.R:11-19`; directly used by `rad_sw_in()` at `R/radiation.R:141` | `datetime`, `lon`, `lat`, `elev`, `temp`; indirect pressure constants | gas transmittance, dimensionless | expected 0-1 for valid optical air mass | attenuation factor multiplied into incoming shortwave | should reduce or preserve incoming radiation, not add energy | invalid/negative solar elevations can make air mass non-finite; no validation range | `open` |
| `trans_ozone()` | Bendix | `1 - (0.1611*x*(1 + 139.48*x)^-0.3035 - 0.002715*x*(1 + 0.044*x + 0.0003*x^2)^-1)` with `x = ozone_column * M_rel` | same | Code: `R/transmittance.R:154-161`; docs: `R/transmittance.R:138-146`; used by `rad_sw_in()` and `rad_diffuse_in()` | `datetime`, `lon`, `lat`, optional `ozone_column` | ozone transmittance, dimensionless | ozone column cm per docs; air mass dimensionless | attenuation factor | expected mostly 0-1 for valid inputs | no range validation for ozone or output; inherits air-mass edge cases | `open` |
| `trans_rayleigh()` | Bendix | `exp(-0.0903 * M_abs^0.84 * (1 + M_abs - M_abs^1.01))` | same | Code: `R/transmittance.R:201-203`; docs: `R/transmittance.R:185-193`; used by `rad_sw_in()` | `datetime`, `lon`, `lat`, `elev`, `temp` | Rayleigh transmittance, dimensionless | air mass dimensionless | attenuation factor | expected mostly 0-1 for valid inputs | expression may exceed 1 or become non-finite if air-mass domain is invalid; no validation | `open` |
| `trans_vapor()` | Bendix | `1 - 2.4959*x*((1 + 79.034*x)^0.6828 + 6.385*x)^-1`, `x = precipitable_water * M_rel` | same | Code: `R/transmittance.R:243-248`; docs: `R/transmittance.R:227-235`; used by `rad_sw_in()` and `rad_diffuse_in()` | `datetime`, `lat`, `lon`, `elev`, `temp`; humidity helper inputs through `...` if any | water-vapor transmittance, dimensionless | precipitable water and air mass dimensionless/product per implementation | attenuation factor | expected mostly 0-1 for valid inputs | no direct RH argument in signature; depends on `hum_precipitable_water()` assumptions; inherits air-mass edge cases | `open` |
| `trans_aerosol()` | Bendix / implementation-specific fitted visibility table | computes `tau38` and `tau50` by log-log linear fits from visibility table, `x = 0.2758*tau38 + 0.35*tau50`, then `exp(-x^0.873 * (1 + x - x^0.7088) * M_abs^0.9108)` | formula documented without the internal fitted `x` detail | Code: `R/transmittance.R:288-303`; docs: `R/transmittance.R:272-280`; used by `rad_sw_in()` | `datetime`, `lon`, `lat`, `elev`, `temp`, optional `vis` | aerosol transmittance, dimensionless | visibility km; air mass dimensionless | attenuation factor | expected mostly 0-1 for valid inputs | fitted table is implementation-specific; no validation for visibility; inherits air-mass edge cases | `open` |

### Related Helpers Used By Radiation

| Helper | Role in radiation | Formula / implementation | References | Unit assumptions | Audit note | Status |
|---|---|---|---|---|---|---|
| `rad_sw_toa()` | source term for `rad_sw_in()` and `rad_diffuse_in()` | `sol_const * sol_eccentricity(datetime) * sin(sol_elevation)` then clips negative solar elevation to 0 | Code: `R/radiation.R:193-199`; docs: `R/radiation.R:172-185` | W m-2; solar elevation degrees converted to radians | Not in requested rows, but necessary for `rad_sw_in()`; doc says default solar constant 1361, while `R/utility.R:9` has `sol_const_default = 1368` unused by this function | `open` |
| `rad_diffuse_in()` | included in `rad_sw_bal()` | `0.5 * ((1 - (1 - vapor) - (1 - ozone)) * sw_toa - sw_in) * sky_view * (1 + cos(terrain_angle)^2 * sin(solar_angle)^3)`, clipped to 0 when elevation < 0 | Code: `R/radiation.R:243-260`; docs: `R/radiation.R:217-235` | W m-2; angles converted to radians | Can become negative in daylight because only night is clipped, unlike `rad_sw_in()`; affects shortwave balance | `open` |
| `rad_diffuse_out()` | included in `rad_sw_bal()` and albedo handling | `rad_diffuse_in(...) * alpha(surface_type)` | Code: `R/radiation.R:342-345`; docs: `R/radiation.R:321-334` | W m-2 | Same albedo lookup risks as `rad_sw_out()` | `open` |
| `terr_sky_view()` | used by `rad_lw_in()` and `rad_diffuse_in()` | non-valley `(1 + cos(slope)) / 2`; valley `cos(slope)` | Code: `R/terrain.R:30-39`; docs: `R/terrain.R:8-16` | slope degrees; return dimensionless | Valid only for plausible slopes; no range validation | `open` |
| `terr_terrain_angle()` | used by `rad_sw_in()` and `rad_diffuse_in()` | terrain-incidence angle from slope, solar elevation, solar azimuth, and exposition | Code: `R/terrain.R:85-100`; docs: `R/terrain.R:64-73` | angles degrees converted internally to radians | Inherits `sol_hour_angle()` and azimuth timebase issues | `open` |

### Tests And Vignette Evidence

- `tests/testthat/test-solar.R:1-8` checks only Julian day for default and weather-station inputs.
- `tests/testthat/test-solar.R:11-16` checks that `sol_medium_suntime()` converts a UTC+3 POSIXlt input to UTC-derived hours, but `sol_hour_angle()` currently does not call `sol_medium_suntime()`.
- `tests/testthat/test-consolidation.R:69-95` checks that packaged Caldern data include measured radiation columns, including `rad_sw_in`, `rad_sw_out`, `RsNet`, `RlNet`, and `rad_net`.
- `tests/testthat/test-consolidation.R:98-123`, `147-173`, and `176-193` use measured `rad_net` and `soil_flux` for flux closure tests; these are not tests of modeled `rad_bal()`.
- `vignettes/fieldclim_check_rad_soil.Rmd:232-287` compares modeled radiation components to measured columns.
- `vignettes/fieldclim_usecase.Rmd:335-439` explicitly warns that component-summed `K* + L*` and measured `rad_net` are not automatically interchangeable for the Caldern dataset.

### Audit Status Summary

- Master modeled radiation sign convention: `code-ok` for the package functions `rad_bal()`, `rad_sw_bal()`, and `rad_lw_bal()` with the definitions `Q* = K* + L*`, `K* = K_down - K_up`, and `L* = L_down - L_up`.
- Radiation source-term and helper physics: `open` where source formulas and edge-case domains have not been independently checked against Bendix, or where implementation-specific behavior affects physical interpretation.
- Solar timebase: `open`; `sol_hour_angle()` documentation names `T_m`, but implementation uses POSIXlt local time fields directly and does not call `sol_medium_suntime()`.
- Measured-vs-modeled radiation: `open`; vignettes correctly treat measured `rad_net` and component-derived `K* + L*` as a validation issue, not as automatically identical quantities.

Recommended next action: independently verify the Bendix equation constants and valid domains for `rad_sw_in()`, diffuse radiation, transmittance, and solar time handling before changing tests or code. No fixes were made in this audit pass.

---

## Audit 2: Soil Heat Flux And Available Energy

Status: completed for soil heat flux, soil thermal properties, attenuation length, workflow `soil_flux`, and available energy only.  
Scope of this pass: `soil_*`, `rad_bal - soil_flux`, Priestley-Taylor, Bulk-Residual, Bowen, and workflow orchestration where these variables enter.  
Edit rule for this pass: package source, tests, and Rd files were not changed.

### Source Material Read

- `R/soil.R`: `soil_heat_flux()`, `soil_thermal_cond()`, `soil_heat_cap()`, `soil_attenuation()`.
- `R/sensible.R`: only `rad_bal` and `soil_flux` use in `sensible_priestley_taylor()` and `sensible_bowen()`.
- `R/latent.R`: only `rad_bal` and `soil_flux` use in `latent_priestley_taylor()`, `latent_penman()`, and `latent_bowen()`.
- `R/bulk.R`: read because Bulk-Residual consumption of `soil_flux` is implemented there; `R/turbulent_flux.R` only calls this workflow.
- `R/turbulent_flux.R`: `turb_flux_calc()` workflow logic for Priestley-Taylor, Bowen, Penman, and Bulk-Residual calls.
- `man/soil_*.Rd`, `man/sensible_priestley_taylor.Rd`, `man/latent_priestley_taylor.Rd`.
- `tests/testthat/test-consolidation.R`.
- `vignettes/*.Rmd`: only occurrences of `Q_star`, `B`, `rad_bal`, `soil_flux`, `Q_minus_B`, or available energy.

### Convention Check

Required convention:

$$
R_n > 0
$$

means net radiative input at the surface.

$$
G > 0
$$

means heat flux into the soil.

$$
R_n - G
$$

is the available turbulent energy when storage is omitted.

Audit finding:

- Package workflow logic follows this convention for functions that consume `rad_bal` and `soil_flux`.
- `sensible_priestley_taylor.default()` uses `(rad_bal - soil_flux)` at `R/sensible.R:46`.
- `latent_priestley_taylor.default()` uses `(rad_bal - soil_flux)` at `R/latent.R:51`.
- `latent_bulk_residual.default()` uses `rad_bal - soil_flux - sensible` at `R/bulk.R:167-174`.
- `sensible_bowen.default()` uses `(rad_bal - soil_flux) * bowen_ratio / denominator` at `R/sensible.R:244-266`.
- `latent_bowen.default()` uses `(rad_bal - soil_flux) / denominator` at `R/latent.R:517-540`.
- `latent_penman.default()` assigns `Rn <- rad_bal`, `G <- soil_flux`, then uses `(Rn - G)` at `R/latent.R:242-246`.
- `turb_flux_calc()` calls Priestley-Taylor, Bowen, Penman, and Bulk-Residual paths at `R/turbulent_flux.R:420-452`; it does not change the sign of `soil_flux`.
- `tests/testthat/test-consolidation.R:88-93` checks positive Priestley-Taylor fluxes and exact closure to `400 - 40`.
- `tests/testthat/test-consolidation.R:141-154` checks PT-only workflow closure to `input$rad_net - input$heatflux_soil`.
- `tests/testthat/test-consolidation.R:199-210` checks Bulk-Residual closure to `ws$rad_bal - ws$soil_flux`.

### Vignette Mapping Check

The main use-case vignette maps variables consistently:

| Teaching variable | Vignette variable | Package / data variable | Evidence |
|---|---|---|---|
| `Q*` | `Q_star` | `rad_net`, `rad_bal` | `vignettes/fieldclim_usecase.Rmd:53`, `vignettes/fieldclim_usecase.Rmd:316` |
| `B` | `B` | `heatflux_soil`, `soil_flux` | `vignettes/fieldclim_usecase.Rmd:54`, `vignettes/fieldclim_usecase.Rmd:317` |
| available energy | `Q_minus_B`, `available_energy` | `rad_bal - soil_flux` / `Q_star - B` | `vignettes/fieldclim_usecase.Rmd:497-503`, `vignettes/fieldclim_usecase.Rmd:1037-1044` |

Additional evidence:

- `vignettes/fieldclim_usecase.Rmd:62-80` states `Q* = B + L + V + S`, omits storage for the teaching workflow, and derives `Q* - B = L + V` and `V = Q* - B - L`.
- `vignettes/fieldclim_usecase.Rmd:815-817` explicitly passes `rad_bal = caldern$Q_star` and `soil_flux = caldern$B` into the weather-station object.
- `vignettes/fieldclim_usecase.Rmd:1037-1044` states that when `B > 0` is into the soil, `Q_star - B` remains available for `L` and `V`.
- `vignettes/fieldclim_additional.Rmd:116-117` maps `rad_bal = caldern$rad_net` and `soil_flux = caldern$heatflux_soil`.
- `vignettes/fieldclim_additional.Rmd:485-490` presents the soil heat-flux workflow with the implementation sign: `B = -lambda_s * (T1 - T2) / (z1 - z2)`.

Conclusion: `Q_star` and `B` map consistently to `rad_bal` and `soil_flux` in the current vignettes checked for this audit.

### Function Audit Rows

| Function / item | Source formula category | Implemented formula | Documented formula | References | Input variables | Output variable | Unit assumptions | Sign convention | Expected invariant | Edge cases | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `soil_heat_flux()` | Bendix | `G = -lambda * (soil_temp1 - soil_temp2) / (soil_depth1 - soil_depth2)`, with `lambda = soil_thermal_cond(texture, moisture)` | Source/Rd equation states `G = lambda * (T1 - T2) / (z1 - z2)`. Prose states negative values are toward atmosphere and positive values into soil. | Code/docs: `R/soil.R:1-19`, implementation: `R/soil.R:33-35`, Rd: `man/soil_heat_flux.Rd:42-47`, source ref: `R/soil.R:16`, vignette implementation formula: `vignettes/fieldclim_additional.Rmd:485-490` | `texture`; `moisture` in m3 m-3; `soil_temp1`, `soil_temp2` in degC; `soil_depth1`, `soil_depth2` in m | soil heat flux `G` / `B`, W m-2 | `lambda` W m-1 K-1; temperature difference in degC equivalent to K; depths documented as positive depth magnitudes in m | Implementation and prose make positive values flux into soil, negative values toward atmosphere | Example from code/doc inputs: with sand, `moisture = 0.25`, `soil_temp1 = 15`, `soil_temp2 = 10`, `soil_depth1 = 0.1`, `soil_depth2 = 0.3`, `lambda = 2.4`, implementation returns `+60 W m-2`, i.e. into soil | Sign depends on whether depths are positive downward or a vertical coordinate; no validation that depths differ; no validation of depth ordering; conductivity may be `NA` outside table range | `sign-mismatch`: implemented sign matches package convention `G > 0` into soil, documented equation omits the leading minus sign |
| `soil_thermal_cond()` | Bendix | Converts `moisture` to Vol-% and linearly interpolates texture-specific conductivity tables: `approx(x, y, moisture)$y` | Documentation says thermal conductivity is determined from texture and moisture by interpolation from measured data | Code/docs: `R/soil.R:52-66`, implementation: `R/soil.R:76-92`, Rd: `man/soil_thermal_cond.Rd:18-31`, source ref: `R/soil.R:63` | `texture` as `sand`, `peat`, or `clay`; `moisture` in m3 m-3 | thermal conductivity `lambda`, W m-1 K-1 | input moisture fraction is multiplied by 100 to Vol-%; table values are W m-1 K-1 | positive material property; no flux direction | For valid physical inputs, conductivity should be positive; for sand at `moisture = 0.25`, implementation gives `2.4 W m-1 K-1` | Scalar `if (texture == ...)` means vectorized texture is unsupported; outside interpolation range returns `NA`; no moisture range validation | `open`: implementation is clear, but source table values and valid interpolation domain were not independently verified in this pass |
| `soil_heat_cap()` | Bendix | Converts `moisture` to Vol-% and linearly interpolates texture-specific volumetric heat-capacity tables: `approx(x, y, xout = moisture, yleft = NA, yright = y[7])$y` | Documentation says volumetric heat capacity is determined from texture and moisture by interpolation from measured data | Code/docs: `R/soil.R:109-123`, implementation: `R/soil.R:134-151`, Rd: `man/soil_heat_cap.Rd:18-31`, source ref: `R/soil.R:120` | `moisture` in m3 m-3; `texture` as `sand`, `peat`, or `clay`, default `sand` | volumetric heat capacity `C_v`, MJ m-3 K-1 | input moisture fraction is multiplied by 100 to Vol-%; table values are MJ m-3 K-1 | positive material property; no flux direction | For valid physical inputs, heat capacity should be positive; for sand at `moisture = 0.25`, implementation gives `2.21 MJ m-3 K-1` | Scalar texture branching; below table range returns `NA`; above table range clamps to last table value via `yright = y[7]`; no warning for clamping | `open`: implementation is clear, but source table values and clamp policy were not independently verified in this pass |
| `soil_attenuation()` | Bendix | `L = sqrt(lambda / (C_v * 10^6 * pi) * 86400)`, with `lambda = soil_thermal_cond(texture, moisture)` and `C_v = soil_heat_cap(moisture, texture)` | Documentation states `L = sqrt(lambda / (C_v * pi) * 86400)` and says `C_v` is in MJ m-3 K-1 | Code/docs: `R/soil.R:165-182`, implementation: `R/soil.R:192-196`, Rd: `man/soil_attenuation.Rd:18-33`, source ref: `R/soil.R:179`, test: `tests/testthat/test-consolidation.R:95-102` | `moisture` in m3 m-3; `texture` as `sand`, `peat`, or `clay`, default `sand` | attenuation length `L`, m | `lambda` W m-1 K-1; `C_v` returned in MJ m-3 K-1 and converted to J m-3 K-1 by `* 10^6`; `86400` seconds per day | positive length; no flux direction | For sand at `moisture = 0.25`, implementation gives about `0.172819 m`; test reproduces `sqrt(soil_thermal_cond(...) / (soil_heat_cap(...) * 10^6 * pi) * 86400)` | If `lambda` or `C_v` is `NA`, result is `NA`; invalid non-positive `C_v` would make formula invalid; documentation omits the explicit `10^6` unit conversion | `open` with documentation unit concern: implementation/test are internally consistent, but source formula and unit notation need verification before `code-ok` |
| `soil_flux` workflow variable | Implementation-specific package workflow using Bendix sign convention | Weather-station workflows pass measured `heatflux_soil` as `soil_flux`; downstream energy methods consume it as `G` in `rad_bal - soil_flux` or `rad_bal - soil_flux - H` | PT docs describe `R_n - G`; Bulk-Residual docs in `R/bulk.R` state `Rn > 0`, `G > 0`, `LE = Rn - G - H`; vignettes map `B` to `heatflux_soil` / `soil_flux` | Tests/data mapping: `tests/testthat/test-consolidation.R:63-64`, `tests/testthat/test-consolidation.R:141-142`, `tests/testthat/test-consolidation.R:172-173`; PT Rd: `man/sensible_priestley_taylor.Rd:20-42`, `man/latent_priestley_taylor.Rd:20-44`; vignette mapping: `vignettes/fieldclim_usecase.Rmd:53-54`, `vignettes/fieldclim_usecase.Rmd:316-317`, `vignettes/fieldclim_usecase.Rmd:815-817` | station field `soil_flux`; measured column `heatflux_soil`; modeled `soil_heat_flux()` output if used | soil heat flux `G` / `B`, W m-2 | W m-2; same averaging interval and timestamp alignment as `rad_bal` required | positive `soil_flux` means heat flux into the soil and is subtracted from net radiation | If `soil_flux > 0`, available turbulent energy is lower than `rad_bal`; if `soil_flux < 0`, soil releases energy and `rad_bal - soil_flux` increases | Package does not validate imported measurement sign convention; an opposite-signed heat-flux plate series would silently invert the available-energy correction | `code-ok` for package convention; measurement sign validation remains `open` |
| available energy `rad_bal - soil_flux` | Bendix / Foken / Oke energy-balance convention | Available energy is computed as `rad_bal - soil_flux` in PT and Bowen, `Rn - G` in Penman, and `rad_bal - soil_flux - sensible` in Bulk-Residual latent heat | PT Rd formulas state `R_n - G`; vignettes state `Q* - B`; Bulk-Residual source docs state `LE = Rn - G - H` | Code: `R/sensible.R:46`, `R/sensible.R:266`, `R/latent.R:51`, `R/latent.R:242-246`, `R/latent.R:540`, `R/bulk.R:167-174`; workflow: `R/turbulent_flux.R:420-452`; tests: `tests/testthat/test-consolidation.R:88-93`, `tests/testthat/test-consolidation.R:141-154`, `tests/testthat/test-consolidation.R:199-210`; vignettes: `vignettes/fieldclim_usecase.Rmd:62-80`, `vignettes/fieldclim_usecase.Rmd:497-503`, `vignettes/fieldclim_usecase.Rmd:1037-1044` | `rad_bal` / `Rn` / `Q_star`; `soil_flux` / `G` / `B`; for residual also sensible heat `H` | available turbulent energy, W m-2; residual latent heat, W m-2 | both `rad_bal` and `soil_flux` are W m-2 and must be on the same processing level and timestamp | `Rn > 0` input at surface; `G > 0` into soil; `Rn - G` available to `H + LE` | Closure methods should satisfy `H + LE = rad_bal - soil_flux` when storage is omitted and no singular-case cap changes the partition; Bulk-Residual enforces `LE = rad_bal - soil_flux - H` | If `rad_bal` and `soil_flux` are misaligned, use different processing levels, or use different sign conventions, available energy is wrong; Monin-Obukhov is diagnostic and not forced to close | `code-ok` for package workflow convention |

### Method Consumption Check

| Method group | Consumption of `soil_flux` | Same sign convention? | Evidence | Status |
|---|---|---|---|---|
| Priestley-Taylor | Latent and sensible fluxes both partition `(rad_bal - soil_flux)` | Yes | `R/latent.R:51`, `R/sensible.R:46`, `man/latent_priestley_taylor.Rd:38-44`, `man/sensible_priestley_taylor.Rd:36-42`, test closure at `tests/testthat/test-consolidation.R:88-93` | `code-ok` |
| Bulk-Residual | `latent_bulk_residual()` computes `LE = rad_bal - soil_flux - sensible`; `turb_flux_calc()` calls it after `sensible_bulk()` | Yes | `R/bulk.R:167-174`, `R/bulk.R:241-251`, `R/turbulent_flux.R:426-427`, test closure at `tests/testthat/test-consolidation.R:199-210` | `code-ok` |
| Bowen | Sensible and latent Bowen both use `rad_bal - soil_flux` with the same denominator convention | Yes | `R/sensible.R:266`, `R/latent.R:540`, workflow calls at `R/turbulent_flux.R:431-432`, vignette formulas at `vignettes/fieldclim_usecase.Rmd:635-644` | `code-ok` for shared soil-flux sign; singular denominator behavior belongs to Bowen audit |

### Audit Status Summary

- Package-level convention: `code-ok` for `Rn > 0` as net radiative input, `G > 0` into soil, and `Rn - G` as available turbulent energy.
- `Q_star` and `B` vignette mapping: `code-ok` for mapping `Q_star -> rad_bal/rad_net` and `B -> soil_flux/heatflux_soil` in checked sections.
- `soil_heat_flux()`: `sign-mismatch` between documented equation and implementation; implementation aligns with package convention, but equation documentation omits the leading minus sign.
- `soil_thermal_cond()` and `soil_heat_cap()`: `open` because table sources and interpolation domains were not independently verified.
- `soil_attenuation()`: `open` with a documentation unit concern because implementation/test include `C_v * 10^6` while docs show `C_v` in MJ m-3 K-1 without the conversion in the equation.
- Priestley-Taylor, Bulk-Residual, and Bowen consume `soil_flux` with the same sign convention: `code-ok`.

Recommended next action: do not fix during this audit. After the audit sequence, align `soil_heat_flux()` formula documentation with the implemented/package sign convention and clarify `soil_attenuation()` unit notation.

---

## Audit 3: Priestley-Taylor, Bulk-Residual And Bowen

Status: completed for Priestley-Taylor, Bulk-Residual, and Bowen formula/workflow audit only.  
Scope of this pass: `latent_priestley_taylor()`, `sensible_priestley_taylor()`, `sensible_bulk()`, `latent_bulk_residual()`, `turb_flux_bulk_residual()`, `sensible_bowen()`, `latent_bowen()`, and `turb_flux_calc()` orchestration for these methods.  
Edit rule for this pass: package source, tests, and Rd files were not changed.

### Source Material Read

- `R/sensible.R`: Priestley-Taylor sensible heat and Bowen sensible heat paths.
- `R/latent.R`: Priestley-Taylor latent heat and Bowen latent heat paths.
- `R/bulk.R`: simple bulk sensible heat, residual latent heat, and Bulk-Residual workflow.
- `R/turbulent_flux.R`: `turb_flux_calc()` method orchestration and `pt_only` path.
- `R/utility_turbulent_flux.R`: `sc()`, `gam()`, and unused `bowen_ratio()` helper for unit/source context.
- `R/utility.R`: Priestley-Taylor coefficient table.
- `man/sensible_priestley_taylor.Rd`, `man/latent_priestley_taylor.Rd`, `man/sensible_bowen.Rd`, `man/latent_bowen.Rd`, `man/sensible_bulk.Rd`, `man/latent_bulk_residual.Rd`.
- `tests/testthat/test-bulk.R` and `tests/testthat/test-consolidation.R`.
- `vignettes/*.Rmd`: only sections using Priestley-Taylor, Bulk-Residual, Bowen, `L`, `V`, `H`, `LE`, `Q_star`, `B`, `rad_bal`, or `soil_flux`.

### Closure Check

Let:

$$
A = R_n - G = rad\_bal - soil\_flux
$$

Required closure checks:

| Method family | Implemented closure | Result | Evidence |
|---|---|---|---|
| Priestley-Taylor | `LE_PT = alpha * Delta / (Delta + gamma) * A`; `H_PT = (((1 - alpha) * Delta + gamma) / (Delta + gamma)) * A`; therefore `H_PT + LE_PT = A` if both functions use the same `sc(temp)`, `gam(temp)`, `alpha`, `rad_bal`, and `soil_flux` | formally closes | `R/latent.R:35-51`, `R/sensible.R:34-46`, test `tests/testthat/test-consolidation.R:88-93`, `tests/testthat/test-consolidation.R:141-154` |
| Bulk-Residual | `H_bulk` is independently estimated; `LE_res = rad_bal - soil_flux - H_bulk`; therefore `H_bulk + LE_res = A` by construction | exactly closes | `R/bulk.R:37-79`, `R/bulk.R:167-174`, tests `tests/testthat/test-bulk.R:19-34`, `tests/testthat/test-bulk.R:37-59`, `tests/testthat/test-consolidation.R:199-210` |
| Bowen | `H_bowen = A * beta / (1 + beta)` and `LE_bowen = A / (1 + beta)`; therefore `H_bowen + LE_bowen = A` when both calls compute the same unmodified denominator | formally closes only outside singular/capped denominator cases | `R/sensible.R:244-266`, `R/latent.R:517-540`, vignette caution `vignettes/fieldclim_usecase.Rmd:1116-1126` |

Formal closure is necessary for these methods, but it is not physical validation. PT can close with wrong `Q_star`, `B`, `alpha`, `Delta`, or `gamma`; Bulk-Residual can close while `H_bulk` is a crude or wrong estimate; Bowen can close while gradient ratios are unstable or physically implausible.

### Function Audit Rows

| Function | Source formula category | Implemented formula | Documented formula | References | Input variables | Output variable | Unit assumptions | Sign convention | Closure invariant | Edge cases | Warning/cap logic | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `latent_priestley_taylor()` | Foken | `alpha_pt * (delta / (delta + gamma)) * (rad_bal - soil_flux)`, with `delta <- sc(temp)`, `gamma <- gam(temp)`, and `alpha_pt` from `priestley_taylor_coefficient` | `Q_e = alpha_PT * Delta / (Delta + gamma) * (R_n - G)` | Code: `R/latent.R:1-27`, `R/latent.R:35-57`; PT coefficient table: `R/utility.R:72-89`; helper units/source comments: `R/utility_turbulent_flux.R:1-29`; Rd: `man/latent_priestley_taylor.Rd:20-46`; source ref: `R/latent.R:27`; test: `tests/testthat/test-consolidation.R:88-93` | `temp` degC, `rad_bal` W m-2, `soil_flux` W m-2, `surface_type` | latent heat flux `LE_PT` / `Q_e` / `V_PT`, W m-2 | `rad_bal` and `soil_flux` W m-2; `delta` and `gamma` must have same units because only their ratio is used; exact units of `sc()` and `gam()` are not exposed in Rd | positive output is flux away from surface; positive `rad_bal - soil_flux` drives positive latent heat if coefficient and ratio are positive | with `sensible_priestley_taylor()` and same inputs, `H_PT + LE_PT = Rn - G` | invalid `surface_type` stops; vectorized `surface_type` is not supported robustly; negative available energy gives negative output; no independent validation of `alpha`, `Delta`, `gamma`, or physical water availability | warns above `600 W m-2` or below `-600 W m-2`; does not cap | `code-ok` for formal closure; `open` for source/unit validation of `sc()`, `gam()`, and coefficient table |
| `sensible_priestley_taylor()` | Foken / implementation-specific residual complement | `(((1 - alpha_pt) * sc + gam) / (sc + gam)) * (rad_bal - soil_flux)` using same table and helpers as latent PT | `Q_h = (((1 - alpha) * s + gamma) / (s + gamma)) * (R_n - G)` | Code: `R/sensible.R:1-26`, `R/sensible.R:34-53`; helper units/source comments: `R/utility_turbulent_flux.R:1-29`; Rd: `man/sensible_priestley_taylor.Rd:20-42`; source ref: `R/sensible.R:17`; test: `tests/testthat/test-consolidation.R:88-93` | `temp` degC, `rad_bal` W m-2, `soil_flux` W m-2, `surface_type` | sensible heat flux `H_PT` / `Q_h` / `L_PT`, W m-2 | same PT assumptions as latent path; `sc` and `gam` must be commensurable | positive output is flux away from surface | this is the algebraic complement of `latent_priestley_taylor()` and is residual by construction relative to PT latent heat: `H_PT = (Rn - G) - LE_PT` | same `surface_type`, vectorization, and negative-energy caveats as latent PT; closure does not prove PT physics | warns above `600 W m-2` or below `-600 W m-2`; does not cap | `code-ok` for formal closure/residual complement; `open` for source/unit validation |
| `sensible_bulk()` | implementation-specific simplified bulk-transfer reference | `wind_mean = v1` if `v2` missing else `(v1 + v2) / 2`; low wind set to `NA`; `delta_t = t1 - t2`; `r_a = log(z2 / z1) / (k * wind_mean)`; `H = rho * cp * delta_t / r_a` | Rd documents sign convention and inputs; no equation is shown in Rd, but source comments describe simplified aerodynamic resistance | Code/docs: `R/bulk.R:1-28`, implementation: `R/bulk.R:37-84`; Rd: `man/sensible_bulk.Rd:36-74`; tests: `tests/testthat/test-bulk.R:1-16`, `tests/testthat/test-bulk.R:61-80`; vignette manual formula: `vignettes/fieldclim_usecase.Rmd:693-745` | `t1`, `t2` degC or K difference; `v1`, optional `v2` m s-1; `z1`, `z2` m; `rho` kg m-3; `cp` J kg-1 K-1; `k`; `min_wind`; `warn_threshold` | sensible heat flux `H_bulk` / `L_bulk`, W m-2 | `t1` lower and `t2` upper; `z1`, `z2` scalar with `0 < z1 < z2`; wind speed m s-1; default constants fixed | `H > 0` away from surface; because `delta_t = t1 - t2`, warmer lower air gives positive `H` | no closure alone; closure occurs only when paired with `latent_bulk_residual()` | invalid heights stop; low/missing wind produces `NA`; vector recycling risks remain for input lengths; simplified neutral/log resistance is not full stability physics | low wind warning and `NA`; high absolute flux warning above `warn_threshold`; values are warned but not capped | `code-ok` for documented implementation behavior; physical adequacy remains `open` |
| `latent_bulk_residual()` | Bendix/Oke energy-balance residual / implementation-specific workflow | `LE = rad_bal - soil_flux - sensible` | Rd states `Rn > 0`, `G > 0`, `H > 0`, `LE > 0`, and `LE = Rn - G - H` | Code/docs: `R/bulk.R:130-158`, implementation: `R/bulk.R:167-184`; Rd: `man/latent_bulk_residual.Rd:24-63`; test: `tests/testthat/test-bulk.R:19-34` | `rad_bal` W m-2, `soil_flux` W m-2, `sensible` W m-2, `warn_threshold` | residual latent heat flux `LE_res` / `V_residual`, W m-2 | all fluxes W m-2 and same timestep/processing level | positive `LE` away from surface; positive `soil_flux` into soil is subtracted | exact by construction: `sensible + latent_bulk_residual = rad_bal - soil_flux` | residual inherits all errors from `rad_bal`, `soil_flux`, and supplied `sensible`; if `sensible` is `NA`, residual is `NA` | high absolute flux warning above `warn_threshold`; no cap | `code-ok` for residual formula and closure; physical validation depends on inputs and remains `open` |
| `turb_flux_bulk_residual()` | implementation-specific workflow | checks fields, computes `h_bulk <- sensible_bulk(weather_station, ...)`, computes `le_residual <- latent_bulk_residual(weather_station, sensible = h_bulk, ...)`, appends both fields | no separate Rd inspected/requested; source documents it as adding `sensible_bulk` and `latent_bulk_residual` fields | Code/docs: `R/bulk.R:229-255`; test: `tests/testthat/test-bulk.R:37-59`; full workflow call: `R/turbulent_flux.R:426-427`, output fields `R/turbulent_flux.R:451-452` | weather station with `t1`, `t2`, `v1`, `z1`, `z2`, `rad_bal`, `soil_flux`; optional `v2` and bulk args | modified `weather_station` with `sensible_bulk` and `latent_bulk_residual` | inherited from bulk/residual methods | inherited: `H > 0` away, `LE > 0` away, `G > 0` into soil | exact closure if component calls return finite/NA consistently: `sensible_bulk + latent_bulk_residual = rad_bal - soil_flux` | missing required fields stop via `check_availability()`; low wind propagates `NA` from `sensible_bulk()` into residual | inherited warnings from `sensible_bulk()` and `latent_bulk_residual()`; no capping | `code-ok` for workflow closure; physical adequacy remains `open` |
| `sensible_bowen()` | Bendix | computes `dpot = (temp_pot_temp(t2, elev) - temp_pot_temp(t1, elev)) / (z2 - z1)`; `dah = (hum_absolute(hum2, t2) - hum_absolute(hum1, t1)) / (z2 - z1)`; `beta = gamma * dpot / dah`, with `gamma = 0.00066 * (1 + 0.000946 * t1)`; `H = (rad_bal - soil_flux) * beta / denominator` | Rd states `Q_h = ((R_n - G) * B) / (1 + B)` and `B = gamma / L_v * Delta T / Delta q` | Code/docs: `R/sensible.R:218-236`, implementation: `R/sensible.R:244-273`; Rd: `man/sensible_bowen.Rd:44-76`; source ref: `R/sensible.R:234`; vignette caution: `vignettes/fieldclim_usecase.Rmd:620-644`, `vignettes/fieldclim_usecase.Rmd:1116-1126` | `t1`, `t2` degC lower/upper; `hum1`, `hum2` RH % lower/upper; `z1`, `z2` m; `elev` m; `rad_bal`, `soil_flux` W m-2; optional `cap` | sensible heat flux `H_bowen` / `L_Bowen`, W m-2 | temperature gradient uses upper minus lower potential temperature per meter; humidity gradient uses upper minus lower absolute humidity per meter, not vapor pressure; beta units are uncertain from code because `gamma/L_v` documented form is not implemented literally | positive output is away from surface; sign depends on beta and available energy | with `latent_bowen()` and same unmodified denominator, `H + LE = rad_bal - soil_flux` | `dah = 0` yields infinite/undefined beta; `1 + beta` near zero yields extreme values; `z2 == z1` invalid but not checked; vector length and surface-layer assumptions not validated | if `cap` is not `NULL`, denominators with `abs(denominator) < cap` are replaced by `+/- cap`; warnings above `600 W m-2` or below `-600 W m-2`; values are not capped except denominator adjustment | `open`: formal partition is implemented, but beta definition/units differ from docs and singular handling changes closure when cap applies |
| `latent_bowen()` | Bendix | computes the same `dpot`, `dah`, `beta`, and `denominator` as `sensible_bowen()`; `LE = (rad_bal - soil_flux) / denominator` | Rd states `Q_e = (R_n - G) / (1 + B)` and same documented beta definition | Code/docs: `R/latent.R:480-508`, implementation: `R/latent.R:517-547`; Rd: `man/latent_bowen.Rd:44-78`; source ref: `R/latent.R:508`; vignette caution: `vignettes/fieldclim_usecase.Rmd:620-644`, `vignettes/fieldclim_usecase.Rmd:1116-1126` | same as `sensible_bowen()` | latent heat flux `LE_bowen` / `V_Bowen`, W m-2 | same beta/unit caveats as sensible Bowen | positive output is away from surface; sign depends on denominator and available energy | with `sensible_bowen()` and same unmodified denominator, `H + LE = rad_bal - soil_flux` | same singular denominator and gradient sensitivity caveats; doc says values are smoothed, but implementation only warns | same denominator cap policy as sensible Bowen; warnings above `600 W m-2` or below `-600 W m-2`; no smoothing/capping of output values | `open`: formal partition is implemented, but beta definition/units and doc smoothing/cap behavior require source validation |

### Priestley-Taylor Details

- Alpha / surface mapping: `R/utility.R:72-89` defines `field = 1.12`, `bare soil = 1.04`, `coniferous forest = 1.13`, `water = 1.26`, `wetland = 1.26`, and `spruce forest = 1.72`. Both PT functions reject unknown `surface_type` (`R/latent.R:37-42`, `R/sensible.R:39-44`). Source values were not independently verified in this pass.
- Delta and gamma: `sc()` and `gam()` are in `R/utility_turbulent_flux.R:1-29`. Comments say both are polynomial fits to Foken table 6. Their returned units are not documented in Rd, but algebra requires matching pressure-per-temperature units because only `Delta / (Delta + gamma)` and related ratios are used.
- `sensible_priestley_taylor()` is residual by construction: its coefficient is `((Delta + gamma - alpha * Delta) / (Delta + gamma))`, so it equals `(Rn - G) - LE_PT` when the same helpers and alpha are used.
- `pt_only = TRUE` isolates the beginner-safe PT path: `turb_flux_calc()` adds only `sensible_priestley_taylor` and `latent_priestley_taylor`, then returns before Bulk, Bowen, Monin, or Penman are called (`R/turbulent_flux.R:420-424`). The consolidation test checks this path excludes `latent_penman` and closes to `rad_net - heatflux_soil` (`tests/testthat/test-consolidation.R:141-154`).

### Bulk-Residual Details

- Sign of `Delta T`: `sensible_bulk()` uses `delta_t = t1 - t2`; with `t1` lower and `t2` upper, warmer lower air gives positive sensible heat away from the surface (`R/bulk.R:1-13`, `R/bulk.R:76-79`). This is tested in `tests/testthat/test-bulk.R:1-16`.
- Lower/upper consistency: docs and weather-station method treat `t1`, `v1`, `z1` as lower and `t2`, optional `v2`, `z2` as upper (`R/bulk.R:14-18`, `R/bulk.R:92-122`). `z1` and `z2` must be scalar and satisfy `0 < z1 < z2` (`R/bulk.R:51-55`).
- Mean wind: if `v2` is provided, `wind_mean = (v1 + v2) / 2`; otherwise `v1` is used (`R/bulk.R:59-63`). This matches the documented optional `v2` behavior in `man/sensible_bulk.Rd:44-46`.
- Low wind: `wind_mean <= min_wind` or `NA` triggers a warning and is set to `NA`, avoiding infinite flux (`R/bulk.R:65-74`; test `tests/testthat/test-bulk.R:61-80`).
- Values are warned but not capped: `abs(h) > warn_threshold` warns only (`R/bulk.R:81-84`). `latent_bulk_residual()` also warns only (`R/bulk.R:176-184`).
- `latent_bulk_residual()` exactly computes `LE = Rn - G - H` (`R/bulk.R:167-174`).

### Bowen Details

- Beta definition: code uses `beta = gamma * dpot / dah`, with `gamma = 0.00066 * (1 + 0.000946 * t1)`, potential-temperature gradient `dpot`, and absolute-humidity gradient `dah` (`R/sensible.R:244-257`, `R/latent.R:517-531`). Rd says `B = gamma / L_v * Delta T / Delta q` (`man/sensible_bowen.Rd:67-72`, `man/latent_bowen.Rd:69-74`). The code does not explicitly divide by `L_v`; it may be relying on the absolute-humidity units and empirical gamma term, but that requires source validation.
- Temperature-gradient sign: code uses upper minus lower potential temperature divided by `z2 - z1`; positive beta sign therefore depends on upper/lower potential-temperature and humidity gradients.
- Humidity-gradient sign: code uses upper minus lower absolute humidity divided by `z2 - z1`. It does not use vapor-pressure gradient directly, although vignette text describes the concept as vapour-pressure or humidity-gradient based.
- Denominator: both functions use `1 + beta`.
- Near-zero/singular denominator: without `cap`, division by zero or near-zero denominators can produce infinite or extreme values; with `cap`, values with `abs(denominator) < cap` are replaced by `+cap` or `-cap` in each function (`R/sensible.R:259-264`, `R/latent.R:534-538`).
- Closure: exact only when both functions use the same unmodified denominator. If denominator capping modifies `1 + beta`, then `H + LE = A * (1 + beta) / capped_denominator`, so closure is no longer exact unless the capped denominator still equals `1 + beta`.
- Warning/cap policy: denominator can be capped; resulting flux values are warned above `600 W m-2` or below `-600 W m-2`, but output fluxes are not capped or smoothed. The latent Bowen Rd description says extreme values are recognized and smoothed; the implementation warns but does not smooth (`man/latent_bowen.Rd:55-57`, `R/latent.R:542-547`).

### Tests And Vignette Evidence

- `tests/testthat/test-bulk.R:1-16` checks `sensible_bulk()` temperature-gradient sign.
- `tests/testthat/test-bulk.R:19-34` checks `latent_bulk_residual()` closure.
- `tests/testthat/test-bulk.R:37-59` checks `turb_flux_bulk_residual()` adds expected fields and closes to `rad_bal - soil_flux`.
- `tests/testthat/test-bulk.R:61-80` checks low wind returns `NA` with warning.
- `tests/testthat/test-consolidation.R:88-93` checks PT positive available-energy convention and closure.
- `tests/testthat/test-consolidation.R:141-154` checks `pt_only = TRUE` creates PT outputs, excludes `latent_penman`, and closes to measured `rad_net - heatflux_soil`.
- `tests/testthat/test-consolidation.R:199-210` checks full workflow includes Bulk-Residual fields and closure.
- `vignettes/fieldclim_usecase.Rmd:594-618` explains PT as energy-bound partitioning and residual sensible heat.
- `vignettes/fieldclim_usecase.Rmd:693-745` explains the manual Bulk-Residual reference and computes `V_residual = Q_star - B - L_bulk`.
- `vignettes/fieldclim_usecase.Rmd:620-644` explains Bowen partitioning and warns about small or sign-changing gradients and near-zero `1 + beta`.
- `vignettes/fieldclim_usecase.Rmd:1116-1126` states that Bowen closure alone is not sufficient physical validation.

### Audit Status Summary

- Priestley-Taylor formal closure: `code-ok`; PT physical/source validation remains `open` for alpha table values and `sc()`/`gam()` units.
- `pt_only = TRUE`: `code-ok` as a beginner-safe PT-only workflow path.
- Bulk-Residual formula and closure: `code-ok`; physical adequacy of the simple bulk transfer estimate remains `open`.
- Bowen formal closure outside denominator capping/singular cases: `code-ok`; Bowen beta definition, units, and doc/implementation consistency remain `open`.
- Warning/cap behavior: PT and Bulk warn but do not cap; Bowen caps denominator only when `cap` is supplied and otherwise warns but does not smooth/cap flux values.

Recommended next action: do not fix during this audit. In the later fix phase, verify PT helper units and alpha values against source, and reconcile Bowen beta documentation with the implemented absolute-humidity-gradient formula and denominator cap behavior.

## Physics Audit 4: Penman, Monin-Obukhov and wrapper logic

Scope: Penman latent heat flux, Monin-Obukhov sensible/latent profile fluxes, stability helpers, and wrapper/container logic. This audit does not treat agreement with Caldern/example data as proof of physical correctness, and it does not treat warnings alone as proof of failure.

### Master checks

- **Penman energy term:** `latent_penman.default()` uses `Rn <- rad_bal`, `G <- soil_flux`, and the available-energy term `delta * (Rn - G)` before returning latent heat flux only; no Penman sensible heat flux is computed (`R/latent.R:185-263`). This follows the package-wide available-energy sign convention if `rad_bal > 0` is net radiative input at the surface and `soil_flux > 0` is heat into the soil.
- **Penman aerodynamic term:** the implementation uses `gamma * (cp * rho / ra) * (es - ea)` with `cp = 1004`, `rho = 1.2`, `ra` from log wind resistance, `es = pres_sat_vapor_p(temp)`, and `ea = pres_vapor_p(temp, rh)` (`R/latent.R:218-246`). `pres_sat_vapor_p()` and `pres_vapor_p()` return hPa (`R/pressure.R:77-80`, `R/pressure.R:122-124`), while `delta` and `gamma` are handled as kPa-scale terms through `es / 10` and `0.665e-3 * pres_p(...)` (`R/latent.R:218-225`). This pressure/vapour-pressure unit mix is not resolved by the current implementation and is therefore open.
- **Penman surface class mapping:** `surface_type = "field"` is accepted and normalized to `"Temperate grassland"`, which is present in `surface_resistance` (`R/latent.R:76-119`, `R/utility.R:92-110`).
- **Penman humidity handling:** the default method accepts `rh`; the weather-station method accepts either `hum1` or `rh`, preferring `hum1` when present and passing the selected value as `rh` to the default method (`R/latent.R:269-330`). This is internally consistent only if `hum1` is relative humidity in percent. The field name is otherwise ambiguous because `hum1` is also used as profile relative humidity in Monin-Obukhov functions.
- **Penman failure in wrapper:** `turb_flux_calc()` wraps `latent_penman()` in `tryCatch()` and returns an `NA_real_` vector with a warning if Penman fails, so Penman failure is non-fatal as intended (`R/turbulent_flux.R:435-440`).
- **Monin-Obukhov closure:** `sensible_monin()` and `latent_monin()` are diagnostic profile-gradient methods. They do not consume `rad_bal` or `soil_flux`, do not close `Rn - G`, and should not be judged by formal energy closure (`R/sensible.R:116-171`, `R/latent.R:386-438`; `vignettes/fieldclim_usecase.Rmd:1118-1120`, `vignettes/fieldclim_usecase.Rmd:1291-1297`).
- **Wrapper sign handling:** `turb_flux_calc()` computes methods and stores outputs; it does not change the sign of `rad_bal`, `soil_flux`, `H`, or `LE` (`R/turbulent_flux.R:420-453`).

### Audit rows

| Item | Source category | Implemented formula | Documented formula | References | Inputs | Output | Unit assumptions | Sign convention | Closure / invariant | Edge cases | Warning / cap logic | Status |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `latent_penman()` | Implementation-specific Penman-Monteith style | `LE = (Delta * (Rn - G) + gamma * (cp * rho / ra) * (es - ea)) / (Delta + gamma * (1 + rs / ra))`; computes `ra = log((z-d)/zom) * log((z-d)/zoh) / (k^2 * v)`, then divides by and multiplies by `Lv`, leaving `LE` unchanged. | Rd documents the same Penman equation and arguments for wind, temperature, RH, radiation, elevation, coordinates, soil heat flux, observation height, and surface type. | `R/latent.R:185-263`; `R/latent.R:218-253`; `man/latent_penman.Rd`; pressure helpers in `R/pressure.R:34-39`, `R/pressure.R:77-80`, `R/pressure.R:122-124`; `hum_evap_heat()` in `R/humidity.R:103-105`. | `datetime`, `v`, `temp`, `rh`, `z`, `rad_bal`, `elev`, `lat`, `lon`, `soil_flux`, `obs_height`, `surface_type`. `datetime`, `doy`, `ut`, `lat`, and `lon` are parsed but not used in the final formula. | Latent heat flux `LE`, W m-2. | `Rn`, `G`, and output are W m-2; `v` m s-1; `temp` deg C; `rh` percent; `z`, `obs_height`, `elev` m. `pres_p()` returns hPa; `gamma` is kPa K-1 scale; `Delta` is kPa K-1 scale; `es - ea` remains hPa. | Formula returns positive `LE` when `Rn - G` and vapour pressure deficit are positive. Rd text states negative heat flux is away from the surface, which conflicts with the package convention used elsewhere. | LE-only method; no `H` is produced and `H + LE = Rn - G` is not expected from this function alone. Energy term uses `Rn - G`. | Low or zero wind can make `ra` infinite or undefined. Vector inputs use scalar `max()` for log arguments, so vector behaviour is uncertain. Surface class must map to `surface_resistance`. | Intended high/low flux warnings exist, but checks use `(!is.na(out)) > 600` and `< -600`, so magnitude warnings are not implemented correctly. No cap. | **Open:** energy term and field mapping are clear, but pressure/vapour-pressure units, sign documentation, vector behaviour, and warning logic need decision. |
| `latent_penman.weather_station()` | Implementation-specific S3 wrapper | Checks required fields, selects `v1` as wind, `z1` as wind height, selects `hum1` if available else `rh`, normalizes `surface_type`, then calls `latent_penman.default()`. | Rd documents weather-station method using stored station fields. | `R/latent.R:269-330`; field-mapping test `tests/testthat/test-consolidation.R:160-180`; wrapper Penman test `tests/testthat/test-consolidation.R:185-193`. | Weather-station fields: `datetime`, `v1`, `temp`, `z1`, `rad_bal`, `elev`, `lat`, `lon`, `soil_flux`, `obs_height`, `surface_type`, plus `hum1` or `rh`. | Latent heat flux `LE`, W m-2. | Same as default. `hum1`/`rh` must be relative humidity in percent for the default formula. | Does not alter signs; passes `rad_bal` and `soil_flux` directly. | Inherits default method behaviour; wrapper invariant is correct field routing. | Missing `rh` and `hum1` stops. If `hum1` exists but is not RH percent, the calculation is physically ambiguous. | No wrapper cap. Default warning logic inherited. | **Open:** routing is mostly code-ok, but physical status inherits default unit/sign concerns and `hum1` naming ambiguity. |
| `sensible_monin()` | Foken / Monin-Obukhov profile-gradient family, implementation-specific details | `H = -rho * cp * (k * ustar * z2 / phi_h) * t_gradient`, with `t_gradient = (theta2 - theta1) / log(z2 - z1)`, `theta = temp_pot_temp(t, elev)`, `phi_h = 0.74 * (1 - 9*s1)^-0.5` for unstable and `0.74 + 4.7*s1` for stable, `s1 = z2 / L`. | Rd documents `Q_h = -rho cp (k u_* z2 / phi_h) * Delta theta / Delta z`. | `R/sensible.R:116-171`; `man/sensible_monin.Rd`; `temp_pot_temp()` used through `R/temperature.R`; weather-station wrapper `R/sensible.R:175-190`; diagnostic vignette context `vignettes/fieldclim_usecase.Rmd:646-670`. | `t1`, `t2`, `z1`, `z2`, `v1`, `v2`, `elev`, optional `cap`, plus `surface_type` or `obs_height` for roughness/displacement. | Sensible heat flux `H`, W m-2. | Temperatures deg C; heights m; wind m s-1; elevation m; density kg m-3; `cp` J kg-1 K-1. | Leading negative sign means a warmer lower level than upper level gives positive upward/away-from-surface `H` if the gradient term is negative. | Diagnostic-only; not expected to close `Rn - G`. | If neither `surface_type` nor `obs_height` is supplied, function prints a message rather than reliably stopping before later calculations. Low-wind and zero-gradient behaviour depends on `ustar`, `L`, and Richardson calculations. | Warns when output magnitude exceeds +/-600 W m-2. Optional `cap` caps only `s1`, not final flux. | **Open:** sign intent is clear, but implemented gradient denominator `log(z2 - z1)` does not match documented `Delta z`, and physical validation is unresolved. |
| `latent_monin()` | Foken / Monin-Obukhov profile-gradient family, implementation-specific details | `LE = -rho * Lv * ((k * ustar) / phi_q) * moisture_gradient`, with `moisture_gradient = (q2 - q1)/(z2 - z1)`, `phi_q = 0.95 * (1 - 11.6*s1)^-0.5` for unstable and `0.95 + 7.8*s1` for stable, `s1 = z2 / L`. | Rd documents `Q_e = -rho L_v (k u_* / phi_q) * Delta q / Delta z`. | `R/latent.R:386-438`; `R/latent.R:444-461`; `man/latent_monin.Rd`; moisture gradient `R/humidity.R:236-239`; specific humidity `R/humidity.R:25-29`; diagnostic vignette context `vignettes/fieldclim_usecase.Rmd:646-670`. | `hum1`, `hum2`, `t1`, `t2`, `v1`, `v2`, `z1`, `z2`, `elev`, optional `cap`, plus `surface_type` or `obs_height`. | Latent heat flux `LE`, W m-2. | `hum1`, `hum2` are RH percent for `hum_specific()`; temperatures deg C; heights m; wind m s-1; `Lv` J kg-1. | Leading negative sign means lower-level moister air than upper-level air gives positive upward/away-from-surface `LE`. | Diagnostic-only; not expected to close `Rn - G`. | Low-wind, zero-gradient, and missing roughness inputs propagate through `ustar`, `L`, and Richardson calculations. | Warns when output magnitude exceeds +/-600 W m-2. Optional `cap` caps only `s1`, not final flux. | **Open:** implemented formula matches documentation structurally, but full physical validation and low-wind/singularity behaviour remain open. |
| `turb_flux_stability()` | Foken / gradient Richardson classification | Converts gradient Richardson number to stability class: `NA -> NA`, `Ri <= -0.005 -> "unstable"`, `-0.005 < Ri < 0.005 -> "neutral"`, `Ri >= 0.005 -> "stable"`. | Rd describes conversion to stability string, but the value section states the return is a gradient Richardson number. | `R/turbulent_flux.R:156-168`; `man/turb_flux_stability.Rd`; vignette use `vignettes/fieldclim_additional.Rmd:601-679`. | Same profile inputs as `turb_flux_grad_rich_no()`: `t1`, `t2`, `z1`, `z2`, `v1`, `v2`, `elev`. | Stability class string or `NA`. | Dimensionless Richardson number thresholds. | Not a flux; no sign convention. | Classification should be consistent with Richardson sign: negative unstable, near-zero neutral, positive stable. | Infinite Richardson values classify as stable or unstable through threshold logic. | No warnings or caps in this helper. | **Open:** threshold implementation is clear, but Rd return text is inconsistent with actual string output. |
| `turb_flux_grad_rich_no()` | Foken / gradient Richardson number | `Ri = (g / theta1) * ((theta2 - theta1)/(z2 - z1)) * ((v2 - v1)/(z2 - z1))^-2`, with `theta` from `temp_pot_temp()`. `NaN` is replaced by `0`. | Rd documents gradient Richardson number and stable/unstable interpretation. | `R/turbulent_flux.R:115-122`; `man/turb_flux_grad_rich_no.Rd`; `temp_pot_temp()` in `R/temperature.R`; vignette use `vignettes/fieldclim_additional.Rmd:601-679`. | `t1`, `t2`, `z1`, `z2`, `v1`, `v2`, `elev`. | Dimensionless gradient Richardson number. | Temperatures deg C converted to K after potential-temperature calculation; heights m; wind m s-1. | Not a flux; sign is Richardson stability sign. | Negative Ri unstable, near-zero neutral, positive Ri stable. | Zero wind gradient can produce `Inf`; zero temperature and zero wind gradient can produce `NaN`, which is forced to `0`. `temp_pot_temp()` second argument is elevation per current implementation, not pressure. | No warnings or caps. | **Open:** formula category is clear, but zero-gradient handling and dependence on the audited `temp_pot_temp()` definition remain open. |
| `turb_flux_calc()` | Implementation-specific orchestration | If `pt_only = TRUE`, computes only Priestley-Taylor `H` and `LE`. Otherwise computes Bulk-Residual, stability, Priestley-Taylor, Bowen, Monin-Obukhov, and Penman outputs and stores them on the weather-station object. | Rd documents full workflow and beginner-safe `pt_only` path. | `R/turbulent_flux.R:420-453`; `man/turb_flux_calc.Rd`; tests `tests/testthat/test-consolidation.R:141-154`, `tests/testthat/test-consolidation.R:185-193`; vignette use `vignettes/fieldclim_usecase.Rmd:894-903`, `vignettes/fieldclim_additional.Rmd:721`. | Weather-station object with fields required by the selected methods. | Weather-station object with added method outputs. | Inherits units from component methods; no unit conversion performed by wrapper. | Does not change signs; passes fields to component methods and assigns results. | PT/Bulk/Bowen closure inherited from those methods; MO and Penman are not made to close energy by wrapper. | Full workflow can fail if non-Penman component requirements are missing. Penman failure alone is caught and converted to `NA`. | Penman failure emits warning and returns `NA` vector. Other method warnings/caps are inherited. | **Code-ok for orchestration; physics inherited open:** wrapper does not alter signs, and Penman non-fatal behaviour is implemented. |
| `build_weather_station()` | Implementation-specific container | Stores all named arguments in a list and assigns class `weather_station`. | Rd documents that it stores supplied data and does not calculate fluxes. | `R/weather_station.R:56-68`; `man/build_weather_station.Rd`; vignette use `vignettes/fieldclim_usecase.Rmd:786-817`, `vignettes/fieldclim_additional.Rmd:85-131`. | Any named station fields, commonly profile, radiation, soil, coordinate, and site metadata fields. | `weather_station` object. | No unit enforcement. | No sign handling. | Invariant: values should be preserved exactly as stored. | No physics validation; invalid or inconsistent fields can be stored. | No warnings or caps. | **Code-ok:** stores fields only; does not validate physics by design. |
| `as.data.frame.weather_station()` | Implementation-specific container conversion | Uses `x$measurements` for legacy objects if present, otherwise `unclass(x)`, then `as.data.frame()`. Optional `reduced` selects known columns; optional `unit` renames columns only. | Rd documents conversion, reduced view, and optional unit-labelled column names. | `R/utility.R:209-268`; `man/as.data.frame.weather_station.Rd`; tests `tests/testthat/test-consolidation.R:1-14`. | Weather-station object. | Data frame. | Values and units are preserved; `unit = TRUE` changes labels, not magnitudes. | No sign handling. | Invariant: stored values should be preserved through conversion. | Reduced output silently omits missing important columns. Legacy `measurements` path can differ from flat-object path. | No warnings or caps. | **Code-ok:** tested value preservation for flat and legacy objects. |
| `check_availability()` | Implementation-specific validation helper | Iterates over `required_params` and stops if a required name is absent from `names(weather_station)`. | Inline documentation says it checks required parameters and mentions `NULL`, but implementation only checks names. | `R/utility.R:120-135`; used by Penman wrapper `R/latent.R:269-291`, Monin wrappers `R/sensible.R:175-190`, `R/latent.R:444-461`. | Weather-station object and character vector of required field names. | Invisibly succeeds or stops with missing-field error. | No unit validation. | No sign handling. | Invariant: required field names must exist before wrapper method proceeds. | Field present with value `NULL`, wrong length, wrong unit, or wrong physical meaning passes this helper. | Stops on absent names only. | **Open:** name-availability check is implemented, but documentation overstates validation and formula-specific unit/physics needs are not checked. |

### Audit status

- **Penman:** Open. The implementation is LE-only and uses `Rn - G`, and `surface_type = "field"` maps to a valid resistance class. However, vapour-pressure units in the aerodynamic term, Penman sign documentation, humidity field naming, vector behaviour, and warning logic need a follow-up decision before marking code-ok.
- **Monin-Obukhov:** Open. Sensible and latent methods are diagnostic-only and do not close `Rn - G`; this is consistent with vignette guidance. The implemented sensible temperature-gradient denominator differs from the documented `Delta z`, and zero-gradient/low-wind behaviour remains partly unresolved.
- **Wrappers:** Mostly code-ok for orchestration and value preservation. `turb_flux_calc()` does not change signs and handles Penman failure non-fatally. `build_weather_station()` stores fields only. `as.data.frame.weather_station()` preserves values. `check_availability()` remains open because it checks names only, not `NULL`, units, lengths, or physical consistency.

### Recommended next action

Do not change code during this audit gate. The next physics decision should separate documentation/sign-convention fixes from implementation questions: first decide the intended Penman pressure units and heat-flux sign convention, then decide whether Monin-Obukhov gradient and zero-wind handling should be made physically stricter or documented as diagnostic and implementation-specific.

