# Air Density

Calculates the air density.

## Usage

``` r
pres_air_density(...)

# S3 method for class 'weather_station'
pres_air_density(weather_station, ...)

# Default S3 method
pres_air_density(elev, temp, ...)
```

## Arguments

- ...:

  Additional arguments.

- weather_station:

  A weather_station object.

- elev:

  Elevation above sea level in m.

- temp:

  Air temperature in degrees C.

## Value

Air density in kg/m³.

## Details

The air density (\\\rho\\) is calculated using the formula: \$\$\rho =
\frac{p \cdot 100}{R \cdot T}\$\$ where: \\p\\ is the air pressure in
hPa, \\R\\ is the specific gas constant for air (287.05 m²/s²/K), and
\\T\\ is the temperature in Kelvin (K).

## Examples

``` r
# Calculate air density at an elevation of 500 meters and temperature of 15°C
pres_air_density(elev = 500, temp = 15)
#> [1] 1.15448
```
