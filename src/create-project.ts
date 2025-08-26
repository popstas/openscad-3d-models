#!/usr/bin/env node
import fs from 'fs';
import path from 'path';

function usage(): never {
  console.error('Usage: npm run create-project <long_name> <short_name>');
  console.error('Example: npm run create-project ecig-platform ecig-platform');
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
  const [, , longRaw, shortRaw] = process.argv;
  if (!longRaw || !shortRaw) usage();

  const longSlug = sanitizeSlug(longRaw);
  const shortSlug = sanitizeSlug(shortRaw);
  if (!longSlug || !shortSlug) usage();

  const date = todayStamp();
  const folder = `${date}-${longSlug}`;
  const root = process.cwd();
  const modelDir = path.join(root, 'models', folder);
  ensureDir(modelDir);

  const scadName = `${shortSlug}.scad`;
  const readmeName = 'README.md';

  const previewBase = `${shortSlug}.preview`;
  const previews = [
    `${previewBase}.iso-p.png`,
    `${previewBase}.xy-o.png`,
    `${previewBase}.xz-p.png`,
    `${previewBase}.yz-p.png`,
  ];

  const scadPath = path.join(modelDir, scadName);
  const readmePath = path.join(modelDir, readmeName);

  const scadTemplate = `// =============================================
// 3D: ${longSlug.replace(/-/g, ' ')}
// Version: 1.0
// Author: generator
// =============================================

description = "";
version_str = "1.0;

use <../modules.scad>;

// ----------------------------
// Настройка точности
// ----------------------------
$fn = 0;        // фиксированную сегментацию отключаем
$fa = 6;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий

// ----------------------------
// Тестовые фрагменты (стандартный блок)
// ----------------------------
test_fragment = false;   // true — печатать только угловые фрагменты (base+frame)
frag_size     = 20;      // размер квадрата вырезки, мм
frag_index    = 0;       // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП (относительно основания)
frag_gap_x    = 10;      // зазор между фрагментами по X, мм
frag_h_extra  = 20;      // запас по высоте клипа, мм

// ----------------------------
// Фаски/скругления по краям (совместимость)
// ----------------------------
tiny = 0.1;                  // небольшой зазор для булевых операций
edge_chamfer_z = 1;          // высота фаски по Z (мм)
edge_chamfer_x = 5;          // горизонтальный вылет фаски по X (каждая сторона), мм
edge_chamfer_y = 5;          // горизонтальный вылет фаски по Y (каждая сторона), мм
screen_frame_gap = 0.2;      // совместимость

// ----------------------------
// Параметры модели (примерные, замените под задачу)
// ----------------------------
base_x = 100;  // ширина X, мм, width
base_y = 50;   // высота Y, мм, height
base_h = 5;    // толщина Z, мм, th
radius_r = 3;  // скругление

// ----------------------------
// Фрагменты: назовите элементы короткими именами с _
// ----------------------------
// - base: основная деталь
// - top_pad, base_pad, wrap_left, main_wall: примеры имён

module base(){
    linear_extrude(height=base_h) rounded_rect([base_x, base_y], r=radius_r);
}

// ---------------
// Клиппер фрагментов
// ---------------
module clip_for_fragments(){
    if(test_fragment){
        intersection(){
            children(0);
            translate([0, 0, -frag_h_extra]) cube([frag_size, frag_size, base_h + 2*frag_h_extra]);
        }
    } else { children(); }
}

// ----------------------------
// ВЫВОД МОДЕЛИ
// ----------------------------
clip_for_fragments(){ base(); }
`;

  const readmeTemplate = `# ${longSlug.replace(/-/g, ' ')}\n\n- Файл модели: \`${shortSlug}.scad\`\n- Версия: 1.0\n\n## Ключевые параметры (см. начало SCAD)\n- $fn, $fa, $fs, pin_fs — точность окружностей\n- test_fragment, frag_* — тест‑фрагменты\n- edge_chamfer_*, tiny — фаски/совм.\n\n## Превью\n\n![${shortSlug} iso-p](${shortSlug}.preview.iso-p.png)\n\n![${shortSlug} xy-o](${shortSlug}.preview.xy-o.png)\n\n![${shortSlug} xz-p](${shortSlug}.preview.xz-p.png)\n\n![${shortSlug} yz-p](${shortSlug}.preview.yz-p.png)\n`;

  writeIfMissing(scadPath, scadTemplate);
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


