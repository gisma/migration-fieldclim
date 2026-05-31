# Source-table and empirical-constant inventory

## Scope

This is an inventory of hard-coded empirical lookup tables, source-dependent coefficients, method parameterizations, reference constants, and package implementation coefficients found in the package source. It is not a validation report. No value was checked against an external source in this pass, no code was changed, and no tests were run.

Allowed material reviewed: `R/*`, `tests/testthat/*`, `man/*.Rd`, `vignettes/*.Rmd`, `dev/physics-audit/*`, `NEWS.md`, `README.md`, and `DESCRIPTION`.

## Summary table

| ID | Area | File/function | Type | Values / compact description | Current citation | Current validation status | Notes |
|---|---|---|---|---|---|---|---|
| ST-001 | Global defaults | `R/utility.R:1-9` | physical constant | `p0=1013.25`, `g=9.81`, `rl=287.05`, `c2k=273.15`, `sigma=5.6704e-8`, `ozone=0.35`, `vis=30`, `sol_const=1368` | citation: none found at object definition | source values not revalidated | Shared defaults. |
| ST-002 | Surface properties | `R/utility.R:12-69` | empirical lookup table | 12 classes with emissivity, roughness length, albedo | citation: none found at table definition | source values not revalidated | Used by radiation/turbulence. |
| ST-003 | PT alpha | `R/utility.R:72-90` | empirical lookup table | alpha values for 6 surface types | Foken formula refs only; no alpha table source found | source values not revalidated | PT closure tested, alpha values not source-tested. |
| ST-004 | Penman resistance | `R/utility.R:92-110` | empirical lookup table | `rs`: 30-80 for 6 vegetation classes | Monteith method ref only; no table source found | source-form open | Used by Penman. |
| ST-005 | Humidity helpers | `R/humidity.R:26-105` | physical constant | `0.622`, `0.21668`, `(2.5008-0.002372*T)*1e6` | Bendix 2004 p. 261-262 | equation-contract tested | Helper equations tested. |
| ST-006 | Precipitable water | `R/humidity.R:145-149` | empirical lookup table | `t0`, `pwst` by tropic/temperate/subarctic season | Bendix 2004 p. 246, no table number | structural/input tested only | Table values not revalidated. |
| ST-007 | Pressure/vapor | `R/pressure.R:37-184` | physical constant | barometric defaults; Magnus constants `6.1078`, `a/b`; density constants | Lente & Ősz 2020; Bendix 2004 p. 261-262; air density no ref | equation-contract tested | Some constants only documented in formula text. |
| ST-008 | Potential temp | `R/temperature.R:36-41` | physical constant | `p0=1000`, `air_const=0.286` | Bendix 2004 p. 261 | equation-contract tested | Elevation-to-pressure behavior audited. |
| ST-009 | Soil conductivity | `R/soil.R:105-118` | empirical lookup table | sand/clay/peat moisture-conductivity vectors | Bendix 2004 p. 254, no table number | behavior tested only | Source table open. |
| ST-010 | Soil heat capacity | `R/soil.R:166-180` | empirical lookup table | sand/clay/peat moisture-heat-capacity vectors; high clamp | Bendix 2004 p. 254, no table number | behavior tested only | Source and clamp policy open. |
| ST-011 | Soil attenuation | `R/soil.R:222-226` | physical constant | `10^6`, `pi`, `86400` | Bendix 2004 p. 253 | equation-contract tested | Unit conversion tested. |
| ST-012 | PT `sc()` | `R/utility_turbulent_flux.R:16-18` | source-dependent helper formula | quadratic in Kelvin | Foken 2013 p. 48 Table 6 after Stull 1988 | equation-contract tested | Source-table tested against rounded values. |
| ST-013 | PT `gam()` | `R/utility_turbulent_flux.R:37-39` | source-dependent helper formula | logistic-like polynomial in Kelvin | Foken 2013 p. 48 Table 6 after Stull 1988 | equation-contract tested | Source-table tested; not FAO-56 gamma. |
| ST-014 | Internal Bowen helper | `R/utility_turbulent_flux.R:54-70` | source-dependent helper formula | `heat_capacity*dpot/(Lv*dah)`; heat capacity polynomial | Bendix 2004 p. 221 eq. 9.21; p. 261 | source-form open | Not used by exported Bowen functions. |
| ST-015 | Exported Bowen beta | `R/sensible.R:315-317`; `R/latent.R:627-629` | empirical coefficient | `0.00066*(1+0.000946*t1)` | Bendix 2004 p. 221 eq. 9.21 | source-form open | Behavior locked, equivalence open. |
| ST-016 | Penman aliases | `R/latent.R:80-121` | surface/land-cover mapping | field/lawn/grass etc. to Penman resistance classes | citation: none found | behavior tested only | Mapping documented/tested. |
| ST-017 | Penman constants | `R/latent.R:237-257` | method parameterization | `cp=1004`, `rho=1.2`, `0.665e-3`, `4098`, `237.3`, `0.123`, `0.1`, `k=0.41`, `1e-6` | Monteith et al. 1994 generic; no per-constant source | source-form open | Unit behavior fixed/tested. |
| ST-018 | Sensible MO | `R/sensible.R:171-189` | method parameterization | `cp=1004.834`, `k=0.35`, `0.74`, `9`, `4.7`, `+/-600` | Bendix 2004 p. 77; Foken 2016 p. 362 Businger | behavior tested only | Diagnostic-only; constants open. |
| ST-019 | Latent MO | `R/latent.R:477-494` | method parameterization | `k=0.4`, `0.95`, `11.6`, `7.8`, `+/-600` | Bendix 2004 p. 77; Foken 2016 p. 61 Tab. 2.10 | behavior tested only | Diagnostic-only; constants open. |
| ST-020 | MO/Richardson helpers | `R/turbulent_flux.R:27-214` | method parameterization | Ri thresholds `-0.005/0.005`, `0.75`, `4.7`, `0.4`, `9.81`, `min_shear=1e-4` | Bendix 2004 p. 241; p. 43 eq. 2.5/picture 2.10 | guard/edge-case tested | Diagnostic helpers. |
| ST-021 | Exchange quotients | `R/turbulent_flux.R:250-365` | method parameterization | heat/impulse constants `0.4`, `0.74`, `9`, `4.7`, `15`, `-0.25` | Foken 2016 p. 361-362 Businger | not assessed | No source-table tests found. |
| ST-022 | Bulk defaults | `R/bulk.R:126-135` | method parameterization | `rho=1.225`, `cp=1005`, `k=0.41`, `min_wind=0.1`, `warn=600`, Ri thresholds | citation: none found in source block | equation-contract tested | Behavior and guard tested. |
| ST-023 | Turbulence roughness/displacement | `R/turbulence.R:40-173` | method parameterization | obstacle roughness `0.1*h`; displacement `2/3`, `0.8`; ustar `0.4` | Bendix 2004 p. 239; Bendix generic for displacement | behavior tested only | Surface table source open. |
| ST-024 | Boundary layers | `R/boundary_layers.R:27-108` | empirical coefficient | `0.3*sqrt(dist)`, `0.43*sqrt(dist)`; thermal formula | Bendix 2004 p. 242, no table/equation number | equation-contract tested | Constants not revalidated. |
| ST-025 | Radiation shortwave/diffuse | `R/radiation.R:169-302` | method parameterization | `0.9751`, `sol_const=1361`, diffuse `0.5`, powers `2`, `3` | Bendix 2004 p. 46, 52, 244, 58, 55 | equation-contract tested | Constants open. |
| ST-026 | Radiation albedo/emissivity | `R/radiation.R:351-594` | empirical lookup table | uses `surface_properties$albedo/emissivity`; air emissivity `1.24`, `1/7`; sigma | Bendix 2004 p. 45, 66, 68 | equation-contract tested | Surface table not revalidated. |
| ST-027 | Gas/air-mass transmittance | `R/transmittance.R:31-132` | method parameterization | `0.0127`, `0.26`; `1.5`, `-0.72` | Bendix 2004 p. 246; R source p. 247 for abs air mass | equation-contract tested | Edge guards tested. |
| ST-028 | Ozone/Rayleigh/vapor transmittance | `R/transmittance.R:180-281` | method parameterization | ozone, Rayleigh, vapor empirical constants | Bendix 2004 p. 245 | equation-contract tested | Constants not revalidated. |
| ST-029 | Aerosol transmittance | `R/transmittance.R:327-339` | empirical lookup table | `vis=10..60`, `tau38`, `tau50`, blend/power constants | Bendix 2004 p. 246, no table number | equation-contract tested | Tau values not revalidated. |
| ST-030 | Solar coefficients | `R/solar.R:26-446` | method parameterization | eccentricity, day angle, obliquity, ecliptic/anomaly/time constants | Bendix 2004 p. 243 | equation-contract tested | Timebase/source constants open. |
| ST-031 | Terrain factors | `R/terrain.R:31-99` | method parameterization | sky view and terrain angle formulas | Bendix 2004 p. 63 eq. 3.15; p. 52 eq. 3.7 | equation-contract tested | No value validation beyond formulas. |
| ST-032 | Unit conversion helpers | `R/utility.R:5` and temp helpers | physical constant | `273.15`, `pi`-based rad/deg conversions | citation: none found at global definition | equation-contract tested | Simple constants. |
| ST-033 | Warning/cap thresholds | multiple heat-flux methods | implementation coefficient | repeated `+/-600`; user `cap`; local `1e-6` | citation: none found | behavior tested only | Numerical policy, not source table. |
| ST-034 | Data-frame field labels | `R/utility.R:215-248` | implementation coefficient | reduced column list and unit suffix replacements | citation: none found | API parity tested | Non-physics implementation set. |
| ST-035 | Surface class labels | multiple files | surface/land-cover mapping | repeated class names from surface/PT/Penman tables | mixed; table definitions mostly uncited | behavior tested only | Unknown/valid behavior tested in places. |

