# fieldClim: Check radiation and soil heat flux

``` r

# load library
library(fieldClim)
```

## check .default methods

``` r

datetime <- as.POSIXlt("2018-02-19 13:15:00", tz = "CET")
lon = 8.683300
lat = 50.840503
elev = 270
temp = 20
rh = 50
slope = 30
exposition = 20
valley = FALSE
surface_type = "field"
surface_temp = 20
texture = "sand"
moisture = 0.2
soil_temp1 = 20
soil_temp2 = 30
soil_depth1 = 1
soil_depth2 = 0

# structure
#*1 means there are optional arguments
#*1.0 means there are optional arguments originated from this function

## soil
soil_heat_flux(texture, moisture, soil_temp1, soil_temp2, soil_depth1, soil_depth2)
```

    ## [1] 23.1

``` r

  soil_thermal_cond(texture, moisture)
```

    ## [1] 2.31

``` r

## rad
rad_bal(datetime, lon, lat, elev, temp, rh, slope, exposition, valley, surface_type, surface_temp)*1
```

    ## [1] 59.40838

``` r

  rad_sw_bal(datetime, lon, lat, elev, temp, slope, exposition, valley, surface_type)*1
```

    ## [1] 189.9542

``` r

    rad_sw_out(datetime, lon, lat, elev, temp, slope, exposition, surface_type)*1
```

    ## [1] 0

``` r

      rad_sw_in(datetime, lon, lat, elev, temp, slope, exposition)*1
```

    ## [1] 0

``` r

        rad_sw_toa(datetime, lon, lat)*1.0
```

    ## [1] 604.7787

``` r

          sol_eccentricity(datetime)
```

    ## [1] 1.024449

``` r

            sol_day_angle(datetime)
```

    ## [1] 48.32877

``` r

              sol_julian_day(datetime)
```

    ## [1] 50

``` r

          sol_elevation(datetime, lon, lat)
```

    ## [1] 25.70632

``` r

            sol_declination(datetime)
```

    ## [1] -11.48695

``` r

              sol_ecliptic_length(datetime)
```

    ## [1] 329.9583

``` r

                sol_medium_anomaly(datetime)
```

    ## [1] 405.88

``` r

            sol_hour_angle(datetime, lon)
```

    ## [1] 18.11096

``` r

              sol_medium_suntime(datetime, lon)
```

    ## [1] 12.82889

``` r

              sol_time_formula(datetime, lon)
```

    ## [1] -0.04260285

``` r

        trans_gas(datetime, lon, lat, elev, temp)*1
```

    ## [1] 0.9855827

``` r

          trans_air_mass_abs(datetime, lon, lat, elev, temp)*1
```

    ## [1] 1.674785

``` r

            trans_air_mass_rel(datetime, lon, lat)
```

    ## [1] 1.72834

``` r

            pres_p(elev, temp)*1
```

    ## [1] 981.8532

``` r

        trans_ozone(datetime, lon, lat)*1.0
```

    ## [1] 0.9763279

``` r

        trans_rayleigh(datetime, lon, lat, elev, temp)*1
```

    ## [1] 0.8710551

``` r

        trans_vapor(datetime, lon, lat, elev, temp)*1
```

    ## [1] 0.8618343

``` r

          hum_precipitable_water(datetime, lat, elev, temp)*1
```

    ## [1] 3.052573

``` r

        trans_aerosol(datetime, lon, lat, elev, temp)*1.0
```

    ## [1] 0.7476903

``` r

        terr_terrain_angle(datetime, lon, lat, slope, exposition)
```

    ## [1] 94.29345

``` r

          sol_azimuth(datetime, lon, lat)
```

    ## [1] 199.7607

``` r

    rad_diffuse_out(datetime, lon, lat, elev, temp, slope, exposition, valley, surface_type)*1
```

    ## [1] 47.48856

``` r

      rad_diffuse_in(datetime, lon, lat, elev, temp, slope, exposition, valley)*1
```

    ## [1] 237.4428

