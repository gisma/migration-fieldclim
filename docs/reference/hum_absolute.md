# Absolute humidity

Calculates absolute humidity from vapor pressure and air temperature.

## Usage

``` r
hum_absolute(...)

# Default S3 method
hum_absolute(rh, temp, ...)

# S3 method for class 'weather_station'
hum_absolute(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- rh:

  Relative humidity in %.

- temp:

  Temperature in °C.

- weather_station:

  Object of class `weather_station`.

## Value

Numeric. Absolute humidity in kg/m³.

## Details

Absolute humidity (\\AH\\) is the mass of water vapor per unit volume of
air. It is calculated from the vapor pressure and temperature using the
formula: \$\$AH = \frac{0.21668 \times pvapor}{T}\$\$ where \\pvapor\\
is the vapor pressure and \\T\\ is the temperature in Kelvin.

## References

Bendix 2004, p. 262.

## Examples

``` r
# Calculate absolute humidity
hum_absolute(rh = 70, temp = 25)
#> [1] 0.01635011
```
