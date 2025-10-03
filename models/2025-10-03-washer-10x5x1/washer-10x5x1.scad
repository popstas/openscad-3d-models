// OpenSCAD: washer 10x5x1 — flat washer
// Версия: v1.0 — initial

// Краткое описание (для таблицы моделей)
description = "Flat washer OD 10mm, ID 5mm, thickness 1mm";

// Общие модули
use <../modules.scad>;

// ===== Точность аппроксимации окружностей =====
$fn = 0;        // фиксированную сегментацию отключаем
$fa = 6;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий

// ===== Режим печати тест‑фрагментов =====
test_fragment = false;   // true — печатать только угловые фрагменты
frag_size     = 20;      // размер квадрата вырезки, мм
frag_index    = 0;       // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП
frag_gap_x    = 10;      // зазор между фрагментами по X, мм
frag_h_extra  = 20;      // запас по высоте клипа, мм

// ===== Общие доп. параметры =====
tiny = 0.1;               // небольшой зазор для булевых операций
edge_chamfer_z = 0;       // высота фаски по Z (мм) — для шайбы сверху
edge_chamfer_x = 0;       // не используется для круглой шайбы
edge_chamfer_y = 0;       // не используется для круглой шайбы
screen_frame_gap = 0.2;   // запас по высоте для вычитаний (не влияет на XY)

// ===== Параметры модели =====
outer_d    = 10;   // внешний диаметр, мм
inner_d    = 5;    // внутренний диаметр, мм
thickness  = 1;    // толщина шайбы, мм

// Производные размеры
base_h = thickness;   // высота основной детали, мм (для клиппера)

// ===== Комментарии =============================================
/*
Модель: простая плоская шайба (кольцо) с настраиваемой фаской по верхней кромке.
Фрагменты:
- base — основная шайба

Поддержка тест‑фрагментов: при test_fragment=true выводится клип по углу
квадратом frag_size×frag_size на высоту base_h.
*/

// ===== Модули деталей ==========================================
module base() {
  ch = clamp_chz(thickness, edge_chamfer_z);
  if (ch > 0) {
    // Кольцо с верхней фаской
    chamfer_ring(d_outer=outer_d, d_inner=inner_d, h=thickness, chamfer=ch);
  } else {
    // Прямое кольцо без фаски
    difference() {
      cylinder(h=thickness, d=outer_d);
      translate([0,0,-tiny]) cylinder(h=thickness + 2*tiny, d=inner_d, $fs=pin_fs, $fa=6);
    }
  }
}

// ===== Вывод всех фрагментов ==================================
module show_all() {
  clip_for_fragments_bbox(
    L=outer_d,
    W=outer_d,
    H=base_h,
    enabled=test_fragment,
    frag_size=frag_size,
    frag_index=frag_index,
    frag_h_extra=frag_h_extra
  ) {
    // Переносим в положительные X,Y, чтобы bbox-клиппер брал углы [0..L,0..W]
    translate([outer_d/2, outer_d/2, 0]) base();
  }
}

// ===== Точка входа =============================================
module main() { show_all(); }
main();
