# Moisture gradient

Calculates moisture gradient.

## Usage

``` r
hum_moisture_gradient(...)

# Default S3 method
hum_moisture_gradient(hum1, hum2, t1, t2, z1 = 2, z2 = 10, elev, ...)

# S3 method for class 'weather_station'
hum_moisture_gradient(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- hum1:

  Relative humidity at lower height in %.

- hum2:

  Relative humidity at upper height in %.

- t1:

  Air temperature at lower height in °C.

- t2:

  Air temperature at upper height in °C.

- z1:

  Lower measurement height in m.

- z2:

  Upper measurement height in m.

- elev:

  Elevation above sea level in m.

- weather_station:

  A weather_station object.

## Value

Numeric. Moisture gradient.

## Details

The moisture gradient is calculated as the difference in specific
humidity at two heights divided by the difference in heights: \$\$\Delta
q / \Delta z\$\$ where \\\Delta q\\ is the difference in specific
humidity and \\\Delta z\\ is the difference in heights.

## Examples

``` r
# Calculate moisture gradient
hum_moisture_gradient(hum1 = 80, hum2 = 60, t1 = 20, t2 = 15, z1 = 2, z2 = 10, elev = 100)
#> [1] -0.0006678021
```
