# Terrain Angle

Calculates the angle between the terrain slope and the incoming solar
radiation.

## Usage

``` r
terr_terrain_angle(...)

# Default S3 method
terr_terrain_angle(datetime, lon, lat, slope, exposition, ...)

# S3 method for class 'weather_station'
terr_terrain_angle(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments passed to other methods.

- datetime:

  POSIXlt or POSIXct object representing the date and time.

- lon:

  Longitude in decimal degrees.

- lat:

  Latitude in decimal degrees.

- slope:

  Slope of the terrain in degrees.

- exposition:

  Exposition of the slope in degrees (direction the slope faces).

- weather_station:

  Object of class `weather_station`.

## Value

Angle in degrees between the terrain slope and the incoming solar
radiation.

## Details

The terrain angle (\\\theta_t\\) is calculated as: \$\$\theta_t =
\arccos\left(\cos(\theta_s) \cdot \sin(\alpha) + \sin(\theta_s) \cdot
\cos(\alpha) \cdot \cos(\phi - \beta)\right)\$\$ where: \\\theta_s\\ is
the slope angle, \\\alpha\\ is the solar elevation angle, \\\phi\\ is
the solar azimuth angle, and \\\beta\\ is the slope exposition angle.

## References

Bendix 2004, p. 52 eq. 3.7.

## Examples

``` r
# Calculate terrain angle for a given datetime, location, and slope
datetime <- as.POSIXlt("2023-08-06 12:00:00", tz = "UTC")
terr_terrain_angle(datetime, lon = 8.6841, lat = 50.1109, slope = 30, exposition = 90)
#> [1] 44.80026
```
