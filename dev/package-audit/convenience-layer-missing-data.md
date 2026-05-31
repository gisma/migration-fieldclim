# Strict missing-input convenience layer audit

## Purpose

This document evaluates which missing `weather_station` fields could theoretically be inspected, derived, modeled or filled by a future convenience layer. It is design-only. No implementation is proposed here as package code, and no current package behaviour is changed.

## Core policy

The convenience layer must be an inspection and preparation layer, not an automatic mutation layer. The default must be `strategy = "inspect_only"`.

Hard requirements:

- Never silently replace missing measured data.
- Never silently prefer modeled data over measured data.
- Never make downstream heat-flux methods appear to use measured forcing when they actually use derived, modeled or user-default forcing.
- Filling requires explicit user opt-in through a non-default strategy.
- The input object remains unchanged by default; a new object is returned if filling is requested.
- In-place modification requires an explicit `in_place = TRUE` argument.
- Measured values are never overwritten unless `overwrite = TRUE` is explicitly set.
- Original measured fields are preserved.
- Original missing values remain auditable.
- Every derived, modeled or user-default value has provenance and a log entry.
- Modeled environmental drivers must warn.
- No strategy may silently escalate to a more permissive strategy.

Allowed strategies should be deliberately explicit:

- `inspect_only`: report missing and fillable fields; do not fill anything.
- `derive_from_measured`: allow only algebraic/helper-derived values from measured inputs.
- `allow_modeled`: allow modeled environmental drivers in addition to measured-derived values.
- `allow_user_defaults`: allow explicit user-supplied constants/defaults/mappings in addition to lower-risk actions.

## Source classes and risk classes

Source classes:

- `measured`: observed value supplied by the user or dataset.
- `missing`: absent or `NA` value with no replacement.
- `derived_from_measured`: algebraic or helper-derived value using measured inputs.
- `modeled`: modeled environmental driver or table/model estimate replacing a direct measurement.
- `user_default`: explicit user-supplied constant, mapping or assumption.

Risk classes:

- `low`: algebraic reconstruction from measured components.
- `medium`: helper-derived value from measured variables or table-derived parameter.
- `high`: modeled environmental driver replacing direct measurement.
- `not_recommended`: profile structure or state variable cannot be reconstructed safely.

## Risk table

