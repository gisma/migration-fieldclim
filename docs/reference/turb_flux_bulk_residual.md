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
  [`sensible_bulk()`](https://gisma.github.io/migration-fieldclim/reference/sensible_bulk.md).

## Value

The input `weather_station` object with additional fields:
`sensible_bulk` and `latent_bulk_residual`.
