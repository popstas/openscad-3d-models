---
description: Create new openscad model from template
auto_execution_mode: 3
---

1. Create project from template
- [ ] Define model long name and short name
- [ ] Run `npm run create-project` with arguments
What happens:**
- Creates folder structure: `YYYY-MM-DD-long-name/`
- Generates README.md with model description and fragments
- Creates main short-name.scad file with proper OpenSCAD structure
- Example: `npm run create-project long-name short-name default "One-line description"`

2. Make final model
- [ ] Ask for all needed dimensions and sizes
- [ ] Fill README.md of the model with fragment descriptions
- [ ] Create scad model code with proper structure, change all TODO lines
- [ ] Entry point is `main()` called at the end (never `module render()` — shadows the OpenSCAD builtin)
- [ ] Declare `expected_dims = [x, y, z];` and `expected_parts = N;` literals for auto-verification
- [ ] Render STL + previews: `npm run render -- models/<folder>` — must print `EXPECT OK`, no `NOTE: model bottom at z=...`
- [ ] Check `<model>.geometry.json` (minZ ~0, parts/dims match README) and `<model>.cut-*.png` cross-sections
