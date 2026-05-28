# Shortwave Radiation at Top of Atmosphere

Calculates the shortwave radiation at the top of the atmosphere without
the influence of the atmosphere.

## Usage

``` r
rad_sw_toa(...)

# Default S3 method
rad_sw_toa(datetime, lon, lat, ..., sol_const = 1361)

# S3 method for class 'weather_station'
rad_sw_toa(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- datetime:

  Datetime of class `POSIXlt`. See
  [`base::as.POSIXlt()`](https://rdrr.io/r/base/as.POSIXlt.html). Make
  sure to provide the correct timezone information!

- lon:

  Longitude in degree.

- lat:

  Latitude in degree.

- sol_const:

  Solar radiation constant in W/m², default is 1361.

- weather_station:

  Object of class `weather_station`.

## Value

Shortwave radiation at top of atmosphere in W/m².

## Details

The shortwave radiation at the top of the atmosphere (\\SW\_{toa}\\) is
calculated using the formula: \$\$SW\_{toa} = S \cdot E \cdot
\sin(E)\$\$ where: \\S\\ is the solar constant (default 1361 W/m²),
\\E\\ is the eccentricity correction factor, \\E\\ is the solar
elevation angle.

## References

Bendix 2004, p. 244.

## Examples

``` r
# Calculate shortwave radiation at top of atmosphere
rad_sw_toa(datetime = Sys.time(), lon = 10, lat = 50)
#> Error in datetime$hour: $ operator is invalid for atomic vectors
```
