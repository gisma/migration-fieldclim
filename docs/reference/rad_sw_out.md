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

  Additional arguments.

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

- weather_station:

  Object of class `weather_station`.

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
rad_sw_out(datetime = Sys.time(), lon = 10, lat = 50, elev = 100, temp = 15,
           slope = 5, exposition = 180, surface_type = "lawn")
#> Error in datetime$hour: $ operator is invalid for atomic vectors
```
