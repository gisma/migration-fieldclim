# Displacement height

Calculates the displacement height caused by an obstacle (e.g., a crop
field). This function works for both vegetation and urban environments.

## Usage

``` r
turb_displacement(...)

# Default S3 method
turb_displacement(obs_height, surroundings = "vegetation", ...)

# S3 method for class 'weather_station'
turb_displacement(weather_station, surroundings = "vegetation", ...)
```

## Arguments

- ...:

  Additional arguments.

- obs_height:

  Numeric. Height of vegetation or buildings in meters (m).

- surroundings:

  Character. Type of surroundings. Options: "vegetation" or "city".

- weather_station:

  Object of class weather_station

## Value

Numeric. Displacement height in meters (m).

## Details

This function calculates the displacement height (\\d\\) caused by an
obstacle, such as vegetation or buildings. The displacement height is an
important parameter in boundary layer meteorology as it affects the wind
profile near the ground.

For vegetation, the displacement height is calculated as two-thirds of
the obstacle height.

For urban environments (dense housing), the displacement height is
calculated as 80% of the obstacle height.

## References

Bendix, J. (2004). Weather and Climate: An Introduction. Springer.

## Examples

``` r
# Calculate displacement height for vegetation with a height of 10 meters
turb_displacement(obs_height = 10, surroundings = "vegetation")
#> [1] 6.666667

# Calculate displacement height for a city with buildings of height 10 meters
turb_displacement(obs_height = 10, surroundings = "city")
#> [1] 8
```
