---
name: openscad-validate
description: Review an OpenSCAD model for technical completeness and maintainability. Use when the user asks to validate, audit, review, or check a SCAD model for module structure, suspicious dimensions, hardcoded numbers, missing variables, or mismatches with the README.
---

# OpenSCAD Validate

## Workflow

Numbers first, pixels second: the render pipeline writes a machine-readable
report next to each model — trust it over eyeballing preview images.

1. Ensure render artifacts are fresh: run `npm run render -- models/<folder>` if
   `<model>.geometry.json` is missing or older than the SCAD file.
2. Read `<model>.geometry.json` and check:
   - `minZ` must be ~0 — a non-zero value means the part floats above the build plate.
   - `parts` count must equal the number of separate printed parts documented in the
     README (note: a fully enclosed internal void also counts as a part — usually a bug).
   - Each part's `dims` must match README/SCAD parameters within tolerance; watch for
     stray tiny parts (debris from bad booleans, `volume_cm3` near 0).
   - `cgal.manifold` must be `true`; `cgal.warnings` must be empty — an
     "unknown variable" warning means geometry silently disappeared.
   - `expected` (when declared): `ok` must be true; report every mismatch.
3. Read the model README and SCAD file. Create a concise technical description of
   the whole model:
   - Purpose.
   - Main printed parts/fragments.
   - Key dimensions and clearances.
   - Expected print orientation or fit constraints when documented.
4. Build an expected-vs-actual table: each key dimension from README/SCAD parameters
   vs the actual value from `geometry.json` (dims, per-part dims), with a verdict per row.
5. Find each module in the SCAD file and describe what it contributes to the model.
6. Check for suspicious numbers:
   - Hardcoded dimensions inside modules.
   - Repeated numeric literals that should be named variables.
   - Offsets, tolerances, and clearances that are not explained.
   - Values that conflict with README dimensions or top-level parameters.
7. Check required project conventions:
   - `description = "...";` near the top.
   - `use <../modules.scad>;`.
   - Required `$fn`, `$fa`, `$fs`, `pin_fs`, and service parameters.
   - Top-level modules only.
   - Separate modules for separate fragments/details.
   - `main()` entry point called at the end (canonical for new models; legacy
     `show_all()` or `render()` is acceptable in existing models, but flag
     `module render()` in new code — it shadows the OpenSCAD builtin).
   - `test_fragment` support when the model uses fragment clipping.
   - Recommend declaring `expected_dims`/`expected_parts` literals when absent —
     the render pipeline then verifies geometry automatically (EXPECT OK/MISMATCH).
8. Suggest concrete fixes, including variable names and likely replacement expressions.

## Output

Lead with issues ordered by severity. Include file and line references when possible, then the expected-vs-actual table from step 4, then a short summary of the model structure.
