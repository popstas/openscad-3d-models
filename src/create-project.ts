#!/usr/bin/env node
import fs from 'fs';
import path from 'path';

function usage(): never {
  console.error('Usage: npm run create-project <long_name> [short_name] [template]');
  console.error('Example: npm run create-project ecig-platform ecig-platform default');
  process.exit(1);
}

function todayStamp(): string {
  const now = new Date();
  const y = now.getFullYear();
  const m = String(now.getMonth() + 1).padStart(2, '0');
  const d = String(now.getDate()).padStart(2, '0');
  return `${y}-${d.startsWith('3') && m === '08' ? m : m}-${d}`; // standard YYYY-MM-DD
}

function sanitizeSlug(s: string): string {
  return s
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9-]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .replace(/--+/g, '-');
}

function ensureDir(p: string) {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
}

function writeIfMissing(filePath: string, content: string) {
  if (fs.existsSync(filePath)) return; // don't overwrite existing
  fs.writeFileSync(filePath, content);
}

function emptyPngPlaceholder(): Buffer {
  // 1x1 transparent PNG
  return Buffer.from(
    '89504e470d0a1a0a0000000d49484452000000010000000108060000001f15c4890000000a49444154789c636000000200015e2b2f950000000049454e44ae426082',
    'hex'
  );
}

function main() {
  const [, , longRaw, shortRaw, templateRaw] = process.argv;
  if (!longRaw) usage();

  const longSlug = sanitizeSlug(longRaw);
  const shortSlug = sanitizeSlug(shortRaw || longSlug);
  const templateName = sanitizeSlug(templateRaw || 'default');
  if (!longSlug || !shortSlug) usage();

  const date = todayStamp();
  const folder = `${date}-${longSlug}`;
  const root = process.cwd();
  const modelDir = path.join(root, 'models', folder);
  ensureDir(modelDir);

  const scadName = `${shortSlug}.scad`;
  const readmeName = 'README.md';

  // New naming: preview.<view>.png (no slug prefix, simplified view names)
  const previews = [
    `preview.iso.png`,
    `preview.xy.png`,
    `preview.xz.png`,
    `preview.yz.png`,
  ];

  const scadPath = path.join(modelDir, scadName);
  const readmePath = path.join(modelDir, readmeName);

  // Read SCAD template from models/templates/<template>.scad and substitute placeholders
  const templatePath = path.join(root, 'models', 'templates', templateName, `${templateName}.scad`);
  let scadContent = fs.readFileSync(templatePath, 'utf8');
  const longName = longSlug.replace(/-/g, ' ');
  const shortDescription = '';
  scadContent = scadContent
    .replace(/\$\{longName\}/g, longName)
    .replace(/\$\{shortDescription\}/g, shortDescription);

  const readmeTemplate = `# ${longSlug.replace(/-/g, ' ')}\n\n- Файл модели: \`${shortSlug}.scad\`\n- Версия: 1.0\n\n## Ключевые параметры (см. начало SCAD)\n- $fn, $fa, $fs, pin_fs — точность окружностей\n- test_fragment, frag_* — тест‑фрагменты\n- edge_chamfer_*, tiny — фаски/совм.\n\n## Превью\n\n![${shortSlug} iso](preview.iso.png)\n\n![${shortSlug} xy](preview.xy.png)\n\n![${shortSlug} xz](preview.xz.png)\n\n![${shortSlug} yz](preview.yz.png)\n`;

  writeIfMissing(scadPath, scadContent);
  writeIfMissing(readmePath, readmeTemplate);

  const png = emptyPngPlaceholder();
  for (const p of previews) {
    const abs = path.join(modelDir, p);
    if (!fs.existsSync(abs)) fs.writeFileSync(abs, png);
  }

  console.log(`Created: ${folder}/`);
  console.log(`- ${scadName}`);
  console.log(`- ${readmeName}`);
  for (const p of previews) console.log(`- ${p}`);
}

main();


