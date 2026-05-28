# Necessary Anemometer Height

Checks if the distance between the climate station and the forest is
smaller than the minimum distance. If so, calculates the height at which
the anemometer needs to be positioned to ensure independent
measurements.

## Usage

``` r
pos_anemometer_height(dist, min_dist, obs_height)
```

## Arguments

- dist:

  Distance between the climate station and the obstacle (e.g., forest)
  in meters (m).

- min_dist:

  Minimum distance between the climate station and the obstacle required
  to ensure independent measurements, in meters (m).

- obs_height:

  Height of the obstacle in meters (m).

## Value

A message indicating if the climate station is well positioned or, if
not, the height at which the anemometer needs to be positioned.

## Details

If the climate station is positioned closer than the minimum required
distance, the anemometer needs to be positioned at a higher altitude to
avoid measurement interference.

Formula used: \\h\_{new} = h \cdot \frac{d\_{min} - d}{d\_{min}}\\

## Examples

``` r
# Check anemometer height for a station too close to the obstacle
pos_anemometer_height(dist = 50, min_dist = 100, obs_height = 30)
#> [1] "The climate station is positioned too close to the obstacle. The anemometer needs to be repositioned 15 m higher."
```