## Detailed inventory

### ST-001: global-default-constants

- Area: Global defaults
- File: `R/utility.R`
- Function: package-level objects
- Lines: `1-9`
- Type: physical constant
- Values:

```text
p0_default=1013.25; g_default=9.81; rl_default=287.05; c2k_default=273.15;
sigma_default=5.6704e-8; ozone_column_default=0.35; vis_default=30;
sol_const_default=1368
```

* Current citation in source:

```text
citation: none found at object definition
```
* Other citations / notes found:
  * man/Rd: consuming functions cite Lente & Ősz 2020, Bendix 2004, or no explicit source.
  * vignettes: no direct source citation for this object set found.
  * dev/physics-audit: Penman and radiation audits keep source-form questions open.
  * README/NEWS: says empirical coefficients and lookup tables are not fully revalidated.
  * Current test coverage: equation-contract: downstream helpers; helper-contract: `c2k()`/`k2c()`; API parity: downstream only; guard/edge-case: transmittance/radiation guards.
  * Validation status: source values not revalidated.
  * Required follow-up only if later source validation is desired: source-backed reference for each default, especially solar constant defaults.
* do not perform the validation now

### ST-002: surface-properties-table

- Area: Surface and land-cover properties
- File: `R/utility.R`
- Function: `surface_properties`
- Lines: `12-69`
- Type: empirical lookup table
- Values:

