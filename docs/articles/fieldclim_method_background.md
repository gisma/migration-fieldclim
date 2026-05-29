# Scientific background for fieldClim heat-flux methods

## Purpose of this vignette

This vignette explains the scientific background of the heat-flux
methods implemented in `fieldClim`. It is not a numerical benchmark, and
it does not claim that one method is the universal reference for all
surfaces, time scales and stability regimes. Its purpose is to make the
method logic explicit: which part of the surface energy balance is used,
which station variables are required, which assumptions enter the
calculation, and how the resulting fluxes should be interpreted. The
methodological frame is the same one used in micrometeorology and
environmental biophysics: turbulent fluxes can be measured directly with
covariance systems, estimated with energy-balance and aerodynamic
methods, or diagnosed from gradients and stability assumptions ([Oke
1987](#ref-oke1987); [Monteith and Unsworth 2013](#ref-monteith2013);
[Foken 2008a](#ref-foken2008book); [Campbell and Norman
1998](#ref-campbell1998)).

`fieldClim` is designed for weather stations and microclimate stations
that measure the near-surface drivers of the energy balance but do not
include full eddy-covariance instrumentation. Typical inputs are net
radiation or radiation components, soil heat flux or soil-temperature
information, air temperature, humidity and wind at one or more heights.
Such stations cannot produce direct covariance fluxes from
high-frequency vertical wind and scalar fluctuations. They can, however,
support established approximation families that diagnose or estimate
sensible and latent heat fluxes from mean meteorological quantities
([Allen et al. 1998](#ref-allen1998); [Brutsaert
1982](#ref-brutsaert1982); [Prueger and Kustas 2005](#ref-prueger2005);
[Campbell and Norman 1998](#ref-campbell1998)).

The central point is therefore not to defend one particular method.
Priestley-Taylor, Penman-type, Bowen-ratio, bulk-resistance/residual and
Monin-Obukhov/profile approaches belong to different micrometeorological
method families, and they answer different operational questions
([Penman 1948](#ref-penman1948); [Priestley and Taylor
1972](#ref-priestley1972); [Allen et al. 1998](#ref-allen1998); [Prueger
and Kustas 2005](#ref-prueger2005); [Stull 1988](#ref-stull1988)). Some
paths close the available energy by construction, one path provides only
latent heat flux, and profile methods are diagnostic rather than
energy-closing in this package. This difference is the reason why
`fieldClim` implements several paths side by side.

## Measuring the surface energy balance: from eddy covariance to station-based methods

Eddy covariance estimates turbulent fluxes from the covariance between
fluctuations in vertical wind velocity and fluctuations in scalar
quantities such as temperature, water vapour or trace-gas concentration
([Aubinet et al. 2012](#ref-aubinet2012); [Foken et al.
2012](#ref-foken2012ec); [Lee et al. 2004](#ref-lee2004); [Kaimal and
Finnigan 1994](#ref-kaimal1994)). In a full EC system, a
three-dimensional sonic anemometer provides the turbulent wind
components and often sonic temperature for sensible heat flux, while a
fast-response gas analyser provides water-vapour or CO2 fluctuations for
latent heat and trace-gas fluxes ([Aubinet et al.
2012](#ref-aubinet2012); [Lee et al. 2004](#ref-lee2004)). This is a
fundamentally different data type from ordinary weather-station data,
which usually provide averaged radiation, temperature, humidity, wind
and soil measurements rather than high-frequency turbulent covariances.

This distinction matters for `fieldClim`. The package does not process
high-frequency EC data. It does not rotate wind vectors, despike raw
turbulence records, correct time lags, estimate spectral losses,
calculate coordinate transformations or perform EC quality control.
Those operations belong to the EC processing chain described in EC
handbooks and method chapters, not to the mean-station data model used
here ([Aubinet et al. 2012](#ref-aubinet2012); [Foken et al.
2012](#ref-foken2012ec); [Lee et al. 2004](#ref-lee2004)).

EC nevertheless remains essential background because many simpler
energy-balance, gradient, aerodynamic and evaporation-model approaches
are evaluated against EC or sonic-anemometer based flux observations. At
the same time, EC is not an error-free truth source. The energy-balance
closure problem is well documented, and closure depends on footprint,
heterogeneity, averaging time, storage terms, advection, instrumentation
and data filtering ([Foken 2008b](#ref-foken2008closure); [Aubinet et
al. 2012](#ref-aubinet2012)). For `fieldClim`, EC comparison studies
therefore provide empirical context, not an automatic target that every
station-based method must reproduce exactly.

### What intercomparison studies actually show

The intercomparison literature does not support a simple hierarchy in
which EC is always truth and all station methods are merely crude
substitutes. It shows a more useful pattern: direct turbulent-flux
systems, Bowen-ratio systems, residual-energy approaches, Penman-type
models, Priestley-Taylor estimates, aerodynamic/profile methods and
bulk-transfer models are repeatedly compared because each method becomes
useful under different instrumentation, surface and stability conditions
([Billesbach et al. 2024](#ref-billesbach2024); [Shi et al.
2008](#ref-shi2008); [Sumner and Jacobs 2005](#ref-sumner2005);
[Tomlinson 1996](#ref-tomlinson1996)).

The studies below are included because they connect directly to the
method families used in `fieldClim`. The table is not a complete
literature review. It is a map of the evidence base that explains why
the package contains several method families rather than one single flux
estimator.

| Evidence block | Key references | What it supports for `fieldClim` |
|----|----|----|
| EC, energy-balance, residual and Bowen-type comparison over grassland | Billesbach et al. ([2024](#ref-billesbach2024)) | Direct comparison of EC, energy-balance/Bowen-ratio, residual-energy and modified Bowen-ratio methods for sensible and latent heat flux over grassland. |
| EC, Bowen-ratio energy balance and Penman-Monteith comparison | Shi et al. ([2008](#ref-shi2008)) | Shows that EC, BREB and Penman-Monteith are evaluated as different operational pathways, not as identical measurements. |
| Bowen-ratio, eddy-correlation and lysimeter comparison | Tomlinson ([1996](#ref-tomlinson1996)) | Links Bowen-ratio and eddy-correlation estimates with an independent evapotranspiration reference, and documents practical field-method differences. |
| Penman-Monteith and aerodynamic resistance from meteorological data | Allen et al. ([1998](#ref-allen1998)) | Provides the standard meteorological basis for Penman-Monteith, surface resistance, aerodynamic resistance and wind-dependent reference formulations. |
| PT and PM evapotranspiration comparison | Sumner and Jacobs ([2005](#ref-sumner2005)); Priestley and Taylor ([1972](#ref-priestley1972)); Penman ([1948](#ref-penman1948)) | Places Priestley-Taylor and Penman-type estimates in the practical evapotranspiration-method family. |
| Aerodynamic and flux-gradient methods | Prueger and Kustas ([2005](#ref-prueger2005)) | Supports profile-gradient and aerodynamic transfer methods as an established micrometeorological method family for turbulent flux estimation. |
| Bulk-transfer estimates against sonic/scintillometer-type observations | Kim and Kwon ([2019](#ref-kim2019)) | Supports empirical comparison of bulk-transfer sensible heat estimates against direct or near-direct turbulent-flux observations. |
| Bulk-transfer models against EC over several seasons | Ala-Könni et al. ([2022](#ref-alakonni2022)) | Shows that bulk-transfer models are evaluated against EC over multi-season field data, although surface type and transfer coefficients differ from the Caldern meadow case. |
| EC closure limitation | Foken ([2008b](#ref-foken2008closure)) | Prevents treating EC as an error-free truth source in method interpretation. |
| Boundary-layer and surface-exchange theory | Stull ([1988](#ref-stull1988)); Garratt ([1992](#ref-garratt1992)); Kaimal and Finnigan ([1994](#ref-kaimal1994)); Arya ([2001](#ref-arya2001)) | Provides the general theory context for gradients, turbulence, stability and surface-layer exchange. |

The conclusion is not that one method is universally correct. The
conclusion is that the implemented approaches belong to evaluated
micrometeorological method families. Their differences are not a
weakness of the package; they are the reason the methods must be shown
separately. Each method exposes a different compromise between data
demand, physical detail, numerical robustness and closure behaviour.

### Method families and their assumptions

The method families in `fieldClim` differ mainly in how they use the
surface energy balance. Priestley-Taylor, Bowen and Bulk-Residual
explicitly partition or close the available energy. Penman provides only
a latent heat estimate. Monin-Obukhov/profile methods use profile and
stability information and are therefore diagnostic rather than
energy-closing in this package. The Bulk-Residual path now also has an
optional Richardson guard; this guard screens the neutral sensible-heat
estimate but does not turn the method into a MO correction.

| Method family | `fieldClim` functions | How station data enter | Closure behaviour | Main sensitivity | Literature anchors |
|----|----|----|----|----|----|
| Priestley-Taylor | [`latent_priestley_taylor()`](https://gisma.github.io/migration-fieldclim/reference/latent_priestley_taylor.md), [`sensible_priestley_taylor()`](https://gisma.github.io/migration-fieldclim/reference/sensible_priestley_taylor.md) | Available energy and empirical PT coefficient. | \\H + LE\\ closes \\R_n - G\\ by construction. | PT coefficient and available-energy quality. | Priestley and Taylor ([1972](#ref-priestley1972)); Sumner and Jacobs ([2005](#ref-sumner2005)) |
| Penman-type | [`latent_penman()`](https://gisma.github.io/migration-fieldclim/reference/latent_penman.md) | Available energy plus aerodynamic vapour-pressure term. | LE only; no paired H is returned. | Humidity, wind, resistance assumptions and pressure-unit consistency. | Penman ([1948](#ref-penman1948)); Allen et al. ([1998](#ref-allen1998)); Brutsaert ([1982](#ref-brutsaert1982)) |
| Bowen ratio | [`sensible_bowen()`](https://gisma.github.io/migration-fieldclim/reference/sensible_bowen.md), [`latent_bowen()`](https://gisma.github.io/migration-fieldclim/reference/latent_bowen.md) | Potential-temperature and absolute-humidity gradients partition available energy through the implemented `fieldClim` beta path. | Closes \\R_n - G\\ only for finite uncapped denominators; capped or non-finite beta cases are guarded diagnostics. | Small humidity gradients, sign changes, non-finite beta, near-zero denominator and source-form ambiguity of `gamma_code`. | Tomlinson ([1996](#ref-tomlinson1996)); Shi et al. ([2008](#ref-shi2008)); Billesbach et al. ([2024](#ref-billesbach2024)) |
| Bulk-Residual | [`sensible_bulk()`](https://gisma.github.io/migration-fieldclim/reference/sensible_bulk.md), [`latent_bulk_residual()`](https://gisma.github.io/migration-fieldclim/reference/latent_bulk_residual.md), [`turb_flux_bulk_residual()`](https://gisma.github.io/migration-fieldclim/reference/turb_flux_bulk_residual.md) | Temperature gradient and wind-dependent resistance estimate H; optional Richardson guard screens very stable or weak-shear cases; residual closes LE. | Closes \\R_n - G\\ by construction when H is valid; guarded H values propagate to NA residual LE. | Wind representation, temperature gradient, Richardson screening, weak-shear cases and residual error propagation. | Prueger and Kustas ([2005](#ref-prueger2005)); Kim and Kwon ([2019](#ref-kim2019)); Ala-Könni et al. ([2022](#ref-alakonni2022)); Allen et al. ([1998](#ref-allen1998)) |
| Monin-Obukhov / profile | [`sensible_monin()`](https://gisma.github.io/migration-fieldclim/reference/sensible_monin.md), [`latent_monin()`](https://gisma.github.io/migration-fieldclim/reference/latent_monin.md), [`turb_flux_stability()`](https://gisma.github.io/migration-fieldclim/reference/turb_flux_stability.md) | Profile gradients, wind information and stability logic diagnose H and LE. | Diagnostic only; not forced to close \\R_n - G\\. | Low wind, zero gradients, weak wind shear, stability classification and invalid height/profile states; guarded cases return diagnostic `NA`. | Stull ([1988](#ref-stull1988)); Garratt ([1992](#ref-garratt1992)); Foken ([2008a](#ref-foken2008book)); Prueger and Kustas ([2005](#ref-prueger2005)) |
| Radiation and soil helpers | `rad_*()`, `sol_*()`, `trans_*()`, `soil_*()` | Provide radiation, soil and auxiliary variables used by flux methods. | Input and consistency layer, not a turbulent-flux closure method. | Sensor consistency, surface type, time base, terrain and soil assumptions. | Oke ([1987](#ref-oke1987)); Campbell and Norman ([1998](#ref-campbell1998)); Monteith and Unsworth ([2013](#ref-monteith2013)); Bendix ([2004](#ref-bendix2004)) |

This table should be read from left to right. The package functions are
not alternative names for the same measurement. They are different ways
of turning available station information into heat-flux estimates or
diagnostics. Their outputs therefore have different closure behaviour
and different failure modes.

### Why fieldClim implements these methods and not EC processing

`fieldClim` starts from the instrumentation reality of many field
stations: radiation and soil variables are available, temperature and
humidity profiles may be available, wind speed may be available at one
or two heights, but high-frequency turbulence data usually are not.
Under these conditions, EC processing would be the wrong package scope.
It would require a different data model, a different quality-control
chain and different raw variables ([Aubinet et al.
2012](#ref-aubinet2012); [Foken et al. 2012](#ref-foken2012ec); [Lee et
al. 2004](#ref-lee2004)).

The implemented methods are therefore not second-best versions of an EC
workflow. They are appropriate method families for mean station data. PT
uses available energy with a compact coefficient; Penman uses available
energy and aerodynamic vapour-pressure forcing; Bowen uses gradients to
partition available energy; Bulk-Residual combines a wind-dependent
sensible heat estimate, optionally screened by a Richardson guard, with
residual latent heat; and MO/profile methods diagnose turbulent exchange
from vertical gradients and stability information ([Priestley and Taylor
1972](#ref-priestley1972); [Penman 1948](#ref-penman1948); [Allen et al.
1998](#ref-allen1998); [Prueger and Kustas 2005](#ref-prueger2005);
[Stull 1988](#ref-stull1988)). These approaches are comparable in the
literature because they are used when the available data, surfaces and
time scales differ ([Billesbach et al. 2024](#ref-billesbach2024); [Shi
et al. 2008](#ref-shi2008); [Sumner and Jacobs 2005](#ref-sumner2005);
[Ala-Könni et al. 2022](#ref-alakonni2022)).

## Surface energy balance and package sign convention

The common reference point is the surface energy balance.
Microclimatological and micrometeorological texts use partly different
symbols for the same physical quantities, but the underlying balance is
shared: net radiation is partitioned into ground heat flux, sensible
heat flux, latent heat flux and, where relevant, storage or advection
terms ([Oke 1987](#ref-oke1987); [Monteith and Unsworth
2013](#ref-monteith2013); [Foken 2008a](#ref-foken2008book); [Bendix
2004](#ref-bendix2004)). `fieldClim` uses technical field and output
names such as `rad_bal`, `soil_flux`, `sensible_*` and `latent_*`. These
are implementation names, not a separate theoretical notation.

| Quantity | Common notation | fieldClim field / output | Positive direction / meaning in fieldClim |
|:---|:---|:---|:---|
| Net radiation | Q\* or Rn | rad_bal | net radiative energy input at the surface |
| Soil heat flux | B or G | soil_flux | heat flux into the soil |
| Sensible heat flux | H or L | sensible\_\* | heat flux away from the surface |
| Latent heat flux | LE or V | latent\_\* | heat flux away from the surface |
| Available turbulent energy | Q\* - B or Rn - G | rad_bal - soil_flux | energy available for sensible and latent heat fluxes |

With storage omitted, the surface energy balance is written here as:

\\ R_n = G + H + LE \\

Therefore the energy available for turbulent heat fluxes is:

\\ R_n - G = H + LE \\

In the notation used in the accompanying theory material, the same
balance is:

\\ Q^\* - B = L + V \\

A residual latent heat flux follows directly from the same balance:

\\ LE = R_n - G - H \\

This convention is used throughout the package: `soil_flux` is consumed
as a positive heat flux into the soil, while positive sensible and
latent heat fluxes are interpreted as fluxes away from the surface. This
convention is also why the residual methods are algebraically
transparent: if \\R_n\\, \\G\\ and \\H\\ are specified, \\LE\\ follows
from the balance.

## Method-specific background

### Priestley-Taylor

The Priestley-Taylor method reduces evaporation and latent heat
estimation to an energy-parameter problem. It starts from available
energy and scales the equilibrium evaporation term with an empirical
coefficient ([Priestley and Taylor 1972](#ref-priestley1972)). This
makes it attractive when radiation and soil heat flux are available but
profile-gradient information is incomplete or noisy. The same method
family is commonly compared with Penman-Monteith and other
evapotranspiration estimates in practical ET applications ([Sumner and
Jacobs 2005](#ref-sumner2005)).

The implemented PT path has the structure:

\\ LE\_{PT} = \alpha \frac{\Delta}{\Delta + \gamma} (R_n - G) \\

The corresponding sensible heat flux is calculated as the remaining
available energy:

\\ H\_{PT} = (R_n - G) - LE\_{PT} \\

Therefore the closure invariant is exact:

\\ H\_{PT} + LE\_{PT} = R_n - G \\

The practical strength of PT is robustness. It needs fewer profile
assumptions than Bowen or MO and avoids explicit wind-resistance
modelling. The price is that surface-atmosphere coupling is condensed
into the coefficient and helper terms. PT is therefore useful as a
stable baseline for station-based energy partitioning, not as a direct
measurement of turbulence ([Priestley and Taylor
1972](#ref-priestley1972); [Sumner and Jacobs 2005](#ref-sumner2005)).

### Penman-type latent heat path

The Penman family is a combination family: it links the energy available
for evaporation with an aerodynamic term driven by atmospheric demand
([Penman 1948](#ref-penman1948)). FAO-56 later standardized the
Penman-Monteith framework for crop evapotranspiration and explicitly
distinguishes the energy term, surface resistance and aerodynamic
resistance ([Allen et al. 1998](#ref-allen1998)). In `fieldClim`,
[`latent_penman()`](https://gisma.github.io/migration-fieldclim/reference/latent_penman.md)
is intentionally LE-only. It does not return a paired sensible heat
flux.

The package keeps the energy term as:

\\ R_n - G \\

The implemented Penman path uses saturation vapour pressure and actual
vapour pressure helpers that return hPa, converts them internally to kPa
for the aerodynamic vapour-pressure deficit, and keeps the
saturation-curve slope and psychrometric constant on the same pressure
scale:

\\ VPD\_{kPa} = \frac{e_s - e_a}{10} \\

This unit consistency matters because mixing hPa vapour-pressure deficit
with kPa-scale helper terms inflates the aerodynamic contribution. After
the unit correction, the method remains a modelled latent heat estimate.
It should not be compared with PT, Bowen or Bulk-Residual as if it also
delivered a corresponding sensible heat flux. The general
combination-method logic belongs to the Penman/Penman-Monteith family,
but the package path is a simplified latent-heat implementation from
standard station variables ([Penman 1948](#ref-penman1948); [Allen et
al. 1998](#ref-allen1998); [Brutsaert 1982](#ref-brutsaert1982)).

The relevant package distinction is:

\\ \text{Penman path} = LE \text{ only} \\

There is no package-defined Penman sensible heat flux.

### Bowen-ratio

The Bowen-ratio method partitions available energy using the ratio of
sensible to latent heat flux:

\\ \beta = \frac{H}{LE} \\

If the ratio is known, the energy balance gives:

\\ H = \frac{\beta}{1 + \beta} (R_n - G) \\

and:

\\ LE = \frac{1}{1 + \beta} (R_n - G) \\

For finite uncapped denominators, the closure invariant is exact:

\\ H + LE = R_n - G \\

The Bowen-ratio energy-balance family is widely used because it connects
measured vertical gradients to energy partitioning and can be compared
directly with EC or lysimeter-based evapotranspiration estimates
([Tomlinson 1996](#ref-tomlinson1996); [Shi et al. 2008](#ref-shi2008);
[Billesbach et al. 2024](#ref-billesbach2024)). In `fieldClim`, the
implemented Bowen ratio is based on a potential-temperature gradient and
an absolute-humidity gradient:

\\ \beta = \gamma\_{code} \frac{\Delta \theta / \Delta z}{\Delta AH /
\Delta z} \\

with:

\\ \gamma\_{code} = 0.00066 (1 + 0.000946 t_1) \\

This matters because the implementation is more specific than a
symbol-only textbook expression. The package converts `t1` and `t2` to
potential temperature, converts `hum1` and `hum2` from relative humidity
to absolute humidity, and then forms the gradient ratio. The coefficient
\\\gamma\_{code}\\ is therefore treated as the empirical coefficient of
the current `fieldClim` implementation. Current validation did not prove
source-equivalence between this form and alternative Bowen-ratio
formulations based on vapour-pressure gradients, specific-humidity
gradients or heat-capacity / latent-heat scaling. The implemented beta
path is therefore tested and documented as package behaviour, while the
exact source-form decision remains open.

The method is powerful when gradients are well resolved. The same
dependence makes it fragile. Small humidity gradients, sign changes and
near-zero values of `1 + beta` can dominate the result. The `cap`
parameter is therefore a numerical safeguard for near-zero denominators.
For finite uncapped cases,
[`sensible_bowen()`](https://gisma.github.io/migration-fieldclim/reference/sensible_bowen.md)
and
[`latent_bowen()`](https://gisma.github.io/migration-fieldclim/reference/latent_bowen.md)
use the same beta path and close \\R_n - G\\. If the denominator is
capped, or if beta or the denominator becomes non-finite, the output is
treated as guarded diagnostic behaviour rather than as an exact physical
closure. Non-finite Bowen ratios or denominators are returned as `NA`
for the affected time steps.

### Bulk-Residual

The Bulk-Residual path combines an aerodynamic-resistance estimate of
sensible heat flux with a residual latent heat flux. It is not an EC
measurement and it is not a full MO surface-layer model. It is a
station-data implementation of a familiar aerodynamic-transfer idea:
wind-driven exchange controls the resistance between a temperature
difference and a sensible heat flux ([Prueger and Kustas
2005](#ref-prueger2005); [Allen et al. 1998](#ref-allen1998); [Campbell
and Norman 1998](#ref-campbell1998)).

The sensible heat calculation follows the general aerodynamic-resistance
form:

\\ H\_{bulk} = \rho c_p \frac{\Delta T}{r_a} \\

In the neutral default implementation:

\\ \Delta T = T_1 - T_2 \\

and:

\\ r_a = \frac{\ln(z_2 / z_1)} {k \bar{u}} \\

Here \\T_1\\ and \\T_2\\ are lower and upper air temperatures, \\z_1\\
and \\z_2\\ are the corresponding measurement heights, \\k\\ is the von
Karman constant and \\\bar{u}\\ is the observed wind-speed scale used by
the package. If two wind heights are available, \\\bar{u}\\ is the
arithmetic mean of `v1` and `v2`; otherwise `v1` is used.

The wind term belongs to the aerodynamic-resistance logic used in
micrometeorology, evapotranspiration modelling and flux-gradient methods
([Allen et al. 1998](#ref-allen1998); [Prueger and Kustas
2005](#ref-prueger2005); [Monteith and Unsworth
2013](#ref-monteith2013)). It should not be read as a full
friction-velocity-based surface-layer formulation. More complete
formulations may use friction velocity, roughness length, displacement
height and stability corrections ([Stull 1988](#ref-stull1988); [Garratt
1992](#ref-garratt1992); [Foken 2008a](#ref-foken2008book)). The default
`fieldClim` implementation is deliberately simpler because standard
station datasets often provide wind speed but not directly measured
friction velocity.

The optional Richardson guard does not replace this neutral bulk
calculation. It screens the neutral estimate when two-height wind and
temperature information are available. With
`stability_method = "ri_guard"`, the package estimates a gradient
Richardson number:

\\ Ri_g = \frac{g}{\bar{\theta}} \frac{\Delta \theta / \Delta z}
{(\Delta u / \Delta z)^2} \\

where \\g\\ is gravitational acceleration, \\\bar{\theta}\\ is mean
potential temperature if elevation is available, \\\Delta \theta /
\Delta z\\ is the vertical potential-temperature gradient, and \\\Delta
u / \Delta z\\ is the vertical wind-speed shear between the two
measurement heights. If elevation is not available, the implementation
uses Kelvin air temperature as a near-surface approximation for the
stability screen.

This Richardson number is used as a guard, not as a flux correction.
Unstable, neutral and moderately stable cases keep the neutral bulk
estimate. Very stable cases, invalid Richardson numbers and weak-shear
cases are returned as `NA` for the affected time steps. The guard
therefore prevents a formally computed neutral bulk flux from being
treated as robust when the two-height profile indicates that the neutral
approximation is not defensible.

The implementation uses wind-speed shear rather than full vector shear
because ordinary station data usually provide wind speed but not
horizontal wind components. This makes the guard a speed-shear
Richardson approximation. It is useful for screening problematic time
steps, but it is not a full MO correction and it does not apply
stability functions to rescale the flux.

The residual latent heat flux is:

\\ LE\_{res} = R_n - G - H\_{bulk} \\

Therefore, when \\H\_{bulk}\\ is valid, the Bulk-Residual workflow
closes available energy by construction:

\\ H\_{bulk} + LE\_{res} = R_n - G \\

If the Richardson guard sets \\H\_{bulk}\\ to `NA`, the residual
\\LE\_{res}\\ is also `NA` for that time step. This is intended. It
prevents residual closure from hiding an invalid or non-robust sensible
heat estimate.

This closure is algebraic. It does not prove that `H_bulk` is a perfect
physical estimate. It means that the residual latent heat flux inherits
all errors in \\R_n\\, \\G\\ and the bulk sensible heat estimate. This
is not a special weakness of the Bulk-Residual path. It is the normal
consequence of residual energy-balance reasoning.

Empirically, the broader bulk-transfer and aerodynamic-transfer family
has been compared with direct or near-direct turbulent-flux
observations. Bulk-transfer sensible heat estimates have been validated
against three-dimensional ultrasonic anemometer or scintillometer-based
observations in UAV-based work ([Kim and Kwon 2019](#ref-kim2019)), and
bulk-transfer models have been evaluated against EC turbulent heat
fluxes over seasonal lake ice ([Ala-Könni et al.
2022](#ref-alakonni2022)). These studies do not validate every possible
station implementation, but they show that bulk/aerodynamic transfer is
an evaluated method family rather than a package invention.

#### Wind speed, friction velocity and two-height station data

The use of wind is not an add-on. Stronger wind-driven turbulent
exchange lowers aerodynamic resistance, so the same temperature
difference produces a larger sensible heat flux when mixing is stronger.
This wind dependence is explicit in aerodynamic-resistance formulations
used in Penman-Monteith and related station-data methods ([Allen et al.
1998](#ref-allen1998); [Monteith and Unsworth 2013](#ref-monteith2013)).

If only one wind speed is available, a friction-velocity-based method
cannot be used without additional roughness assumptions. If two wind
heights are available, friction velocity can be estimated under a
neutral log-profile assumption:

\\ u\_\* = k \frac{u_2 - u_1} {\ln(z_2 / z_1)} \\

and then a neutral heat-transfer resistance can be written as:

\\ r\_{ah} = \frac{\ln(z_2 / z_1)} {k u\_\*} \\

This is a possible alternative formulation, but it is not automatically
more robust for ordinary station data. If the wind-speed difference is
small, noisy or changes sign, the estimated friction velocity becomes
unstable. The current Bulk-Residual implementation therefore keeps the
observed-wind neutral resistance as its default and uses the Richardson
number only as an optional stability guard.

The important distinction is this:
[`sensible_bulk()`](https://gisma.github.io/migration-fieldclim/reference/sensible_bulk.md)
is not a full friction-velocity or MO method. Its default path is a
neutral bulk-resistance estimate from observed wind speed. Its optional
Richardson guard is a diagnostic screen for stability and weak-shear
problems. A future friction-velocity-based mode would be a separate
method option and should not silently replace the current default.

### Monin-Obukhov and profile methods

Monin-Obukhov similarity theory provides the theoretical background for
profile-gradient and stability-based interpretations of turbulent
transfer. The `fieldClim` implementation should be read more narrowly:
it provides guarded diagnostic profile estimates and stability
classifications from station data, not a full MOST solution with
independently measured friction velocity, roughness lengths and complete
stability-function correction. ([Stull 1988](#ref-stull1988); [Garratt
1992](#ref-garratt1992); [Foken 2008a](#ref-foken2008book)). They are
methodologically important because they connect observed profiles with
turbulence theory. In `fieldClim`, however, the MO path is
diagnostic-only.

The package uses profile information to derive diagnostic sensible and
latent heat-flux estimates from vertical temperature, humidity and wind
information. The sensible heat profile term follows the documented
vertical-gradient structure and uses the height difference \\z_2 -
z_1\\. This keeps the implemented profile-gradient term aligned with the
Richardson-gradient logic used elsewhere in the package.

The diagnostic rule remains:

\\ H\_{MO} + LE\_{MO} \\

is not required to equal:

\\ R_n - G \\

This is not a defect. It is a consequence of method class. A profile
method estimates fluxes from profile and stability assumptions, while
PT, Bowen and Bulk-Residual are explicit energy-partition or residual
workflows. Forcing MO output to close \\R_n - G\\ would hide the
diagnostic information that profile methods are meant to expose.

The practical issue is numerical robustness. Zero gradients, very small
wind shear, invalid height relationships and unstable or non-finite
stability diagnostics can produce misleading or undefined outputs.
`fieldClim` therefore treats these cases explicitly. A zero
potential-temperature gradient returns zero sensible heat flux. A zero
moisture gradient returns zero latent heat flux. Invalid heights,
invalid wind and invalid numerical profile states return `NA` with a
warning. Richardson-number diagnostics return `NA` for invalid heights,
invalid wind, weak or zero shear, and non-finite values.

This guard behaviour does not make MO an energy-balance closure method.
It only prevents invalid profile states from being interpreted as
ordinary heat-flux events. MO outputs should therefore be inspected
together with stability classification and diagnostic warnings. They
should not be silently normalized to available turbulent energy.

## Practical interpretation in fieldClim

The practical interpretation follows from the closure behaviour. If the
goal is a stable first estimate of the partitioning of available energy,
the PT path is the least demanding because it avoids explicit
profile-gradient and wind-resistance assumptions. Its stability is
bought by using an empirical coefficient. It is therefore useful as a
baseline, not as a direct turbulent-flux measurement ([Priestley and
Taylor 1972](#ref-priestley1972); [Sumner and Jacobs
2005](#ref-sumner2005)).

The Penman path should be interpreted separately because it is LE-only.
It combines an energy term with an aerodynamic vapour-pressure term and
is useful when a latent heat estimate is needed from standard
meteorological variables. It should not be compared with PT, Bowen or
Bulk-Residual as if it also provided a corresponding sensible heat flux
([Penman 1948](#ref-penman1948); [Allen et al. 1998](#ref-allen1998)).

The Bowen path is a gradient-partitioning method. Its strength is that
it uses measured vertical gradients to divide available energy into
sensible and latent parts. Its weakness is the same property: small
humidity gradients, sign changes and near-singular values of `1 + beta`
can dominate the result. In `fieldClim`, the beta path is locked and
tested as the current implementation, but the exact source-form
equivalence of the empirical \\\gamma\_{code}\\ coefficient remains
open. Exact closure is therefore a property of finite uncapped cases,
not of capped, non-finite or otherwise guarded Bowen outputs ([Tomlinson
1996](#ref-tomlinson1996); [Shi et al. 2008](#ref-shi2008); [Billesbach
et al. 2024](#ref-billesbach2024)).

The Bulk-Residual path uses measured temperature gradients and wind
speed to estimate sensible heat flux, optionally screens this estimate
with the Richardson guard, and then assigns the remaining available
energy to latent heat. This makes the residual closure transparent, but
the closure is only meaningful for time steps where the sensible heat
estimate is valid. If the guard marks a very stable, weak-shear or
otherwise invalid profile as non-robust, `H_bulk` and the residual
`LE_res` become `NA` for that time step. The method should therefore be
interpreted as a station-data aerodynamic/residual pathway with an
optional stability screen, not as a full MO correction ([Prueger and
Kustas 2005](#ref-prueger2005); [Kim and Kwon 2019](#ref-kim2019);
[Ala-Könni et al. 2022](#ref-alakonni2022); [Stull
1988](#ref-stull1988); [Garratt 1992](#ref-garratt1992)).

The MO/profile path has the strongest link to profile and stability
reasoning, but it is also the most numerically sensitive. The current
implementation guards zero-gradient, low-wind, invalid-height and
non-finite Richardson cases, but it remains diagnostic-only. Its value
is to show how profile gradients and stability assumptions behave in the
available data, not to force closure with \\R_n - G\\. Guarded `NA`
values should therefore be read as diagnostic information rather than
ordinary heat-flux events ([Stull 1988](#ref-stull1988); [Garratt
1992](#ref-garratt1992); [Foken 2008a](#ref-foken2008book); [Arya
2001](#ref-arya2001)).

The central conclusion is therefore not that one method is universally
correct. The implemented methods belong to evaluated micrometeorological
method families, but they answer different operational questions.
`fieldClim` makes these differences explicit so that station-based
heat-flux estimates can be compared, diagnosed and interpreted without
pretending that they are interchangeable measurements.

## References

Ala-Könni, Joonatan, Ivan Mammarella, Anne Ojala, et al. 2022.
“Validation of Turbulent Heat Transfer Models Against Eddy-Covariance
Flux Measurements over a Seasonally Ice-Covered Lake.” *Geoscientific
Model Development* 15: 4739–55.
<https://doi.org/10.5194/gmd-15-4739-2022>.

Allen, Richard G., Luis S. Pereira, Dirk Raes, and Martin Smith. 1998.
*Crop Evapotranspiration: Guidelines for Computing Crop Water
Requirements*. FAO Irrigation and Drainage Paper 56. Food; Agriculture
Organization of the United Nations.
<https://www.fao.org/4/x0490e/x0490e00.htm>.

Arya, S. Pal. 2001. *Introduction to Micrometeorology*. 2nd ed. Academic
Press.

Aubinet, Marc, Timo Vesala, and Dario Papale, eds. 2012. *Eddy
Covariance: A Practical Guide to Measurement and Data Analysis*.
Springer. <https://doi.org/10.1007/978-94-007-2351-1>.

Bendix, Jörg. 2004. *Geländeklimatologie*. Gebrüder Borntraeger.

Billesbach, David P., Timothy J. Arkebauer, Daniel T. Walters, and
Shashi B. Verma. 2024. “Intercomparison of Sensible and Latent Heat Flux
Measurements from Combined Eddy Covariance, Energy Balance, and Bowen
Ratio Methods Above a Grassland Prairie.” *Scientific Reports* 14:
21486. <https://doi.org/10.1038/s41598-024-67911-z>.

Brutsaert, Wilfried. 1982. *Evaporation into the Atmosphere: Theory,
History, and Applications*. D. Reidel.
<https://doi.org/10.1007/978-94-017-1497-6>.

Campbell, Gaylon S., and John M. Norman. 1998. *An Introduction to
Environmental Biophysics*. 2nd ed. Springer.
<https://doi.org/10.1007/978-1-4612-1626-1>.

Foken, Thomas. 2008a. *Micrometeorology*. Springer.

Foken, Thomas. 2008b. “The Energy Balance Closure Problem: An Overview.”
*Ecological Applications* 18 (6): 1351–67.
<https://doi.org/10.1890/06-0922.1>.

Foken, Thomas, Marc Aubinet, and Ray Leuning. 2012. “The Eddy Covariance
Method.” In *Eddy Covariance: A Practical Guide to Measurement and Data
Analysis*, edited by Marc Aubinet, Timo Vesala, and Dario Papale.
Springer. <https://doi.org/10.1007/978-94-007-2351-1_1>.

Garratt, J. R. 1992. *The Atmospheric Boundary Layer*. Cambridge
University Press.

Kaimal, J. C., and J. J. Finnigan. 1994. *Atmospheric Boundary Layer
Flows: Their Structure and Measurement*. Oxford University Press.
<https://doi.org/10.1093/oso/9780195062397.001.0001>.

Kim, Min-Seong, and Byung Hyuk Kwon. 2019. “Estimation of Sensible Heat
Flux and Atmospheric Boundary Layer Height Using an Unmanned Aerial
Vehicle.” *Atmosphere* 10 (7): 363.
<https://doi.org/10.3390/atmos10070363>.

Lee, Xuhui, William Massman, and Beverly Law, eds. 2004. *Handbook of
Micrometeorology: A Guide for Surface Flux Measurement and Analysis*.
Kluwer Academic Publishers. <https://doi.org/10.1007/1-4020-2265-4>.

Monteith, John L., and Mike H. Unsworth. 2013. *Principles of
Environmental Physics: Plants, Animals, and the Atmosphere*. 4th ed.
Academic Press.

Oke, T. R. 1987. *Boundary Layer Climates*. 2nd ed. Methuen.

Penman, Howard L. 1948. “Natural Evaporation from Open Water, Bare Soil
and Grass.” *Proceedings of the Royal Society of London. Series A* 193
(1032): 120–45. <https://doi.org/10.1098/rspa.1948.0037>.

Priestley, C. H. B., and R. J. Taylor. 1972. “On the Assessment of
Surface Heat Flux and Evaporation Using Large-Scale Parameters.”
*Monthly Weather Review* 100 (2): 81–92.
<https://doi.org/10.1175/1520-0493(1972)100%3C0081:OTAOSH%3E2.3.CO;2>.

Prueger, John H., and William P. Kustas. 2005. “Aerodynamic Methods for
Estimating Turbulent Fluxes.” In *Micrometeorology in Agricultural
Systems*, edited by Jerry L. Hatfield and John M. Baker. Agronomy
Monograph 47. American Society of Agronomy, Crop Science Society of
America,; Soil Science Society of America.

Shi, Ting-Ting, De-Xin Guan, Jia-Bing Wu, An-Zhi Wang, Chang-Jie Jin,
and Shi-Jie Han. 2008. “Comparison of Methods for Estimating
Evapotranspiration Rate of Dry Forest Canopy: Eddy Covariance, Bowen
Ratio Energy Balance, and Penman-Monteith Equation.” *Journal of
Geophysical Research: Atmospheres* 113 (D19): D19116.
<https://doi.org/10.1029/2008JD010174>.

Stull, Roland B. 1988. *An Introduction to Boundary Layer Meteorology*.
Springer. <https://doi.org/10.1007/978-94-009-3027-8>.

Sumner, David M., and Jennifer M. Jacobs. 2005. “Utility of
Penman-Monteith, Priestley-Taylor, Reference Evapotranspiration, and Pan
Evaporation Methods to Estimate Pasture Evapotranspiration.” *Journal of
Hydrology* 308 (1–4): 81–104.
<https://doi.org/10.1016/j.jhydrol.2004.10.023>.

Tomlinson, Stuart A. 1996. *Comparison of Bowen-Ratio, Eddy-Correlation,
and Weighing-Lysimeter Evapotranspiration Measurements in a Semiarid
Rangeland*. Water-Resources Investigations Report Nos. 96-4081. U.S.
Geological Survey. <https://pubs.usgs.gov/wri/1996/4081/report.pdf>.
