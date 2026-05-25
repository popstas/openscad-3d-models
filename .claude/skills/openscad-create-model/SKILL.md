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

Before finishing, remove template TODOs, check that filenames match the folder slug, and run the most relevant OpenSCAD render/export command available in the project.
