# Turbulent impulse exchange

Calculation of the turbulent impulse exchange.

## Usage

``` r
turb_flux_imp_exchange(...)

# Default S3 method
turb_flux_imp_exchange(
  t1,
  t2,
  v1,
  v2,
  z1 = 2,
  z2 = 10,
  elev,
  surface_type = NULL,
  obs_height = NULL,
  ...
)

# S3 method for class 'weather_station'
turb_flux_imp_exchange(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- t1:

  Temperature at lower height (e.g. height of anemometer) in °C.

- t2:

  Temperature at upper height in degrees C.

- v1:

  Windspeed at lower height (e.g. height of anemometer) in m/s.

- v2:

  Windspeed at upper height in m/s.

- z1:

  Lower height of measurement (e.g. height of anemometer) in m.

- z2:

  Upper height of measurement in m.

- elev:

  Elevation above sea level in m.

- surface_type:

  Type of surface. Options: r surface_properties\$surface_type

- obs_height:

  Height of obstacle in meters (m).

- weather_station:

  Object of class weather_station

## Value

Turbulent impulse exchange in kg/(m\*s\\^2\\).