| Missing variable | Possible replacement | Required inputs | fieldClim function or formula | Source type | Risk level | Allowed strategy | Recommended default | Notes |
|---|---|---|---|---|---|---|---|---|
| `rad_bal` / `rad_net` | `(K_down - K_up) + (L_down - L_up)` | measured `rad_sw_in`, `rad_sw_out`, `rad_lw_in`, `rad_lw_out` or equivalent measured components | arithmetic balance | `derived_from_measured` | low | `derive_from_measured` | inspect only | Safe algebraically if all components are measured and same timebase. |
| `rad_bal` | modeled `rad_bal()` | datetime, lon, lat, elev, temp, rh, slope, exposition, valley, surface_type, surface_temp | `rad_bal()` modeled radiation chain | `modeled` | high | `allow_modeled` | inspect only | Modeled radiation is not equivalent to measured net radiation; must warn. |
| `rad_sw_out` | `albedo * rad_sw_in` | measured `rad_sw_in`, measured albedo | arithmetic reflection | `derived_from_measured` | medium | `derive_from_measured` | inspect only | Requires albedo to be measured or explicitly supplied, not inferred silently. |
| `rad_sw_out` | estimate albedo from `surface_type`, then multiply by `rad_sw_in` | `rad_sw_in`, `surface_type` | `surface_properties` albedo lookup / `rad_sw_out()` | `modeled` | high | `allow_modeled` | inspect only | Surface table source validation and unknown-surface policy remain open; must warn. |
| `rad_sw_in` | model incoming shortwave | datetime, lon, lat, elev, temp, slope, exposition; transmittance chain may need humidity/precipitable-water inputs | `rad_sw_in()`, solar/transmittance/terrain helpers | `modeled` | high | `allow_modeled` | inspect only | Modeled shortwave is not measured shortwave; night/near-horizon guards apply. |
| `rad_lw_in` | model incoming longwave | temp, rh, slope, valley | `rad_lw_in()` | `modeled` | high | `allow_modeled` only if explicitly supported | inspect only | Longwave modeling chain exists, but replacing measurement is high risk and domain validation remains open. |
| `rad_lw_out` | model outgoing longwave | surface_type, surface_temp | `rad_lw_out()` | `modeled` | high | `allow_modeled` only if explicitly supported | inspect only | Surface emissivity table/unknown-surface policy open; do not auto-fill. |
| `albedo` | lookup from `surface_type` | surface_type | `surface_properties$albedo` | `modeled` | high | `allow_modeled` | inspect only | Never silently set albedo from surface_type. |
| `surface_type` | user-supplied class | explicit user value | no automatic formula | `user_default` | high | `allow_user_defaults` | inspect only | Never silently default surface type. |
| `soil_flux` | `soil_heat_flux(...)` from measured gradient and measured conductivity | measured soil_temp1, soil_temp2, soil_depth1, soil_depth2, measured `thermal_cond` if future API supports it | `G = -lambda * (T1 - T2)/(z1 - z2)` | `derived_from_measured` | low to medium | `derive_from_measured` | inspect only | Current `soil_heat_flux()` computes conductivity from texture/moisture; a measured-conductivity path would be cleaner if implemented later. |
| `soil_flux` | `soil_heat_flux(texture, moisture, soil_temp1, soil_temp2, soil_depth1, soil_depth2)` | texture, moisture, measured soil temperature gradient/depths | `soil_heat_flux()` plus `soil_thermal_cond()` table | `modeled` | medium | `allow_modeled` | inspect only | Soil table/source validation remains open; log table-derived conductivity. |
| `thermal_cond` | table/interpolation from texture and moisture | texture, moisture | `soil_thermal_cond()` | `modeled` | medium | `allow_modeled` | inspect only | Table-derived parameter; invalid texture/moisture policy must be reported. |
| `moisture` | user default | explicit user value | none | `user_default` | high | `allow_user_defaults` | inspect only | Do not infer soil moisture automatically. |
| vapour pressure | derive from measured RH and temperature | rh, temp | `pres_vapor_p(temp, rh)` | `derived_from_measured` | medium | `derive_from_measured` | inspect only | Helper-derived; keep hPa provenance. |
| absolute humidity | derive from measured RH and temperature | rh, temp | `hum_absolute(rh, temp)` | `derived_from_measured` | medium | `derive_from_measured` | inspect only | Useful intermediate, but not a direct measurement. |
| specific humidity | derive from RH, temperature and elevation | rh, temp, elev | `hum_specific(rh, temp, elev)` | `derived_from_measured` | medium | `derive_from_measured` | inspect only | Uses modeled pressure from elevation unless measured pressure path exists. |
| `rh` | infer from unrelated fields | none recommended | no safe current inverse chain | `missing` | not_recommended | none | inspect only | Do not infer RH unless explicit inverse formula and all required inputs are documented. |
| `hum1` / `hum2` | map single-level `rh` to one or both profile levels | explicit user mapping | no automatic formula | `user_default` | high | `allow_user_defaults` | inspect only | Do not derive profile humidity from single-level RH automatically. |
| pressure | standard-atmosphere estimate | elev, temp | `pres_p(elev, temp)` | `modeled` | medium | `allow_modeled` | inspect only | Warn that this is a pressure estimate, not measured pressure. |
| potential temperature | derive from temperature and pressure/elevation | temp plus elev or measured pressure path | `temp_pot_temp()` / pressure helper | `derived_from_measured` or `modeled` | medium | `derive_from_measured` if measured pressure exists; otherwise `allow_modeled` | inspect only | Class depends on pressure source. |
| `t1` / `t2` | map single-level `temp` to profile level | explicit user mapping | none | `user_default` | high | `allow_user_defaults` | inspect only | Do not invent temperature profiles. |
| `v2` | estimate second wind height | none recommended | none | `missing` | not_recommended | none | inspect only | Never invent `v2`; `ri_guard` remains unavailable. |
| `z1` / `z2` | user-supplied heights | explicit user values | none | `user_default` | high | `allow_user_defaults` | inspect only | Do not auto-fill measurement heights. |
| profile gradients | reconstruct from single-height data | none recommended | none | `missing` | not_recommended | none | inspect only | Do not reconstruct vertical profiles from single-height data. |
| `obs_height` | user-supplied obstacle/observation height | explicit user value | none | `user_default` | high | `allow_user_defaults` | inspect only | Ambiguous meaning across methods; must be explicit. |
| `slope` / `exposition` | user-supplied terrain | explicit user values | none | `user_default` | high | `allow_user_defaults` | inspect only | Do not silently assume flat terrain if modeling radiation. |

## Variable-group evaluation

### Net radiation and radiation components

