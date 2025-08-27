# Mic Transceiver Box (100×35×17 inner) — base + cap

Parametric OpenSCAD model of a small rounded box for a mic/transceiver module.
Inner cavity size: 100×35 mm, inner height: 17 mm. Includes a base (open tray)
and a slip-over cap. Corners are rounded; fit/clearances are configurable.

## Files
- `mic-box.scad` — main model (base + cap)

## Key parameters (mm)
- Inner: `inner_x=100`, `inner_y=35`, `inner_h=17`
- Walls: `wall_th` (base), `bottom_th` (base bottom)
- Corners: `corner_r` (inner radius)
- Cap: `fit_clearance`, `cap_wall_th`, `cap_top_th`, `cap_lip_h`
- Round/Chamfer controls: `radius` via `corner_r`, chamfers via `edge_chamfer_*`

## Test fragments
Set `test_fragment = true` to clip printable corner samples for quick fit tests.
Adjust window via `frag_size`, `frag_index`, `frag_gap_x`, `frag_h_extra`.

## Usage
Preview (GUI):
```bash
openscad 2025-08-26-mic-transiever-box/mic-box.scad
```

Export STL (CLI):
```bash
openscad -o mic-box-base.stl -D print_base=true -D print_cap=false 2025-08-26-mic-transiever-box/mic-box.scad
openscad -o mic-box-cap.stl  -D print_base=false -D print_cap=true  2025-08-26-mic-transiever-box/mic-box.scad
```

Override sizes from CLI, e.g. 2.4 mm walls and 0.28 mm fit:
```bash
openscad -o mic-box-cap.stl \
  -D wall_th=2.4 -D fit_clearance=0.28 -D print_cap=true -D print_base=false \
  2025-08-26-mic-transiever-box/mic-box.scad
```

## Print notes
- Orientation: print the base open side up; print the cap top up.
- First-layer elephant foot can affect fit; tune `fit_clearance` (0.20–0.35 typical).
- Walls ≥2.0 mm recommended; increase if the box needs more rigidity.
- Corner radius affects toolpaths; larger radius improves strength and aesthetics.

## Fragments
- `base` — main tray, inner 100×35×17 mm
- `cap` — slip-over lid with configurable lip depth and clearances

## License
MIT

## Превью

![iso](preview.iso.png)

![xy](preview.xy.png)

![xz](preview.xz.png)

![yz](preview.yz.png)
