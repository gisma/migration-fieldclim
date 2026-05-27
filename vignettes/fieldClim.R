## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>"
)


## -----------------------------------------------------------------------------
library(fieldClim)
ws <- get(data(weather_station_example_data, package = "fieldClim"))

colnames(ws)


## -----------------------------------------------------------------------------
# Check datetime class
class(ws$datetime)

# Looks good! However just to demonstrate here's how to convert to POSIXt:
wrong_type <- as.character(ws$datetime)
class(wrong_type)

# convert with
ws$datetime <- strptime(wrong_type, format = "%Y-%m-%d %H:%M:%S")
# or
ws$datetime <- as.POSIXlt(wrong_type)



## -----------------------------------------------------------------------------
# Check if any remaining classes are not numeric
colnames(Filter(Negate(is.numeric), ws))



## -----------------------------------------------------------------------------
test_station <- build_weather_station(lat = 50.840503,
                                      lon = 8.6833,
                                      elev = 270,
                                      surface_type = "field",
                                      obs_height = 0.3, # obstacle height
                                      z1 = 2, # measurement heights
                                      z2 = 10,
                                      datetime = ws$datetime,
                                      t1 = ws$t1, # temperature
                                      t2 = ws$t2,
                                      v1 = ws$v1, # windspeed
                                      v2 = ws$v2,
                                      hum1 = ws$hum1, # humidity
                                      hum2 = ws$hum2,
                                      sw_in = ws$rad_sw_in, # shortwave radiation
                                      sw_out = ws$rad_sw_out,
                                      lw_in = ws$rad_lw_in, # longwave radiation
                                      lw_out = ws$rad_lw_out,
                                      soil_flux = ws$heatflux_soil)

# We can see that this is indeed a weather_station object.
class(test_station)


## -----------------------------------------------------------------------------
test_station <- build_weather_station(lat = 50.840503,
                                      lon = 8.6833,
                                      elev = 270,
                                      surface_type = "field",
                                      obs_height = 0.3,
                                      z1 = 2,
                                      z2 = 10,
                                      datetime = ws$datetime,
                                      t1 = ws$t1,
                                      t2 = ws$t2,
                                      v1 = ws$v1,
                                      v2 = ws$v2,
                                      hum1 = ws$hum1,
                                      hum2 = ws$hum2,
                                      sw_in = ws$rad_sw_in,
                                      sw_out = ws$rad_sw_out,
                                      lw_in = ws$rad_lw_in,
                                      lw_out = ws$rad_lw_out,
                                      soil_flux = ws$heatflux_soil,
                                      # ADDED PRESSURE
                                      p1 = ws$p1,
                                      p2 = ws$p2)


## -----------------------------------------------------------------------------
test_station <- build_weather_station(lat = 50.840503,
                                      lon = 8.6833,
                                      elev = 270,
                                      surface_type = "field",
                                      obs_height = 0.3,
                                      z1 = 2,
                                      z2 = 10,
                                      datetime = ws$datetime,
                                      t1 = ws$t1,
                                      t2 = ws$t2,
                                      v1 = ws$v1,
                                      v2 = ws$v2,
                                      hum1 = ws$hum1,
                                      hum2 = ws$hum2,
                                      sw_in = ws$rad_sw_in,
                                      sw_out = ws$rad_sw_out,
                                      lw_in = ws$rad_lw_in,
                                      lw_out = ws$rad_lw_out,
                                      # Alternative Soil flux:
                                      depth1 = 0,
                                      depth2 = 0.3,
                                      ts1 = ws$t_surface,
                                      ts2 = ws$ts1,
                                      moisture = ws$water_vol_soil,
                                      texture = "clay")


## -----------------------------------------------------------------------------
test_station <- build_weather_station(lat = 50.840503,
                                      lon = 8.6833,
                                      elev = 270,
                                      surface_type = "field",
                                      obs_height = 0.3,
                                      z1 = 2,
                                      z2 = 10,
                                      datetime = ws$datetime,
                                      t1 = ws$t1,
                                      t2 = ws$t2,
                                      v1 = ws$v1,
                                      v2 = ws$v2,
                                      hum1 = ws$hum1,
                                      hum2 = ws$hum2,
                                      lw_in = ws$rad_lw_in,
                                      lw_out = ws$rad_lw_out,
                                      soil_flux = ws$heatflux_soil,
                                      # Alternative shortwave radiation:
                                      # Topographic correction
                                      slope = 10, # In degrees
                                      exposition = 20, # North = 0, South = 180
                                      sky_view = 0.82 # Sky view factor (0-1)
                                      )


## -----------------------------------------------------------------------------
test_station <- build_weather_station(lat = 50.840503,
                                      lon = 8.6833,
                                      elev = 270,
                                      surface_type = "field",
                                      obs_height = 0.3,
                                      z1 = 2,
                                      z2 = 10,
                                      datetime = ws$datetime,
                                      t1 = ws$t1,
                                      t2 = ws$t2,
                                      v1 = ws$v1,
                                      v2 = ws$v2,
                                      hum1 = ws$hum1,
                                      hum2 = ws$hum2,
                                      sw_in = ws$rad_sw_in,
                                      sw_out = ws$rad_sw_out,
                                      soil_flux = ws$heatflux_soil,
                                      # Alternative longwave radiation:
                                      t_surface = ws$t_surface,
                                      # Different emissivity:
                                      # lw_out = rad_lw_out(ws$t_surface, emissivity_surface = 0.92),
                                      # Topographic correction
                                      sky_view = 0.82 # Sky view factor (0-1)
                                      )


## -----------------------------------------------------------------------------
grad_rich_manual <- turb_flux_grad_rich_no(t1 = ws$t1,
                                           t2 = ws$t2,
                                           z1 = 2,
                                           z2 = 10,
                                           v1 = ws$v1,
                                           v2 = ws$v2,
                                           p1 = pres_p(270+2, ws$t1),
                                           p2 = pres_p(270+10, ws$t2))

head(grad_rich_manual)


## -----------------------------------------------------------------------------
grad_rich_quick <- turb_flux_grad_rich_no(test_station)

head(grad_rich_quick)


## -----------------------------------------------------------------------------
station_turbulent <- turb_flux_calc(test_station)

names(station_turbulent$measurements)


## -----------------------------------------------------------------------------

normal <- as.data.frame(station_turbulent)
colnames(normal)

reduced <- as.data.frame(station_turbulent, reduced = T)
colnames(reduced)

unit <- as.data.frame(station_turbulent, reduced = T, unit = T)
colnames(unit)


