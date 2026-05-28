# Latent Heat Penman-Monteith Method

Calculates the latent heat flux using the Penman-Monteith equation.
Positive latent heat flux signifies flux away from the surface. Negative
latent heat flux indicates flux toward the surface or a
condensation-like direction, depending on context.

## Usage

``` r
latent_penman(...)

# Default S3 method
latent_penman(
  datetime,
  v,
  temp,
  rh,
  z = 2,
  rad_bal,
  elev,
  lat,
  lon,
  soil_flux,
  obs_height,
  surface_type,
  ...
)

# S3 method for class 'weather_station'
latent_penman(weather_station, ...)
```

## Arguments

- ...:

  Additional arguments.

- datetime:

  POSIXt object (POSIXct, POSIXlt). See
  [base::as.POSIXlt](https://rdrr.io/r/base/as.POSIXlt.html) and
  [base::strptime](https://rdrr.io/r/base/strptime.html) for conversion.

- v:

  Wind velocity in m/s.

- temp:

  Air temperature in degrees C.

- rh:

  Relative humidity in %.

- z:

  Height of measurement for temperature and wind speed in m.

- rad_bal:

  Net radiation balance in W m-2.

- elev:

  Elevation above sea level in m.

- lat:

  Latitude in decimal degrees.

- lon:

  Longitude in decimal degrees.

- soil_flux:

  Soil heat flux in W m-2.

- obs_height:

  Observation height in m. Used for calculating aerodynamic resistance.

- surface_type:

  Surface type for determining surface resistance. Options: \`r
  surface_resistance\$surface_type“.

- weather_station:

  A weather_station object.

## Value

Latent heat flux in W m-2.

## Details

The latent heat flux (\\Q_e\\) using the Penman-Monteith method is
calculated as: \$\$Q_e = \frac{\Delta (R_n - G) + \gamma \frac{c_p
\rho}{r_a} (e_s - e_a)}{\Delta + \gamma (1 + \frac{r_s}{r_a})}\$\$
where: \\\Delta\\ is the slope of the saturation vapor pressure curve,
\\\gamma\\ is the psychrometric constant, \\R_n\\ is the net radiation,
\\G\\ is the soil heat flux, \\c_p\\ is the specific heat of air,
\\\rho\\ is the air density, \\r_a\\ is the aerodynamic resistance,
\\r_s\\ is the surface resistance, \\e_s\\ is the saturation vapor
pressure, and \\e_a\\ is the actual vapor pressure.

[`pres_sat_vapor_p()`](https://gisma.github.io/migration-fieldclim/reference/pres_sat_vapor_p.md)
and
[`pres_vapor_p()`](https://gisma.github.io/migration-fieldclim/reference/pres_vapor_p.md)
return pressure in hPa. `latent_penman()` converts \\e_s\\ and \\e_a\\
internally to kPa before computing the aerodynamic
vapour-pressure-deficit term. \\\Delta\\ and \\\gamma\\ are handled on
the same kPa scale.

The aerodynamic resistance (\\r_a\\) is calculated based on wind speed,
observation height, and surface roughness. The surface resistance
(\\r_s\\) is selected based on the specified surface type.

**Available Surface Types:**

- Temperate grassland

- Coniferous forest

- Temperate deciduous forest

- Tropical rain forest

- Cereal crops

- Broadleaved herbaceous crops

`surface_type` may either be a Penman resistance class
(`Temperate grassland`, `Cereal crops`, ...), or a mapped fieldClim
surface class such as `field`, `lawn`, `agriculture`,
`coniferous forest`, `deciduous forest`, `mixed forest`, or `shrub`. For
example, `field` is mapped to `Temperate grassland`.

## References

Monteith, John L., Mike H. Unsworth, and Ann Webb. "Principles of
environmental physics." Quarterly Journal of the Royal Meteorological
Society 120.520 (1994): 1699.

## Examples

``` r
# Calculate latent heat flux using the Penman-Monteith method
datetime <- as.POSIXlt("2022-07-15 12:00:00")
latent_penman(
  datetime = datetime, v = 2, temp = 25, rh = 60, z = 2, rad_bal = 200,
  elev = 100, lat = 50, lon = 8, soil_flux = 50, obs_height = 10, surface_type = "Temperate grassland"
)
#> Warning: latent_penman: invalid aerodynamic resistance for some values; returning NA there.
#> [1] NA
```
