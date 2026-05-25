---
name: openscad-validate
description: Review an OpenSCAD model for technical completeness and maintainability. Use when the user asks to validate, audit, review, or check a SCAD model for module structure, suspicious dimensions, hardcoded numbers, missing variables, or mismatches with the README.
---

# OpenSCAD Validate

## Workflow

1. Read the model README and SCAD file.
2. Create a concise technical description of the whole model:
   - Purpose.
   - Main printed parts/fragments.
   - Key dimensions and clearances.
   - Expected print orientation or fit constraints when documented.
3. Find each module in the SCAD file and describe what it contributes to the model.
4. Check for suspicious numbers:
   - Hardcoded dimensions inside modules.
   - Repeated numeric literals that should be named variables.
   - Offsets, tolerances, and clearances that are not explained.
   - Values that conflict with README dimensions or top-level parameters.
5. Check required project conventions:
   - `description = "...";` near the top.
   - `use <../modules.scad>;`.
   - Required `$fn`, `$fa`, `$fs`, `pin_fs`, and service parameters.
   - Top-level modules only.
   - Separate modules for separate fragments/details.
   - `show_all()` or `main()` entry point called at the end.
   - `test_fragment` support when the model uses fragment clipping.
6. Suggest concrete fixes, including variable names and likely replacement expressions.

## Output

Lead with issues ordered by severity. Include file and line references when possible, then a short summary of the model structure.
