# Longwave Radiation Balance

Calculates the sum of longwave incoming and outgoing radiation.

## Usage

``` r
rad_lw_bal(...)

# Default S3 method
rad_lw_bal(temp, rh, slope, valley, surface_type, surface_temp, ...)

# S3 method for class 'weather_station'
rad_lw_bal(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- temp:

  Air temperature in degree Celcius.

- rh:

  Relative humidity in %.

- slope:

  Slope in degree.

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

Longwave radiation balance in W/m².

## Details

The longwave radiation balance (\\R\_{lw}\\) is calculated as:
\$\$R\_{lw} = LW\_{in} - LW\_{out}\$\$ where: \\LW\_{in}\\ is the
longwave incoming radiation, \\LW\_{out}\\ is the longwave outgoing
radiation.

## References

Bendix 2004, p. 68. eq. 3.25.

## Examples

``` r
# Calculate longwave radiation balance
rad_lw_bal(temp = 15, rh = 60, slope = 5, valley = FALSE, surface_type = "lawn", surface_temp = 15)
#> [1] -121.2849
```
