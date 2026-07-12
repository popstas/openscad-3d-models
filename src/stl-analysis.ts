// ASCII STL analysis: bounding box, connected components (printed parts),
// per-part dimensions and volumes. Feeds <model>.geometry.json so agents can
// validate geometry with numbers instead of guessing from preview pixels.
import fs from 'fs';

export type Vec3 = [number, number, number];
export type Triangle = [Vec3, Vec3, Vec3];

export function parseStlText(txt: string): Triangle[] {
  const re = /vertex\s+([+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)\s+([+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)\s+([+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?)/g;
  const verts: Vec3[] = [];
  let m: RegExpExecArray | null;
  while ((m = re.exec(txt)) != null) {
    const v: Vec3 = [Number(m[1]), Number(m[2]), Number(m[3])];
    if (v.every(Number.isFinite)) verts.push(v);
  }
  const tris: Triangle[] = [];
  for (let i = 0; i + 2 < verts.length; i += 3) {
    tris.push([verts[i], verts[i + 1], verts[i + 2]]);
  }
  return tris;
}

export function parseStlFile(stlPath: string): Triangle[] | null {
  let txt: string;
  try { txt = fs.readFileSync(stlPath, 'utf8'); } catch { return null; }
  const tris = parseStlText(txt);
  return tris.length ? tris : null;
}

export type PartInfo = {
  dims: Vec3;      // bounding box size of this connected component, mm
  offset: Vec3;    // bounding box min corner, mm
  volume_cm3: number;
  facets: number;
};

export type StlAnalysis = {
  dims: Vec3;                       // overall bounding box size, mm
  bbox: { min: Vec3; max: Vec3 };
  minZ: number;                     // 0 means the model sits on the build plate
  facets: number;
  parts: PartInfo[];                // connected components, largest volume first
};

const round2 = (v: number) => Math.round(v * 100) / 100;
const round3 = (v: number) => Math.round(v * 1000) / 1000;

// Union-find over vertices quantized to 1e-3 mm; triangles sharing a vertex
// belong to the same printed part. Note: a fully enclosed internal void forms
// its own shell and is counted as a separate "part".
export function analyzeTriangles(tris: Triangle[]): StlAnalysis {
  const idOf = new Map<string, number>();
  const parent: number[] = [];
  const find = (i: number): number => {
    while (parent[i] !== i) { parent[i] = parent[parent[i]]; i = parent[i]; }
    return i;
  };
  const union = (a: number, b: number) => { const ra = find(a), rb = find(b); if (ra !== rb) parent[rb] = ra; };
  const vid = (v: Vec3): number => {
    const key = `${Math.round(v[0] * 1000)},${Math.round(v[1] * 1000)},${Math.round(v[2] * 1000)}`;
    let id = idOf.get(key);
    if (id === undefined) { id = parent.length; idOf.set(key, id); parent.push(id); }
    return id;
  };

  const triVid: number[] = [];
  for (const [a, b, c] of tris) {
    const ia = vid(a), ib = vid(b), ic = vid(c);
    union(ia, ib); union(ib, ic);
    triVid.push(ia);
  }

  type Acc = { min: Vec3; max: Vec3; signedVol: number; facets: number };
  const comps = new Map<number, Acc>();
  const gmin: Vec3 = [Infinity, Infinity, Infinity];
  const gmax: Vec3 = [-Infinity, -Infinity, -Infinity];

  for (let t = 0; t < tris.length; t++) {
    const root = find(triVid[t]);
    let acc = comps.get(root);
    if (!acc) {
      acc = { min: [Infinity, Infinity, Infinity], max: [-Infinity, -Infinity, -Infinity], signedVol: 0, facets: 0 };
      comps.set(root, acc);
    }
    const [a, b, c] = tris[t];
    for (const v of [a, b, c]) {
      for (let k = 0; k < 3; k++) {
        if (v[k] < acc.min[k]) acc.min[k] = v[k];
        if (v[k] > acc.max[k]) acc.max[k] = v[k];
        if (v[k] < gmin[k]) gmin[k] = v[k];
        if (v[k] > gmax[k]) gmax[k] = v[k];
      }
    }
    // signed tetrahedron volume relative to origin: dot(a, cross(b, c)) / 6
    acc.signedVol += (
      a[0] * (b[1] * c[2] - b[2] * c[1]) +
      a[1] * (b[2] * c[0] - b[0] * c[2]) +
      a[2] * (b[0] * c[1] - b[1] * c[0])
    ) / 6;
    acc.facets++;
  }

  const parts: PartInfo[] = Array.from(comps.values()).map(acc => ({
    dims: acc.min.map((mn, k) => round2(acc.max[k] - mn)) as Vec3,
    offset: acc.min.map(round2) as Vec3,
    volume_cm3: round3(Math.abs(acc.signedVol) / 1000),
    facets: acc.facets,
  }));
  parts.sort((a, b) => b.volume_cm3 - a.volume_cm3);

  return {
    dims: gmin.map((mn, k) => round2(gmax[k] - mn)) as Vec3,
    bbox: { min: gmin.map(round2) as Vec3, max: gmax.map(round2) as Vec3 },
    minZ: round2(gmin[2]),
    facets: tris.length,
    parts,
  };
}