``` r

        terr_sky_view(slope, valley)
```

    ## [1] 0.9330127

``` r

  rad_lw_bal(temp, rh, slope, valley, surface_type, surface_temp)*1
```

    ## [1] -130.5458

``` r

    rad_lw_in(temp, rh, slope, valley)*1.0
```

    ## [1] 254.7205

``` r

      rad_emissivity_air(temp, rh)*1
```

    ## [1] 0.6519332

``` r

        pres_vapor_p(temp, rh)*1
```

    ## [1] 11.83287

``` r

          pres_sat_vapor_p(temp)*1.0
```

    ## [1] 23.66574

``` r

    rad_lw_out(surface_type, surface_temp)*1.0
```

    ## [1] 385.2664

## prepare 1 day of data

``` r

# Metadata: inst/302_caldernklimawiese_complete_meta.xml
# Packaged five-minute teaching day extracted from the Caldern dataset.
input_day <- read.csv(caldern_path, na.strings = c("NA", "NULL"))
input_day <- input_day[!is.na(input_day$datetime) &
                         input_day$datetime >= "2017-06-30 00:00:00" &
                         input_day$datetime <= "2017-06-30 23:55:00", ]
```

## check .weather_station method with 3 day values and 3 night values

``` r

# use selected complete day
input <- input_day

# Interpret timestamps as local station time for Caldern, Germany.
input$datetime <- as.POSIXlt(input$datetime, format = "%Y-%m-%d %H:%M:%S", tz = "Europe/Berlin")

# 3 day values and 3 night values
input <- input[c(1:3, 133:135), ]

# build_weather_station
weather_station <- build_weather_station(
  datetime = input$datetime,
  lon = 8.6832,
  lat = 50.8405,
  elev = 261,
  temp = input$Ta_2m,
  slope = 0,
  exposition = 0,
  valley = FALSE,
  surface_type = "field",
  surface_temp = input$Ta_2m,
  rh = input$Huma_2m,
  texture = "peat",
  moisture = input$water_vol_soil,
  soil_temp1 = input$Ts,
  soil_temp2 = input$Ta_2m,
  soil_depth1 = 0.25,
  soil_depth2 = 0
)

# show structure
str(weather_station)
```

    ## List of 17
    ##  $ datetime    : POSIXlt[1:6], format: "2017-06-30 00:00:00" "2017-06-30 00:05:00" ...
    ##  $ lon         : num 8.68
    ##  $ lat         : num 50.8
    ##  $ elev        : num 261
    ##  $ temp        : num [1:6] 13.1 13 13 18.6 19 ...
    ##  $ slope       : num 0
    ##  $ exposition  : num 0
    ##  $ valley      : logi FALSE
    ##  $ surface_type: chr "field"
    ##  $ surface_temp: num [1:6] 13.1 13 13 18.6 19 ...
    ##  $ rh          : num [1:6] 100 100 100 63 60.5 ...
    ##  $ texture     : chr "peat"
    ##  $ moisture    : num [1:6] 0.344 0.344 0.344 0.348 0.348 0.348
    ##  $ soil_temp1  : num [1:6] 16.3 16.3 16.2 17.8 17.8 ...
    ##  $ soil_temp2  : num [1:6] 13.1 13 13 18.6 19 ...
    ##  $ soil_depth1 : num 0.25
    ##  $ soil_depth2 : num 0
    ##  - attr(*, "class")= chr "weather_station"

``` r

# calculate
## soil
soil_heat_flux(weather_station)
```

    ## [1] -2.0881056 -2.1270144 -2.0945904  0.5281280  0.7591840  0.8516064

``` r

  soil_thermal_cond(weather_station)
```

    ## [1] 0.16212 0.16212 0.16212 0.16504 0.16504 0.16504

``` r

## rad
rad_bal(weather_station)
```

    ## [1] -92.14542 -92.22640 -92.21629 553.80198 555.21345 558.48442

