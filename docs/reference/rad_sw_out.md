# Shortwave Outgoing Radiation

Calculates the reflected shortwave incoming radiation.

## Usage

``` r
rad_sw_out(...)

# Default S3 method
rad_sw_out(
  datetime,
  lon,
  lat,
  elev,
  temp,
  slope,
  exposition,
  surface_type,
  ...
)

# S3 method for class 'weather_station'
rad_sw_out(weather_station, ...)
```

## Arguments

- ...:

  Named station fields, site parameters or model assumptions.

- datetime:

  POSIXlt or POSIXct date-time vector.

- lon:

  Longitude in degrees.

- lat:

  Latitude in degrees.

- elev:

  Elevation above sea level in m.

- temp:

  Air temperature in degrees C.

- slope:

  Slope in degrees.

- exposition:

  Exposition or aspect in degrees.

- surface_type:

  Surface-type label.

- weather_station:

  A weather_station object.

## Value

Reflected shortwave incoming radiation in W/m².

## Details

The reflected shortwave incoming radiation (\\SW\_{out}\\) is calculated
using the formula: \$\$SW\_{out} = SW\_{in} \cdot \alpha\$\$ where:
\\SW\_{in}\\ is the shortwave incoming radiation, \\\alpha\\ is the
albedo of the surface.

## References

Bendix 2004, p. 45 eq. 3.1.

## Examples

``` r
# Calculate reflected shortwave incoming radiation
example_time <- as.POSIXlt("2023-08-06 12:00:00", tz = "UTC")
rad_sw_out(datetime = example_time, lon = 10, lat = 50, elev = 100, temp = 15,
           slope = 5, exposition = 180, surface_type = "lawn")
#> [1] 178.7765
```
