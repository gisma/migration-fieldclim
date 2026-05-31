# Convenience layer API sketch for missing weather-station inputs

## Design recommendation

Use two layers:

1. `inspect_weather_station_inputs()` for inspection only.
2. `complete_weather_station()` for explicit opt-in filling/preparation.

Do not implement this layer as part of this audit. The design below is a proposal only.

## Why two layers

A single function that both inspects and fills missing inputs is easy to misuse. The safest design separates read-only diagnosis from opt-in mutation/preparation. The current `weather_station` object stores fields exactly as supplied and should continue to do so unless the user explicitly requests a derived or completed object.

Recommended default: `strategy = "inspect_only"`.

## Name evaluation

| Candidate | Assessment | Recommendation |
|---|---|---|
| `inspect_weather_station_inputs()` | Clear, safe, read-only. Communicates that no filling happens. | Use for inspection layer. |
| `complete_weather_station()` | Clear for explicit preparation, but could imply automatic completion unless defaults are strict. | Use only with `strategy = "inspect_only"` default and explicit fill strategies. |
| `derive_missing_inputs()` | Too narrow: does not cover modeled values or user defaults and may imply automatic derivation. | Do not use as main API. |
| `prepare_weather_station()` | Vague; may hide whether fields are derived, modeled or defaulted. | Avoid as primary name. |

## Proposed signatures

```r
inspect_weather_station_inputs(
  weather_station,
  targets = c("all", "radiation", "soil", "humidity", "pressure", "profiles", "heat_flux"),
  methods = c("priestley_taylor", "bulk_residual", "bowen", "monin_profile", "penman", "all")
)
```

```r
complete_weather_station(
  weather_station,
  strategy = c("inspect_only", "derive_from_measured", "allow_modeled", "allow_user_defaults"),
  targets = c("all", "radiation", "soil", "humidity", "pressure", "profiles"),
  methods = c("all", "priestley_taylor", "bulk_residual", "bowen", "monin_profile", "penman"),
  overwrite = FALSE,
  keep_original = TRUE,
  add_provenance = TRUE,
  return_log = TRUE,
  warn = TRUE,
  in_place = FALSE
)
```

## Strategy semantics

| Strategy | Meaning | May fill? | May model environmental drivers? | May use user defaults? |
|---|---|---|---|---|
| `inspect_only` | Report available, missing, fillable and unsafe fields only. | No | No | No |
| `derive_from_measured` | Fill only algebraic/helper-derived values from measured inputs. | Yes, low/medium measured-derived only | No | No |
| `allow_modeled` | Allow modeled environmental drivers and table-derived parameters. | Yes | Yes, with warning and provenance | No |
| `allow_user_defaults` | Allow explicit user-supplied constants, mappings and assumptions. | Yes | Yes if also allowed by strategy semantics or explicitly included | Yes, with provenance |

No strategy may silently escalate. For example, `derive_from_measured` must not use modeled radiation because required solar/transmittance inputs happen to be present.

## Output design

The returned object or result should include:

- unchanged original fields, always preserved unless `overwrite = TRUE` and provenance is enabled;
- filled fields only if explicitly requested;
- provenance table;
- fill log;
- summary of remaining missing fields;
- summary of unsupported or not-recommended replacements;
- method readiness report for PT, Bulk-Residual, Bowen, Monin/Profile and Penman.

For `inspect_weather_station_inputs()`, the output should be a report object, not a modified `weather_station`.

For `complete_weather_station()`, the default return should be a new object or a list containing the new object plus log/provenance. The input object must be unchanged unless `in_place = TRUE` is explicitly requested.

## Provenance table fields

Required provenance fields:

- `variable`
- `row_index` or `time_index`
- `source_type` (`measured`, `missing`, `derived_from_measured`, `modeled`, `user_default`)
- `method`
- `required_inputs`
- `confidence`
- `risk_level` (`low`, `medium`, `high`, `not_recommended`)
- `warning`
- `old_value`
- `new_value`
- `overwritten`
- `timestamp`
- `strategy`
- `user_requested`

## Fill log fields

Required log fields:

- `action`
- `variable`
- `n_missing_before`
- `n_filled`
- `n_missing_after`
- `source_type`
- `method`
- `message`

## Suffix and overwrite policy

Two alternatives are possible:

### A. Overwrite with provenance

Example: `rad_bal` remains the field name and provenance records which rows were filled.

Pros: downstream methods can run without new field names. Cons: dangerous if provenance is ignored; modeled fields can look measured.

### B. Explicit filled fields

Examples: `rad_bal_filled`, `rad_bal_source`, `soil_flux_filled`, `soil_flux_source`.

Pros: safer and visible. Cons: more verbose; downstream methods need explicit selection/mapping.

Recommendation:

- Use explicit filled fields by default for modeled or high-risk replacements.
- Allow overwriting only when `overwrite = TRUE` and `add_provenance = TRUE`.
- For low-risk `derived_from_measured` values, overwriting may still require `overwrite = TRUE`; otherwise write explicit filled fields.
- Never use modeled data under the same name as measured data without visible provenance.

## Safety rules

- Default behaviour is inspection-only.
- No missing value replacement is allowed unless the user explicitly chooses a filling strategy.
- No measured value may be overwritten unless `overwrite = TRUE`.
- No modeled data may be used under the name of a measured field without provenance.
- No method workflow should silently switch from measured forcing to modeled forcing.
- Never invent `v2` for Richardson.
- Never reconstruct vertical profiles from single-height data.
- Never set `surface_type` silently.
- Never use modeled radiation as if it were measured radiation in validation plots.
- Always expose remaining missing fields.

## Future implementation test plan

A future implementation should add tests before adding broad fill behaviour:

- `inspect_only` does not alter the object.
- `derive_from_measured` must be explicitly selected before any derived fields are added.
- `allow_modeled` must be explicitly selected before modeled radiation or table-derived environmental drivers are used.
- Measured values are not overwritten by default.
- `overwrite = TRUE` is required for overwriting existing values.
- Provenance is created for every filled value.
- Fill log records every action.
- Derived `rad_bal` from measured radiation components is correct.
- Derived `soil_flux` from measured soil gradient is correct.
- Modeled `rad_sw_in` is flagged as `modeled` and high-risk.
- Missing `v2` prevents `ri_guard` filling/readiness.
- Profile gradients are not invented from single-height data.
- `surface_type` is not silently defaulted.
- Method workflows can run with derived fields but retain provenance.
- Row-wise partial missingness is handled without corrupting valid measured rows.
- Strategy escalation is impossible: `derive_from_measured` cannot perform modeled fills; `allow_modeled` cannot invent user defaults.
- Existing `weather_station` fields are preserved exactly when `keep_original = TRUE`.
- A modified object is a new object unless `in_place = TRUE` is explicit.

## Final recommendation

Implement the convenience layer only as explicit preprocessing. The default must be inspection-only. Filling must require explicit strategy selection. Modeled replacements must require explicit opt-in. Provenance and logging must be first-class outputs. The layer may help make downstream methods runnable, but it must never blur measured, derived, modeled and user-default inputs.
