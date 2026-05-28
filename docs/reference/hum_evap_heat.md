# Enthalpy of vaporization

Calculates heat of evaporation for water from air temperature.

## Usage

``` r
hum_evap_heat(...)

# Default S3 method
hum_evap_heat(temp, ...)

# S3 method for class 'weather_station'
hum_evap_heat(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- temp:

  Air temperature in °C.

- weather_station:

  Object of class `weather_station`.

## Value

Numeric. Enthalpy of vaporization in J/kg.

## Details

The enthalpy of vaporization (\\L\\) is the amount of heat required to
convert a unit mass of a liquid into vapor without a temperature change.
It is calculated using the formula: \$\$L = (2.5008 - 0.002372 \times T)
\times 10^6\$\$ where \\T\\ is the temperature in °C.

## References

Bendix 2004, p. 261.

## Examples

``` r
# Calculate enthalpy of vaporization
hum_evap_heat(temp = 25)
#> [1] 2441500
```
