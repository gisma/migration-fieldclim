# Monin-Obhukov-Length

Calculation of the Monin-Obhukov-Length. The calculation depends on the
stability of the atmosphere. This value will be taken from the
Gradient-Richardson-Number.

## Usage

``` r
turb_flux_monin(...)

# Default S3 method
turb_flux_monin(
  z1 = 2,
  z2 = 10,
  v1,
  v2,
  t1,
  t2,
  elev,
  surface_type = NULL,
  obs_height = NULL,
  ...
)

# S3 method for class 'weather_station'
turb_flux_monin(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- z1:

  Lower height of measurement (e.g. height of anemometer) in m.

- z2:

  Upper height of measurement in m.

- v1:

  Windspeed at lower height (e.g. height of anemometer) in m/s.

- v2:

  Windspeed at upper height in m/s.

- t1:

  Temperature at lower height (e.g. height of anemometer) in °C.

- t2:

  Temperature at upper height in °C.

- elev:

  Elevation above sea level in m.

- surface_type:

  Type of surface. Options: r surface_properties\$surface_type

- obs_height:

  Height of obstacle in meters (m).

- weather_station:

  Object of class weather_station

## Value

Monin-Obhukov-Length in m.

## References

Bendix 2004, p. 241
