---
name: openscad-check-renders
description: Inspect OpenSCAD preview render images for a model and fix geometry mismatches. Use when the user asks to check renders, compare expected versus actual model shape, review preview.iso.png or preview.xy.png, or diagnose visual problems after SCAD changes.
---

# OpenSCAD Check Renders

## Workflow

Numbers first, pixels second: start from the machine-readable render report,
then use images to locate what the numbers flagged.

1. Read `<model>.geometry.json` (regenerate with `npm run render -- models/<folder>`
   if missing/stale) and check before looking at any image:
   - `minZ` ~0 — otherwise the part floats above the build plate (invisible in
     previews because of `--viewall --autocenter`).
   - `dims` and per-part `dims` vs README/SCAD parameters.
   - `parts` count vs the intended number of printed parts; tiny extra parts are
     boolean debris, a missing part means a fragment was silently dropped.
   - `cgal.warnings` — "unknown variable" means geometry silently disappeared;
     non-manifold warnings mean broken booleans.
   - `expected.mismatches` when the model declares `expected_dims`/`expected_parts`.
2. Open the render images again even if they were opened earlier. After every SCAD
   change, assume all PNGs changed:
   - `preview.iso/xy/xz/yz.png` — exterior camera views (bbox overlay bottom-left).
   - `<model>.cut-x/y/z.png` — cross-sections through the bbox middle: use these to
     verify wall thickness, pocket depth, internal cavities and clearances. Grid step
     is 10 mm; the darker line marks coordinate 0.
3. Identify the intended geometry from the README, SCAD parameters, user request, and nearby model context.
4. Compare expected geometry against actual render geometry:
   - Overall dimensions and orientation.
   - Visible missing or extra cutouts.
   - Misaligned holes, frames, pins, ribs, lips, or clips.
   - Unexpected intersections, floating parts, inverted axes, or wrong Z placement.
   When a detail is ambiguous at full size, zoom into the specific PNG region instead
   of judging from the overview.
5. Trace each visual problem back to the responsible variables/modules in the SCAD file.
6. Fix the SCAD with the smallest geometry-preserving change that addresses the mismatch.
7. Regenerate renders after each fix with `npm run render -- models/<folder>` (or rely on a running `npm run watch`) and repeat until both the numbers (step 1) and the images match the expected model.

## Notes

Prefer measured evidence (geometry.json, cut views with the 10 mm grid) over
impressions from perspective views. Mention any remaining uncertainty when the
expected physical dimensions are not documented.