``` r

  rad_sw_bal(weather_station)
```

    ## [1]   0.0000   0.0000   0.0000 658.2696 660.8652 663.1179

``` r

    rad_sw_out(weather_station)
```

    ## [1]   0.0000   0.0000   0.0000 137.0706 137.7178 138.2854

``` r

      rad_sw_in(weather_station)
```

    ## [1]   0.0000   0.0000   0.0000 685.3532 688.5891 691.4270

``` r

        rad_sw_toa(weather_station)
```

    ## [1]    0.000    0.000    0.000 1141.424 1145.400 1149.021

``` r

          sol_eccentricity(weather_station)
```

    ## [1] 0.9666303 0.9666303 0.9666303 0.9666303 0.9666303 0.9666303

``` r

            sol_day_angle(weather_station)
```

    ## [1] 177.5342 177.5342 177.5342 177.5342 177.5342 177.5342

``` r

              sol_julian_day(weather_station)
```

    ## [1] 181 181 181 181 181 181

``` r

          sol_elevation(weather_station)
```

    ## [1] -15.95104 -15.93532 -15.90315  60.18302  60.53307  60.85528

``` r

            sol_declination(weather_station)
```

    ## [1] 23.20675 23.20675 23.20675 23.20675 23.20675 23.20675

``` r

              sol_ecliptic_length(weather_station)
```

    ## [1] 457.8612 457.8612 457.8612 457.8612 457.8612 457.8612

``` r

                sol_medium_anomaly(weather_station)
```

    ## [1] 534.9936 534.9936 534.9936 534.9936 534.9936 534.9936

``` r

            sol_hour_angle(weather_station)
```

    ## [1] -179.43111 -178.18111 -176.93111  -14.43111  -13.18111  -11.93111

``` r

              sol_medium_suntime(weather_station)
```

    ## [1] 22.578880 22.662213 22.745547  9.578880  9.662213  9.745547

``` r

              sol_time_formula(weather_station)
```

    ## [1] 0.0379263 0.0379263 0.0379263 0.0379263 0.0379263 0.0379263

``` r

        trans_gas(weather_station)
```

    ## [1]       NaN       NaN       NaN 0.9872992 0.9873083 0.9873167

``` r

          trans_air_mass_abs(weather_station)
```

    ## [1]      NaN      NaN      NaN 1.025120 1.022253 1.019638

``` r

            trans_air_mass_rel(weather_station)
```

    ## [1]      NaN      NaN      NaN 1.056950 1.053949 1.051229

``` r

            pres_p(weather_station)
```

    ## [1] 982.1623 982.1537 982.1548 982.7353 982.7785 982.8001

``` r

        trans_ozone(weather_station)
```

    ## [1]       NaN       NaN       NaN 0.9830862 0.9831191 0.9831490

``` r

        trans_rayleigh(weather_station)
```

    ## [1]       NaN       NaN       NaN 0.9119427 0.9121377 0.9123158

``` r

        trans_vapor(weather_station)
```

    ## [1]       NaN       NaN       NaN 0.8378446 0.8382666 0.8385097

``` r

          hum_precipitable_water(weather_station)
```

    ## [1] 13.43360 13.47472 13.46956 11.29129 11.16609 11.10503

``` r

        trans_aerosol(weather_station)
```

    ## [1]       NaN       NaN       NaN 0.8303224 0.8307157 0.8310748

``` r

        terr_terrain_angle(weather_station)
```

    ## [1] 105.95104 105.93532 105.90315  29.81698  29.46693  29.14472

``` r

          sol_azimuth(weather_station)
```

    ## [1]   0.543802   1.738508   2.932716 152.570695 154.783288 157.036367

``` r

    rad_diffuse_out(weather_station)
```

    ## [1]  0.00000  0.00000  0.00000 27.49675 27.49847 27.49406

