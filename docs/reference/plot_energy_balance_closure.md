# Plot energy-balance closure diagnostics

Visualizes output from
[`energy_balance_closure()`](https://gisma.github.io/migration-fieldclim/reference/energy_balance_closure.md).
This is a plotting helper for diagnostics, not a flux model. It does not
compute new turbulent fluxes and does not alter the diagnostic object.

## Usage

``` r
plot_energy_balance_closure(
  x,
  type = c("residual", "ratio"),
  methods = NULL,
  ...
)
```

## Arguments

- x:

  Output from
  [`energy_balance_closure()`](https://gisma.github.io/migration-fieldclim/reference/energy_balance_closure.md).

- type:

  Plot type. `"residual"` plots closure residuals and Penman unresolved
  complements. `"ratio"` plots finite closure ratios for paired methods.

- methods:

  Optional character vector of methods to include.

- ...:

  Additional arguments passed to base plotting functions.

## Value

Invisibly returns `x`.

## Details

For residual plots, paired methods use `closure_residual`. Penman uses
`unresolved_complement`, labelled explicitly as such; the Penman
complement is not sensible heat. Monin/Profile residuals remain
diagnostic and are not forced to close.

Ratio plots use `closure_ratio` for paired methods only. Penman is
excluded because fieldClim does not provide a paired Penman sensible
heat flux. Rows marked `low_available_energy` are omitted from ratio
plots because closure ratios are unstable near zero available energy.
