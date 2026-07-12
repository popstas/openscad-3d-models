// Watch mode: rebuild changed .scad files and keep models/README.md fresh.
// Render/index machinery lives in render-core.ts (shared with render-once.ts).
import fs from 'fs';
import path from 'path';
import Bluebird from 'bluebird';
import {
  ROOT,
  OPENSCAD_CMD,
  buildIfOutdated,
  compileAll,
  generateModelsMd,
  listScadFiles,
  statSafe,
} from './render-core';

const THROTTLE_MS = 1000;

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
  return base === 'node_modules' || base === '.git' || base === 'dist' || base === 'BOSL2';
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
