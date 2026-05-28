# Diffused Outgoing Radiation

Calculates the reflected diffused incoming radiation.

## Usage

``` r
rad_diffuse_out(...)

# Default S3 method
rad_diffuse_out(
  datetime,
  lon,
  lat,
  elev,
  temp,
  slope,
  exposition,
  valley,
  surface_type,
  ...
)

# S3 method for class 'weather_station'
rad_diffuse_out(weather_station, ...)
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

- valley:

  Is the position in a valley (`TRUE`) or on a slope (`FALSE`)?

- surface_type:

  Surface type. Allowed values are: field, acre, lawn, street,
  agriculture, settlement, coniferous forest, deciduous forest, mixed
  forest, city, water, shrub. EXCEPTION: for functions related to
  Priestley-Taylor methods, allowed values are: field, bare soil,
  coniferous forest, water, wetland, spruce forest.

- weather_station:

  Object of class `weather_station`.

## Value

Reflected diffused incoming radiation in W/m².

## Details

The reflected diffused incoming radiation (\\D\_{out}\\) is calculated
using the formula: \$\$D\_{out} = D\_{in} \cdot \alpha\$\$ where:
\\D\_{in}\\ is the diffused incoming radiation, \\\alpha\\ is the albedo
of the surface.

## References

Bendix 2004, p. 45 eq. 3.1.

## Examples

``` r
# Calculate reflected diffused incoming radiation
rad_diffuse_out(datetime = Sys.time(), lon = 10, lat = 50, elev = 100, temp = 15,
                slope = 5, exposition = 180, valley = FALSE, surface_type = "lawn")
#> Error in datetime[i]$mon: $ operator is invalid for atomic vectors
```
