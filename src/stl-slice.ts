// Cross-section previews from STL triangles: <model>.cut-x/y/z.png.
// Shows wall thickness, pockets and internal cavities that exterior camera
// views cannot reveal. Grid step is 10 mm; the thick line through 0 marks the axis.
import { PNG } from 'pngjs';
import { Triangle, Vec3 } from './stl-analysis';
import { drawLineThick, drawText, fillRect, textSize, writePngDeterministic, Rgba } from './png-utils';

const IMG_W = 800;
const IMG_H = 600;
const MARGIN = 50;

const BG: Rgba = { r: 255, g: 255, b: 255, a: 255 };
const GRID: Rgba = { r: 225, g: 225, b: 225, a: 255 };
const AXIS: Rgba = { r: 160, g: 160, b: 160, a: 255 };
const CUTLINE: Rgba = { r: 0, g: 0, b: 0, a: 255 };
const LABEL_BG: Rgba = { r: 0, g: 0, b: 0, a: 180 };
const LABEL_FG: Rgba = { r: 255, g: 255, b: 255, a: 255 };

export type SliceAxis = 'x' | 'y' | 'z';
type Seg = [number, number, number, number]; // u0, v0, u1, v1 in model mm

// In-plane axes for each cut: cut-z shows XY, cut-x shows YZ, cut-y shows XZ
function planeAxes(axis: SliceAxis): [number, number, number] {
  if (axis === 'z') return [0, 1, 2];
  if (axis === 'x') return [1, 2, 0];
  return [0, 2, 1];
}

export function sliceSegments(tris: Triangle[], axis: SliceAxis, at: number): Seg[] {
  const [ui, vi, wi] = planeAxes(axis);
  const segs: Seg[] = [];
  for (const tri of tris) {
    const d = tri.map(p => p[wi] - at);
    const pts: [number, number][] = [];
    for (let i = 0; i < 3; i++) {
      const j = (i + 1) % 3;
      if (d[i] === 0) pts.push([tri[i][ui], tri[i][vi]]);
      if (d[i] * d[j] < 0) {
        const t = d[i] / (d[i] - d[j]);
        pts.push([
          tri[i][ui] + t * (tri[j][ui] - tri[i][ui]),
          tri[i][vi] + t * (tri[j][vi] - tri[i][vi]),
        ]);
      }
    }
    // dedupe near-identical points, keep first two distinct
    const uniq: [number, number][] = [];
    for (const p of pts) {
      if (!uniq.some(q => Math.abs(q[0] - p[0]) < 1e-6 && Math.abs(q[1] - p[1]) < 1e-6)) uniq.push(p);
    }
    if (uniq.length >= 2) segs.push([uniq[0][0], uniq[0][1], uniq[1][0], uniq[1][1]]);
  }
  return segs;
}

export function renderSlicePng(
  tris: Triangle[],
  bboxMin: Vec3,
  bboxMax: Vec3,
  axis: SliceAxis,
  pngPath: string,
): void {
  const [ui, vi, wi] = planeAxes(axis);
  // nudge off the exact mid-plane so flat faces lying on it don't degenerate
  const at = (bboxMin[wi] + bboxMax[wi]) / 2 + 0.01;
  const segs = sliceSegments(tris, axis, at);

  const umin = bboxMin[ui], vmin = bboxMin[vi];
  const du = Math.max(bboxMax[ui] - umin, 1e-6);
  const dv = Math.max(bboxMax[vi] - vmin, 1e-6);
  const scale = Math.min((IMG_W - 2 * MARGIN) / du, (IMG_H - 2 * MARGIN) / dv);
  const px = (u: number) => Math.round(MARGIN + (u - umin) * scale);
  const py = (v: number) => Math.round(IMG_H - MARGIN - (v - vmin) * scale);

  const img = new PNG({ width: IMG_W, height: IMG_H });
  fillRect(img, 0, 0, IMG_W, IMG_H, BG);

  // 10 mm grid in model coordinates; heavier line through coordinate 0
  const umax = bboxMax[ui], vmax = bboxMax[vi];
  for (let gu = Math.ceil(umin / 10) * 10; gu <= umax; gu += 10) {
    const color = gu === 0 ? AXIS : GRID;
    drawLineThick(img, px(gu), py(vmin), px(gu), py(vmax), color, gu === 0 ? 2 : 1);
  }
  for (let gv = Math.ceil(vmin / 10) * 10; gv <= vmax; gv += 10) {
    const color = gv === 0 ? AXIS : GRID;
    drawLineThick(img, px(umin), py(gv), px(umax), py(gv), color, gv === 0 ? 2 : 1);
  }

  for (const [u0, v0, u1, v1] of segs) {
    drawLineThick(img, px(u0), py(v0), px(u1), py(v1), CUTLINE, 2);
  }

  // label, e.g. "CUT Z=17.51mm"
  const label = `CUT ${axis.toUpperCase()}=${at.toFixed(2)}mm`;
  const ts = textSize(label, 2);
  const pad = 6;
  fillRect(img, pad, IMG_H - ts.h - 3 * pad, ts.w + 2 * pad, ts.h + 2 * pad, LABEL_BG);
  drawText(img, label, 2 * pad, IMG_H - ts.h - 2 * pad, 2, LABEL_FG);

  writePngDeterministic(img, pngPath);
}
