# fieldClim

`fieldClim` is an R package for weather-station based microclimate and micrometeorological calculations.

It provides functions for:

- organizing station data in a structured `weather_station` object
- calculating short-wave, long-wave and net radiation components
- estimating atmospheric transmittance and solar-geometry variables
- calculating soil heat flux and soil thermal parameters
- estimating latent and sensible heat fluxes from standard station data
- comparing Priestley-Taylor, Bulk-Residual, Bowen-ratio, Monin-Obukhov/Profile and Penman-type heat-flux paths
- estimating thermal and mechanical boundary-layer properties

The package was originally cloned from:

```text
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

The package is under active consolidation. Historical rendered HTML vignettes included in the repository may be archived outputs and should not be treated as current numerical references.

In the Caldern metadata, `EC` means electric conductivity. The package does not implement a complete Eddy Covariance processing chain. It does not include Reynolds decomposition, coordinate rotation, WPL correction, quality control or covariance aggregation.

The current package workflow is a weather-station based energy-balance and heat-flux workflow, not an Eddy Covariance workflow.

A small packaged example dataset is provided:

```text
inst/extdata/caldern_wiese_2017-06-30.csv
```

It contains one complete 5-minute day with 288 observations. The full Caldern raw dataset is intentionally not included in the package.

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

For energy-balance closing methods, the working relation is:

```text
H + LE = Rn - G
```

Not all implemented methods are energy-balance closing methods.

Priestley-Taylor, finite uncapped Bowen-ratio cases and valid Bulk-Residual cases are interpreted through this balance. Monin-Obukhov/Profile outputs are profile-based estimates and are not forced to close `Rn - G`. Penman is implemented as a latent-heat-only comparison path.

## Main heat-flux workflows

A narrow Priestley-Taylor workflow is available through:

```r
turb_flux_calc(weather_station, pt_only = TRUE)
```

This computes only:

```text
sensible_priestley_taylor
latent_priestley_taylor
```

and avoids optional Penman, Bowen, Bulk-Residual and Monin-Obukhov/Profile paths.

The full workflow is available through:

```r
turb_flux_calc(weather_station)
```

It attempts the available package heat-flux paths:

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

The Richardson guard classifies profile stability and returns `NA` for invalid, weak-shear or very stable profile cases. The default remains the neutral unguarded bulk estimate:

```r
stability_method = "none"
```

## Consolidation changes in this branch

This branch includes functional fixes, robustness improvements and documentation consolidation.

### Heat-flux methods

* Added a package-level Bulk-Residual workflow with `sensible_bulk()`, `latent_bulk_residual()` and `turb_flux_bulk_residual()`.
* Added optional Richardson-number screening for Bulk-Residual through `stability_method = "ri_guard"`.
* Preserved the default neutral Bulk-Residual behaviour with `stability_method = "none"`.
* Extended `turb_flux_calc()` so that the full workflow also includes Bulk-Residual output fields.
* Added `pt_only = TRUE` to `turb_flux_calc()` for a narrower Priestley-Taylor workflow.

### Penman

* Corrected Penman vapour-pressure scaling by converting saturation and actual vapour pressure from hPa to kPa before use in the aerodynamic vapour-pressure-deficit term.
* Made aerodynamic-resistance handling elementwise.
* Invalid Penman aerodynamic states now return `NA` with a warning.
* `latent_penman.weather_station()` uses `hum1` when available and falls back to `rh`.
* Penman failures inside `turb_flux_calc()` are now non-fatal and are represented as `NA` output.

### Bowen

* Bowen denominator handling was made more robust.
* Sensible and latent Bowen paths now share guarded denominator logic.
* Finite, uncapped Bowen cases close `rad_bal - soil_flux`.
* Capped or non-finite cases are not interpreted as exact energy-balance closure.
* The implemented Bowen beta form remains source-form open and is documented as the `fieldClim` implementation.

### Monin-Obukhov/Profile

* Corrected `sensible_monin()` to use the documented vertical gradient denominator `z2 - z1` instead of `log(z2 - z1)`.
* Zero temperature gradients return zero sensible heat flux.
* Zero moisture gradients return zero latent heat flux.
* Invalid heights, invalid wind input, weak shear and non-finite profile states return `NA` with warnings.
* Monin-Obukhov/Profile outputs remain profile-based estimates and are not forced to close `rad_bal - soil_flux`.

### Radiation, solar geometry and humidity

* Improved POSIXct/POSIXlt datetime handling in solar and humidity-related paths.
* Fixed `hum_precipitable_water()` so POSIXct input works through the `rad_sw_in()` -> `trans_vapor()` -> `hum_precipitable_water()` path.
* `trans_air_mass_rel()` now returns `NA` with a warning for non-positive or invalid solar elevation instead of leaking `NaN`.

### Soil

* `soil_heat_flux()` now returns `NA` with a warning for invalid depth pairs.
* Valid `soil_heat_flux()` cases keep the existing sign convention.
* `soil_attenuation()` now calls `soil_thermal_cond(texture, moisture)` in the documented argument order.

### `weather_station` handling

* `as.data.frame.weather_station()` now supports the current flat `weather_station` object structure.
* `turb_flux_calc()` now has a full workflow and a restricted Priestley-Taylor-only workflow.
* Several wrapper and availability paths were made more explicit.

### Documentation and tests

New or updated documentation covers:

* energy-balance workflow steps
* scientific background for heat-flux methods
* additional package functionality
* radiation and soil heat-flux checks
* method-specific sign conventions
* guard behaviour and remaining validation boundaries

Tests were added or updated for:

* the packaged Caldern one-day dataset
* `weather_station` handling
* Priestley-Taylor closure
* Bulk-Residual and Richardson guard behaviour
* Bowen closure, cap and non-finite cases
* Penman source-form and unit behaviour
* Monin-Obukhov/Profile guards
* radiation, solar and transmittance contracts
* soil thermal functions
* POSIXct/POSIXlt handling in humidity and solar-related paths

## Remaining validation boundaries

This branch fixes implementation-level issues such as unit mismatches, denominator errors, invalid input handling and numerical edge cases. It does not fully re-derive or independently validate every empirical coefficient, lookup table or simplified method form against primary literature.

Remaining scientific source-validation items include:

* exact source form and literature equivalence of the Bowen `gamma_code` coefficient
* simplified Penman resistance assumptions and their mapping to published Penman-Monteith variants
* Monin-Obukhov/Profile stability functions, constants and interpretation of profile-based outputs
* absolute unit scale and source interpretation of the Priestley-Taylor helper coefficients `sc()` and `gam()`
* radiation and atmospheric transmittance formula references
* soil thermal conductivity, heat-capacity and attenuation table values
* precipitable-water seasonal reference table used by `hum_precipitable_water()`

These open items do not mean that the affected functions are known to be wrong. They document the boundary between code-level fixes completed in this branch and scientific source validation that remains to be completed.

