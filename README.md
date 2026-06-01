# fieldClim

`fieldClim` is an R package for weather-station based microclimate and micrometeorological calculations.

It provides functions for:

- organizing station data in a `weather_station` object
- calculating short-wave, long-wave and net radiation components
- estimating atmospheric transmittance and solar-geometry variables
- calculating soil heat flux and soil thermal parameters
- estimating sensible and latent heat fluxes from standard station data
- comparing Priestley-Taylor, Bulk-Residual, Bowen-ratio, Monin-Obukhov/Profile and Penman-type heat-flux paths
- estimating thermal and mechanical boundary-layer properties

The package was originally cloned from:

```text
https://gitlab.uni-marburg.de/fb19/ag-bendix/fieldClim.git
```

This repository is a private development and migration repository. It is under active consolidation and should not be treated as a stable public release.

## Installation

Install the current development version with:

```r
pak::pak("https://github.com/gisma/migration-fieldclim.git")
```

Then load the package with:

```r
library(fieldClim)
```

For private repository access, R must be authenticated against GitHub, for example via a valid `GITHUB_PAT`.

## Current status

The current workflow is a weather-station based energy-balance and heat-flux workflow. 

A small packaged example dataset is included:

```text
inst/extdata/caldern_wiese_2017-06-30.csv
```

It contains one complete 5-minute day with 288 observations. The full Caldern raw dataset is intentionally not included.

Historical rendered HTML vignettes in the repository may be archived outputs and should not be treated as current numerical references.

## Sign convention

The consolidated sign convention is:

```text
Rn > 0   radiative energy input at the surface
G  > 0   heat flux into the soil
H  > 0   sensible heat flux away from the surface
LE > 0   latent heat flux away from the surface
```

The available turbulent energy is:

```text
Rn - G
```

For energy-balance closing methods:

```text
H + LE = Rn - G
```

Not all implemented methods are energy-balance closing methods. Priestley-Taylor, finite uncapped Bowen-ratio cases and valid Bulk-Residual cases are interpreted through this balance. Monin-Obukhov/Profile outputs are profile-based estimates and are not forced to close `Rn - G`. Penman is implemented as a latent-heat-only comparison path.

## Main heat-flux workflows

A restricted Priestley-Taylor workflow is available through:

```r
turb_flux_calc(weather_station, pt_only = TRUE)
```

This computes only:

```text
sensible_priestley_taylor
latent_priestley_taylor
```

The full workflow is available through:

```r
turb_flux_calc(weather_station)
```

It attempts the available heat-flux paths:

```text
Priestley-Taylor
Bulk-Residual
Bowen-ratio
Monin-Obukhov/Profile
Penman-type latent heat
```

Bulk-Residual can also be calculated explicitly:

```r
turb_flux_bulk_residual(weather_station)
```

For stations with two wind heights, the optional Richardson-number guard can be enabled:

```r
turb_flux_bulk_residual(
  weather_station,
  stability_method = "ri_guard"
)
```

The default remains the neutral unguarded bulk estimate:

```r
stability_method = "none"
```

## Energy-balance closure diagnostics

`fieldClim` provides `energy_balance_closure()` to make the closure behaviour
of calculated heat-flux outputs explicit. The function does not compute new
fluxes. It inspects existing fields of a `weather_station` object and compares
the available energy, `rad_bal - soil_flux`, with already calculated sensible
and latent heat fluxes.

For methods with paired sensible and latent heat outputs, the diagnostic
residual is:

```r
closure_residual = rad_bal - soil_flux - sensible - latent
```

and the closure ratio is:

```r
closure_ratio = (sensible + latent) / (rad_bal - soil_flux)
```

For Penman, `fieldClim` reports an open complement:

```r
unresolved_complement = rad_bal - soil_flux - latent_penman
```

This complement must not be interpreted as sensible heat. Monin-Obukhov/Profile
residuals are diagnostic differences between profile-derived turbulent fluxes
and available energy; they are not automatic errors and are not forced to close.
Formal closure indicates an algebraic relationship in the package output, not
physical validation.

The companion `plot_energy_balance_closure()` function plots residuals,
Penman unresolved complements and closure ratios from the diagnostic output.


## Missing-data inspection and quality-control boundary

`fieldClim` does not fill, impute, interpolate, model, complete or replace missing meteorological time-series data. The package can inspect `weather_station` objects with `inspect_weather_station_inputs()` to report available variables, missingness, gap runs, variable classes, simple quality-control flags and heat-flux method input availability.

Any treatment of missing data must be performed outside `fieldClim` in a documented external workflow. The package does not create `*_filled` replacement columns and heat-flux methods require their actual input fields.

The missing-data inspection vignette demonstrates this read-only workflow using a synthetic gap/QC variant of the packaged Caldern teaching dataset.

## Validation status

The package is now tested for internal consistency. Method equations, helper equations, guard behaviour and `weather_station` wrappers are covered by automated tests.

The tests verify that the implemented code matches the documented equations. They do not claim empirical validation against independent flux measurements.

Source references and method-family context are documented in the help pages and vignettes. Further validation can be added through benchmark datasets, published numerical examples and explicit table-value audits where needed.

## Main changes in version 1.2.0

The detailed changelog is maintained in `NEWS.md`. The main functional changes are:

- Added Bulk-Residual workflow with `sensible_bulk()`, `latent_bulk_residual()` and `turb_flux_bulk_residual()`.
- Added optional Richardson-number guard for Bulk-Residual.
- Corrected Penman vapour-pressure scaling from hPa to kPa.
- Corrected `sensible_monin()` to use `z2 - z1` instead of `log(z2 - z1)`.
- Added guards for invalid or non-finite Bowen, Monin-Obukhov/Profile, Penman, soil, Richardson-number and transmittance states.
- Improved POSIXct/POSIXlt handling in solar and humidity-related paths.
- Fixed `hum_precipitable_water()` for POSIXct input in the `rad_sw_in()` -> `trans_vapor()` path.
- Corrected `soil_attenuation()` argument forwarding.
- Extended `turb_flux_calc()` with Bulk-Residual output, `pt_only`, and graceful Penman fallback to `NA`.
- Added `energy_balance_closure()` and `plot_energy_balance_closure()` for diagnostic inspection of formal closure behaviour in existing flux outputs.
- Updated Roxygen documentation for formulas, units, sign conventions and guard behaviour.
