# Specific humidity

Calculates specific humidity from vapor pressure and air pressure.

## Usage

``` r
hum_specific(...)

# Default S3 method
hum_specific(rh, temp, elev, ...)

# S3 method for class 'weather_station'
hum_specific(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- rh:

  Relative humidity in %.

- temp:

  Temperature in °C.

- elev:

  Elevation above sea level in m.

- weather_station:

  Object of class `weather_station`.

## Value

Numeric. Specific humidity in kg/kg.

## Details

Specific humidity (\\q\\) is the ratio of the mass of water vapor to the
total mass of the air parcel. It is calculated from the vapor pressure
and air pressure using the formula: \$\$q = 0.622 \times
\frac{pvapor}{p}\$\$ where \\pvapor\\ is the vapor pressure and \\p\\ is
the air pressure.

## References

Bendix 2004, p. 262.

## Examples

``` r
# Calculate specific humidity
hum_specific(rh = 70, temp = 25, elev = 100)
#> [1] 0.01396975
```
