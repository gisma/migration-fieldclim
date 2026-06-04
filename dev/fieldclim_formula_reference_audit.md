# fieldClim formula reference audit

## Inspected files

Primary implementation files inspected:

- `R/weather_station.R`
- `R/missing_inputs.r`
- `R/radiation.R`
- `R/solar.R`
- `R/transmittance.R`
- `R/terrain.R`
- `R/soil.R`
- `R/sensible.R`
- `R/latent.R`
- `R/bulk.R`
- `R/turbulent_flux.R`
- `R/turbulence.R`
- `R/utility_turbulent_flux.R`
- `R/energy_balance_closure.R`
- `R/humidity.R`
- `R/pressure.R`
- `R/temperature.R`
- `R/fieldclim_params.R`
- `R/utility.R`
- `R/globals.R`

Tests inspected:

- `tests/testthat/test-equation-contracts.R`
- `tests/testthat/test-helper-equation-contracts.R`
- `tests/testthat/test-physics-contract.R`
- `tests/testthat/test-priestley-taylor-contract.R`
- `tests/testthat/test-priestley-taylor-source-table.R`
- `tests/testthat/test-bulk.R`
- `tests/testthat/test-bulk-exchange-velocity.R`
- `tests/testthat/test-bulk-stability.R`
- `tests/testthat/test-bowen-source.R`
- `tests/testthat/test-monin-obukhov.R`
- `tests/testthat/test-penman.R`
- `tests/testthat/test-penman-source.R`
- `tests/testthat/test-penman-unit-validation.R`
- `tests/testthat/test-radiation-contract.R`
- `tests/testthat/test-soil-contract.R`
- `tests/testthat/test-turbulence.R`
- `tests/testthat/test-turbulent-flux-remaining-coverage.R`
- `tests/testthat/test-weather-station-object-contract.R`
- `tests/testthat/test-weather-station-api-parity.R`
- `tests/testthat/test-energy-balance-closure.R`

Documentation inspected:

- `man/*.Rd`
- `vignettes/*.Rmd`
- `README.md`
- `DESCRIPTION`
- `vignettes/fieldclim-methods.bib`

Rendered HTML and existing figures were not used as evidence.

## Unresolved ambiguities

| Topic | Finding | Status |
|---|---|---|
| Exact Bulk literature support | The Bulk formulas and exchange-velocity variants are implemented and tested, but no package-level citation directly supports the exact combined implementation. | No package-level reference found for exact variant set. |
| Bowen vignette citations | `bowen1926` and `ohmura1982` appear in vignette text but were not found as keys in the inspected bibliography. | Citation-key mismatch. |
| Monin vignette citation | `monin1954` appears in vignette text but was not found as a key in the inspected bibliography. | Citation-key mismatch. |
| `sol_time_formula()` formula provenance | Solar helper documentation cites Bendix (2004), but the exact code expression should remain implementation-derived in formula references. | Possible but unverified reference. |
| Empirical parameter tables | Surface properties, Priestley-Taylor coefficients, surface resistance and soil thermal tables are implemented package parameters. | Some table values have general source context; source validation remains partial. |
| `surface_temp` measurement status | Code uses `surface_temp` as an explicit input to `rad_lw_out()` and `rad_bal()` and does not calculate it. | Treat as model input or provided measurement, depending on user data; not a standard station sensor by package code. |

## Formula-to-function mapping

