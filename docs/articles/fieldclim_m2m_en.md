# Choosing fieldClim Heat-Flux Methods by Measurement Design

## Purpose

This page is a practical decision guide. Its starting point is not the
question “Which heat-flux method is best?”, but the question “What
measurement architecture do I have, what reference surface do I mean,
and what kind of finding can I defend from this dataset?”

The same energy-balance equation can be used in very different epistemic
ways. A one-height station with radiation and soil heat flux supports a
different interpretation than a two-height profile station. A tower
above or within a canopy requires an explicit reference-surface decision
before any flux interpretation is meaningful.

The core notation used here is:

\\ A = Q^\* - B \\

\\ Q^\* - B = H + LE + R_E \\

\\ R_E = Q^\* - B - H - LE \\

Here, Q\* means net radiation, B means soil heat flux, A means available
energy, H means sensible heat flux, LE means latent heat flux, and R_E
means the residual or non-closed energy term. Positive B means soil heat
flux into the soil as a sign convention. The real soil heat flux can
change direction; this is represented by the sign of B.

## Evidence base and reference frame

This page separates implementation evidence from physical reference
evidence. Implementation evidence describes what the current `fieldClim`
code, tests, and generated documentation actually do. The current audit
reports that the Bulk path estimates sensible heat with a neutral bulk
aerodynamic-resistance structure and then defines latent heat as an
algebraic residual in the Bulk–Residual workflow. It also reports that
the optional `ri_guard` is a diagnostic filter rather than a full
stability correction, and that Bulk must not be described as MOST.

Physical reference evidence defines the method families:
available-energy partitioning, Bowen-ratio energy balance, aerodynamic
resistance or bulk transfer, Penman-type latent heat estimation, and
Monin–Obukhov or profile-gradient diagnostics. These references provide
the comparison frame, but they do not prove that every package
implementation is a complete canonical implementation.

Priestley–Taylor is treated here as an available-energy partitioning
approach for latent heat. In the original formulation, evaporation is
parameterized from available energy and a coefficient, rather than
derived from a measured humidity-gradient flux.[^1] In `fieldClim`, this
role is mirrored by estimating LE_PT from available energy and a
surface-dependent coefficient, while H_PT is the complement.

Bowen-ratio methods are treated as gradient-based energy partitioning
methods. Their key assumption is that the ratio of sensible to latent
heat can be inferred from temperature and humidity or vapour-pressure
gradients under suitable measurement conditions.[^2] Because this ratio
becomes fragile when gradients are small or noisy, Bowen-ratio
calculations require rejection or filtering logic in practical
applications.[^3]

Penman-type methods are treated as latent-heat or evaporation-oriented
methods. They combine available energy with an aerodynamic drying-power
term and therefore produce an LE estimate rather than a complete paired
H/LE solution.[^4] This is why the Penman remainder is described here as
an unresolved remainder, not as sensible heat.

Monin–Obukhov Similarity Theory is the canonical reference frame for
surface-layer profile-gradient and stability-based flux
interpretation.[^5] In this page, however, the package method is
deliberately called Monin/Profile diagnostic. This avoids overstating
the implementation as a fully validated canonical MOST solution. Foken’s
review of MOST provides the theoretical reference frame, but it is not
evidence that the package implementation satisfies all canonical
requirements.[^6]

The tables below are therefore decision-support tools, not a validation
hierarchy. The implementation evidence tells us what the package
computes. The micrometeorological references tell us which physical
method family the computation resembles. Neither replaces independent
field validation.

## The selection problem

A heat-flux method should be selected in three steps. First, define the
reference surface. Second, identify the measurement architecture. Third,
choose the target quantity or finding.

This order matters. If the reference surface is unclear, the flux
interpretation is underdefined. If the measurement architecture does not
include vertical gradients, gradient-based methods are not defensible.
If the target quantity is H, an LE-only method is not enough. If the
target quantity is LE, a residual LE term is not the same as an
independent evaporation estimate.

### Step 1: Define the reference surface

The reference surface is the surface to which the flux interpretation
refers. Over a meadow or bare soil this is often straightforward. Over a
forest, crop canopy, or tower profile it is not. A sensor above a
canopy, a sensor within a canopy, and a sensor near the forest floor do
not describe the same exchange surface.

