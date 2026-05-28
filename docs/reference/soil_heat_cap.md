# Soil Volumetric Heat Capacity

Calculates soil volumetric heat capacity (MJ / (m³ \* K)) from soil
moisture and texture. Works by linearly interpolating volumetric heat
capacity based on measured data.

## Usage

``` r
soil_heat_cap(...)

# Default S3 method
soil_heat_cap(moisture, texture = "sand", ...)

# S3 method for class 'weather_station'
soil_heat_cap(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- moisture:

  Soil moisture in cubic meters per cubic meter.

- texture:

  Soil texture. Either "sand", "peat" or "clay".

- weather_station:

  Object of class `weather_station`.

## Value

Soil volumetric heat capacity in MJ/(m³ \* K).

## Details

The volumetric heat capacity (\\C_v\\) of the soil is determined based
on its texture and moisture content. The values are interpolated from
measured data for different soil types.

## References

Bendix 2004, p. 254.

## Examples

``` r
# Calculate soil volumetric heat capacity
soil_heat_cap(moisture = 0.25, texture = "sand")
#> [1] 2.21
```
