# Roughness length

Calculates the roughness length of a surface based on the obstacle
height or the type of the surface.

## Usage

``` r
turb_roughness_length(...)

# Default S3 method
turb_roughness_length(surface_type = NULL, obs_height = NULL, ...)

# S3 method for class 'weather_station'
turb_roughness_length(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- surface_type:

  Type of surface. Options: r surface_properties\$surface_type

- obs_height:

  Height of obstacle in meters (m).

- weather_station:

  Object of class weather_station

## Value

Numeric. Roughness length in meters (m).

Numeric. Roughness length in meters (m).

## Details

Possible surface types are: "field", "acre", "lawn", "street",
"agriculture", "settlement", "coniferous forest", "deciduous forest",
"mixed forest", "city", "water", "shrub".

You need to specify only one of `surface_type` or `obs_height`.

This function calculates the roughness length (\\z_0\\) of a surface.
The roughness length is a measure of the roughness of the surface, which
affects the wind profile near the ground. It can be calculated either
based on the height of obstacles on the surface or by specifying the
type of surface.

When the obstacle height (`obs_height`) is provided, the roughness
length is calculated as 10% of the obstacle height.

When the surface type (`surface_type`) is provided, the roughness length
is looked up from predefined values.

## References

Bendix 2004, p. 239

## Examples

``` r
# Calculates roughness length based on obstacle height
turb_roughness_length(obs_height = 10)
#> [1] 1

# Calculate roughness length based on surface type
turb_roughness_length(surface_type = "deciduous forest")
#> [1] 1.5
```
