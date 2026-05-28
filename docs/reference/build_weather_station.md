# Build a weather station object

Creates a list of class `weather_station` that contains all input
arguments.

## Usage

``` r
build_weather_station(...)
```

## Arguments

- ...:

  Arguments passed on to
  [`rad_sw_toa.default`](https://gisma.github.io/migration-fieldclim/reference/rad_sw_toa.md),
  [`pres_p.default`](https://gisma.github.io/migration-fieldclim/reference/pres_p.md),
  [`trans_ozone.default`](https://gisma.github.io/migration-fieldclim/reference/trans_ozone.md),
  [`trans_aerosol.default`](https://gisma.github.io/migration-fieldclim/reference/trans_aerosol.md),
  [`pres_sat_vapor_p.default`](https://gisma.github.io/migration-fieldclim/reference/pres_sat_vapor_p.md),
  [`rad_lw_in.default`](https://gisma.github.io/migration-fieldclim/reference/rad_lw_in.md)

  `sol_const`

  :   Solar radiation constant in W/m², default is 1361.

  `p0`

  :   Standard pressure in hPa, default 1013.25.

  `g`

  :   Gravitational acceleration in \\m \cdot s^{-2}\\, default 9.81.

  `rl`

  :   Specific gas constant for air in \\m^2 \cdot s^{-2} \cdot
      K^{-1}\\, default 287.05.

  `ozone_column`

  :   Atmospheric ozone as column in cm, default `ozone_column_default`.

  `vis`

  :   Visibility in km, default `vis_default`.

  `a`

  :   Constant a, default is 7.5 over water.

  `b`

  :   Constant b, default is 235 over water.

- weather_station:

  Object of class `weather_station`.

- datetime:

  Datetime of class `POSIXlt`. See
  [`base::as.POSIXlt()`](https://rdrr.io/r/base/as.POSIXlt.html). Make
  sure to provide the correct timezone information!

- lon:

  Longitude in degree.

- lat:

  Latitude in degree.

- elev:

  Elevation above sea level in m.

- temp:

  Air temperature in degree Celcius.

- t1:

  Air temperature at lower height in degree Celcius.

- t2:

  Air temperature at upper height in degree Celcius.

- v1:

  Windspeed at lower height (e.g. height of anemometer) in m/s.

- v2:

  Windspeed at upper height in m/s.

- slope:

  Slope in degree.

- exposition:

  Exposition in degree.

- surface_type:

  Surface type. Allowed values are: field, acre, lawn, street,
  agriculture, settlement, coniferous forest, deciduous forest, mixed
  forest, city, water, shrub. EXCEPTION: for functions related to
  Priestley-Taylor methods, allowed values are: field, bare soil,
  coniferous forest, water, wetland, spruce forest.

- obs_height:

  Height of obstacle in m.

- valley:

  Is the position in a valley (`TRUE`) or on a slope (`FALSE`)?

- surface_temp:

  Surface temperature in degree Celcius.

- rh:

  Relative humidity in %.

- hum1:

  Relative humidity at lower height in %.

- hum2:

  Relative humidity at upper height in %.

- rad_bal:

  Radiation balance in W/m\\^2\\.

- texture:

  Soil texture. Either "sand", "clay", or "peat".

- moisture:

  Soil moisture in cubic meter/cubic meter.

- soil_flux:

  Soil flux in W/m\\^2\\.

- soil_temp1:

  Soil temperature in degree Celcius of measurement 1.

- soil_temp2:

  Soil temperature in degree Celcius of measurement 2.

- soil_depth1:

  Depth of the soil temperature measurement 1 in m.

- soil_depth2:

  Depth of the soil temperature measurement 2 in m.

## Details

Provided input arguments will only be used if they are listed in the
section "Arguments". No warning message is generated for unused
arguments.
