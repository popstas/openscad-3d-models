---
name: openscad-simplify
description: Simplify an OpenSCAD model without changing its geometry. Use when the user asks to simplify SCAD code, reduce duplication, replace local geometry code with modules from modules.scad, or make a model easier to maintain while preserving rendered output.
---

# OpenSCAD Simplify

## Workflow

1. Read the target `.scad` file and `modules.scad`.
2. Identify repeated or overly complex geometry that can be expressed more directly without changing dimensions:
   - Repeated holes, ribs, pins, clips, chamfers, frames, or cutouts.
   - Boolean blocks that can be grouped into named top-level modules.
   - Magic offsets that duplicate existing variables.
3. Look for reusable modules in `modules.scad` that can replace local code.
   Most useful, ordered by how often models use them: `rounded_prism`,
   `clip_for_fragments`, `upside_down`, `clip_for_fragments_bbox`, `rounded_rect`,
   `rr_extrude`, `chamfer_rr_extrude`, `rounded_prism_with_pocket`, `rounded_rect_aniso`,
   `chamfer_ring`, plus helpers `clamp`/`clamp_chz`/`clamp_chxy`/`eps`/`fs_pin`.
   Do not introduce modules from the DEPRECATED section at the end of `modules.scad`.
4. Preserve behavior:
   - Do not change model dimensions, clearances, placement, orientation, or `test_fragment` behavior unless the user asks.
   - Keep all modules at top scope.
   - Keep variables in `snake_case` and all dimensions in millimeters.
5. Apply small refactors:
   - Extract top-level modules for repeated fragments.
   - Replace duplicated numeric expressions with named variables.
   - Use list-driven loops for repeated positions when clearer.
6. Verify with `npm run render -- models/<folder>` (forced one-shot STL + previews) and compare the relevant preview images if they exist.

## Output

Summarize what was simplified and explicitly call out that geometry was intended to remain unchanged.
