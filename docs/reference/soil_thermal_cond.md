# Soil Thermal Conductivity

Calculates soil thermal conductivity from soil texture and soil
moisture. Works by linearly interpolating thermal conductivity based on
measured data. Moisture is supplied as m3 m-3 and converted internally
to volume percent.

## Usage

``` r
soil_thermal_cond(...)

# Default S3 method
soil_thermal_cond(texture, moisture, ...)

# S3 method for class 'weather_station'
soil_thermal_cond(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- texture:

  Soil texture. Either "sand", "peat" or "clay".

- moisture:

  Soil moisture content in cubic meters per cubic meter.

- weather_station:

  A weather_station object.

## Value

Soil thermal conductivity in W/m/K.

## Details

The thermal conductivity (\\\lambda\\) of the soil is determined based
on its texture and moisture content. The values are interpolated from
measured data for different soil types. Values outside the tabulated
moisture domain return `NA`.

## References

Bendix 2004, p. 254.

## Examples

``` r
# Calculate soil thermal conductivity
soil_thermal_cond(texture = "sand", moisture = 0.25)
#> [1] 2.4
```
