#!/usr/bin/env node
// One-shot render CLI (no watch). Single source of truth for cameras/sizes
// is PNG_VIEWS in render-core.ts.
//
// Usage:
//   npm run render -- <model-folder|file.scad>   # force-render one model (STL + 4 previews)
//   npm run render:all                            # render all outdated models (mtime-based)
//   npm run render:all -- --force                 # force-render everything
//
// Single-model renders are always forced: edits to shared modules.scad do not
// touch model mtimes, so an mtime check would skip the rebuild.
import fs from 'fs';
import path from 'path';
import {
  OPENSCAD_CMD,
  ROOT,
  buildIfOutdated,
  compileAll,
  generateModelsMd,
  listScadFiles,
} from './render-core';

function usage(): never {
  console.error('Usage: npm run render -- <model-folder|file.scad>');
  console.error('       npm run render:all [-- --force]');
  process.exit(1);
}

async function renderTarget(target: string): Promise<void> {
  const abs = path.isAbsolute(target) ? target : path.join(ROOT, target);
  let scads: string[] = [];
  const st = fs.existsSync(abs) ? fs.statSync(abs) : null;
  if (st?.isFile() && abs.toLowerCase().endsWith('.scad')) {
    scads = [abs];
  } else if (st?.isDirectory()) {
    scads = listScadFiles(abs);
  }
  if (!scads.length) {
    console.error(`No .scad files found for: ${target}`);
    process.exit(1);
  }
  let failed = 0;
  for (const scad of scads) {
    const res = await buildIfOutdated(scad, { force: true });
    console.log(`${path.relative(ROOT, scad)} -> ${res}`);
    if (res === 'failed') failed++;
  }
  await generateModelsMd();
  if (failed > 0) process.exit(1);
}

async function main() {
  const args = process.argv.slice(2);
  const force = args.includes('--force');
  const all = args.includes('--all');
  const targets = args.filter(a => !a.startsWith('--'));

  console.log(`Using OpenSCAD: ${OPENSCAD_CMD}`);
  if (all) {
    await compileAll({ force });
    return;
  }
  if (!targets.length) usage();
  for (const t of targets) {
    await renderTarget(t);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
