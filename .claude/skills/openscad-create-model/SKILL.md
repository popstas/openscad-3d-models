---
name: openscad-create-model
description: Create a new project folder for an OpenSCAD 3D model in this repository. Use when the user asks to create, scaffold, start, or implement a new model, including choosing a long model name, short kebab-case SCAD filename, README, model fragments, and template-generated project structure.
---

# OpenSCAD Create Model

## Workflow

1. Read `AGENTS.md` and inspect 2-3 existing model README files before creating a new model.
2. Define the model long name and short name:
   - Use a descriptive kebab-case long name for the dated folder.
   - Use a short kebab-case name for the main `.scad` file.
3. Run the project generator (the optional 4th argument fills `description = "...";` —
   without a description the model is hidden from the models index):

```bash
npm run create-project long-name short-name default "One-line model description"
```

4. Ask for or infer the dimensions needed for the physical object before final geometry work.
5. Write the model `README.md` first:
   - Describe the model purpose.
   - List every fragment/detail that will exist in the SCAD file.
   - Record key dimensions, clearances, and print assumptions.
6. Implement the SCAD file:
   - Add `description = "...";` near the top with a one-line model description.
   - Keep all tunable dimensions as named variables near the top.
   - Use `use <../modules.scad>;`.
   - Keep all modules at top scope; do not define inline modules.
   - Create separate modules for each fragment/detail.
   - Provide `main()` as the entry point and call it at the end. Legacy models may use
     `show_all()`; never define `module render()` in new code — it shadows the OpenSCAD
     builtin `render()`.
   - Support `test_fragment` clipping through `intersection()` when appropriate.

## Reusable modules (models/modules.scad)

Prefer these over hand-rolled geometry, ordered by how often models use them:

- `rounded_prism(size=[x,y], h, r, kr)` — rounded box; `kr>0` also rounds edges via minkowski
- `clip_for_fragments()` — wrap the entry point to support `test_fragment` corner clipping
- `upside_down(h)` — flip a part for printing
- `clip_for_fragments_bbox(L, W, H, ...)` — corner clipper for explicit bounding boxes
- `rounded_rect(size=[x,y], r)` / `rounded_rect_aniso(w, h, rx, ry)` — 2D rounded rectangles
- `rr_extrude(size=[x,y], r, h)` — extruded rounded rectangle
- `chamfer_rr_extrude(size=[x,y], h, r, ch)` — extruded rounded rect with bottom chamfer
- `rounded_prism_with_pocket(size, h, r, kr, wall_th, h_th, pocket_r)` — box minus inner
  pocket (`pocket_r<0` → outer `r`; `pocket_r=0` → sharp corners)
- `chamfer_ring(d_outer, d_inner, h, chamfer)` — ring with top outward chamfer
- helpers: `clamp()`, `clamp_chz()`, `clamp_chxy()`, `eps()`, `fs_pin()`

## Completion

Before finishing, remove template TODOs and check that filenames match the folder slug.

Then render the STL and the four preview images. The generator only writes 1×1
placeholder PNGs — render the real ones with the one-shot render command (single source
of truth for cameras/sizes is `PNG_VIEWS` in `src/render-core.ts`):

```bash
npm run render -- models/<folder>
```

The STL export log must report `Simple: yes` (manifold check). Read the rendered PNGs and
confirm the geometry matches the README before declaring done. The command also regenerates
the global `models/README.md` index — that index is auto-generated, so don't hand-edit it.

`npm run watch` is the continuous alternative: it rebuilds on every save and keeps the
index fresh. Use `npm run render:all` to rebuild every outdated model once
(`-- --force` to rebuild everything, e.g. after editing `modules.scad`).
