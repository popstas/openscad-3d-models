# OpenSCAD 3D Models

A collection of small, self‑contained OpenSCAD models organized by date and slug. Each folder contains the source `.scad` and, optionally, exported `.stl` files.

## Requirements
- OpenSCAD (GUI or CLI)
- macOS/Linux/Windows. For Windows paths, set the binary in `.env`.

## Quick start
- Preview a model (GUI): `openscad 2025-08-24-ecig-platform/ecig-platform.scad`
- Export STL (CLI): `openscad -o out.stl path/to/model.scad`
- Batch render all up‑to‑date STLs: `./compile-stl.sh`
  - Configure `.env`: `openscad_path=D:\prog\_3d\OpenSCAD\openscad.exe`

## Project layout
- `YYYY-MM-DD-short-slug/` — one folder per model
  - `model-name.scad` — primary OpenSCAD source
  - `model-name.stl` — optional export (may be git‑ignored)
- `compile-stl.sh` — rebuilds `.stl` when `.scad` is newer
- `AGENTS.md` — contributor guidelines

## Conventions
- Units: millimeters. Use clear parameter names (e.g., `wall_mm`).
- Style: 2‑space indent, `snake_case` for variables/modules, constants in `UPPER_SNAKE`.
- Entry point: prefer `module main()` and call `main();` at the end of the file.

## Tips
- Use F5 (preview) for speed, F6 (CGAL) to validate manifolds before export.
- For variants via CLI: `openscad -D wall=2.2 -o out.stl path/to/model.scad`
- Check printability in your slicer; keep models upright at Z=0.

## Contributing
See `AGENTS.md` for structure, style, testing, and PR guidance.