| Reference situation | What must be clarified | Consequence for method choice |
|----|----|----|
| Short homogeneous surface, such as meadow or bare soil | Sensor heights above the surface, Q\*, B, wind exposure | Bulk, Bowen, Priestley–Taylor, Penman, and profile diagnostics can be compared if data are available |
| Forest floor or under-canopy station | Whether the target is ground microclimate or canopy exchange | Available-energy and microclimate interpretation may be valid; above-canopy flux interpretation is not automatic |
| Above-canopy tower | Canopy-top reference, roughness length, displacement height, roughness sublayer | Bulk and Monin/Profile become highly parameter- and reference-surface dependent |
| Mixed within-canopy and above-canopy profile | Whether the profile represents exchange, storage, or coupling/decoupling | Treat primarily as process diagnosis, not as a simple surface-layer flux |
| Unknown or changing reference surface | Reference level and surface properties are not defined | Do not report robust fluxes; report exploratory diagnostics only |

### Step 2: Identify the measurement architecture

The available station architecture controls which methods can be used
defensibly. One height supports LE-oriented or available-energy
interpretations. Two heights support direct H baselines and gradient
partitioning.

| Measurement architecture | Data pattern | Methods that are structurally supported | Main finding type |
|----|----|----|----|
| One height with Q\* and B | T, RH, u at one height; Q\*; B | Priestley–Taylor, Penman, available-energy diagnostics | LE-oriented estimate, partition, or unresolved remainder |
| Two heights with Q\* and B | T, RH, u at two heights; Q\*; B | Bulk–Residual, Bowen, Monin/Profile diagnostic, Priestley–Taylor, Penman | H baseline, H/LE partition, method comparison, diagnostic residual |
| Canopy tower | One or two relevant heights above, within, or below canopy; Q\* and B may refer to different surfaces | Only after reference-surface definition | Canopy exchange or coupling/decoupling diagnosis |
| Missing Q\* or B | Profile information may exist, but available energy is incomplete | Profile-only diagnostics or partial Penman-type comparison | Incomplete flux interpretation |

### Step 3: Choose the target finding

The target finding determines the method role. The same dataset can
support several methods, but each method answers a different question.

| Target finding | Best method role | Defensible interpretation | What not to claim |
|----|----|----|----|
| Direct sensible heat estimate | Bulk | H is estimated from a vertical temperature gradient and an exchange assumption | The residual closure validates H |
| Latent heat or evaporation estimate | Penman, Priestley–Taylor | LE is estimated from available energy, atmospheric demand, or empirical partitioning | The remaining energy is automatically H |
| H/LE partition of available energy | Priestley–Taylor, Bowen, Bulk–Residual | A is distributed according to a method assumption | Partition closure is independent validation |
| Profile and stability diagnosis | Monin/Profile diagnostic | H and LE are diagnostic profile outputs and R_E remains visible | This is automatically a complete MOST truth |
| Formal closure demonstration | Bulk–Residual, Priestley–Taylor, Bowen | H + LE equals A because of definition or partition assumption | Formal closure proves physical accuracy |
| Open residual diagnosis | Penman remainder, Monin/Profile residual | The unresolved part remains visible | The residual is automatically a known physical flux |

## Decision scheme by dataset

### Case A: One-height station with radiation and soil heat flux

A one-height station can define available energy but cannot estimate H
from a vertical air-temperature gradient. It can support
Priestley–Taylor, Penman, and basic energy-balance interpretation.

\\ A = Q^\* - B \\

For Penman, the useful interpretation is latent-heat-oriented:

\\ LE\_\mathrm{Penman} = f(A, VPD, r_a, r_s) \\

The remainder is:

\\ U\_\mathrm{Penman} = A - LE\_\mathrm{Penman} \\

U_Penman is an unresolved energy remainder. It can contain sensible
heat, closure error, input error, and model mismatch. It should not be
labelled H unless an explicit additional closure assumption is
introduced.

| Dataset | Primary methods | Reportable finding | Avoid |
|----|----|----|----|
| One height: T, RH, u, Q\*, B | Penman, Priestley–Taylor | Available energy and LE-oriented estimate | Direct gradient-based H |
| One height: T, RH, u, no reliable Q\* or B | Limited Penman-type comparison if inputs exist | Atmospheric demand or incomplete LE comparison | Energy-balance closure |
| One height with soil data only | Energy-state description | Ground and radiation context | Turbulent flux partitioning |

A defensible wording is: “Available energy was quantified as A = Q\* −
B. Latent heat was estimated using Penman or Priestley–Taylor. A direct
gradient-based sensible heat estimate was not possible from this
dataset.”

### Case B: Two-height station over a defined reference surface

A two-height station is the first configuration that supports
gradient-based interpretation. If T, RH, and u are measured at two known
heights, the station can support Bulk, Bowen, and Monin/Profile
diagnostics, in addition to Priestley–Taylor and Penman.

