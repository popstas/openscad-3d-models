import { spawn } from 'child_process';
import fs from 'fs';
import path from 'path';
import zlib from 'zlib';
import { PNG } from 'pngjs';
import Bluebird from 'bluebird';

const ROOT = process.cwd();
const OPENSCAD_CMD = process.env.OPENSCAD_CMD || process.env.openscad_path || 'openscad';
const THROTTLE_MS = 1000;
const IMG_SIZE = process.env.OPENSCAD_IMG_SIZE || '1200,900';

function toStl(scadPath: string): string {
  return scadPath.replace(/\.scad$/i, '.stl');
}

function toPng(scadPath: string, view: string): string {
  // New naming: place alongside .scad with filename 'preview.<view>.png'
  const dir = path.dirname(scadPath);
  return path.join(dir, `preview.${view}.png`);
}

function toPosixRel(p: string): string {
  return path.relative(ROOT, p).split(path.sep).join('/');
}

function statSafe(p: string): fs.Stats | null {
  try { return fs.statSync(p); } catch { return null; }
}

function listScadFiles(dir: string): string[] {
  const out: string[] = [];
  const stack = [dir];
  while (stack.length) {
    const d = stack.pop()!;
    let entries: fs.Dirent[] = [];
    try { entries = fs.readdirSync(d, { withFileTypes: true }); } catch { continue; }
    for (const e of entries) {
      if (e.name === 'node_modules' || e.name === '.git' || e.name === 'dist') continue;
      const p = path.join(d, e.name);
      if (e.isDirectory()) stack.push(p);
      else if (e.isFile() && p.toLowerCase().endsWith('.scad')) out.push(p);
    }
  }
  return out;
}

async function render(scad: string, stl: string): Promise<void> {
  // Fire-and-forget: start OpenSCAD and return immediately without waiting
  const args = ['-o', stl, scad];
  const child = spawn(OPENSCAD_CMD, args, { stdio: 'inherit' });
  // Log errors but do not block the caller
  child.on('error', (err) => {
    console.warn(`openscad spawn error for ${path.relative(ROOT, scad)} -> ${path.relative(ROOT, stl)}:`, err.message);
  });
  // Optionally detach so it doesn't keep the event loop tied to the child
  if (typeof child.unref === 'function') {
    try { child.unref(); } catch {}
  }
  // Resolve immediately
  return;
}

type CamView = { name: string; camera: string; projection: 'o' | 'p' };
const PNG_VIEWS: CamView[] = [
  // --camera = tx,ty,tz,rx,ry,rz,dist ; --viewall will frame the model
  // Names simplified: iso (isometric-like perspective), xy (orthographic top), xz, yz
  { name: 'iso', camera: '0,0,0,55,0,25,500', projection: 'p' },
  { name: 'xy',  camera: '0,0,0,0,0,0,500',   projection: 'o' },
  { name: 'xz',  camera: '0,0,0,90,0,0,500',  projection: 'p' },
  { name: 'yz',  camera: '0,0,0,0,90,0,500',  projection: 'p' },
];

function renderPng(scad: string, png: string, cam: CamView): Promise<void> {
  return new Promise((resolve, reject) => {
    const args = [
      '-o', png,
      '--imgsize=' + IMG_SIZE,
      '--projection=' + cam.projection,
      '--camera=' + cam.camera,
      '--render',
      '--viewall',
      '--autocenter',
      '--view=axes',
      scad,
    ];
    // Debug: print full command line
    const cmdline = [OPENSCAD_CMD, ...args.map(a => (a.includes(' ') ? `"${a}"` : a))].join(' ');
    console.log('PNG cmd:', cmdline);
    const child = spawn(OPENSCAD_CMD, args, { stdio: 'inherit' });
    child.on('exit', (code) => {
      if (code === 0) resolve(); else reject(new Error(`openscad exit ${code}`));
    });
    child.on('error', reject);
  });
}

// Re-encode PNG with no filtering and fixed Huffman strategy for deterministic output
function normalizePng(pngPath: string): void {
  let buf: Buffer;
  try { buf = fs.readFileSync(pngPath); } catch { return; }
  try {
    const img = PNG.sync.read(buf);
    const colorType = (img as any).colorType ?? 6;
    const bitDepth = (img as any).depth ?? 8;
    const out = new PNG({
      width: img.width,
      height: img.height,
      colorType,
      bitDepth,
      filterType: 0,
    });
    img.data.copy(out.data);
    const outBuf = PNG.sync.write(out, {
      filterType: 0,
      colorType,
      bitDepth,
      deflateLevel: 9,
      deflateStrategy: zlib.constants.Z_FIXED,
    });
    if (!outBuf.equals(buf)) fs.writeFileSync(pngPath, outBuf);
  } catch {
    // ignore malformed images
  }
}