```text
surface_type = field, acre, lawn, street, agriculture, settlement, coniferous forest,
deciduous forest, mixed forest, city, water, shrub
emissivity = 0.92,0.98,0.95,0.95,0.95,0.80,0.98,0.98,0.98,0.90,0.95,0.96
roughness_length = 0.02,0.05,0.20,0.20,0.20,1.00,1.00,1.50,1.50,2.00,0.01,0.50
albedo = 0.200,0.050,0.260,0.120,0.220,0.300,0.100,0.170,0.135,0.220,0.050,0.170
```

* Current citation in source:

```text
citation: none found at table definition
```
* Other citations / notes found:
  * man/Rd: consuming formulas cite Bendix pages/equations, not this table specifically.
  * vignettes: surface classes discussed; no table source found.
  * dev/physics-audit: albedo/source validation open.
  * README/NEWS: radiation/transmittance references remain future validation items.
  * Current test coverage: equation-contract: radiation formulas; helper-contract: none; API parity: indirect; guard/edge-case: valid albedo and unknown surface behavior.
  * Validation status: source values not revalidated.
  * Required follow-up only if later source validation is desired: source table for emissivity, roughness length, and albedo values.
* do not perform the validation now

### ST-003: priestley-taylor-alpha-table

- Area: Priestley-Taylor
- File: `R/utility.R`
- Function: `priestley_taylor_coefficient`
- Lines: `72-90`
- Type: empirical lookup table
- Values:

```text
field=1.12; bare soil=1.04; coniferous forest=1.13; water=1.26;
wetland=1.26; spruce forest=1.72
```

* Current citation in source:

```text
# Priestley-Taylor coefficient
citation: no table/source reference at object definition
```
* Other citations / notes found:
  * man/Rd: PT functions cite Foken 2016 p. 220 eq. 5.6/5.7.
  * vignettes: PT method family cited, not the alpha table specifically.
  * dev/physics-audit: alpha table values/source remain open.
  * README/NEWS: PT empirical validation listed as boundary item.
  * Current test coverage: equation-contract: PT closure; helper-contract: valid/invalid surface behavior; API parity: PT methods; guard/edge-case: invalid surface error.
  * Validation status: source values not revalidated.
  * Required follow-up only if later source validation is desired: source table/page for each alpha value.
* do not perform the validation now

### ST-004: penman-surface-resistance-table

- Area: Penman
- File: `R/utility.R`
- Function: `surface_resistance`
- Lines: `92-110`
- Type: empirical lookup table
- Values:

```text
Temperate grassland=60; Coniferous forest=50; Temperate deciduous forest=50;
Tropical rain forest=80; Cereal crops=30; Broadleaved herbaceous crops=35
```

* Current citation in source:

```text
citation: none found at table definition
```
* Other citations / notes found:
  * man/Rd: Penman cites Monteith et al. 1994; no table source found.
  * vignettes: Penman-type method cites Penman/Allen/Brutsaert, not this table.
  * dev/physics-audit: `rs` table source is `source-form-open`.
  * README/NEWS: simplified Penman resistance assumptions remain future validation item.
  * Current test coverage: equation-contract: Penman equation uses `Temperate grassland`; helper-contract: none; API parity: Penman method; guard/edge-case: field mapping and invalid aerodynamic cases.
  * Validation status: source-form open.
  * Required follow-up only if later source validation is desired: source for surface resistance table and class mapping.
* do not perform the validation now

### ST-005: humidity-helper-constants

- Area: Humidity
- File: `R/humidity.R`
- Function: `hum_specific()`, `hum_absolute()`, `hum_evap_heat()`
- Lines: `26-29`, `66-69`, `104-105`
- Type: physical constant
- Values:

```text
q = 0.622 * pvapor / p
AH = 0.21668 * pvapor / T_K
L = (2.5008 - 0.002372 * T) * 10^6
```

* Current citation in source:

```text
@references Bendix 2004, p. 262.
@references Bendix 2004, p. 261.
```
* Other citations / notes found: man/Rd repeats references; vignettes no extra source; dev audit treats as helper equations; README/NEWS no specific item.
  * Current test coverage: equation-contract: yes; helper-contract: scalar/vector behavior; API parity: humidity methods; guard/edge-case: limited.
  * Validation status: equation-contract tested.
  * Required follow-up only if later source validation is desired: confirm Bendix equations/units.
* do not perform the validation now

### ST-006: precipitable-water-seasonal-table

- Area: Humidity/transmittance
- File: `R/humidity.R`
- Function: `hum_precipitable_water()`
- Lines: `116-200`, table at `145-149`
- Type: empirical lookup table
- Values:

```text
row.names = tropic, temperate_summer, temperate_winter, subarctic_summer, subarctic_winter
t0 = 300, 294, 272.2, 287, 257.1
pwst = 4.1167, 2.9243, 0.8539, 2.0852, 0.4176
classification: abs(lat)<=30; abs(lat)<=60; months 4:9; hemisphere reversal
```

* Current citation in source:

```text
@references Bendix 2004, p. 246.
```
* Other citations / notes found: man/Rd same; vignettes no table citation; dev audit keeps radiation/transmittance source validation open; NEWS mentions POSIXct fix only.
  * Current test coverage: equation-contract: explicitly excluded; helper-contract: POSIXct/POSIXlt and vector length; API parity: yes; guard/edge-case: hemisphere tests.
  * Validation status: structural/input tested only.
  * Required follow-up only if later source validation is desired: Bendix p. 246 table for `t0`, `pwst`, and thresholds.
* do not perform the validation now

### ST-007: pressure-and-vapor-constants

- Area: Pressure
- File: `R/pressure.R`
- Function: `pres_p()`, `pres_vapor_p()`, `pres_sat_vapor_p()`, `pres_air_density()`
- Lines: `37-41`, `83-85`, `130-131`, `182-184`
- Type: physical constant
- Values:

```text
pres_p uses p0=1013.25, g=9.81, rl=287.05
pres_vapor_p uses RH/100
pres_sat_vapor_p = 6.1078 * 10^((a*T)/(b+T)); defaults a=7.5,b=235
pres_air_density = (p*100)/(287.05*(temp+273.15))
```

* Current citation in source:

```text
pres_p: Lente & Ősz 2020 eq. 5.
pres_vapor_p: Bendix 2004, p. 262
pres_sat_vapor_p: Bendix 2004, p. 261.
pres_air_density: citation: none found
```
* Other citations / notes found: man/Rd repeats formula references; dev audit records Penman VPD pressure-scale fix; README/NEWS mention Penman pressure scaling.
  * Current test coverage: equation-contract: yes; helper-contract: pressure/humidity tests; API parity: indirect; guard/edge-case: not central.
  * Validation status: equation-contract tested.
  * Required follow-up only if later source validation is desired: source for saturation vapor and air-density constants.
* do not perform the validation now

### ST-008: potential-temperature-constants

- Area: Temperature
- File: `R/temperature.R`
- Function: `temp_pot_temp()`
- Lines: `36-41`
- Type: physical constant
- Values:

```text
p0=1000; air_const=0.286; theta_C = k2c(c2k(t) * (p0/p)^air_const)
```

* Current citation in source:

```text
@references Bendix 2004, p. 261.
```
* Other citations / notes found: man/Rd clarifies elevation-to-pressure conversion; dev audit Gate 0 records expected value; vignettes no extra source.
  * Current test coverage: equation-contract and audited numeric behavior; API parity: not separate; guard/edge-case: not assessed.
  * Validation status: equation-contract tested.
  * Required follow-up only if later source validation is desired: confirm Bendix reference pressure convention.
* do not perform the validation now

### ST-009: soil-thermal-conductivity-table

- Area: Soil thermal properties
- File: `R/soil.R`
- Function: `soil_thermal_cond()`
- Lines: `75-118`, values at `105-113`
- Type: empirical lookup table
- Values:

```text
sand x=0,5,10,15,20,30,43; y=0.269,1.46,1.98,2.18,2.31,2.49,2.58
clay x=0,5,10,15,20,30,43; y=0.276,0.586,1.1,1.43,1.57,1.74,1.95
peat x=0,10,30,50,70,80,90; y=0.033,0.042,0.130,0.276,0.421,0.478,0.528
```

* Current citation in source:

```text
@references Bendix 2004, p. 254.
```
* Other citations / notes found: man/Rd same; dev soil audit says table validation open; NEWS says soil table values unchanged.
  * Current test coverage: equation-contract: not table values; helper-contract: valid/domain behavior; API parity: soil methods; guard/edge-case: invalid texture/out-of-domain.
  * Validation status: behavior tested only.
  * Required follow-up only if later source validation is desired: Bendix p. 254 table and interpolation policy.
* do not perform the validation now

### ST-010: soil-heat-capacity-table

- Area: Soil thermal properties
- File: `R/soil.R`
- Function: `soil_heat_cap()`
- Lines: `134-180`, values at `166-174`
- Type: empirical lookup table
- Values:

```text
sand x=0,5,10,15,20,30,43; y=1.17,1.38,1.59,1.8,2.0,2.42,2.97
clay x=0,5,10,15,20,30,43; y=1.19,1.4,1.61,1.82,2.03,2.45,2.99
peat x=0,10,30,50,70,80,90; y=0.25,0.67,1.51,2.35,3.19,3.61,4.03
approx uses yleft=NA, yright=y[7]
```

* Current citation in source:

```text
@references Bendix 2004, p. 254.
```
* Other citations / notes found: man/Rd same; dev audit says source/clamp policy open; NEWS says values unchanged.
  * Current test coverage: helper/domain/clamp behavior and API parity; equation-contract only for formulas using helper.
  * Validation status: behavior tested only.
  * Required follow-up only if later source validation is desired: Bendix p. 254 table and high-moisture clamp policy.
* do not perform the validation now

### ST-011: soil-attenuation-constants

- Area: Soil thermal properties
- File: `R/soil.R`
- Function: `soil_attenuation()`
- Lines: `193-226`
- Type: physical constant
- Values:

```text
sqrt(lambda / (C_v * 10^6 * pi) * 86400)
```

* Current citation in source:

```text
@references Bendix 2004, p. 253.
```
* Other citations / notes found: man/Rd same; dev audit marks unit conversion code-ok; vignettes no extra source.
  * Current test coverage: equation-contract yes; helper-contract soil tests; API parity yes; guard/edge-case inherited from soil tables.
  * Validation status: equation-contract tested.
  * Required follow-up only if later source validation is desired: Bendix p. 253 formula and daily period assumption.
* do not perform the validation now

### ST-012: priestley-taylor-sc-polynomial

- Area: Priestley-Taylor helpers
- File: `R/utility_turbulent_flux.R`
- Function: `sc()`
- Lines: `1-18`
- Type: source-dependent helper formula
- Values:

```text
8.5e-7*(t+273.15)^2 - 0.0004479*(t+273.15) + 0.05919
```

* Current citation in source:

```text
Foken/Stull Table 6 scale; specific humidity; kg kg-1 K-1; used with gam()
```
* Other citations / notes found: no Rd due `@noRd`; dev PT validation records Foken 2013 p. 48 Table 6 after Stull 1988; README/NEWS older notes mention helper scale boundary.
  * Current test coverage: source-table tests, PT equation tests, helper behavior tests, API parity indirect.
  * Validation status: equation-contract tested.
  * Required follow-up only if later source validation is desired: no further follow-up for the four rounded Table 6 values; alpha table separate.