Bulk–Residual estimates sensible heat from the two-height temperature
difference and an exchange assumption:

\\ H\_\mathrm{bulk} = \rho c_p \frac{t_1 - t_2}{r_a} \\

The Bulk–Residual latent heat is then defined as:

\\ LE\_\mathrm{res} = Q^\* - B - H\_\mathrm{bulk} \\

The closure follows by definition:

\\ R_E = Q^\* - B - H\_\mathrm{bulk} - LE\_\mathrm{res} = 0 \\

This does not validate H_bulk. It only states how LE_res was defined.

| Data available | Method role | Reportable finding | Diagnostic risk |
|----|----|----|----|
| T at two heights and wind | Bulk | Direct H baseline | Exchange assumption and stability |
| T and RH at two heights | Bowen | Gradient-based partition | Weak or noisy humidity gradients |
| T, RH, and wind at two heights | Monin/Profile diagnostic | Profile/stability-sensitive diagnostic outputs | Not force-closed; parameter-sensitive |
| Q\* and B also reliable | Method comparison | How assumptions distribute A into H and LE | Closure is not validation |

A defensible wording is: “Bulk–Residual estimated sensible heat from the
vertical temperature gradient and defined latent heat as the remaining
available energy. The resulting closure is algebraic and follows by
definition.”

### Case C: Tower above or within canopy

A canopy tower must not be treated like a simple meadow profile unless
the reference surface is explicitly defined. Above-canopy measurements
may describe exchange above the canopy. Within-canopy gradients may
describe coupling, storage, or decoupling rather than a surface-layer
flux.

| Tower situation | First decision | Method role | Reportable finding |
|----|----|----|----|
| Both levels above canopy | Define canopy-top or aerodynamic reference | Bulk as cautious baseline; Monin/Profile diagnostic | Above-canopy exchange comparison |
| One level inside canopy and one above canopy | Define whether exchange or coupling is the target | Diagnostic only | Canopy coupling or decoupling signal |
| Forest-floor station under canopy | Define ground as reference | Available energy and microclimate state near ground | Local under-canopy energy context |
| Unknown reference surface | Do not force flux interpretation | Exploratory diagnostics only | Flux interpretation remains underdefined |

A defensible wording is: “The interpretation depends on the chosen
reference surface. Above-canopy gradients can support an exchange
diagnostic if roughness and reference-height assumptions are explicit;
within-canopy gradients should be treated primarily as coupling or
decoupling diagnostics.”

## Method roles in the implemented canon

The methods are not competitors in a single accuracy ranking. They
determine different things.

| Method | What it determines directly | What is assumed or residual | Best used for | Main limitation |
|----|----|----|----|----|
| Priestley–Taylor | LE_PT from available energy and empirical partitioning | H_PT is the complement | LE-oriented partition for moist vegetation | Depends on alpha_PT and surface assumptions |
| Bulk–Residual | H_bulk from temperature gradient and exchange assumption | LE_res is the remaining available energy | H estimate from two-height station data; residual closure demonstration | Neutral transfer assumption; LE_res absorbs errors in Q\*, B, and H_bulk |
| Bowen Ratio | H/LE partition through beta | Closure only for valid finite beta | H/LE partition when T/RH gradients are reliable | Fragile for weak or noisy humidity gradients |
| Penman | LE_Penman | U_Penman remains open | Latent heat or evaporation comparison | No direct H |
| Monin/Profile diagnostic | H_MO and LE_MO from profile/stability logic | R_E,MO remains visible | Profile and stability diagnosis | Input- and parameter-intensive; not force-closed |
| Closure diagnostics | R_E, closure ratio, open remainders | No flux is computed | Interpreting method semantics | Diagnostic only |

## Operational selection matrix

This table is the practical tool for deciding what to run and what to
report.

| Measurement architecture | Main method choice | Secondary comparison | Reportable finding | Avoid claiming |
|----|----|----|----|----|
| One height plus Q\*, B | Penman or Priestley–Taylor | Available-energy diagnostics | LE-oriented estimate or partition | Direct gradient-based H |
| Two heights plus Q\*, B | Bulk–Residual for H and residual LE; Bowen if gradients are reliable | Penman/PT comparison; Monin/Profile diagnostic | Method-sensitive H/LE partition | Bulk closure as validation |
| One or two heights in canopy/tower context | Reference-surface diagnosis first | Bulk–Residual, Bowen, or Monin/Profile only with explicit height/roughness logic | Ground, canopy, or above-canopy diagnostic interpretation | Simple surface-layer flux without reference definition |
| Missing Q\* or B | Profile-only diagnostics if two heights exist | Penman if required meteorology exists | Incomplete flux comparison | Energy-balance closure |