// Helper: render PNG and normalize it for deterministic output
async function renderPngWithNormalize(scad: string, png: string, cam: CamView): Promise<void> {
  await renderPng(scad, png, cam);
  // Post-process: re-encode for deterministic output
  normalizePng(png);
}

let building = new Set<string>();

async function buildIfOutdated(scad: string): Promise<'built' | 'skipped' | 'failed'> {
  if (scad.toLowerCase().endsWith('modules.scad')) return 'skipped';
  const stl = toStl(scad);
  const pngs = PNG_VIEWS.map(v => ({ v, path: toPng(scad, v.name) }));
  const sStat = statSafe(scad);
  const tStat = statSafe(stl);
  const pStats = pngs.map(p => ({ p, st: statSafe(p.path) }));
  if (!sStat) return 'failed';
  const needStl = !(tStat && tStat.mtimeMs >= sStat.mtimeMs);
  const needPng = pStats.some(({ st }) => !(st && st.mtimeMs >= sStat.mtimeMs));
  if (!needStl && !needPng) return 'skipped';
  if (building.has(scad)) return 'skipped';

  // output time change
  const fmt = (ms: number) => new Date(ms).toTimeString().slice(0, 8);
  const srcT = fmt(sStat.mtimeMs);
  const outT = tStat ? fmt(tStat.mtimeMs) : 'missing';
  process.stdout.write(`mtime src ${srcT}, stl ${outT}\n`);

  building.add(scad);
  process.stdout.write(`Rendering: ${path.relative(ROOT, scad)} -> ${path.relative(ROOT, stl)}\n`);
  try {
    fs.mkdirSync(path.dirname(stl), { recursive: true });
    if (needStl) {
      await render(scad, stl);
      console.log(`Built: ${path.relative(ROOT, stl)}`);
    }
    if (needPng) {
      for (const { v, path: png } of pngs) {
        const st = statSafe(png);
        if (st && st.mtimeMs >= sStat.mtimeMs) continue;
        fs.mkdirSync(path.dirname(png), { recursive: true });
        console.log(`Rendering PNG (${v.name}): ${path.relative(ROOT, png)}`);
        await renderPngWithNormalize(scad, png, v);
      }
    }
    return 'built';
  } catch (e) {
    console.error(`Error rendering ${scad}:`, (e as Error).message);
    return 'failed';
  } finally {
    building.delete(scad);
  }
}

async function compileAll(): Promise<void> {
  const scads = listScadFiles(ROOT);
  const results = await Bluebird.map(scads, buildIfOutdated, { concurrency: 5 });
  let built = 0, skipped = 0, failed = 0;
  for (const res of results) {
    if (res === 'built') built++;
    else if (res === 'skipped') skipped++;
    else failed++;
  }
  console.log(`Done. Total: ${scads.length}, built: ${built}, skipped: ${skipped}, failed: ${failed}`);
  if (failed > 0) process.exitCode = 1;
  await generateModelsMd();
}

// Per-file debounce + global concurrency-limited queue to rebuild changed files
const fileTimers = new Map<string, NodeJS.Timeout>();
const pendingBuilds = new Set<string>();
let processingPending = false;

async function processPendingBuilds() {
  if (processingPending) {
    console.log('processPendingBuilds: already running, skip');
    return;
  }
  processingPending = true;
  const started = Date.now();
  console.log(`processPendingBuilds: start, pending=${pendingBuilds.size}`);
  try {
    while (pendingBuilds.size) {
      const batch: string[] = Array.from(pendingBuilds);
      pendingBuilds.clear();
      console.log(`processPendingBuilds: batch size=${batch.length}`);
      const batchStart = Date.now();
      await Bluebird.map(batch, async (file: string) => {
        const rel = path.relative(ROOT, file);
        const fileStart = Date.now();
        const res = await buildIfOutdated(file);
        console.log(`processPendingBuilds: ${rel} -> ${res} (${Date.now() - fileStart}ms)`);
      }, { concurrency: 5 });
      console.log(`processPendingBuilds: batch done in ${Date.now() - batchStart}ms`);
      // Update models index after each batch
      await generateModelsMd();
      console.log('processPendingBuilds: models.md updated');
    }
  } catch (e) {
    console.warn('processPendingBuilds: error', (e as Error).message);
    throw e;
  } finally {
    processingPending = false;
    console.log(`processPendingBuilds: finished in ${Date.now() - started}ms`);
  }
}