* do not perform the validation now

### ST-013: priestley-taylor-gam-polynomial

- Area: Priestley-Taylor helpers
- File: `R/utility_turbulent_flux.R`
- Function: `gam()`
- Lines: `21-39`
- Type: source-dependent helper formula
- Values:

```text
0.0004 + (0.00041491 - 0.0004) / (1 + (299.44/(t+273.15))^383.4)
```

* Current citation in source:

```text
Polynomial fit to Table 6 in Foken (2013, p. 48), after Stull (1988);
specific-humidity scale, kg kg-1 K-1; not FAO-56 gamma.
```
* Other citations / notes found: no Rd due `@noRd`; dev PT validation records source-table tested.
  * Current test coverage: source-table tests, PT equation tests, helper behavior tests, API parity indirect.
  * Validation status: equation-contract tested.
  * Required follow-up only if later source validation is desired: no further follow-up for the four rounded Table 6 values.
* do not perform the validation now

### ST-014: internal-bowen-helper-and-heat-capacity

- Area: Bowen/turbulent utility helpers
- File: `R/utility_turbulent_flux.R`
- Function: `bowen_ratio()`, `heat_capacity()`
- Lines: `42-70`
- Type: source-dependent helper formula
- Values:

```text
bowen_ratio = heat_capacity(t) * dpot / (hum_evap_heat(t) * dah)
heat_capacity = 1005 * (1.2754298 - 0.0047219538*t + 1.6463585e-5*t)
```

* Current citation in source:

```text
bowen_ratio: Bendix 2004, p. 221eq9.21.
heat_capacity: Bendix 2004, p. 261.
```
* Other citations / notes found: no Rd due `@noRd`; dev Bowen validation notes exported functions do not call this helper.
  * Current test coverage: no source-table validation found; exported Bowen tested separately.
  * Validation status: source-form open.
  * Required follow-up only if later source validation is desired: decide whether exported beta should use this source-referenced helper.
* do not perform the validation now

### ST-015: exported-bowen-gamma-code

- Area: Bowen
- File: `R/sensible.R`, `R/latent.R`
- Function: `sensible_bowen()`, `latent_bowen()`
- Lines: `R/sensible.R:315-317`, `R/latent.R:627-629`
- Type: empirical coefficient
- Values:

```text
gamma_code = 0.00066 * (1 + 0.000946 * t1)
beta = gamma_code * dpot / dah
```

* Current citation in source:

```text
@references Bendix 2004, p. 221, eq. 9.21
```
* Other citations / notes found: Rd and vignettes document current implementation and source-form-open status; dev Bowen audits classify source-form open; README/NEWS list gamma_code equivalence open.
  * Current test coverage: equation-contract, source-behavior lock, API parity, cap/guard tests.
  * Validation status: source-form open.
  * Required follow-up only if later source validation is desired: unit/source derivation for gamma_code or source-backed replacement decision.
* do not perform the validation now

### ST-016: penman-surface-alias-mapping

- Area: Penman wrappers
- File: `R/latent.R`
- Function: `.normalize_penman_surface_type()`
- Lines: `80-121`
- Type: surface/land-cover mapping
- Values:

```text
field,lawn,grass -> Temperate grassland
agriculture,acre,crop,cereal crops -> Cereal crops
coniferous forest -> Coniferous forest
deciduous forest,mixed forest -> Temperate deciduous forest
shrub -> Broadleaved herbaceous crops
```

* Current citation in source:

```text
citation: none found
```
* Other citations / notes found: Rd documents list; dev Penman audits mark field mapping code-ok but resistance assumptions open.
  * Current test coverage: Penman field mapping, API parity, behavior tests.
  * Validation status: behavior tested only.
  * Required follow-up only if later source validation is desired: surface-class mapping source.
* do not perform the validation now

### ST-017: penman-method-constants

- Area: Penman
- File: `R/latent.R`
- Function: `latent_penman()`
- Lines: `237-257`
- Type: method parameterization
- Values:

```text
cp=1004; rho=1.2; gamma=0.665e-3*pres_p(elev,temp);
delta=4098*es_kPa/(temp+237.3)^2; d=turb_displacement(...vegetation);
zom=0.123*obs_height; zoh=0.1*zom; k=0.41; cap_value=1e-6
```

* Current citation in source:

```text
@references Monteith, John L., Mike H. Unsworth, and Ann Webb. ... 1994
```
* Other citations / notes found: Rd says simplified Penman-Monteith-type; vignettes cite Penman/Allen/Brutsaert; dev audits keep exact source form/resistance assumptions open; NEWS documents VPD unit fix.
  * Current test coverage: Penman unit/source tests, equation contracts, API parity, invalid aerodynamic guard.
  * Validation status: source-form open.
  * Required follow-up only if later source validation is desired: exact Penman/Penman-Monteith source form for all constants and roughness assumptions.
* do not perform the validation now

### ST-018: sensible-monin-constants

- Area: Monin-Obukhov/Profile
- File: `R/sensible.R`
- Function: `sensible_monin()`
- Lines: `171-189`
- Type: method parameterization
- Values:

```text
cp=1004.834; k=0.35; s1=z2/monin;
phi_h unstable = 0.74*(1-9*s1)^-0.5;
phi_h stable = 0.74+4.7*s1; output warning thresholds +/-600
```

* Current citation in source:

```text
@references Bendix 2004, p. 77, eq. 4.6
@references Foken 2016, p. 362: Businger
```
* Other citations / notes found: Rd same; vignettes cite Stull/Garratt/Foken; dev MO validation says physical source validation remains open.
  * Current test coverage: MO edge/guard tests; API parity; diagnostic-only tests.
  * Validation status: behavior tested only.
  * Required follow-up only if later source validation is desired: MOST/Businger source check for constants and signs.
