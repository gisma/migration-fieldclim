physics_standard_datetime <- function(n = 2) {
  as.POSIXct(
    "2017-06-30 12:00:00",
    tz = "Europe/Berlin"
  ) + seq_len(n) * 300
}

physics_minimal_pt_station <- function() {
  build_weather_station(
    temp = c(22, 21),
    rad_bal = c(500, -80),
    soil_flux = c(50, 20),
    surface_type = "field"
  )
}

physics_standard_weather_station <- function() {
  build_weather_station(
    datetime = physics_standard_datetime(2),
    lon = 8.6832,
    lat = 50.8405,
    elev = 261,
    temp = c(22, 21),
    rh = c(55, 60),
    t1 = c(22.4, 21.8),
    t2 = c(21.2, 20.7),
    hum1 = c(60, 62),
    hum2 = c(55, 58),
    v1 = c(2, 2.5),
    v2 = c(4, 4.5),
    z1 = 2,
    z2 = 10,
    rad_bal = c(500, 450),
    soil_flux = c(50, 40),
    obs_height = 2,
    surface_type = "field"
  )
}
