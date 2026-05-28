# Soil Attenuation Length

Calculates soil attenuation length.

## Usage

``` r
soil_attenuation(...)

# Default S3 method
soil_attenuation(moisture, texture = "sand", ...)

# S3 method for class 'weather_station'
soil_attenuation(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- moisture:

  Soil moisture in cubic meters per cubic meter.

- texture:

  Soil texture. Either "sand", "peat" or "clay".

- weather_station:

  A weather_station object.

## Value

Soil attenuation length in m.

## Details

The soil attenuation length (\\L\\) is calculated using the formula:
\$\$L = \sqrt{\frac{\lambda}{C_v \cdot 10^6 \cdot \pi} \cdot 86400}\$\$
where: \\\lambda\\ is the thermal conductivity of the soil (W/m/K),
\\C_v\\ is the volumetric heat capacity of the soil (MJ/(m³ \* K));
\\10^6\\ converts it to J/(m³ \* K) for the calculation, \\86400\\ is
the number of seconds in a day.

## References

Bendix 2004, p. 253.

## Examples

``` r
# Calculate soil attenuation length
soil_attenuation(moisture = 0.25, texture = "sand")
#> [1] 0.172819
```