| Formula / relation | Implemented function(s) | Output field(s) | Test evidence | Notes |
|---|---|---|---|---|
| `A = Q* - B` | `energy_balance_closure()`, flux formulas | `available_energy` in closure output | `test-energy-balance-closure.R`, `test-physics-contract.R` | `Q*` maps to `rad_bal`, `B` maps to `soil_flux`. |
| `R_E = Q* - B - H - LE` | `energy_balance_closure()` | `closure_residual` | `test-energy-balance-closure.R` | Paired methods only; Penman uses unresolved complement. |
| `closure_ratio = (H + LE) / A` | `energy_balance_closure()` | `closure_ratio` | `test-energy-balance-closure.R` | Ratio withheld near low available energy. |
| `Q* = R_sw + L*` | `rad_bal()` | return vector | `test-equation-contracts.R`, radiation tests | Longwave terms are radiation, not sensible heat. |
| `R_sw = SW_in - SW_out + D_in - D_out` | `rad_sw_bal()` | return vector | `test-equation-contracts.R` | Uses direct and diffuse shortwave components. |
| `L* = L_down - L_up` | `rad_lw_bal()` | return vector | `test-equation-contracts.R` | `L_up` can be modelled from `surface_temp`. |
| `L_down = epsilon_air sigma T_air,K^4 sky_view` | `rad_lw_in()` | return vector | radiation tests | Air emissivity from vapour pressure and air temperature. |
| `L_up = epsilon(surface_type) sigma T_s,K^4` | `rad_lw_out()` | return vector | radiation tests | `surface_temp` is an explicit input. |
| `B = -lambda (T1 - T2)/(z1 - z2)` | `soil_heat_flux()` | return vector | `test-equation-contracts.R`, soil tests | Invalid depths return row-local `NA`. |
| `LE_PT = alpha sc/(sc+gam) A` | `latent_priestley_taylor()` | `latent_priestley_taylor` | PT tests | `sc`/`gam` are package-scale helpers. |
| `H_PT = A - LE_PT` equivalent | `sensible_priestley_taylor()` | `sensible_priestley_taylor` | PT tests | Implemented as explicit coefficient expression. |
| `H_bulk = rho cp (t1 - t2)/r_a` | `sensible_bulk()` | `sensible_bulk` | Bulk tests | Default `rho` and `cp` are fixed unless user overrides. |
| `r_a = log(z2/z1)/(k u_mean)` | `sensible_bulk(exchange_velocity = "wind_mean")` | `sensible_bulk` | Bulk tests | `u_mean = v1` or `(v1 + v2)/2`. |
| `u* = k(v2-v1)/log(z2/z1)` | `sensible_bulk(exchange_velocity = "u_star_profile")` | `sensible_bulk` | `test-bulk-exchange-velocity.R` | Non-positive `u*` rows become `NA`. |
| `u* = k u_ref/log(z_ref/z0)` | `sensible_bulk(exchange_velocity = "u_star_roughness")` | `sensible_bulk` | `test-bulk-exchange-velocity.R` | `z0` from `surface_type` or `obs_height`. |
| `Ri_g = g/theta_mean * dtheta_dz/du_dz^2` | `sensible_bulk(stability_method = "ri_guard")` | attributes on `sensible_bulk` result | `test-bulk-stability.R`, equation tests | Guard filters invalid/very stable rows; no correction. |
| `LE_res = Q* - B - H_bulk` | `latent_bulk_residual()` | `latent_bulk_residual` | Bulk and physics tests | Algebraic residual closure. |
| `beta = gamma_code dtheta_dz/dah_dz` | `bowen_ratio()`, `sensible_bowen()`, `latent_bowen()` | beta internal, `sensible_bowen`, `latent_bowen` | Bowen tests | Uses potential temperature and absolute humidity gradients. |
| `H_BR = beta/(1+beta) A` | `sensible_bowen()` | `sensible_bowen` | Bowen tests | Finite uncapped cases close. |
| `LE_BR = 1/(1+beta) A` | `latent_bowen()` | `latent_bowen` | Bowen tests | Capped cases are not required to close. |
| Penman LE combination equation | `latent_penman()` | `latent_penman` | Penman tests | VPD is kPa-scale; output is W m-2. |
| `U_Penman = A - LE_Penman` | `energy_balance_closure()` | `unresolved_complement` | closure tests | Complement is not sensible heat. |
| `H_MO` profile-gradient expression | `sensible_monin()` | `sensible_monin` | Monin tests | Uses profile/stability helper logic, not force-closed. |
| `LE_MO` profile-gradient expression | `latent_monin()` | `latent_monin` | Monin tests | Moisture-gradient based. |
| `R_E,MO = A - H_MO - LE_MO` | `energy_balance_closure()` | `closure_residual` | closure tests | Diagnostic residual. |

## Test contract extraction