``` r

      rad_diffuse_in(weather_station)
```

    ## [1]   0.0000   0.0000   0.0000 137.4838 137.4924 137.4703

``` r

        terr_sky_view(weather_station)
```

    ## [1] 1

``` r

  rad_lw_bal(weather_station)
```

    ## [1]  -92.14542  -92.22640  -92.21629 -104.46759 -105.65171 -104.63344

``` r

    rad_lw_in(weather_station)
```

    ## [1] 258.0600 257.5876 257.6466 273.2326 274.2285 276.3403

``` r

      rad_emissivity_air(weather_station)
```

    ## [1] 0.6779312 0.6774474 0.6775079 0.6655385 0.6641310 0.6673244

``` r

        pres_vapor_p(weather_station)
```

    ## [1] 15.19176 15.11181 15.12178 13.60589 13.42505 13.89347

``` r

          pres_sat_vapor_p(weather_station)
```

    ## [1] 15.19176 15.11181 15.12178 21.60693 22.18650 22.48135

``` r

    rad_lw_out(weather_station)
```

    ## [1] 350.2054 349.8140 349.8629 377.7002 379.8802 380.9738

## check .weather_station method with data for 1 day

``` r

# use selected complete day
input <- input_day

# show structure
str(input)
```

    ## 'data.frame':    288 obs. of  19 variables:
    ##  $ record        : int  147 148 149 150 151 152 153 154 155 156 ...
    ##  $ datetime      : chr  "2017-06-30 00:00:00" "2017-06-30 00:05:00" "2017-06-30 00:10:00" "2017-06-30 00:15:00" ...
    ##  $ Ta_2m         : num  13.1 13 13 13.2 13.3 ...
    ##  $ Huma_2m       : num  100 100 100 100 100 98.1 98.3 99.4 99.9 99.3 ...
    ##  $ Ta_10m        : num  13.6 13.5 13.7 13.8 13.8 ...
    ##  $ Huma_10m      : num  97.6 97.7 96.5 96.1 96.4 92.4 92.6 94.6 95.6 94.3 ...
    ##  $ Windspeed_2m  : num  0.448 0.38 0.548 0.581 0.764 0.589 0.602 0.714 0.637 0.553 ...
    ##  $ Windspeed_10m : num  0.529 0.409 0.67 0.658 0.887 0.744 0.712 0.696 0.743 0.84 ...
    ##  $ rad_sw_in     : num  -0.902 -0.435 0.964 1.15 1.026 ...
    ##  $ rad_sw_out    : num  1.24 0.844 1.134 1.134 1.161 ...
    ##  $ RsNet         : num  -2.141 -1.279 -0.171 0.016 -0.135 ...
    ##  $ RlNet         : num  -13.06 -7.64 -1.79 -1.81 -2.33 ...
    ##  $ rad_net       : num  -15.2 -8.92 -1.97 -1.79 -2.47 ...
    ##  $ LUpCo         : num  362 367 374 376 377 ...
    ##  $ LDnCo         : num  375 375 376 378 379 ...
    ##  $ water_vol_soil: num  0.344 0.344 0.344 0.344 0.344 0.344 0.344 0.344 0.344 0.344 ...
    ##  $ Ts            : num  16.3 16.3 16.2 16.2 16.2 ...
    ##  $ heatflux_soil : num  1.55 1.49 1.45 1.39 1.33 ...
    ##  $ PCP           : logi  NA NA NA NA NA NA ...

``` r

# Interpret timestamps as local station time for Caldern, Germany.
input$datetime <- as.POSIXlt(input$datetime, format = "%Y-%m-%d %H:%M:%S", tz = "Europe/Berlin")

# build_weather_station
weather_station <- build_weather_station(
  datetime = input$datetime,
  lon = 8.6832,
  lat = 50.8405,
  elev = 261,
  temp = input$Ta_2m,
  slope = 0,
  exposition = 0,
  valley = FALSE,
  surface_type = "field",
  surface_temp = input$Ta_2m,
  rh = input$Huma_2m,
  texture = "peat",
  moisture = input$water_vol_soil,
  soil_temp1 = input$Ts,
  soil_temp2 = input$Ta_2m,
  soil_depth1 = 0.25,
  soil_depth2 = 0
)
```

