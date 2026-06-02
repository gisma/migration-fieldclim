# Diagnose surface-energy-balance closure from existing flux fields

This is a diagnostic function, not a flux model. It inspects existing
fields in a `weather_station` object and calculates closure quantities
from already-computed heat-flux outputs. It does not compute new
turbulent fluxes and does not alter the input object.

## Usage

``` r
energy_balance_closure(
  weather_station,
  methods = c("priestley_taylor", "bulk_residual", "bowen", "penman", "monin"),
  min_available = 20
)
```

## Arguments

- weather_station:

  A `weather_station` object containing `rad_bal`, `soil_flux`, and any
  already-computed flux fields to inspect.

- methods:

  Character vector of method families to inspect. Supported values are
  `"priestley_taylor"`, `"bulk_residual"`, `"bowen"`, `"penman"`, and
  `"monin"`.

- min_available:

  Minimum absolute available energy in W m-2 required for stable
  closure-ratio interpretation.

## Value

A long `data.frame` with one row per input row and requested method.
Columns include `datetime`, `method`, `closure_type`, `rad_bal`,
`soil_flux`, `available_energy`, `sensible`, `latent`, `turbulent_sum`,
`closure_residual`, `closure_ratio`, `unresolved_complement`, and
`status`.

## Details

The package sign convention is \\R_n \> 0\\ for net radiative input at
the surface, \\G \> 0\\ for soil heat flux into the soil, and \\H \> 0\\
and \\LE \> 0\\ for turbulent fluxes away from the surface. Available
energy is calculated as:

\$\$A = R_n - G\$\$

using `available_energy = rad_bal - soil_flux`.

For paired \\H\\/\\LE\\ methods, including Priestley-Taylor,
Bulk-Residual, Bowen, and Monin/Profile diagnostics, the function
computes:

\$\$closure\\residual = available\\energy - sensible - latent\$\$

and:

\$\$closure\\ratio = turbulent\\sum / available\\energy\$\$

where `turbulent_sum = sensible + latent`.

For Penman, which is latent-heat-only in fieldClim, no paired sensible
heat flux is available. The function therefore computes:

\$\$unresolved\\complement = available\\energy - latent\\penman\$\$

The Penman complement must not be interpreted as measured sensible heat.
Monin/Profile residuals are diagnostic and are not forced to close.
Formal closure does not validate physical correctness; it only describes
the algebraic behaviour of the existing method outputs.

## Examples

``` r
ws <- structure(
  list(
    datetime = as.POSIXct(
      c("2023-06-30 12:00", "2023-06-30 12:30"),
      tz = "UTC"
    ),
    rad_bal = c(400, 300),
    soil_flux = c(60, 40),

    # Bulk-Residual: formally closed by construction.
    sensible_bulk = c(120, 80),
    latent_bulk_residual = c(220, 180),

    # Penman: latent heat only; complement remains unresolved.
    latent_penman = c(200, 160),

    # Monin/Profile: diagnostic residual remains visible.
    sensible_monin = c(100, 100),
    latent_monin = c(180, 130)
  ),
  class = "weather_station"
)

closure <- energy_balance_closure(
  ws,
  methods = c("bulk_residual", "penman", "monin")
)

closure
#>              datetime        method       closure_type rad_bal soil_flux
#> 1 2023-06-30 12:00:00 bulk_residual   residual_closure     400        60
#> 2 2023-06-30 12:30:00 bulk_residual   residual_closure     300        40
#> 3 2023-06-30 12:00:00        penman       le_only_open     400        60
#> 4 2023-06-30 12:30:00        penman       le_only_open     300        40
#> 5 2023-06-30 12:00:00         monin profile_diagnostic     400        60
#> 6 2023-06-30 12:30:00         monin profile_diagnostic     300        40
#>   available_energy sensible latent turbulent_sum closure_residual closure_ratio
#> 1              340      120    220           340                0     1.0000000
#> 2              260       80    180           260                0     1.0000000
#> 3              340       NA    200            NA               NA            NA
#> 4              260       NA    160            NA               NA            NA
#> 5              340      100    180           280               60     0.8235294
#> 6              260      100    130           230               30     0.8846154
#>   unresolved_complement              status
#> 1                    NA                  ok
#> 2                    NA                  ok
#> 3                   140     open_complement
#> 4                   100     open_complement
#> 5                    NA diagnostic_residual
#> 6                    NA diagnostic_residual
```
