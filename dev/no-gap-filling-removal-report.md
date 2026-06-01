# No-gap-filling removal report

## Scope

This pass removes live weather-station data-completion behavior from package code and documentation. `fieldClim` is now limited to inspection, missingness/gap reporting, variable classification, selected quality-control flags and method input availability reporting. It must not fill, impute, interpolate, model, complete or replace missing meteorological time-series data.

## Repository scan

Search terms included: `fill`, `filled`, `filling`, `gap`, `gapfill`, `gap_fill`, `impute`, `imputation`, `interpolate`, `interpolation`, `complete_weather_station`, `complete`, `derive_from_measured`, `allow_modeled`, `rad_bal_filled`, `soil_flux_filled`, `pressure_filled`, `modeled radiation`, `replacement`, `substitute`, and `missing data completion`.

### Remove

| Hit family | Location | Action |
|---|---|---|
| live completion strategy names | `R/convenience_missing_inputs.R` | Removed. No `derive_from_measured`, `allow_modeled`, or completion strategies remain in R source. |
| replacement columns | `R/convenience_missing_inputs.R` and old convenience tests | Removed from live implementation. No R source creates `rad_bal_filled`, `soil_flux_filled`, `pressure_filled`, or modeled radiation `*_filled` columns. |
| completion tests | `tests/testthat/test-convenience-*` | Rewritten to inspection/QC-only tests. Completion test files are not present in the working tree; `test-convenience-inspection.R` now asserts no live replacement-column API terms remain in R source. |
| README completion wording | `README.md` | Replaced with missing-data inspection and QC boundary language. |
| NEWS completion status | `NEWS.md` | Added missing-data inspection boundary note. |

### Rewrite to inspection-only

| Hit family | Location | Action |
|---|---|---|
| `inspect_weather_station_inputs()` description | `R/convenience_missing_inputs.R` | Rewritten as read-only inspection: field status, gap runs, method readiness, QC flags, and guidance. |
| possible future actions table | `R/convenience_missing_inputs.R` | Removed. The output now returns `guidance`, not future strategy actions. |
| tests for possible actions | `tests/testthat/test-convenience-inspection.R` | Rewritten to assert guidance, gap classes, QC flags and method availability. |
| repository knowledge state | `dev/repo-knowledge-state.md` | Appended update note that earlier completion actions are historical context only. |

### Keep because unrelated

| Hit family | Location | Reason |
|---|---|---|
| `complete.cases()` | `tests/testthat/test-consolidation.R` | Base R phrase meaning a row has no missing values; not a data-completion algorithm. |
| `complete day` | `README.md`, `tests/testthat/test-consolidation.R` | Describes the packaged one-day Caldern example, not gap filling. |
| Penman fallback to `NA` | `R/turbulent_flux.R`, tests | Error containment for a method output, not missing time-series completion. |
| interpolation in source-table context | `R/soil.R`, source-table audits | Soil thermal property lookup/interpolation is an empirical helper formula, not weather-station gap filling. This task did not change soil formulas. |
| replacement in Bowen/source validation prose | `dev/source-table-audit/*`, `dev/physics-audit/*` | Historical/source-validation language, not live missing-data functionality. |

### Keep as historical dev note only

Historical design/audit reports under `dev/package-audit/`, `dev/physics-audit/`, `dev/test-audit/`, and `dev/source-table-audit/` still contain terms such as filling, replacement, modeled radiation and completion. These files are retained as audit history and are not live package functionality. The current repository state is superseded by this removal report and the appended note in `dev/repo-knowledge-state.md`.

Generated pkgdown files under `docs/` may also contain stale completion-language output. They were not treated as source of truth and were not edited in this pass.

## Files changed

- `R/convenience_missing_inputs.R`
- `tests/testthat/test-convenience-inspection.R`
- `README.md`
- `NEWS.md`
- `dev/repo-knowledge-state.md`
- `dev/no-gap-filling-removal-report.md`
- generated `NAMESPACE` and `man/*.Rd` after `devtools::document()`

## Removed or disabled functions

- `complete_weather_station()` is not present in the live R source after this pass and is not exported.
- Internal completion helpers and strategy tables were removed.
- No live R function creates replacement `*_filled` columns.

## Remaining inspection-only functions

- `inspect_weather_station_inputs()` remains exported.
- It returns:
  - `fields`: field presence, missing counts, missing fraction, group and variable type;
  - `gaps`: missing-value runs, start/end index, optional timestamps, duration and gap class;
  - `method_readiness`: heat-flux method input availability;
  - `qc_flags`: selected QC warnings/errors;
  - `guidance`: inspection and external-workflow guidance;
  - `summary`: counts and ready/blocked methods.

## Tests added or rewritten

`tests/testthat/test-convenience-inspection.R` now verifies:

- inspection does not mutate input objects;
- no `*_filled` columns are created by inspection;
- field missingness and variable types are reported;
- gap runs and gap classes are reported;
- method readiness reports blocked inputs without using replacement fields;
- guidance says missing-data treatment belongs outside `fieldClim`;
- simple QC problems are flagged;
- heat-flux methods still require actual input fields;
- R source contains no live replacement-column completion terms: `rad_bal_filled`, `soil_flux_filled`, `pressure_filled`, `allow_modeled`, `derive_from_measured`, `complete_weather_station`.

## Ambiguous terms needing manual decision

- The word `complete` remains in unrelated contexts such as `complete day` and `complete.cases()`.
- Generated `docs/` output may be stale and should be regenerated or cleaned in a separate documentation-site task if published pages must match the new policy.
- Historical `dev/` audit/design reports intentionally retain old discussion. They should not be read as current package behavior.
