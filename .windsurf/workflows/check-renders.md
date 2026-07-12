---
description: Check png renders to find errors
auto_execution_mode: 3
---

Numbers first: read `<model>.geometry.json` (minZ ~0, parts count, dims vs README, cgal.warnings empty, expected.mismatches). Then check preview.iso.png, preview.xy.png and `<model>.cut-x/y/z.png` cross-sections (10mm grid) for wall thickness and pockets. Open images again even if opened previously — after each scad change pngs also change. Regenerate with `npm run render -- models/<folder>`. Analyze expected geometry vs actual. Find errors, fix scad