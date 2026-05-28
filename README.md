# fieldClim

`fieldClim` is an R package for calculations of weather-station based microclimate and micrometeorological parameters.

It provides functions for:

- estimating radiation properties,
- calculating latent and sensible heat fluxes,
- calculating turbulent heat flux diagnostics,
- calculating soil heat fluxes,
- estimating thermal and mechanical boundary-layer properties,
- organizing station data in a structured `weather_station` object.

The package was originally cloned from:

```r
https://gitlab.uni-marburg.de/fb19/ag-bendix/fieldClim.git
```

This repository is a private development and migration repository. It is currently under construction and should not be treated as a stable public release.

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

The package is under active consolidation. Some historical rendered HTML vignettes included in the repository are archived outputs and should not be treated as current numerical references.

In the Caldern metadata, `EC` means electric conductivity. The package does not implement a complete Eddy Covariance processing chain.

This clone adds a stable workflow for microclimate energy-balance calculations.

A small packaged teaching dataset is provided:

```text
inst/extdata/caldern_wiese_2017-06-30.csv
```

It contains one complete 5-minute day with 288 observations. The full Caldern raw dataset is intentionally not included in the package.

The consolidated sign convention is:

* `Rn > 0`: radiative energy input at the surface
* `G > 0`: heat flux into the soil
* `H > 0`: sensible heat flux away from the surface
* `LE > 0`: latent heat flux away from the surface

For the Priestley-Taylor teaching path:

```text
H + LE = Rn - G
```

The Priestley-Taylor formulas were not changed. Documentation and tests were updated to match the already implemented `Rn - G` convention.

A beginner-safe workflow is available through:

```r
turb_flux_calc(weather_station, pt_only = TRUE)
```

This computes only:

```text
sensible_priestley_taylor
latent_priestley_taylor
```

and avoids optional Penman, Bowen and Monin-Obukhov paths in first teaching exercises.

## Consolidation changes in this branch

This branch includes small robustness fixes and documentation clarifications:

`turb_flux_calc(weather_station, pt_only = TRUE)` provides a beginner-safe teaching path. It computes only:

- `sensible_priestley_taylor`
- `latent_priestley_taylor`

This avoids the optional Penman, Bowen and Monin-Obukhov paths in first teaching exercises.

`turb_flux_calc()` keeps the full method workflow available, including:

- Priestley-Taylor
- Bowen
- Monin-Obukhov
- Penman

Penman failures are now non-fatal inside `turb_flux_calc()`.

`latent_penman.weather_station()` was consolidated so that common `fieldClim` surface types, such as `field`, can be mapped to Penman-compatible resistance classes.

Relative humidity handling in the Penman weather-station method was made consistent:

- profile humidity is used when available,
- otherwise the standard `rh` field is used.

`as.data.frame.weather_station()` now supports the current flat `weather_station` object structure.

Numeric warning checks in heat-flux functions were repaired so warnings are based on calculated numeric values rather than broken logical checks.

`soil_attenuation()` argument forwarding was corrected.

Bowen denominator handling was made more robust.

The Caldern teaching vignette now uses the packaged one-day dataset. It:

- reads `"NULL"` as `NA`,
- parses timestamps explicitly with `Europe/Berlin`,
- avoids depending on the full raw CSV.

New teaching and documentation material was added for:

- energy-balance workflows,
- radiation checks,
- soil heat flux checks,
- additional package use cases.

Tests were added or updated for:

- the consolidated teaching dataset,
- `weather_station` handling,
- warning logic,
- soil attenuation,
- Bowen denominator behavior,
- Penman availability.

## What this package does not currently provide

`fieldClim` currently does not provide a full Eddy Covariance workflow. It does not implement a complete chain including Reynolds decomposition, covariance calculation, coordinate rotation, WPL correction, quality control and 30-minute flux aggregation.

The current teaching workflow is therefore an energy-balance and heat-flux-methods workflow, not an Eddy Covariance workflow.

```
```
