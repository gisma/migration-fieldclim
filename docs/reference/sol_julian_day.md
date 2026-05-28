# Julian day

Day of year as an integer from 1 to 366.

## Usage

``` r
sol_julian_day(...)
```

## Arguments

- ...:

  Additional arguments.

## Value

Unitless.

## Details

The Julian day (\\J\\) is the day of the year, ranging from 1 to 366.

## Examples

``` r
# Calculate Julian day
sol_julian_day(as.POSIXlt("2022-06-21"))
#> [1] 172
```
