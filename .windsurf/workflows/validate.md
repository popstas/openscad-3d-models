---
description: Check model
auto_execution_mode: 3
---

Read `<model>.geometry.json` first (regenerate: `npm run render -- models/<folder>`): minZ must be ~0, parts count and dims must match README, cgal.manifold true, cgal.warnings empty, expected.ok true. Build expected-vs-actual dims table. Create technical description of whole model. Then find each module in scad file. Check for suspicious numbers. Check for hardcoded numbers without variables. Recommend expected_dims/expected_parts literals when absent. Suggest fixes.