* do not perform the validation now

### ST-019: latent-monin-constants

- Area: Monin-Obukhov/Profile
- File: `R/latent.R`
- Function: `latent_monin()`
- Lines: `477-494`
- Type: method parameterization
- Values:

```text
k=0.4; s1=z2/monin;
phi_q unstable = 0.95*(1-11.6*s1)^-0.5;
phi_q stable = 0.95+7.8*s1; output warning thresholds +/-600
```

* Current citation in source:

```text
@references Bendix 2004, p. 77, eq.4.6
@references Foken 2016, p. 61, Tab. 2.10
```
* Other citations / notes found: Rd/vignettes/dev audits mark diagnostic-only and source validation open.
  * Current test coverage: MO edge/guard tests; API parity; diagnostic-only tests.
  * Validation status: behavior tested only.
  * Required follow-up only if later source validation is desired: Foken/Businger source validation for humidity stability constants.
* do not perform the validation now

### ST-020: monin-richardson-stability-constants

- Area: Monin/Richardson diagnostics
- File: `R/turbulent_flux.R`
- Function: `turb_flux_monin()`, `turb_flux_grad_rich_no()`, `turb_flux_stability()`
- Lines: `27-65`, `120-155`, `209-214`
- Type: method parameterization
- Values:

```text
Ri thresholds: <=-0.005 unstable; -0.005..0.005 neutral; >=0.005 stable
Monin neutral factor 0.75; stable factor 4.7; k-like 0.4; g=9.81
min_shear=1e-4; safe fallback profile values t=20/19 or 20/20, z=2/10, v=2/4, elev=0
```

* Current citation in source:

```text
Bendix 2004, p. 241
Bendix 2004, p. 43, eq. 2.5
Based on Bendix 2004, p.43, picture 2.10
```
* Other citations / notes found: Rd same; dev MO audit says source constants open.
  * Current test coverage: Richardson/stability edge tests; API parity indirect.
  * Validation status: guard/edge-case tested.
  * Required follow-up only if later source validation is desired: source values for thresholds and Monin-length branches.
* do not perform the validation now

### ST-021: turbulent-exchange-quotient-constants

- Area: Turbulent exchange helpers
- File: `R/turbulent_flux.R`
- Function: `turb_flux_ex_quotient_temp()`, `turb_flux_ex_quotient_imp()`
- Lines: `250-365`
- Type: method parameterization
- Values:

```text
heat: 0.4, 0.74, 9, -0.5 exponent, 4.7
impulse: 0.4, 15, -0.25 exponent, 4.7
same Ri thresholds inherited from helper
```

* Current citation in source:

```text
Foken 2016, p. 362: Businger.
Foken 2016, p. 361: Businger.
```
* Other citations / notes found: Rd same; dev audits focus mainly MO flux functions.
  * Current test coverage: not assessed in current source-table tests; no dedicated source validation found.
  * Validation status: not assessed.
  * Required follow-up only if later source validation is desired: Foken/Businger constants and branch logic.
* do not perform the validation now

### ST-022: bulk-and-richardson-guard-defaults

- Area: Bulk-Residual
- File: `R/bulk.R`
- Function: `sensible_bulk()`
- Lines: `119-240`, defaults at `126-135`
- Type: method parameterization
- Values:

```text
rho=1.225; cp=1005; k=0.41; min_wind=0.1; warn_threshold=600;
ri_neutral=0.01; ri_critical=0.25; min_shear=1e-4; g=9.81
```

* Current citation in source:

```text
citation: none found in R/bulk.R roxygen; formula documented as simplified neutral bulk-transfer reference
```
* Other citations / notes found: dev fix plan/audit says bulk physical adequacy open; vignettes discuss optional Richardson guard.
  * Current test coverage: equation-contract; bulk-stability guard tests; API parity; low-wind/closure tests.
  * Validation status: equation-contract tested.
  * Required follow-up only if later source validation is desired: source for neutral bulk defaults and Richardson thresholds.
* do not perform the validation now

### ST-023: turbulence-roughness-displacement-constants

- Area: Turbulence/roughness
- File: `R/turbulence.R`
- Function: `turb_roughness_length()`, `turb_displacement()`, `turb_ustar()`
- Lines: `40-173`
- Type: method parameterization
- Values:

```text
roughness from obstacle height = 0.1*h
vegetation displacement = (2/3)*h; city displacement = 0.8*h
ustar = (v*0.4)/log(z/z0)
```

* Current citation in source:

```text
turb_roughness_length: Bendix 2004, p. 239
turb_displacement: Bendix, J. (2004). Weather and Climate: An Introduction. Springer.
turb_ustar: Bendix 2004, p. 239
```
* Other citations / notes found: Rd same; dev Penman/MO audits mark roughness source convention open.
  * Current test coverage: behavior tests for roughness; API parity indirect.
  * Validation status: behavior tested only.
  * Required follow-up only if later source validation is desired: exact source for obstacle ratios and roughness table linkage.
* do not perform the validation now

### ST-024: boundary-layer-constants

- Area: Boundary layers
- File: `R/boundary_layers.R`
- Function: `bound_mech_low()`, `bound_mech_avg()`, `bound_thermal_avg()`
- Lines: `27-108`
- Type: empirical coefficient
- Values:

```text
bound_mech_low(dist) = 0.3 * sqrt(dist)
bound_mech_avg(dist) = 0.43 * sqrt(dist)
bound_thermal_avg = (ustar/v) * sqrt((dist*abs(delta_theta))/abs(lapse_rate))
```

* Current citation in source:

