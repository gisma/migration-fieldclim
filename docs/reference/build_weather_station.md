# Build a weather station object

Creates a list of class `weather_station` from named input arguments.

## Usage

``` r
build_weather_station(...)
```

## Arguments

- ...:

  Named station fields, site parameters or model assumptions.

## Value

A list of class `weather_station`.

## Details

The function stores all named arguments exactly as provided. It does not
calculate physical quantities and it does not validate whether all
fields are sufficient for later methods. Downstream functions such as
radiation, soil-heat or turbulent-flux functions check whether the
fields they need are available.

The object is therefore a structured container for station data, site
metadata, measurement heights and model assumptions.

Common field names used by `fieldClim` methods include:

- `datetime`: datetime vector, preferably with explicit timezone
  information.

- `lon`: longitude in degrees.

- `lat`: latitude in degrees.

- `elev`: elevation above sea level in m.

- `temp`: air temperature in degrees C.

- `rh`: relative humidity in percent.

- `t1`: air temperature at lower measurement height in degrees C.

- `t2`: air temperature at upper measurement height in degrees C.

- `hum1`: relative humidity at lower measurement height in percent.

- `hum2`: relative humidity at upper measurement height in percent.

- `v1`: wind speed at lower measurement height in m s-1.

- `v2`: wind speed at upper measurement height in m s-1.

- `z1`: lower measurement height in m.

- `z2`: upper measurement height in m.

- `rad_bal`: net radiation / radiation balance in W m-2.

- `soil_flux`: soil heat flux in W m-2.

- `surface_type`: surface-type label used by surface-dependent methods.

- `surface_temp`: surface temperature in degrees C.

- `moisture`: soil moisture in m3 m-3.

- `texture`: soil texture label.

- `soil_temp1`: soil temperature at first soil depth in degrees C.

- `soil_temp2`: soil temperature at second soil depth in degrees C.

- `soil_depth1`: first soil measurement depth in m.

- `soil_depth2`: second soil measurement depth in m.

- `slope`: slope in degrees.

- `exposition`: exposition / aspect in degrees.

- `valley`: logical value indicating valley position.

- `obs_height`: observation or obstacle height in m, depending on
  method.

These names are conventions used by other `fieldClim` methods. Unknown
names are still stored in the object, but they are ignored by methods
that do not request them.
