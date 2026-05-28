# Mechanical internal boundary layer; average height.

This function calculates the average height of the mechanical internal
boundary layer (MIBL). The MIBL height is calculated based on the
distance to the point of roughness change using an empirical
relationship described by Bendix (2004, p. 242).

## Usage

``` r
bound_mech_avg(dist)
```

## Arguments

- dist:

  Numeric. The distance to the point of roughness change in meters (m).

## Value

Numeric. The average height of the boundary layer in meters (m).

## Details

The mechanical internal boundary layer (MIBL) is a concept used in
meteorology to describe the layer of air that develops after a change in
surface roughness. The height of the MIBL is important for understanding
the vertical distribution of wind speed and other meteorological
variables.

The function uses the formula: \$\$height = 0.43 \sqrt{dist}\$\$ where
\\dist\\ is the distance to the point of roughness change in meters.

## References

Bendix, J. (2004). Weather and Climate: An Introduction. Springer.

## Examples

``` r
# Calculate the average height of the MIBL for a distance of 100 meters
bound_mech_avg(100)
#> [1] 4.3
```
