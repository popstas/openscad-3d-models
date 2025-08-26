# OpenSCAD 3D Models

A collection of small, self‑contained OpenSCAD models organized by date and slug. Each folder contains the source `.scad` and, optionally, exported `.stl` files.

[All models index with previews](models.md)

## Requirements
- OpenSCAD (GUI or CLI)
- macOS/Linux/Windows. For Windows paths, set the binary in `.env`.

## Environment (.env)
- __Setup__: Copy `.env.example` to `.env` and set `openscad_path`.

Example `.env`:
```
openscad_path=C:/Program Files/OpenSCAD/openscad.exe
# macOS example:
# openscad_path=/Applications/OpenSCAD-2021.1.app/Contents/MacOS/openscad
```

## Create a new project
```bash
npm run create-project
```

Then ask the agent to create scad code for the project. Add your photos, descriptions, sizes, etc.

Example:
```bash
npm run create-project printer-ceiling-support printer-ceiling
```


## Project layout
- `YYYY-MM-DD-short-slug/` — one folder per model
  - `model-name.scad` — primary OpenSCAD source
  - `model-name.stl` — optional export (may be git‑ignored)
- `AGENTS.md` — contributor guidelines

- __Windows notes__:
  - Do not add quotes. Use either forward slashes `C:/...` or plain Windows paths with spaces (quotes are not needed).
  - The script prints which binary it will use: `Using OpenSCAD: ...`.
- __Git__: `.env` is ignored by Git (see `.gitignore`).

## Conventions
- Units: millimeters. Use clear parameter names (e.g., `wall_mm`).
- Style: 2‑space indent, `snake_case` for variables/modules, constants in `UPPER_SNAKE`.
- Entry point: prefer `module main()` and call `main();` at the end of the file.

## Tips
- Use F5 (preview) for speed, F6 (CGAL) to validate manifolds before export.
- For variants via CLI: `openscad -D wall=2.2 -o out.stl path/to/model.scad`
- Check printability in your slicer; keep models upright at Z=0.

## Contributing
See `AGENTS.md` for structure, style, testing, and PR guidance.

## Промпт для агента:

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