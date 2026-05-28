# Total Radiation Balance

Calculates the total radiation balance by summing the shortwave and
longwave radiation balances.

## Usage

``` r
rad_bal(...)

# Default S3 method
rad_bal(
  datetime,
  lon,
  lat,
  elev,
  temp,
  rh,
  slope,
  exposition,
  valley,
  surface_type,
  surface_temp,
  ...
)

# S3 method for class 'weather_station'
rad_bal(weather_station, ...)
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

- rh:

  Relative humidity in %.

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

- surface_temp:

  Surface temperature in degree Celcius.

- weather_station:

  Object of class `weather_station`.

## Value

Total radiation balance in W/m².

## Details

The total radiation balance (\\R\_{total}\\) is calculated as:
\$\$R\_{total} = R\_{sw} + R\_{lw}\$\$ where: \\R\_{sw}\\ is the
shortwave radiation balance, \\R\_{lw}\\ is the longwave radiation
balance.

## References

Bendix 2004, p. 45 eq. 3.1.

## Examples

``` r
# Calculate total radiation balance
rad_bal(datetime = Sys.time(), lon = 10, lat = 50, elev = 100, temp = 15, rh = 60,
        slope = 5, exposition = 180, valley = FALSE, surface_type = "lawn", surface_temp = 15)
#> Error in datetime$hour: $ operator is invalid for atomic vectors
```
