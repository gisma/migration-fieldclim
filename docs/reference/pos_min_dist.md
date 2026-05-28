# Minimum Distance between Climate Station and Obstacle

Calculates the minimum distance required between a climate station and
an obstacle (e.g., forest) to ensure independence of measurements.

## Usage

``` r
pos_min_dist(...)

# Default S3 method
pos_min_dist(obs_width, obs_height, ring = FALSE, obs_radius = NULL, ...)
```

## Arguments

- ...:

  Additional arguments.

- obs_width:

  Width of the obstacle in meters (m).

- obs_height:

  Height of the obstacle in meters (m).

- ring:

  Logical. If TRUE, the obstacle surrounds the station circularly.

- obs_radius:

  If `ring` is TRUE, radius of the circular obstacle in meters (m).

## Value

Minimum distance in meters (m).

Minimum distance between the measurement point and the obstacle for
undisturbed measurement in meters (m).

## Details

The minimum distance is calculated to ensure that the climate station's
measurements are not influenced by nearby obstacles. The calculation
varies based on whether the obstacle surrounds the station circularly or
is positioned behind the station.

Formulas used:

- For a circularly surrounded obstacle: \\d\_{min} = \pi \cdot r + 10
  \cdot h\\

- For an obstacle behind the station:

  - If \\h \> w\\: \\d\_{min} = 0.5 \cdot h + 10 \cdot w\\

  - If \\h \< w\\: \\d\_{min} = 0.5 \cdot w + 10 \cdot h\\

  - If \\h \approx w\\ (within \\±5\\\\): \\d\_{min} = 5 \cdot (h + w)\\

## References

Bendix 2004, p. 189, eq. 9.1.

## Examples

``` r
# Minimum distance for an obstacle behind the station
pos_min_dist(obs_width = 50, obs_height = 30)
#> [1] 325

# Minimum distance for a circularly surrounded obstacle
pos_min_dist(obs_width = 50, obs_height = 30, ring = TRUE, obs_radius = 100)
#> [1] 614.1593
```
