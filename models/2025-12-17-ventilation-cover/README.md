# ventilation cover

- Файл модели: `ventilation-cover.scad`
- Версия: 1.0

## Назначение
Тонкостенный квадратный кожух вентиляции: 4 стенки (без крышек сверху/снизу), внутренний проём **127×127 мм**, высота **250 мм**.
Задняя стенка имеет разрез по центру с зазором **0.1 мм** (параметр `back_slit_gap_mm`).

## Ключевые параметры (см. начало SCAD)
- $fn, $fa, $fs, pin_fs — точность окружностей
- test_fragment, frag_* — тест‑фрагменты
- edge_chamfer_*, tiny — фаски/совм.

## Фрагменты модели
- **base**: основная деталь (4 стенки) + разрез на задней стенке

## Экспорт STL

```bash
openscad -o models/2025-12-17-ventilation-cover/ventilation-cover.stl models/2025-12-17-ventilation-cover/ventilation-cover.scad
```

## Превью

![ventilation-cover iso](preview.iso.png)

![ventilation-cover xy](preview.xy.png)

![ventilation-cover xz](preview.xz.png)

![ventilation-cover yz](preview.yz.png)