```text
Bendix, J. (2004). Weather and Climate: An Introduction. Springer.
Roxygen prose says Bendix 2004, p. 242.
```
* Other citations / notes found: Rd same; no dev audit specifically for constants found.
  * Current test coverage: helper equation-contract tests.
  * Validation status: equation-contract tested.
  * Required follow-up only if later source validation is desired: Bendix p. 242 equation/table for coefficients 0.3 and 0.43.
* do not perform the validation now

### ST-025: radiation-shortwave-and-diffuse-constants

- Area: Radiation
- File: `R/radiation.R`
- Function: `rad_sw_in()`, `rad_sw_toa()`, `rad_diffuse_in()`
- Lines: `169-232`, `286-302`
- Type: method parameterization
- Values:

```text
rad_sw_in: sw_toa * 0.9751 * trans_total / sin(elevation) * cos(terrain_angle)
rad_sw_toa default sol_const=1361
rad_diffuse_in: 0.5 * (...) * sky_view * (1 + cos(terrain_angle)^2 * sin(solar_angle)^3)
```

* Current citation in source:

```text
Bendix 2004, p. 46 eq. 3.3, p. 52 eq. 3.8
Bendix 2004, p. 244
Bendix 2004, p. 58 eq. 3.14, p. 55 eq. 3.9
```
* Other citations / notes found: Rd same; radiation audit marks helper constants/domains open.
  * Current test coverage: radiation equation and contract tests; near-horizon/night guards.
  * Validation status: equation-contract tested.
  * Required follow-up only if later source validation is desired: Bendix equation constants and solar constant choice (`1361` vs global `1368`).
* do not perform the validation now

### ST-026: radiation-albedo-emissivity-and-longwave-constants

- Area: Radiation
- File: `R/radiation.R`, `R/utility.R`
- Function: `rad_sw_out()`, `rad_diffuse_out()`, `rad_emissivity_air()`, `rad_lw_out()`
- Lines: `R/radiation.R:351-407`, `501-594`; table `R/utility.R:12-69`
- Type: empirical lookup table
- Values:

```text
albedo/emissivity from surface_properties
rad_emissivity_air = (1.24 * vapor_p / temp_K)^(1/7)
longwave uses sigma_default = 5.6704e-8
```

* Current citation in source:

```text
Bendix 2004, p. 45 eq. 3.1
Bendix 2004, p. 66 eq. 3.20 / eq. 3.22
Bendix 2004, p. 68 eq. 3.24
```
* Other citations / notes found: Rd same; dev radiation audit says albedo/source validation open.
  * Current test coverage: radiation balance/albedo behavior tests; API parity indirect.
  * Validation status: equation-contract tested.
  * Required follow-up only if later source validation is desired: source for table values and air emissivity coefficient.
* do not perform the validation now

### ST-027: transmittance-gas-and-air-mass-constants

- Area: Transmittance
- File: `R/transmittance.R`
- Function: `trans_gas()`, `trans_air_mass_abs()`, `trans_air_mass_rel()`
- Lines: `31-132`
- Type: method parameterization
- Values:

```text
trans_gas = exp(-0.0127 * M_abs^0.26)
M_abs = M_rel * p/p0
M_rel = 1 / (sin(elevation_rad) + 1.5 * elevation_deg^-0.72)
```

* Current citation in source:

```text
trans_gas: Bendix 2004, p. 246.
trans_air_mass_abs: Bendix 2004, p. 247.
trans_air_mass_rel: Bendix 2004, p. 246.
```
* Other citations / notes found: Rd mostly same but air-mass abs Rd showed p. 246 in grep output; dev radiation/transmittance audit keeps source constants open.
  * Current test coverage: transmittance equation/contract tests and near-horizon guards.
  * Validation status: equation-contract tested.
  * Required follow-up only if later source validation is desired: reconcile p. 246/247 citation and constants.
* do not perform the validation now

### ST-028: transmittance-ozone-rayleigh-vapor-constants

- Area: Transmittance
- File: `R/transmittance.R`
- Function: `trans_ozone()`, `trans_rayleigh()`, `trans_vapor()`
- Lines: `180-281`
- Type: method parameterization
- Values:

```text
Ozone: 0.1611, 139.48, -0.3035, 0.002715, 0.044, 0.0003
Rayleigh: exp(-0.0903 * M_abs^0.84 * (1 + M_abs - M_abs^1.01))
Vapor: 1 - 2.4959*x*((1 + 79.034*x)^0.6828 + 6.385*x)^-1
```

* Current citation in source:

```text
@references Bendix 2004, p. 245.
```
* Other citations / notes found: Rd same; dev radiation/transmittance audit keeps constants open.
  * Current test coverage: transmittance equation-contract tests; guard behavior via air mass tests.
  * Validation status: equation-contract tested.
  * Required follow-up only if later source validation is desired: Bendix p. 245 source equations/constants.
* do not perform the validation now

### ST-029: transmittance-aerosol-table

- Area: Transmittance
- File: `R/transmittance.R`
- Function: `trans_aerosol()`
- Lines: `327-339`
- Type: empirical lookup table
- Values:

```text
vis = seq(10,60,10)
tau38 = 0.71,0.43,0.33,0.27,0.22,0.20
tau50 = 0.46,0.28,0.21,0.17,0.14,0.13
x = 0.2758*tau38 + 0.35*tau50
T = exp(-x^0.873 * (1+x-x^0.7088) * M_abs^0.9108)
```

* Current citation in source:

```text
@references Bendix 2004, p. 246.
```
* Other citations / notes found: Rd same; no table number found; dev audit keeps source constants open.
  * Current test coverage: transmittance contracts; no source-table value validation.
  * Validation status: equation-contract tested.
  * Required follow-up only if later source validation is desired: Bendix p. 246 aerosol tau table/source.
