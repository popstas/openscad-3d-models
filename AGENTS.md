# Repository Guidelines

## Project Structure & Module Organization
- One model per folder: `YYYY-MM-DD-short-slug/` (e.g., `2025-08-24-ecig-platform`).
- Primary source: one `kebab-case.scad` file per folder.
- Exports: optional `.stl` (and images) alongside the `.scad` in the same folder.
- Keep assets local to the model folder; avoid cross-folder imports unless intentional.

## Build, Test, and Development Commands
- Preview in GUI: `openscad 2025-08-24-ecig-platform/ecig-platform.scad`
- Export STL: `openscad -o 2025-08-24-ecig-platform/ecig-platform.stl 2025-08-24-ecig-platform/ecig-platform.scad`
- Override params for variants: `openscad -D wall=2.2 -o out.stl path/to/model.scad`
- Compile (CGAL) in GUI with F6 to catch geometry errors before export.

## Coding Style & Naming Conventions
- Indentation: 2 spaces; no tabs.
- Naming: `snake_case` for variables/modules; `UPPER_SNAKE` for constants; file names in `kebab-case.scad` matching the folder slug.
- Units: millimeters; name variables with units when helpful (e.g., `wall_mm`).
- Structure: prefer `module main()` as the entry point and call `main();` at the end; keep helper modules above or in a separate `*-lib.scad` within the same folder.
- Document top-level parameters with brief comments and sensible defaults.

## Testing Guidelines
- Visual checks: F5 preview for speed, F6 compile for validity; ensure no CGAL errors.
- Dimensional checks: verify key clearances and overall size against real parts; parametrize where practical.
- Printability: export at Z=0, upright orientation, manifold solids only; sanity-check in a slicer.
- If adding tests/assets, include small preview PNGs instead of large renders where possible.

## Commit & Pull Request Guidelines
- Commits: imperative, scoped by model folder. Example: `ecig-platform: increase battery bay clearance +0.4mm`.
- Include what/why and mention adjusted parameters.
- PRs: link related issues (if any), include before/after screenshots or STL diff notes, list key dimensions/clearances, and note print results (material, layer height, fit).
- Keep generated files minimal; commit STLs only for stable releases/variants.

## Инструкции
Ты принимаешь фото объектов и описание 3д модели. Нужно использовать OpenSCAD.
Спроектировать 3д модель детали или нескольких деталей.
Нужно уточнить все размеры.
Нужно все размеры сохранять в начале проекта как переменные, чтобы менять параметры модели.

Должен быть test_fragment = true, когда активен:
```
test_fragment = true;   // true — печатать только угловые фрагменты (base+frame)
frag_size     = 20;     // размер квадрата вырезки, мм
frag_index    = 0;      // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП (относительно основания)
frag_gap_x    = 10;     // зазор между фрагментами по X, мм
frag_h_extra  = 20;     // запас по высоте клипа, мм
```

Должна быть возможность задавать размеры фаски по краям детали:
```
tiny = 0.1;                  // небольшой зазор для булевых операций
edge_chamfer_z = 1;       // высота фаски по Z (мм)
edge_chamfer_x = 5;       // горизонтальный вылет фаски по X (с каждой стороны), мм
edge_chamfer_y = 5;       // горизонтальный вылет фаски по Y (с каждой стороны), мм
screen_frame_gap = 0.2;      // только для высоты вычитаний в рамке (не влияет на XY)
```

Блоки кода в проекте модели:
- Версия модели, начиная с 1.0
- Переменные, описывают все размеры модели.
- Комментарии с описанием работы модели, списком фрагментов модели
- Функции фрагментов детали.
- Функция вывода всех фрагментов.
- Функция обрезки через intersection, если указан test_fragment.

По умолчанию главная деталь называется base.
Также могут быть детали: front, frame и т.п.

Предусмотреть настройку фасок и скруглений по краям модели.

Настройка точности:
Вверху файла укажи набор параметров:
```
$fn = 0;        // фиксированную сегментацию отключаем
$fa = 6;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий
```

И локально в цилиндрах для штырей/отверстий добавь точность:
```
// в pin()
cylinder(h=..., d=d,   $fs=pin_fs, $fa=6);
cylinder(h=..., d1=d, d2=max(d-0.6,0.5), $fs=pin_fs, $fa=6);

// отверстия в рамке
cylinder(h=..., d=pin_diam + 0.2, $fs=pin_fs, $fa=6);
```

Так ты получишь минимально необходимое число сегментов без потери округлости на любых размерах, а время рендера/слайсинга останется разумным.

Нужно вывести код проекта с учётом всех правил.
Используй /canvas