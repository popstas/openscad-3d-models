---
name: openscad-check-renders
description: Inspect OpenSCAD preview render images for a model and fix geometry mismatches. Use when the user asks to check renders, compare expected versus actual model shape, review preview.iso.png or preview.xy.png, or diagnose visual problems after SCAD changes.
---

# OpenSCAD Check Renders

## Workflow

1. Open the current render images again even if they were opened earlier. After every SCAD change, assume `preview.iso.png`, `preview.xy.png`, and other render PNGs may have changed.
2. Identify the intended geometry from the README, SCAD parameters, user request, and nearby model context.
3. Compare expected geometry against actual render geometry:
   - Overall dimensions and orientation.
   - Visible missing or extra cutouts.
   - Misaligned holes, frames, pins, ribs, lips, or clips.
   - Unexpected intersections, floating parts, inverted axes, or wrong Z placement.
4. Trace each visual problem back to the responsible variables/modules in the SCAD file.
5. Fix the SCAD with the smallest geometry-preserving change that addresses the mismatch.
6. Regenerate or reopen renders after each fix and repeat until the render matches the expected model.

## Notes

Prefer visual evidence over assumptions. Mention any remaining uncertainty when the expected physical dimensions are not documented.
