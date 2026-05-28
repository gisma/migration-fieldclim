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
Create docs/physics-formula-audit.md from the package source.

Read:
- docs/physics-formula-audit.md
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

Test the invariants listed in docs/physics-formula-audit.md:
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
docs/physics-formula-audit.md
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
