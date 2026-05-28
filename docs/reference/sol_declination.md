# Solar declination

Solar declination

## Usage

``` r
sol_declination(...)

# Default S3 method
sol_declination(datetime, ...)

# S3 method for class 'weather_station'
sol_declination(weather_station, ...)
```

## Arguments

- ...:

  Named station fields, site parameters or model assumptions.

- datetime:

  POSIXlt or POSIXct date-time vector.

- weather_station:

  A weather_station object.

## Value

Degree.

## Details

The solar declination (\\\delta\\) is the angle between the rays of the
sun and the plane of the Earth's equator. It is calculated as:
\$\$\delta = \arcsin(\sin(23.44^\circ) \cdot \sin(L))\$\$ where: \\L\\
is the ecliptic longitude.

## References

Bendix 2004, p. 243.

## Examples

``` r
# Calculate solar declination
sol_declination(as.POSIXlt("2022-06-21"))
#> [1] 23.43806
```
