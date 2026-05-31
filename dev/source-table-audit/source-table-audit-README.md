# Source-table audit notes

## Purpose

This note records the current source status of hard-coded empirical tables, coefficients and method parameterizations in `fieldClim`.

The audit separates three levels:

1. implementation consistency;
2. source support from the available Bendix and Foken textbooks;
3. remaining package-specific mappings or shortcuts.

This is not a new physical validation against measurements. It records which tables and constants can be linked to the available textbook material and which items remain package-specific.

## Current technical status

The package now has contract tests for:

- documented method equations;
- documented helper equations;
- guard and edge-case behaviour;
- `weather_station` API parity;
- `turb_flux_calc()` workflows.

The tests verify that the implementation matches the documented equations and wrapper logic. They do not independently validate all inherited empirical coefficients and lookup tables against primary sources.

## Source status after checking Bendix and Foken

### Strong textbook support found

The available Bendix material supports several previously unclear table and coefficient groups.

The precipitable-water reference table used by `hum_precipitable_water()` is present in Bendix. The table gives standard-atmosphere values for `T0` and `pwSt` for tropics, mid-latitude summer/winter and subarctic summer/winter. It also gives the scaling relation `pw = pwSt * (p / p0) * (T0 / T)^0.5`.

The radiation/transmittance formulas for Rayleigh scattering, ozone absorption, water-vapour absorption and gas absorption are present in Bendix. The constants used in the package formulas can be traced to that section.

The aerosol-transmittance table is present in Bendix. The visibility classes, `tau38`, `tau50` values and empirical expression used by `trans_aerosol()` are supported by the Bendix appendix material.

The soil thermal conductivity and heat-capacity tables for sand, clay and peat are present in Bendix. The package values for moisture, thermal conductivity and volumetric heat capacity correspond to the appendix table structure.

The Bowen-ratio equation using heat-capacity density, latent heat of vaporization, temperature difference and absolute-humidity difference is present in Bendix. This supports the internal `bowen_ratio()` helper form based on `Ca / Lv`.

The humidity and thermodynamic helper formulas for specific humidity, absolute humidity, latent heat of vaporization, potential temperature and heat-capacity density are present in Bendix.

The Priestley-Taylor equations and the table values for `gamma` and `sc` are present in Foken. Foken also gives the usual Priestley-Taylor coefficient around 1.25 for water-saturated surfaces and the Penman method context.

### Partly supported, but not one-to-one package tables

The `surface_properties` table is partly supported. Bendix provides albedo and emissivity values for several surface types, but the package table combines its own surface classes with albedo, emissivity and roughness length. The roughness-length column and package-specific class mapping are not fully covered by that Bendix table.

The `priestley_taylor_coefficient` table is partly supported. Foken supports the Priestley-Taylor method and the common coefficient around 1.25 for water-saturated surfaces, but the package-specific alpha values by surface class are not fully matched as a source table.

The Penman method is supported at the method-family level by Foken, and the package Penman correction now fixes a clear vapour-pressure unit issue. However, the package `surface_resistance` table and alias mapping are not matched one-to-one to a source table in the two checked textbooks.

The Monin-Obukhov/Profile and Businger-type parameterizations are partly supported by Foken. Foken supports the flux-gradient and turbulent-Prandtl context, but the full package-specific constant set and branch logic should be cited carefully and not overclaimed as a complete one-to-one source match unless the exact section is checked.

The exported Bowen `gamma_code = 0.00066 * (1 + 0.000946 * t1)` remains package-specific in the current source status. Bendix supports the Bowen-ratio formulation using `Ca / Lv`, but the shortcut coefficient in the exported Bowen functions is not directly proven equivalent by the checked textbook material.

### Remaining package-specific or policy items

The following items should remain documented as implementation choices unless a more exact source is added later:

- package surface-class mappings;
- roughness-length values in `surface_properties`;
- package-specific Priestley-Taylor alpha values by surface class;
- Penman surface-resistance classes and aliases;
- exported Bowen `gamma_code`;
- complete latent Monin/Profile constant set and branch logic;
- diagnostic thresholds such as `+/-600 W m-2`.

## Recommended documentation policy

Use precise but restrained language.

Preferred wording:

```text
The implemented equations, helper equations, wrapper behaviour and numerical edge cases are covered by tests. Several inherited empirical tables and coefficients were inventoried and many can be traced to Bendix or Foken. Some package-specific mappings and shortcut coefficients remain documented as implementation choices rather than independently revalidated source tables.
```

Avoid wording that suggests the package is physically fully validated against measurements.

Avoid wording that exaggerates the open items as if the package physics were broadly unsupported.

## Recommended code documentation policy

In roxygen documentation, cite the generic source where a table or formula is supported, but do not overstate one-to-one validation.

Examples:

```r
#' @references Bendix (2004), appendix material on standard-atmosphere
#' precipitable-water values and atmospheric transmittance approximations.
```

```r
#' @references Bendix (2004), appendix material on soil thermal properties
#' for sand, clay and peat.
```

```r
#' @references Foken (2016), Priestley-Taylor equations and table of
#' temperature-dependent `gamma` and `sc` values.
```

```r
#' @details The implemented Bowen beta path uses the fieldClim coefficient
#' `gamma_code = 0.00066 * (1 + 0.000946 * t1)`. Bendix (2004) supports the
#' Bowen-ratio formulation based on heat-capacity density, latent heat of
#' vaporization, temperature difference and absolute-humidity difference.
#' The equivalence of this exported shortcut coefficient is not asserted here.
```

## Practical follow-up

The next step should not change formulas.

The next step is to add generic but accurate roxygen references to the relevant functions, aligned with the source status above.

Do not replace tables or coefficients unless a separate source-validation task proves a mismatch and explicitly decides a replacement.
