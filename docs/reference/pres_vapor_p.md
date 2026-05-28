# Vapor Pressure

Calculates vapor pressure from relative humidity and saturation vapor
pressure.

## Usage

``` r
pres_vapor_p(...)

# Default S3 method
pres_vapor_p(temp, rh, ...)

# S3 method for class 'weather_station'
pres_vapor_p(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- temp:

  Air temperature in degree Celcius.

- rh:

  Relative humidity in %.

- weather_station:

  Object of class `weather_station`.

## Value

Vapor pressure in hPa.

## Details

The vapor pressure (\\e\\) is calculated as: \$\$e = \frac{RH}{100}
\cdot e_s\$\$ where: \\RH\\ is the relative humidity in %, \\e_s\\ is
the saturation vapor pressure in hPa.

## References

Bendix 2004, p. 262

## Examples

``` r
# Calculate vapor pressure at a temperature of 20°C and 60% relative humidity
pres_vapor_p(temp = 20, rh = 60)
#> [1] 14.19944
```
