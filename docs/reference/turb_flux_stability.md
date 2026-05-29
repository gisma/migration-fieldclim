# Stability

Conversion of Gradient-Richardson-Number to stability string. Non-finite
Richardson numbers return `NA`. This is a diagnostic classification, not
a heat-flux closure check.

## Usage

``` r
turb_flux_stability(...)

# Default S3 method
turb_flux_stability(grad_rich_no, ...)

# S3 method for class 'weather_station'
turb_flux_stability(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- grad_rich_no:

  Gradient-Richardson-Number

- weather_station:

  Object of class weather_station

## Value

A stability class string: "unstable", "neutral", "stable", or `NA`,
according to the current Gradient-Richardson-Number thresholds.

## References

Based on Bendix 2004, p.43, picture 2.10
