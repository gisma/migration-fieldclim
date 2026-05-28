# Emissivity of the Atmosphere

Calculates the emissivity of the atmosphere.

## Usage

``` r
rad_emissivity_air(...)

# Default S3 method
rad_emissivity_air(temp, rh, ...)

# S3 method for class 'weather_station'
rad_emissivity_air(weather_station, ...)
```

## Arguments

- ...:

  Named station fields, site parameters or model assumptions.

- temp:

  Air temperature in degrees C.

- rh:

  Relative humidity in percent.

- weather_station:

  A weather_station object.

## Value

Emissivity ratio from 0 to 1.

## Details

The emissivity of the atmosphere (\\\epsilon\_{air}\\) is calculated as:
\$\$\epsilon\_{air} = (1.24 \cdot \frac{e}{T\_{air}})^{1/7}\$\$ where:
\\e\\ is the vapor pressure, \\T\_{air}\\ is the air temperature in
Kelvin.

## References

Bendix 2004, p. 66 eq. 3.22.

## Examples

``` r
# Calculate emissivity of the atmosphere
rad_emissivity_air(temp = 15, rh = 60)
#> [1] 0.6409648
```