* do not perform the validation now

### ST-030: solar-astronomical-coefficients

- Area: Solar geometry
- File: `R/solar.R`
- Function: `sol_*()` helpers
- Lines: `26-446`
- Type: method parameterization
- Values:

```text
eccentricity: 1.00011, 0.034221, 0.00128, 0.000719, 0.000719
day angle denominator: 365
obliquity: 23.44
ecliptic length: 279.3 + 0.9856*J + 1.92*sin(M)
medium anomaly: 356.6 + 0.9856*J
hour angle/time: 15, 12, lon/15, 0.1644, 0.1277
```

* Current citation in source:

```text
@references Bendix 2004, p. 243.
```
* Other citations / notes found: Rd same; dev audit/fix plan flags solar timebase/source constants open.
  * Current test coverage: solar equation/contract tests; POSIXct/POSIXlt timebase behavior tests.
  * Validation status: equation-contract tested.
  * Required follow-up only if later source validation is desired: Bendix p. 243 equations and timebase convention.
* do not perform the validation now

### ST-031: terrain-factors

- Area: Terrain/radiation geometry
- File: `R/terrain.R`
- Function: `terr_sky_view()`, `terr_terrain_angle()`
- Lines: `31-99`
- Type: method parameterization
- Values:

```text
SVF non-valley = (1 + cos(slope))/2
SVF valley = cos(slope)
terrain angle = acos(cos(slope)*sin(elevation) + sin(slope)*cos(elevation)*cos(azimuth-exposition))
```

* Current citation in source:

```text
Bendix 2004, p. 63 eq. 3.15.
Bendix 2004, p. 52 eq. 3.7.
```
* Other citations / notes found: Rd same; radiation audit includes terrain/sky-view effects.
  * Current test coverage: terrain via radiation/solar contracts; no independent source validation.
  * Validation status: equation-contract tested.
  * Required follow-up only if later source validation is desired: Bendix terrain equations and domain assumptions.
* do not perform the validation now

### ST-032: unit-conversion-helpers

- Area: Unit conversion
- File: `R/utility.R`, `R/temperature.R`, helper functions where used
- Function: `c2k()`, `k2c()`, rad/deg helpers if present
- Lines: global `c2k_default` at `R/utility.R:5`
- Type: physical constant
- Values:

```text
Celsius/Kelvin offset = 273.15
radian/degree conversions use pi where implemented
```

* Current citation in source:

```text
citation: none found at global definition
```
* Other citations / notes found: helper equation tests document expected relation; no source citation needed/located.
  * Current test coverage: helper equation-contract tests.
  * Validation status: equation-contract tested.
  * Required follow-up only if later source validation is desired: not usually necessary unless package citation policy requires constants cited.
* do not perform the validation now

### ST-033: diagnostic-warning-and-cap-thresholds

- Area: Numerical diagnostics
- File: multiple heat-flux methods
- Function: PT/Bowen/Monin/Penman/Bulk methods
- Lines: examples include `R/bulk.R:129-135`, `R/sensible.R:209-213`, `R/latent.R:514-518`, `R/latent.R:293-299`
- Type: implementation coefficient
- Values:

```text
common high/low flux diagnostic threshold: +/-600 W m-2
Bowen cap is user-supplied denominator guard
Penman local cap_value <- 1e-6
```

* Current citation in source:

```text
citation: none found
```
* Other citations / notes found: dev audits distinguish warnings/guards from physical failure; README/NEWS mention guards added.
  * Current test coverage: behavior/guard tests for Bowen, Penman, Monin, Bulk.
  * Validation status: behavior tested only.
  * Required follow-up only if later source validation is desired: source or policy decision for diagnostic thresholds.
* do not perform the validation now

### ST-034: weather-station-dataframe-labels

- Area: Wrapper/output formatting
- File: `R/utility.R`
- Function: `as.data.frame.weather_station()`
- Lines: `215-248`
- Type: implementation coefficient
- Values:

```text
Hard-coded reduced column list and unit/name replacement suffixes for weather_station data frames.
```

* Current citation in source:

```text
citation: none found
```
* Other citations / notes found: Rd documents output behavior; no physics audit source required.
  * Current test coverage: wrapper preservation/API parity tests.
  * Validation status: API parity tested.
  * Required follow-up only if later source validation is desired: not source-table validation; only API contract decision if labels change.
* do not perform the validation now

### ST-035: surface-class-label-sets

- Area: Surface/land-cover naming
- File: multiple (`R/utility.R`, `R/latent.R`, `R/turbulence.R`, PT/Bowen/Radiation callers)
- Function: multiple
- Lines: `R/utility.R:13-25`, `73-80`, `93-100`; `R/latent.R:93-105`
- Type: surface/land-cover mapping
- Values:

```text
surface_properties classes: field, acre, lawn, street, agriculture, settlement,
  coniferous forest, deciduous forest, mixed forest, city, water, shrub
PT alpha classes: field, bare soil, coniferous forest, water, wetland, spruce forest
Penman resistance classes: Temperate grassland, Coniferous forest, Temperate deciduous forest,
  Tropical rain forest, Cereal crops, Broadleaved herbaceous crops
Alias mapping bridges some but not all classes.
```

* Current citation in source:

```text
citation: mixed; no source found at table definitions for class systems
```
* Other citations / notes found: Rd documents available class names; dev audits note unknown/case-mismatched surface behavior and mapping questions.
  * Current test coverage: valid/invalid surface behavior in radiation, PT, Penman, soil where relevant; API parity indirect.
  * Validation status: behavior tested only.
  * Required follow-up only if later source validation is desired: source-backed taxonomy and mapping policy across radiation, turbulence, PT, and Penman.
* do not perform the validation now