## Method-specific decision notes

### Bulk–Residual

Bulk–Residual estimates sensible heat from a two-height temperature
gradient and an exchange assumption. The corresponding latent heat is
defined as the remaining available energy.

\\ H\_\mathrm{bulk} = \rho c_p \frac{t_1 - t_2}{r_a} \\

\\ LE\_\mathrm{res} = Q^\* - B - H\_\mathrm{bulk} \\

Bulk–Residual is appropriate when the dataset contains two measurement
heights and the target is a direct sensible-heat estimate plus an
explicitly residual latent-heat term. Its limitation is the neutral
transfer assumption. The residual term absorbs errors in Q\*, B, and
H_bulk.

### Priestley–Taylor

Priestley–Taylor is an available-energy partitioning method. It is
useful when the target is LE-oriented partitioning, especially for moist
vegetated surfaces.

\\ LE\_\mathrm{PT} = \alpha\_\mathrm{PT} \frac{sc}{sc + \gamma} (Q^\* -
B) \\

\\ H\_\mathrm{PT} = (Q^\* - B) - LE\_\mathrm{PT} \\

Its limitation is that H_PT is a complement, not an independently
estimated sensible heat flux. The result depends on alpha_PT and surface
assumptions.

### Bowen Ratio

Bowen is useful when temperature and humidity gradients are reliable. It
partitions available energy through a gradient ratio.

\\ H\_\mathrm{BR} = \frac{\beta}{1 + \beta} (Q^\* - B) \\

\\ LE\_\mathrm{BR} = \frac{1}{1 + \beta} (Q^\* - B) \\

Its limitation is denominator fragility. Weak or noisy humidity
gradients can dominate the result.

### Penman

Penman is an LE-oriented method.

\\ LE\_\mathrm{Penman} = f(A, VPD, r_a, r_s) \\

\\ U\_\mathrm{Penman} = A - LE\_\mathrm{Penman} \\

U_Penman is an unresolved remainder. It is not H. Penman is useful for
evaporation or latent-heat comparison, not for a full paired H/LE
solution.

### Monin/Profile diagnostic

Monin/Profile is a profile and stability diagnostic path. It should not
be used as automatic truth or forced closure.

\\ R\_{E,\mathrm{MO}} = Q^\* - B - H\_\mathrm{MO} - LE\_\mathrm{MO} \\

Its value is that R_E,MO remains visible. Its limitation is that the
result is input- and parameter-sensitive and depends strongly on the
quality and meaning of the selected two-height profile.

## Final rule

A heat-flux method should be selected by measurement design and target
quantity. Priestley–Taylor partitions available energy through an
empirical latent-heat formulation. Bulk–Residual estimates sensible heat
from a two-height gradient and defines latent heat as the residual.
Bowen partitions available energy through temperature and humidity
gradients. Penman estimates latent heat and leaves the remaining energy
unresolved. Monin/Profile provides a process-oriented diagnostic and
keeps the residual visible.

## References

[^1]: Priestley, C. H. B., & Taylor, R. J. (1972). *On the Assessment of
    Surface Heat Flux and Evaporation Using Large-Scale Parameters*.
    Monthly Weather Review, 100(2), 81–92. DOI:
    10.1175/1520-0493(1972)100\<0081:OTAOSH\>2.3.CO;2.

[^2]: Bowen, I. S. (1926). *The ratio of heat losses by conduction and
    by evaporation from any water surface*. Physical Review, 27,
    779–787.

[^3]: Ohmura, A. (1982). *Objective Criteria for Rejecting Data for
    Bowen Ratio Flux Calculations*. Journal of Applied Meteorology,
    21(4), 595–598. DOI:
    10.1175/1520-0450(1982)021\<0595:OCFRDF\>2.0.CO;2.

[^4]: Penman, H. L. (1948). *Natural Evaporation from Open Water, Bare
    Soil and Grass*. Proceedings of the Royal Society of London. Series
    A, 193(1032), 120–145. DOI: 10.1098/rspa.1948.0037.

[^5]: Monin, A. S., & Obukhov, A. M. (1954). *Basic laws of turbulent
    mixing in the surface layer of the atmosphere*. Trudy
    Geofizicheskogo Instituta AN SSSR, 24, 163–187.

[^6]: Foken, T. (2006). *50 Years of the Monin–Obukhov Similarity
    Theory*. Boundary-Layer Meteorology, 119, 431–447. DOI:
    10.1007/s10546-006-9048-6.