| Test file | Test name / group | Function(s) | Expected formula or relation | Tolerance | Verifies | Does not verify |
|---|---|---|---|---|---|---|
| `test-equation-contracts.R` | radiation balance functions follow component balance equations | `rad_bal`, `rad_sw_bal`, `rad_lw_bal` | `Q* = (SW_in - SW_out + D_in - D_out) + (L_down - L_up)` | `1e-8` | Component arithmetic | Empirical radiation accuracy |
| `test-equation-contracts.R` | soil_heat_flux follows documented conductive flux equation | `soil_heat_flux` | `B = -lambda (T1-T2)/(z1-z2)` | `1e-10` | Conductive formula | Table-source validity |
| `test-equation-contracts.R` | Priestley-Taylor functions follow documented partition | PT functions | `LE = alpha sc/(sc+gam) A`, `H + LE = A` | `1e-10` | Implemented partition | Empirical alpha validity |
| `test-equation-contracts.R` | Bulk-Residual functions follow neutral resistance and residual equations | Bulk functions | `H_bulk`, `LE_res = Q* - B - H_bulk` | `1e-10` | Neutral resistance and residual contract | Physical adequacy of Bulk |
| `test-equation-contracts.R` | Bulk Richardson guard attributes follow documented Ri equation | `sensible_bulk` | `Ri_g` attribute formula and classes | `1e-12` | Guard attribute contract | Stability correction adequacy |
| `test-equation-contracts.R` | Bowen functions follow documented beta partition | Bowen functions | beta partition | `1e-10` | Finite uncapped closure | Reliability under weak gradients |
| `test-equation-contracts.R` | latent_penman follows documented kPa VPD combination equation | `latent_penman` | Penman equation with kPa VPD | `1e-10` | Unit-scale contract | Empirical Penman validation |
| `test-physics-contract.R` | positive soil heat flux lowers available turbulent energy | accounting | `A = Q* - B` | exact comparison | Sign convention | Measurement validity |
| `test-physics-contract.R` | PT closes positive and negative cases | PT functions | `H + LE = A` | `1e-8` | Closure across signs | Source validation |
| `test-physics-contract.R` | Bulk contracts preserve sign, closure, and low-wind control | Bulk functions | Positive `t1-t2` gives positive H; residual closure; low wind NA | `1e-12` | Sign and guard behaviour | Flux realism |
| `test-physics-contract.R` | Bowen cap controls near-singular cases without requiring closure | Bowen functions | Capped case finite, not exact closure | `1e-8` negative assertion | Cap semantics | Best cap selection |
| `test-physics-contract.R` | Penman returns LE only | `latent_penman` | no `sensible_penman` | structural | LE-only semantics | Closure inference |
| `test-physics-contract.R` | Monin outputs remain diagnostic | `turb_flux_calc`, Monin fields | Monin fields exist and are not forced to close | structural | Diagnostic semantics | MOST adequacy |
| `test-energy-balance-closure.R` | closure diagnostics tests | `energy_balance_closure`, plotting | method-specific residuals, complements, plot filters | mostly exact | Closure-output semantics | Physical validation |
| `test-weather-station-object-contract.R` | weather_station object tests | `build_weather_station`, `as.data.frame` | stores flat fields; omits NULL | exact | Container contract | Unit validity |
| `test-missing-data*` / convenience tests | inspection-only checks | `inspect_weather_station_inputs` | missingness/gaps/QC, no mutation | exact/structural | Inspection behaviour | Data repair |

## Reference mapping table

| Method / topic | Formula or concept | Source cited in package docs | Where cited | Citation key if available | DOI / URL if available | Support status |
|---|---|---|---|---|---|---|
| Radiation helpers | SW/LW balance, solar/transmittance/terrain helpers | Bendix 2004 | Roxygen/man for radiation, solar, terrain, transmittance | `bendix2004` | none recorded in bib entry | supports general method family |
| Soil heat flux | Conductive gradient equation and soil tables | Bendix 2004 | `soil_heat_flux.Rd`, `R/soil.R` | `bendix2004` | none recorded | supports implemented formula |
| Priestley-Taylor | PT available-energy latent partition | Foken 2016 in man text; Priestley and Taylor 1972 in vignettes | `latent_priestley_taylor.Rd`, theory vignette | `priestley1972`; no `foken2016` key found | `priestley1972` DOI in bib | supports general method family |
| `sc()`/`gam()` | Foken/Stull table-scale coefficients | Foken/Stull table text | `R/utility_turbulent_flux.R`, tests | `stull1988`; no `foken2013` key found | none recorded for Stull | code comment reference |
| Bulk sensible | Neutral aerodynamic resistance and exchange variants | No direct package-level source found for full variant set | `sensible_bulk.Rd` documents formulas | none | none | missing reference |
| Bulk Richardson guard | Gradient Richardson diagnostic | Bendix 2004 | `R/bulk.R`, `turb_flux_grad_rich_no.Rd` | `bendix2004` | none recorded | supports general method family |
| Roughness helpers | Roughness length and displacement parameterizations | Bendix 2004 | `turb_roughness_length.Rd`, `turb_displacement.Rd` | `bendix2004` | none recorded | supports general method family |
| Bowen ratio | Potential-temperature / absolute-humidity gradient ratio | Bendix 2004; Bowen/Ohmura in theory text | R/man, theory vignette | `bendix2004`; missing `bowen1926`, `ohmura1982` | none for missing keys | supports implemented formula for Bendix citation; missing references for vignette keys |
| Penman | Penman-type latent heat | Penman 1948; Foken/Monteith text | bibliography, vignettes, man text | `penman1948`, `monteith2013` | Penman DOI recorded in bib | supports general method family |
| Monin/Profile | Profile/stability terms, Businger-type helpers | Bendix 2004; Foken 2016 text; MOST refs in vignettes | R/man, vignettes | `bendix2004`, `foken2006`; missing `monin1954` | none for Bendix; Foken DOI in bib | supports general method family |
| Energy-balance closure diagnostics | Diagnostic residuals and ratios | Package implementation and tests | `R/energy_balance_closure.R`, tests | none | none | code comment reference / implementation contract |
| Missing-data inspection | Missingness/gap/QC reporting | Package implementation | `R/missing_inputs.r`, man | none | none | code comment reference |