### A function for plotting

``` r

plotme <- function(topic, calculated, measured, legend_position) {
  values_combined <- c(calculated, measured)
  plot(
    calculated,
    xlab = "Day of year", ylab = "W/m2", main = topic,
    ylim = c(min(values_combined), max(values_combined))
  )
  lines(measured)
  legend(
    legend_position,
    c("calculated", "measured"),
    pch = c(1, NA),
    lty = c(0, 1)
  )
}
```

### Shortwave incoming

``` r

topic <- "Shortwave incoming"
calculated <- rad_sw_in(weather_station) + rad_diffuse_in(weather_station)
measured <- input$rad_sw_in
legend_position <- "topright"
plotme(topic, calculated, measured, legend_position)
```

![](fieldclim_check_rad_soil_files/figure-html/unnamed-chunk-7-1.png)

### Shortwave outgoing

``` r

topic <- "Shortwave outgoing"
calculated <- rad_sw_out(weather_station) + rad_diffuse_out(weather_station)
measured <- input$rad_sw_out
legend_position <- "topright"
plotme(topic, calculated, measured, legend_position)
```

![](fieldclim_check_rad_soil_files/figure-html/unnamed-chunk-8-1.png)

### Shortwave balance

``` r

topic <- "Shortwave balance"
calculated <- rad_sw_bal(weather_station)
measured <- input$RsNet
legend_position <- "topright"
plotme(topic, calculated, measured, legend_position)
```

![](fieldclim_check_rad_soil_files/figure-html/unnamed-chunk-9-1.png)

### Longwave incoming

``` r

topic <- "Longwave incoming"
calculated <- rad_lw_in(weather_station)
measured <- input$LUpCo
legend_position <- "left"
plotme(topic, calculated, measured, legend_position)
```

![](fieldclim_check_rad_soil_files/figure-html/unnamed-chunk-10-1.png)

### Longwave outgoing

``` r

topic <- "Longwave outgoing"
calculated <- rad_lw_out(weather_station)
measured <- input$LDnCo
legend_position <- "left"
plotme(topic, calculated, measured, legend_position)
```

![](fieldclim_check_rad_soil_files/figure-html/unnamed-chunk-11-1.png)

### Longwave balance

``` r

topic <- "Longwave balance"
calculated <- rad_lw_bal(weather_station)
measured <- input$RlNet
legend_position <- "left"
plotme(topic, calculated, measured, legend_position)
```

![](fieldclim_check_rad_soil_files/figure-html/unnamed-chunk-12-1.png)

### Radiation balance

``` r

topic <- "Radiation balance"
calculated <- rad_bal(weather_station)
measured <- input$rad_net
legend_position <- "topright"
plotme(topic, calculated, measured, legend_position)
```

![](fieldclim_check_rad_soil_files/figure-html/unnamed-chunk-13-1.png)

### Soil heat flux

``` r

topic <- "Soil heat flux"
calculated <- soil_heat_flux(weather_station)
measured <- input$heatflux_soil
legend_position <- "topright"
plotme(topic, calculated, measured, legend_position)
```

![](fieldclim_check_rad_soil_files/figure-html/unnamed-chunk-14-1.png)

## Examples

### .default method with optional arguments

``` r

pres_p(0, 20)
```

    ## [1] 1013.25

``` r

pres_p(0, 20, p0 = 1013)
```

    ## [1] 1013

### .weather_station method with optional arguments

``` r

weather_station <- build_weather_station(
  elev = 0,
  temp = 20
)
pres_p(weather_station)
```

    ## [1] 1013.25

``` r

pres_p(weather_station, p0 = 1013)
```

    ## [1] 1013