function scheduleFile(scadFile: string) {
  if (fileTimers.has(scadFile)) clearTimeout(fileTimers.get(scadFile)!);
  const timer = setTimeout(() => {
    fileTimers.delete(scadFile);
    pendingBuilds.add(scadFile);
    void processPendingBuilds();
  }, THROTTLE_MS);
  fileTimers.set(scadFile, timer);
}

// =============== Native watchers (fs.watch + fs.watchFile) ===============
const WATCH_FILE_INTERVAL = Number(process.env.WATCH_POLL_INTERVAL || 500);
const watchedFiles = new Set<string>();
const dirWatchers = new Map<string, fs.FSWatcher>();

function isIgnoredBase(base: string): boolean {
  return base === 'node_modules' || base === '.git' || base === 'dist';
}

function listDirs(dir: string): string[] {
  const out: string[] = [];
  const stack = [dir];
  while (stack.length) {
    const d = stack.pop()!;
    let entries: fs.Dirent[] = [];
    try { entries = fs.readdirSync(d, { withFileTypes: true }); } catch { continue; }
    for (const e of entries) {
      if (isIgnoredBase(e.name)) continue;
      const p = path.join(d, e.name);
      if (e.isDirectory()) { out.push(p); stack.push(p); }
    }
  }
  return out;
}

function watchFileIfNeeded(file: string) {
  if (!file.toLowerCase().endsWith('.scad')) return;
  if (file.toLowerCase() === 'models.scad') return;
  if (watchedFiles.has(file)) return;
  try {
    fs.watchFile(file, { interval: WATCH_FILE_INTERVAL }, () => {
      console.log(`File changed (poll): ${path.relative(ROOT, file)}`);
      scheduleFile(file);
    });
    watchedFiles.add(file);
  } catch (e) {
    console.warn('Failed to watchFile:', file, (e as Error).message);
  }
}

function ensureDirWatcher(dir: string) {
  if (dirWatchers.has(dir)) return;
  try {
    const w = fs.watch(dir, { persistent: true }, (event, filename) => {
      const rel = filename ? filename.toString() : '';
      const full = rel ? path.join(dir, rel) : dir;
      // Manage dynamic additions/removals
      const st = statSafe(full);
      if (st?.isDirectory()) {
        // New directory: recurse
        if (!isIgnoredBase(path.basename(full))) {
          ensureDirWatcher(full);
          for (const f of listScadFiles(full)) watchFileIfNeeded(f);
        }
      } else if (st?.isFile()) {
        if (full.toLowerCase().endsWith('.scad')) watchFileIfNeeded(full);
      } else {
        // Removed file: stop polling if we had it
        if (watchedFiles.has(full)) {
          fs.unwatchFile(full);
          watchedFiles.delete(full);
        }
      }
      // Any change triggers rebuild of the specific file
      // console.log(`Dir event: ${event} -> ${path.relative(ROOT, full)}`);
      if (full.toLowerCase().endsWith('.scad')) {
        scheduleFile(full);
      }
    });
    w.on('error', (err) => console.warn('Dir watcher error:', path.relative(ROOT, dir), err.message));
    dirWatchers.set(dir, w);
  } catch (e) {
    console.warn('Failed to watch dir:', dir, (e as Error).message);
  }
}

function primeWatchers() {
  const modelsPath = path.join(ROOT, 'models');
  // Root directory watcher
  ensureDirWatcher(modelsPath);
  // All subdirectories (excluding ignored)
  const dirs = listDirs(modelsPath);
  for (const d of dirs) ensureDirWatcher(d);
  // Start polling existing .scad files
  for (const f of listScadFiles(modelsPath)) watchFileIfNeeded(f);
  console.log(`fs.watch ready. Dirs: ${dirWatchers.size}, files: ${watchedFiles.size}, pollInterval: ${WATCH_FILE_INTERVAL}ms`);
}

async function main() {
  console.log(`Using OpenSCAD: ${OPENSCAD_CMD}`);
  await compileAll();

  // Initialize native watchers
  primeWatchers();

  console.log('Watching for .scad changes (native fs.watch, debounce', THROTTLE_MS, 'ms)...');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});

// ======================= models.md generation =======================
type ModelMeta = {
  name: string;
  description: string;
  scadRel: string; // posix relative path to .scad
  previews: { name: string; rel: string }[]; // existing preview PNGs
};

