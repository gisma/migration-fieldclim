# Bulk-residual turbulent heat flux workflow

Adds `sensible_bulk` and `latent_bulk_residual` to a `weather_station`
object.

## Usage

``` r
turb_flux_bulk_residual(weather_station, ...)
```

## Arguments

- weather_station:

  A `weather_station` object.

- ...:

  Further arguments passed to
  [`sensible_bulk()`](https://gisma.github.io/migration-fieldclim/reference/sensible_bulk.md)
  and
  [`latent_bulk_residual()`](https://gisma.github.io/migration-fieldclim/reference/latent_bulk_residual.md).

## Value

The input `weather_station` object with additional fields
`sensible_bulk` and `latent_bulk_residual`.

## Details

This workflow combines the simple bulk-transfer estimate of sensible
heat flux with an energy-balance residual for latent heat flux.

First, sensible heat flux is estimated with:

\$\$ H\_{bulk} = \rho c_p \frac{T_1 - T_2}{r_a} \$\$

with:

\$\$ r_a = \frac{\log(z_2 / z_1)}{k \bar{u}} \$\$

Then latent heat flux is calculated as:

\$\$ LE\_{res} = R_n - G - H\_{bulk} \$\$

The resulting workflow closes the available turbulent energy exactly:

\$\$ H\_{bulk} + LE\_{res} = R_n - G \$\$

under the package sign convention. Here \\R_n \> 0\\ is net radiative
input at the surface, \\G \> 0\\ is heat flux into the soil, \\H \> 0\\
is sensible heat flux away from the surface, and \\LE \> 0\\ is latent
heat flux away from the surface.

The workflow is intended as a transparent reference and teaching path.
It is not a full Monin-Obukhov method and does not apply stability
corrections. The latent heat flux is a residual and therefore depends
directly on the quality of `rad_bal`, `soil_flux`, and the bulk sensible
heat estimate.

Required fields in `weather_station` are:

- `t1`: lower air temperature in degrees C.

- `t2`: upper air temperature in degrees C.

- `v1`: lower wind speed in m s-1.

- `z1`: lower measurement height in m.

- `z2`: upper measurement height in m.

- `rad_bal`: net radiation \\R_n\\ in W m-2.

- `soil_flux`: soil heat flux \\G\\ in W m-2.

If `v2` is present, it is used together with `v1` to compute mean wind
speed. If `v2` is missing, `v1` is used.

## Examples

``` r
ws <- build_weather_station(
  datetime = as.POSIXct(
    c("2023-06-01 12:00:00", "2023-06-01 12:30:00"),
    tz = "UTC"
  ),
  t1 = c(20, 18),
  t2 = c(18, 19),
  v1 = c(2, 2),
  v2 = c(4, 3),
  z1 = 2,
  z2 = 10,
  rad_bal = c(400, 300),
  soil_flux = c(60, 40),
  elev = 100
)

out <- turb_flux_bulk_residual(ws)
#> Warning: sensible_bulk: there are values above the diagnostic threshold of 600 W m-2.
#> Warning: latent_bulk_residual: there are values above the diagnostic threshold of 600 W m-2.

names(out)
#>  [1] "datetime"             "t1"                   "t2"                  
#>  [4] "v1"                   "v2"                   "z1"                  
#>  [7] "z2"                   "rad_bal"              "soil_flux"           
#> [10] "elev"                 "sensible_bulk"        "latent_bulk_residual"

out_guarded <- turb_flux_bulk_residual(
  ws,
  stability_method = "ri_guard"
)
#> Warning: sensible_bulk: there are values above the diagnostic threshold of 600 W m-2.
#> Warning: sensible_bulk: very stable Richardson cases for some values; returning NA there.
#> Warning: latent_bulk_residual: there are values above the diagnostic threshold of 600 W m-2.

attr(out_guarded$sensible_bulk, "bulk_stability")
#> [1] "unstable"    "very_stable"
attr(out_guarded$sensible_bulk, "bulk_Ri_g")
#> [1] -0.1338652  0.2681879
```
