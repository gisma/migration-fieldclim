# Potential Temperature

Calculates the potential air temperature, which is the temperature that
a parcel of air would have if it were expanded or compressed
adiabatically to a standard pressure (usually 1000 hPa).

## Usage

``` r
temp_pot_temp(...)

# Default S3 method
temp_pot_temp(t, elev, ...)

# S3 method for class 'weather_station'
temp_pot_temp(weather_station, height = "lower", ...)
```

## Arguments

- ...:

  Additional arguments.

- t:

  Temperature in °C.

- elev:

  Elevation above sea level in m.

- weather_station:

  Object of class `weather_station`.

- height:

  Height of measurement, either "upper" or "lower".

## Value

Potential temperature in °C.

## Details

The potential temperature (\\\theta\\) is calculated using the formula:
\$\$\theta = T \left(\frac{p_0}{p}\right)^{R/c_p}\$\$ where: \\T\\ is
the temperature in Kelvin, \\p_0\\ is the standard pressure (1000 hPa),
\\p\\ is the actual pressure, \\R\\ is the specific gas constant for dry
air (287 J/(kg·K)), \\c_p\\ is the specific heat at constant pressure
(1004 J/(kg·K)).

## References

Bendix 2004, p. 261.

## Examples

``` r
# Calculate potential temperature at a given temperature and elevation
temp_pot_temp(t = 20, elev = 500)
#> [1] 23.80798
```
