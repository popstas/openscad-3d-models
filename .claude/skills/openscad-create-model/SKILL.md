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
3. Run the project generator:

```bash
npm run create-project long-name short-name
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
   - Provide `show_all()` or `main()` as the entry point and call it at the end.
   - Support `test_fragment` clipping through `intersection()` when appropriate.

## Completion

Before finishing, remove template TODOs and check that filenames match the folder slug.

Then export the STL and render the four preview images. The generator only writes 1×1
placeholder PNGs — render the real ones. The canonical camera params live in `src/watch.ts`
(`PNG_VIEWS`); replicate them for a one-shot render:

```bash
# manifold check (expect "Simple: yes")
openscad -o NAME.stl NAME.scad
# previews (run per view): VIEW/PROJ/CAMERA =
#   iso p 0,0,0,55,0,25,500 | xy o 0,0,0,0,0,0,500 | xz p 0,0,0,90,0,0,500 | yz p 0,0,0,0,90,0,500
openscad -o preview.VIEW.png --imgsize=1200,900 --projection=PROJ \
  --camera=CAMERA --render --viewall --autocenter --view=axes NAME.scad
```

Read the rendered PNGs and confirm the geometry matches the README before declaring done.
`npm run watch` (a continuous watcher, no one-shot flag) regenerates STL + previews and the
global `models/README.md` index — that index is auto-generated, so don't hand-edit it.

If the previews aren't rendering/updating, start `npm run watch` in the background and let it
regenerate them; the project's normal workflow expects the watcher to be running.