function extractModelName(source: string): { name: string; description: string } {
  // Name: line starting with // 3D:
  const nameRe = /^\s*\/\/\s*3D:\s*(.+)\s*$/im;
  const m = source.match(nameRe);
  const full = m ? m[1].trim() : '';
  // Description: description = "...";
  const descRe = /^\s*description\s*=\s*"([^"]*)"\s*;\s*$/im;
  const d = source.match(descRe);
  const desc = d ? d[1].trim() : '';
  return { name: full, description: desc };
}

function readTextSafe(file: string): string | null {
  try { return fs.readFileSync(file, 'utf8'); } catch { return null; }
}

function collectModelMeta(scadFile: string): ModelMeta | null {
  const txt = readTextSafe(scadFile);
  if (txt == null) return null;
  const { name, description } = extractModelName(txt);
  const baseName = path.basename(scadFile, '.scad');
  const finalName = name || baseName;
  const scadRel = toPosixRel(scadFile);
  // Collect any previews of pattern preview.*.png in the same folder (new naming)
  const previews: { name: string; rel: string }[] = [];
  try {
    const dir = path.dirname(scadFile);
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const e of entries) {
      if (!e.isFile()) continue;
      const fname = e.name;
      const lc = fname.toLowerCase();
      if (lc.startsWith('preview.') && lc.endsWith('.png')) {
        const full = path.join(dir, fname);
        const view = fname.slice('preview.'.length, fname.length - '.png'.length);
        previews.push({ name: view, rel: toPosixRel(full) });
      }
    }
    // Stable sort by preview name
    previews.sort((a, b) => a.name.localeCompare(b.name));
  } catch {}
  return { name: finalName, description: description || '', scadRel, previews };
}

function renderModelsTable(models: ModelMeta[]): string {
  const lines: string[] = [];
  lines.push('# Models');
  lines.push('');
  lines.push('| Info | Description | Preview 1 | Preview 2 |');
  lines.push('| ---- | ----------- | --------- | --------- |');
  for (const m of models) {
    const url = m.scadRel.replace('models/', '');
    const parts = url.split('/');
    const folder = parts[0] || '';
    const file = parts.slice(1).join('/') || '';
    const dateMatch = folder.match(/^\d{4}-\d{2}-\d{2}/);
    const date = dateMatch ? dateMatch[0] : '';
    const dirLink = folder ? `[${folder}](${folder}/)` : '';
    const fileLink = file ? `[${file}](${url})` : '';
    const infoCell = `${m.name}<br>${date}<br>${dirLink}<br>${fileLink}`;
    const p1 = m.previews[0] ? `![${m.previews[0].name}](${m.previews[0].rel.replace('models/', '')})` : '—';
    const p2 = m.previews[1] ? `![${m.previews[1].name}](${m.previews[1].rel.replace('models/', '')})` : '—';
    const p3 = m.previews[2] ? `![${m.previews[2].name}](${m.previews[2].rel.replace('models/', '')})` : '—';
    const p4 = m.previews[3] ? `![${m.previews[3].name}](${m.previews[3].rel.replace('models/', '')})` : '—';
    const descCell = m.description ? m.description : '—';
    lines.push(`| ${infoCell} | ${descCell} | ${p1} ${p2} | ${p3} ${p4} |`);
  }
  lines.push('');
  return lines.join('\n');
}

function renderModelsList(models: ModelMeta[]): string {
  const lines: string[] = [];
  lines.push('# Models');
  lines.push('');
  for (const m of models) {
    lines.push(`## ${m.name}`);
    const url = m.scadRel;
    lines.push(`- URL: [${url}](${url})`);
    lines.push(`- Description: ${m.description || ''}`);
    if (m.previews.length) {
      lines.push(`- Previews: ${m.previews.map(p => `[${p.name}](${p.rel})`).join(' ')}`);
    } else {
      lines.push(`- Previews: —`);
    }
    lines.push('');
  }
  return lines.join('\n');
}

async function generateModelsMd(): Promise<void> {
  try {
    const scads = listScadFiles(ROOT)
      .filter(p => p.toLowerCase().endsWith('.scad'))
      .sort((a, b) => toPosixRel(a).localeCompare(toPosixRel(b)));
    const models: ModelMeta[] = [];
    for (const s of scads) {
      const meta = collectModelMeta(s);
      if (meta) models.push(meta);
    }
    const md = renderModelsTable(models);
    const outFile = path.join(ROOT, 'models', 'README.md');
    fs.writeFileSync(outFile, md, 'utf8');
    console.log('Updated models.md');
  } catch (e) {
    console.warn('Failed to update models.md:', (e as Error).message);
  }
}