## Citation key inventory

| Citation key | Full reference summary | Used for | Files where cited or available | DOI / URL | Notes |
|---|---|---|---|---|---|
| `bendix2004` | Bendix, Weather and Climate: An Introduction | Radiation, soil, pressure/humidity helpers, turbulence helpers | `vignettes/fieldclim-methods.bib`, many R/man references | none recorded | Primary package method-background source. |
| `penman1948` | Penman 1948 natural evaporation | Penman method family | bibliography, theory vignette | DOI recorded in bib | General method reference. |
| `priestley1972` | Priestley and Taylor 1972 | Priestley-Taylor method family | bibliography, theory vignette | DOI recorded in bib | General method reference. |
| `foken2008closure` | Foken closure problem paper | Closure/background | bibliography | DOI recorded | General closure context. |
| `foken2008book` | Foken micrometeorology book | General micrometeorology | bibliography | none recorded | Available bibliography source. |
| `foken2006` | Foken MOST review | MOST theory context | bibliography, m2m/theory context | DOI recorded | General method family, not full implementation validation. |
| `stull1988` | Stull boundary layer meteorology | PT helper coefficient context | bibliography; helper docs mention Stull | none recorded | Table-scale context. |
| `monteith2013` | Monteith and Unsworth environmental physics | Penman/general environmental physics | bibliography; man text mentions Monteith/Unsworth | none recorded | General method reference. |
| `brutsaert1982` | Evaporation into the atmosphere | Surface-layer/evaporation context | bibliography | none recorded | General context. |
| `garratt1992` | Atmospheric boundary layer | Boundary-layer context | bibliography | none recorded | General context. |
| `arya2001` | Introduction to micrometeorology | Micrometeorology context | bibliography | none recorded | General context. |
| `oke1987` | Boundary layer climates | Urban/surface context | bibliography | none recorded | General context. |
| `allen1998` | FAO56 crop evapotranspiration | Evapotranspiration context | bibliography | URL recorded | General context; implementation uses package-specific Penman contract. |
| `wilson2002` | Energy balance closure at FLUXNET sites | Closure context | bibliography | DOI recorded | Empirical closure context, not implementation formula. |
| `billesbach2024` | eddy4R | EC processing context | bibliography | DOI recorded | Context only. |
| `mauder2024` | REddyProc | EC/gap-processing context | bibliography | DOI recorded | Context only. |

## Duplicate or missing citation keys

- `bowen1926` is cited in vignette text but was not found in
  `vignettes/fieldclim-methods.bib`.
- `ohmura1982` is cited in vignette text but was not found in
  `vignettes/fieldclim-methods.bib`.
- `monin1954` is cited in vignette text but was not found in
  `vignettes/fieldclim-methods.bib`.
- Roxygen/man references often cite “Foken 2016” and “Foken 2013” as text, but
  the inspected bibliography contains `foken2008book`, `foken2008closure`,
  `foken2012ec` and `foken2006`, not `foken2016` or `foken2013`.
- No duplicate bibliography keys were observed from the `@...{key,` scan.

## Documentation mismatches and recommended corrections

| Area | Mismatch | Correction |
|---|---|---|
| Vignette citations | Missing `.bib` entries for several conceptual citations. | Add entries or revise to available keys. |
| Bulk reference status | Docs correctly state neutral approximation, but exact variant references are not mapped to bibliography. | Mark as implemented/tested package method; avoid source-overclaim. |
| Penman complement | Some user-facing summaries must maintain `unresolved_complement` wording. | Keep “Penman provides LE only; complement remains unresolved.” |
| Monin/Profile | Workflow text should maintain diagnostic residual wording. | Avoid suggesting balance normalization. |
| Longwave vs sensible heat notation | Tutorial `L_*` variables can be confused with longwave `L`. | Always map `L_*` to `H` and reserve `L_down`, `L_up`, `L*` for radiation. |

## Self-check

- Every formula in `fieldclim_formula_reference.qmd` is linked to an
  implemented function or explicitly labelled conceptual.
- H/LE mappings follow package output columns.
- `L_down`, `L_up` and `L*` are separated from `H`.
- `Q*`, `B`, `A` and `R_E` are used consistently.
- Guards and NA rules are documented at method-family level.
- Closure claims are phrased as implementation semantics, not validation.
- Penman is described as LE-only.
- Monin/Profile is described as diagnostic and not force-closed.
- Bulk-Residual closure is described as algebraic by definition.
- Code variables are preserved.
- References are harvested from package documentation and bibliography.
- Missing references are marked explicitly.
