# Precipitable water

Selects reference temperature and pressure based on location and season.
Then calculates precipitable water.

## Usage

``` r
hum_precipitable_water(...)

# Default S3 method
hum_precipitable_water(datetime, lat, elev, temp, ...)

# S3 method for class 'weather_station'
hum_precipitable_water(weather_station, ...)
```

## Arguments

- ...:

  Arguments passed on to
  [`pres_p.default`](https://gisma.github.io/migration-fieldclim/reference/pres_p.md)

  `g`

  :   Gravitational acceleration in \\m \cdot s^{-2}\\, default 9.81.

  `rl`

  :   Specific gas constant for air in \\m^2 \cdot s^{-2} \cdot
      K^{-1}\\, default 287.05.

- datetime:

  POSIXlt or POSIXct date-time vector.

- lat:

  Latitude in degrees.

- elev:

  Elevation above sea level in m.

- temp:

  Air temperature in degrees C.

- weather_station:

  A weather_station object.

## Value

Numeric. Precipitable water in cm·grams.

## Details

Latitude \<= 30 degrees is defined as tropic; \<= 60 is temperate;
others is subarctic. Summer is defined as April to September in the
northern hemisphere.

Precipitable water (\\PW\\) is the total amount of water vapor in a
column of air from the surface to the top of the atmosphere. It is
calculated using reference temperature and pressure values based on
location and season.

## References

Bendix 2004, p. 246.

## Examples

``` r
# Calculate precipitable water
hum_precipitable_water(datetime = as.POSIXlt("2022-07-15"), lat = 50, elev = 100, temp = 20)
#> [1] 11.08199
```
