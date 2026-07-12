// Tests for STL analysis and geometry validation helpers:
// node --import tsx --test src/stl-analysis.test.ts
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parseStlText, analyzeTriangles, Vec3 } from './stl-analysis';
import { parseCgalStats, parseExpected, checkExpected } from './render-core';
import { sliceSegments } from './stl-slice';

// Build ASCII STL text for an axis-aligned cuboid with outward-facing winding
function cuboidStl(origin: Vec3, size: Vec3): string {
  const [x0, y0, z0] = origin;
  const [x1, y1, z1] = [x0 + size[0], y0 + size[1], z0 + size[2]];
  // 8 corners
  const p = (x: number, y: number, z: number) => [x, y, z] as Vec3;
  const c = [
    p(x0, y0, z0), p(x1, y0, z0), p(x1, y1, z0), p(x0, y1, z0), // bottom 0-3
    p(x0, y0, z1), p(x1, y0, z1), p(x1, y1, z1), p(x0, y1, z1), // top 4-7
  ];
  // faces as vertex index triples (CCW seen from outside)
  const faces = [
    [0, 2, 1], [0, 3, 2], // bottom (normal -Z)
    [4, 5, 6], [4, 6, 7], // top (+Z)
    [0, 1, 5], [0, 5, 4], // front (-Y)
    [2, 3, 7], [2, 7, 6], // back (+Y)
    [3, 0, 4], [3, 4, 7], // left (-X)
    [1, 2, 6], [1, 6, 5], // right (+X)
  ];
  const lines = ['solid test'];
  for (const [a, b, cc] of faces) {
    lines.push('facet normal 0 0 0', 'outer loop');
    for (const idx of [a, b, cc]) {
      lines.push(`vertex ${c[idx][0]} ${c[idx][1]} ${c[idx][2]}`);
    }
    lines.push('endloop', 'endfacet');
  }
  lines.push('endsolid test');
  return lines.join('\n');
}

test('analyzeTriangles: single 10mm cube', () => {
  const tris = parseStlText(cuboidStl([0, 0, 0], [10, 10, 10]));
  assert.equal(tris.length, 12);
  const a = analyzeTriangles(tris);
  assert.deepEqual(a.dims, [10, 10, 10]);
  assert.equal(a.minZ, 0);
  assert.equal(a.parts.length, 1);
  assert.equal(a.parts[0].volume_cm3, 1); // 1000 mm3
  assert.deepEqual(a.parts[0].offset, [0, 0, 0]);
});

test('analyzeTriangles: two separate parts, one floating', () => {
  const stl = cuboidStl([0, 0, 2], [10, 10, 10]) + '\n' + cuboidStl([30, 0, 2], [5, 5, 5]);
  const a = analyzeTriangles(parseStlText(stl));
  assert.equal(a.parts.length, 2);
  assert.equal(a.minZ, 2); // floating above the plate — must be flagged
  assert.deepEqual(a.dims, [35, 10, 10]);
  // sorted by volume desc
  assert.deepEqual(a.parts[0].dims, [10, 10, 10]);
  assert.deepEqual(a.parts[1].dims, [5, 5, 5]);
  assert.equal(a.parts[1].volume_cm3, 0.125);
});

test('sliceSegments: mid-Z slice of a cube outlines its walls', () => {
  const tris = parseStlText(cuboidStl([0, 0, 0], [10, 10, 10]));
  const segs = sliceSegments(tris, 'z', 5);
  assert.ok(segs.length >= 4); // at least one segment per side wall
  for (const [u0, v0, u1, v1] of segs) {
    for (const c of [u0, v0, u1, v1]) {
      assert.ok(c >= -1e-9 && c <= 10 + 1e-9);
    }
    // every segment lies on the cube boundary
    assert.ok([u0, u1].some(u => u === 0 || u === 10) || [v0, v1].some(v => v === 0 || v === 10));
  }
});

test('parseCgalStats extracts manifold flag, counts and warnings', () => {
  const out = [
    'Geometries in cache: 19',
    '   Top level object is a 3D object:',
    '   Simple:        yes',
    '   Vertices:      380',
    '   Facets:        196',
    '   Volumes:         2',
    'WARNING: Ignoring unknown variable \'inner_x\'',
  ].join('\n');
  const s = parseCgalStats(out);
  assert.equal(s.manifold, true);
  assert.equal(s.volumes, 2);
  assert.equal(s.facets, 196);
  assert.equal(s.vertices, 380);
  assert.equal(s.warnings.length, 1);
});

test('parseExpected reads literals and ignores commented lines', () => {
  const src = [
    '// expected_dims = [1, 2, 3];',
    'expected_dims = [116, 106.4, 30];',
    'expected_parts = 2;',
  ].join('\n');
  const spec = parseExpected(src);
  assert.ok(spec);
  assert.deepEqual(spec!.dims, [116, 106.4, 30]);
  assert.equal(spec!.parts, 2);
  assert.equal(spec!.tol, 0.5);
  assert.equal(parseExpected('// expected_dims = [1,2,3];'), null);
});

test('checkExpected reports mismatches beyond tolerance', () => {
  const a = analyzeTriangles(parseStlText(cuboidStl([0, 0, 0], [10, 10, 10])));
  assert.equal(checkExpected(a, { dims: [10, 10, 10.4], parts: 1, tol: 0.5 }).ok, true);
  const bad = checkExpected(a, { dims: [10, 10, 12], parts: 2, tol: 0.5 });
  assert.equal(bad.ok, false);
  assert.equal(bad.mismatches.length, 2);
});