Measured net radiation should remain preferred whenever available. If `rad_bal` is missing but measured shortwave and longwave components exist, an algebraic reconstruction is low risk under `derive_from_measured`. If any component is modeled from solar/transmittance/surface tables, the result becomes a modeled environmental driver and must require `allow_modeled` with warnings.

The package has modeled shortwave and longwave functions, but current audits keep modeled-versus-measured equivalence open. The convenience layer must therefore preserve naming/provenance so downstream heat-flux methods cannot silently consume modeled `rad_bal` as if it were measured `rad_bal`.

Longwave components have a clear implemented chain (`rad_lw_in()`, `rad_lw_out()`), but automatic filling is not recommended by default because emissivity, surface temperature and domain policy are high-risk replacements for measurement.

### Soil heat flux

If measured soil temperature gradients and a measured thermal conductivity are available, soil heat flux can be algebraically derived with low-to-medium risk. In the current package, `soil_heat_flux()` computes conductivity from `texture` and `moisture`, so the practical current replacement is table-derived/model-assisted and should be treated as medium risk under `allow_modeled`, not as a direct measurement.

Missing soil moisture should not be inferred. It may only be supplied as an explicit user default under `allow_user_defaults`, with high-risk provenance.

### Humidity variables

RH, temperature and elevation can support vapour pressure, absolute humidity and specific humidity helper values. These are medium-risk derived intermediates because they depend on helper equations and, for specific humidity, pressure estimation. Missing `rh` should not be inferred from unrelated fields unless a future explicit inverse formula and complete input set are documented.

Profile humidity fields `hum1` and `hum2` are required by Bowen and Monin/Profile. They must not be derived from a single station-level `rh` automatically. Any mapping of `rh` to profile humidity must be explicit user action and logged as `user_default` or user mapping.

### Temperature and pressure

Pressure can be modeled from elevation and temperature with `pres_p()`, but this is a standard-atmosphere estimate and should be `modeled`, medium risk, not measured. Potential temperature is derived from temperature plus pressure/elevation; its risk class depends on whether pressure is measured or modeled.

Missing `t1` or `t2` cannot be reconstructed safely from single-level `temp`. Explicit user mapping may be allowed under `allow_user_defaults`, but it remains high risk and should be visibly logged.

### Wind and profile variables

The layer must not invent `v2`, `z1`, `z2`, profile gradients, `surface_type`, `obs_height`, slope or exposition. These are structural or state assumptions. Bulk neutral can use `v1` only, but Richardson guard and profile methods require actual two-height structure. Missing `v2` means `ri_guard` remains unavailable.

## Heat-flux method-specific fallback policy

| Method | Required direct inputs | Permitted convenience support | Explicitly forbidden default behaviour |
|---|---|---|---|
| Priestley-Taylor | `temp`, `rad_bal`, `soil_flux`, `surface_type` | May consume explicitly derived `rad_bal` or `soil_flux` if provenance is attached and strategy permits. | Do not model radiation or soil heat by default; do not set `surface_type` silently. |
| Bulk-Residual | `t1`, `t2`, `v1`, `z1`, `z2`, `rad_bal`, `soil_flux`; optional `v2`; `ri_guard` requires `v2`. | May consume explicitly derived `rad_bal`/`soil_flux`; neutral path can run without `v2`. | Do not invent `v2`; do not enable `ri_guard` without real `v2`; do not invent profile temperatures/heights. |
| Bowen | `t1`, `t2`, `hum1`, `hum2`, `z1`, `z2`, `elev`, `rad_bal`, `soil_flux`. | May consume explicitly derived `rad_bal`/`soil_flux`. | Do not derive `hum1`/`hum2` from single-level `rh`; do not invent gradients. |
| Monin-Obukhov/Profile | valid vertical profile of temperature, humidity, wind and heights plus roughness context. | Very limited; only explicit user mappings/defaults for structural fields. | Do not reconstruct profiles from single-height data; do not force closure. |
| Penman | `datetime`, wind, temp, humidity, height, `rad_bal`, elev, lat/lon, `soil_flux`, `obs_height`, `surface_type`. | Can use `rh` or current `hum1` routing; may consume explicitly modeled radiation only under `allow_modeled`. | Do not hide modeled radiation or user-default surface assumptions; do not invent paired sensible heat. |

## Audit conclusion

A convenience layer can be useful, but only if it makes missingness and provenance more visible. It should first report what is present, missing, fillable and unsafe. Filling should be an explicit preprocessing action. The layer must never blur measured, derived, modeled and user-default inputs, because downstream heat-flux outputs are highly sensitive to `rad_bal`, `soil_flux`, humidity/profile gradients and surface assumptions.
