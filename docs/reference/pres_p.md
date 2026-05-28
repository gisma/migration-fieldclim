# Air Pressure

Calculate air pressure based on the barometric formula.

## Usage

``` r
pres_p(...)

# Default S3 method
pres_p(elev, temp, ..., p0 = p0_default, g = g_default, rl = rl_default)

# S3 method for class 'weather_station'
pres_p(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- elev:

  Elevation above sea level in m.

- temp:

  Air temperature in degree Celcius.

- p0:

  Standard pressure in hPa, default 1013.25.

- g:

  Gravitational acceleration in \\m \cdot s^{-2}\\, default 9.81.

- rl:

  Specific gas constant for air in \\m^2 \cdot s^{-2} \cdot K^{-1}\\,
  default 287.05.

- weather_station:

  Object of class `weather_station`.

## Value

Air pressure in hPa.

## Details

The formula assumes that the temperature does not change with altitude.
The results are accurate for elevations lower than 5 km.

The air pressure (\\p\\) is calculated using the barometric formula:
\$\$p = p_0 \cdot \exp{\left(-\frac{g \cdot h}{R \cdot T}\right)}\$\$
where: \\p_0\\ is the standard pressure (default 1013.25 hPa), \\g\\ is
the gravitational acceleration (default 9.80665 m/s²), \\h\\ is the
elevation above sea level in meters (m), \\R\\ is the specific gas
constant for air (default 287.05 m²/s²/K), and \\T\\ is the temperature
in Kelvin (K).

## References

Lente & Ősz 2020 eq. 5.

## Examples

``` r
# Calculate air pressure at an elevation of 500 meters and temperature of 15°C
pres_p(elev = 500, temp = 15)
#> [1] 954.9101
```
