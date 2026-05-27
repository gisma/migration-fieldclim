Cloned from https://github.com/FabianMitze/fieldClim

`fieldClim` is designed as a handy tool for calculations of various weather and micromicrometeorological parameters based on the measurements of a weather station.
It includes functions adressing the estimation of radiation properties, the calculations of latent, sensible, and turbulent heat fluxes, the calculation of soil heat fluxes 
as well as the estimation of thermal and mechanical boundary layers. 
			 
Note that this package is currently under development. 

The rendered HTML vignettes included in this repository are historical outputs
and are not current numerical references. In the Caldern metadata, `EC` means
electric conductivity; the package does not implement complete Eddy Covariance
processing.


Use with:

remotes::install_git("https://gitlab.uni-marburg.de/fb19/ag-bendix/fieldClim.git")

library("fieldClim") 

TEACHING-READY ENERGY BALANCE WORKFLOW

This branch adds a stable teaching workflow for microclimate energy-balance
calculations.

A small packaged teaching dataset is provided:

inst/extdata/caldern_wiese_2017-06-30.csv

It contains one complete 5-minute day with 288 observations. The full Caldern
raw dataset is intentionally not included in the package.

The consolidated sign convention is:

- Rn > 0: radiative energy input at the surface
- G > 0: heat flux into the soil
- H > 0: sensible heat flux away from the surface
- LE > 0: latent heat flux away from the surface

For the Priestley-Taylor teaching path:

H + LE = Rn - G

The PT formulas were not changed. Documentation and tests were updated to
match the already implemented Rn - G convention.

A beginner-safe workflow is available through:

turb_flux_calc(weather_station, pt_only = TRUE)

This computes only sensible_priestley_taylor and latent_priestley_taylor,
avoiding optional Penman, Bowen and Monin-Obukhov paths in first teaching
exercises.

This branch also fixes small robustness issues in
as.data.frame.weather_station(), numeric warning checks, soil_attenuation(),
Bowen denominator handling, and non-fatal Penman behavior inside
turb_flux_calc().

This is not an Eddy Covariance implementation. In the Caldern metadata, EC
means electric conductivity, not Eddy Covariance.
