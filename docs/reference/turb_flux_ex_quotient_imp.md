# Exchange quotient for impulse transmission

Calculation of the exchange quotient of the turbulent impulse
transmission.

## Usage

``` r
turb_flux_ex_quotient_imp(...)

# Default S3 method
turb_flux_ex_quotient_imp(
  t1,
  t2,
  z1 = 2,
  z2 = 10,
  v1,
  v2,
  elev,
  surface_type = NULL,
  obs_height = NULL,
  ...
)

# S3 method for class 'weather_station'
turb_flux_ex_quotient_imp(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- t1:

  Temperature at lower height (e.g. height of anemometer) in °C.

- t2:

  Temperature at upper height in degrees C.

- z1:

  Lower height of measurement (e.g. height of anemometer) in m.

- z2:

  Upper height of measurement in m.

- v1:

  Windspeed at lower height (e.g. height of anemometer) in m/s.

- v2:

  Windspeed at upper height in m/s.

- elev:

  Elevation above sea level in m.

- surface_type:

  Type of surface. Options: r surface_properties\$surface_type

- obs_height:

  Height of obstacle in meters (m).

- weather_station:

  Object of class weather_station

## Value

Exchange quotient for impulse transmission in kg/(m\*s).

## References

Foken 2016, p. 361: Businger.
