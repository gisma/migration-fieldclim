# Sensible and latent heat fluxes

Calculate sensible and latent heat fluxes, using the methods of
Priestly-Taylor, Bowen, Monin and Penman (only latent).

## Usage

``` r
turb_flux_calc(weather_station, pt_only = FALSE)
```

## Arguments

- weather_station:

  Object of class weather_station

- pt_only:

  If `TRUE`, calculate only the Priestley-Taylor sensible and latent
  heat fluxes. This supports the introductory energy balance workflow
  without requiring inputs for the optional additional methods. In the
  full workflow, unavailable Penman inputs result in `NA` values and a
  warning.

## Value

Object of class weather_station
