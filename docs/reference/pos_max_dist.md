# Maximum Distance between Climate Station and Obstacle

Checks if the climate station is positioned within the maximum allowable
distance from the obstacle.

## Usage

``` r
pos_max_dist(dist, obs_width, obs_height, ring = FALSE)
```

## Arguments

- dist:

  Distance between the climate station and the obstacle (e.g., forest)
  in meters (m).

- obs_width:

  Width of the obstacle in meters (m).

- obs_height:

  Height of the obstacle in meters (m).

- ring:

  Logical. If TRUE, the obstacle surrounds the station circularly.

## Value

A message indicating if the climate station is well positioned or if it
needs to be moved closer to the obstacle.

## Details

The maximum distance is calculated to ensure that the climate station's
measurements are within a reasonable range from the obstacle. If the
station is positioned too far, it needs to be moved closer.

Formula used:

- For a circularly surrounded obstacle: \\d\_{max} = 15 \cdot h\\

- For an obstacle behind the station:

  - If \\h \> w\\: \\d\_{max} = 15 \cdot w\\

  - If \\h \< w\\: \\d\_{max} = 15 \cdot h\\

## References

Bendix 2004, p. 189, eq. 9.1.

## Examples

``` r
# Check maximum distance for an obstacle behind the station
pos_max_dist(dist = 500, obs_width = 50, obs_height = 30)
#> [1] "The climate station is positioned too far from the obstacle. It needs to be placed in a position closer than 450 m from the obstacle."

# Check maximum distance for a circularly surrounded obstacle
pos_max_dist(dist = 500, obs_width = 50, obs_height = 30, ring = TRUE)
#> [1] "The climate station is positioned too far from the obstacle. It needs to be placed in a position closer than 450 m from the obstacle."
```
