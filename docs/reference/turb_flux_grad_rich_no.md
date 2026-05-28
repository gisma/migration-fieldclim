# Gradient-Richardson-Number

Calculation of the Gradient-Richardson-Number. The number represents the
stability of the atmosphere. Negative values signify unstable
conditions, positive values signify stable conditions, whereas values
around zero represent neutral conditions.

## Usage

``` r
turb_flux_grad_rich_no(...)

# Default S3 method
turb_flux_grad_rich_no(t1, t2, z1 = 2, z2 = 10, v1, v2, elev, ...)

# S3 method for class 'weather_station'
turb_flux_grad_rich_no(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- t1:

  Temperature at lower height (e.g. height of anemometer) in °C.

- t2:

  Temperature at upper height in degrees C.

- z1:

  Lower height of measurement (e.g. height of anemometer) in m.

- z2:

  Upper height of measurement in m.

- v1:

  Windspeed at lower height (e.g. height of anemometer) in m/s.

- v2:

  Windspeed at upper height in m/s.

- elev:

  Elevation above sea level in m.

- weather_station:

  Object of class weather_station

## Value

A stability class string: "unstable", "neutral", "stable", or `NA`,
according to the current Gradient-Richardson-Number thresholds.

## References

Bendix 2004, p. 43, eq. 2.5
