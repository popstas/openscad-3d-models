# Repository Guidelines

## Project Structure & Module Organization
- One model per folder: `YYYY-MM-DD-short-slug/` (e.g., `2025-08-24-ecig-platform`).
- Primary source: one `kebab-case.scad` file per folder.
- Exports: optional `.stl` (and images) alongside the `.scad` in the same folder.
- Keep assets local to the model folder; avoid cross-folder imports unless intentional.

## Build, Test, and Development Commands
- Preview in GUI: `openscad 2025-08-24-ecig-platform/ecig-platform.scad`
- Export STL: `openscad -o 2025-08-24-ecig-platform/ecig-platform.stl 2025-08-24-ecig-platform/ecig-platform.scad`
- Override params for variants: `openscad -D wall=2.2 -o out.stl path/to/model.scad`
- Compile (CGAL) in GUI with F6 to catch geometry errors before export.

## Coding Style & Naming Conventions
- Indentation: 2 spaces; no tabs.
- Naming: `snake_case` for variables/modules; `UPPER_SNAKE` for constants; file names in `kebab-case.scad` matching the folder slug.
- Units: millimeters; name variables with units when helpful (e.g., `wall_mm`).
- Structure: prefer `module main()` as the entry point and call `main();` at the end; keep helper modules above or in a separate `*-lib.scad` within the same folder.
- Document top-level parameters with brief comments and sensible defaults.

## Testing Guidelines
- Visual checks: F5 preview for speed, F6 compile for validity; ensure no CGAL errors.
- Dimensional checks: verify key clearances and overall size against real parts; parametrize where practical.
- Printability: export at Z=0, upright orientation, manifold solids only; sanity-check in a slicer.
- If adding tests/assets, include small preview PNGs instead of large renders where possible.

## Commit & Pull Request Guidelines
- Commits: imperative, scoped by model folder. Example: `ecig-platform: increase battery bay clearance +0.4mm`.
- Include what/why and mention adjusted parameters.
- PRs: link related issues (if any), include before/after screenshots or STL diff notes, list key dimensions/clearances, and note print results (material, layer height, fit).
- Keep generated files minimal; commit STLs only for stable releases/variants.
