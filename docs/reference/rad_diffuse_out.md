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

- valley:

  Logical value indicating whether the station is in a valley.

- surface_type:

  Surface-type label.

- weather_station:

  A weather_station object.

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
example_time <- as.POSIXlt("2023-08-06 12:00:00", tz = "UTC")
rad_diffuse_out(datetime = example_time, lon = 10, lat = 50, elev = 100, temp = 15,
                slope = 5, exposition = 180, valley = FALSE, surface_type = "lawn")
#> [1] 31.5791
```
