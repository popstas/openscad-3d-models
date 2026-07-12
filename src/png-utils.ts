// Shared PNG drawing helpers: tiny bitmap font, primitives and deterministic
// encoding. Used by render-core.ts (dimension overlay) and stl-slice.ts.
import fs from 'fs';
import zlib from 'zlib';
import { PNG } from 'pngjs';

export type Rgba = { r: number; g: number; b: number; a: number };

// ======== tiny 3x5 bitmap font ========
export const FONT_W = 3;
export const FONT_H = 5;
// Each glyph is an array of 5 strings of length 3, using '#' for on, '.' for off.
const FONT: Record<string, string[]> = {
  '0': ['###', '#.#', '#.#', '#.#', '###'],
  '1': ['..#', '..#', '..#', '..#', '..#'],
  '2': ['###', '..#', '###', '#..', '###'],
  '3': ['###', '..#', '###', '..#', '###'],
  '4': ['#.#', '#.#', '###', '..#', '..#'],
  '5': ['###', '#..', '###', '..#', '###'],
  '6': ['###', '#..', '###', '#.#', '###'],
  '7': ['###', '..#', '..#', '..#', '..#'],
  '8': ['###', '#.#', '###', '#.#', '###'],
  '9': ['###', '#.#', '###', '..#', '###'],
  'X': ['#.#', '#.#', '.#.', '#.#', '#.#'],
  'Y': ['#.#', '#.#', '.#.', '.#.', '.#.'],
  'Z': ['###', '..#', '.#.', '#..', '###'],
  'C': ['###', '#..', '#..', '#..', '###'],
  'U': ['#.#', '#.#', '#.#', '#.#', '###'],
  'T': ['###', '.#.', '.#.', '.#.', '.#.'],
  'm': ['...', '##.', '#.#', '#.#', '#.#'],
  ':': ['...', '.#.', '...', '.#.', '...'],
  '=': ['...', '###', '...', '###', '...'],
  '-': ['...', '...', '###', '...', '...'],
  '.': ['...', '...', '...', '...', '.#.'],
  ' ': ['...', '...', '...', '...', '...'],
};

export function putPixel(img: PNG, x: number, y: number, rgba: Rgba) {
  if (x < 0 || y < 0 || x >= img.width || y >= img.height) return;
  const idx = (img.width * y + x) << 2;
  const a = rgba.a / 255;
  const a0 = img.data[idx + 3] / 255;
  const outA = a + a0 * (1 - a);
  // simple alpha over
  img.data[idx + 0] = Math.round(rgba.r * a + img.data[idx + 0] * (1 - a));
  img.data[idx + 1] = Math.round(rgba.g * a + img.data[idx + 1] * (1 - a));
  img.data[idx + 2] = Math.round(rgba.b * a + img.data[idx + 2] * (1 - a));
  img.data[idx + 3] = Math.round(outA * 255);
}

export function fillRect(img: PNG, x: number, y: number, w: number, h: number, color: Rgba) {
  for (let yy = 0; yy < h; yy++) {
    for (let xx = 0; xx < w; xx++) {
      putPixel(img, x + xx, y + yy, color);
    }
  }
}

function drawChar(img: PNG, ch: string, x: number, y: number, scale: number, color: Rgba) {
  const glyph = FONT[ch] || FONT[' '];
  for (let gy = 0; gy < FONT_H; gy++) {
    const row = glyph[gy];
    for (let gx = 0; gx < FONT_W; gx++) {
      if (row[gx] === '#') {
        fillRect(img, x + gx * scale, y + gy * scale, scale, scale, color);
      }
    }
  }
}

export function textSize(text: string, scale: number): { w: number; h: number } {
  const w = text.length * (FONT_W * scale) + Math.max(0, text.length - 1) * scale; // 1px space between chars scaled
  const h = FONT_H * scale;
  return { w, h };
}

export function drawText(img: PNG, text: string, x: number, y: number, scale: number, color: Rgba) {
  let cx = x;
  for (const ch of text) {
    drawChar(img, ch, cx, y, scale, color);
    cx += FONT_W * scale + scale; // char width + spacer
  }
}

// drawLineThick — sampled line with square brush of given thickness (px)
export function drawLineThick(img: PNG, x0: number, y0: number, x1: number, y1: number, color: Rgba, thickness = 2) {
  const steps = Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0), 1);
  const half = Math.floor(thickness / 2);
  for (let s = 0; s <= steps; s++) {
    const x = Math.round(x0 + ((x1 - x0) * s) / steps);
    const y = Math.round(y0 + ((y1 - y0) * s) / steps);
    fillRect(img, x - half, y - half, thickness, thickness, color);
  }
}

// Deterministic PNG encoding: no filtering, fixed Huffman strategy
export function encodePngDeterministic(img: PNG): Buffer {
  return PNG.sync.write(img, {
    filterType: 0,
    colorType: (img as any).colorType ?? 6,
    bitDepth: (img as any).depth ?? 8,
    deflateLevel: 9,
    deflateStrategy: zlib.constants.Z_FIXED,
  });
}

export function writePngDeterministic(img: PNG, pngPath: string): void {
  fs.writeFileSync(pngPath, encodePngDeterministic(img));
}
