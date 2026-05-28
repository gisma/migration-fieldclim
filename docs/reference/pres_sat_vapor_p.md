# Saturated Vapor Pressure

Calculates the saturation vapor pressure for a given temperature.

## Usage

``` r
pres_sat_vapor_p(...)

# Default S3 method
pres_sat_vapor_p(temp, ..., a = 7.5, b = 235)

# S3 method for class 'weather_station'
pres_sat_vapor_p(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- temp:

  Air temperature in degree Celcius.

- a:

  Constant a, default is 7.5 over water.

- b:

  Constant b, default is 235 over water.

- weather_station:

  Object of class `weather_station`.

## Value

Saturation vapor pressure in hPa.

## Details

The saturation vapor pressure (\\e_s\\) is calculated using the formula:
\$\$e_s = 6.1078 \cdot 10^{\left(\frac{a \cdot T}{b + T}\right)}\$\$
where: \\T\\ is the temperature in °C, \\a\\ and \\b\\ are constants
that vary depending on the state of water:

- Over water: \\a = 7.5\\, \\b = 235\\

- Over undercooled water: \\a = 7.6\\, \\b = 240.7\\

- Over ice: \\a = 9.5\\, \\b = 265.5\\

## References

Bendix 2004, p. 261.

## Examples

``` r
# Calculate saturation vapor pressure at a temperature of 20°C
pres_sat_vapor_p(temp = 20)
#> [1] 23.66574
```
