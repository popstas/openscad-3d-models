// =============================================
// 3D: Ventilation cover (square tube with back slit)
// Версия: v1.0 — initial model: 127x127 inner, h=250, wall=0.8, back slit
// =============================================

// Short description for models table
description = "Ventilation cover: square tube 127x127x250, wall 0.8, back slit";

use <../modules.scad>;

// ===== Точность аппроксимации окружностей =====
$fn = 0;        // фиксированную сегментацию отключаем
$fa = 6;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий

// ===== Режим печати тест‑фрагментов =====
test_fragment = false;   // true — печатать только угловой фрагмент
frag_size     = 200;      // размер квадрата вырезки, мм
frag_index    = 0;       // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП (относительно основания)
frag_gap_x    = 10;      // зазор между фрагментами по X, мм (не используется в этой модели)
frag_h_extra  = -110;      // запас по высоте клипа, мм

// ===== Общие доп. параметры =====
tiny = 0.1;              // небольшой зазор для булевых операций
edge_chamfer_z = 1;      // высота фаски по Z (мм)
edge_chamfer_x = 5;      // горизонтальный вылет фаски по X (с каждой стороны), мм
edge_chamfer_y = 5;      // горизонтальный вылет фаски по Y (с каждой стороны), мм
screen_frame_gap = 0.2;  // только для высоты вычитаний (не влияет на XY)

// ===== Параметры модели =====
inner_x_mm = 25;        // внутренний размер по X, мм
inner_y_mm = 2;        // внутренний размер по Y, мм
cover_h_mm = 10;        // высота по Z, мм
wall_th_mm = 1;        // толщина стенок, мм

back_slit_enable = true; // разрез задней стенки по центру
back_slit_gap_mm = 0.1;  // ширина разреза, мм

// ===== Вычисляемые размеры =====
outer_x_mm = inner_x_mm + 2 * wall_th_mm;
outer_y_mm = inner_y_mm + 2 * wall_th_mm;

// ===== Комментарии ===========================
/*
Модель: вентиляционный кожух (тонкостенная квадратная труба) без крышек сверху/снизу.

Фрагменты:
- base: основная деталь (4 стенки) с разрезом на задней стенке

План:
- Делается оболочка как разность outer_box - inner_box.
- Разрез задней стенки: щель шириной back_slit_gap_mm по центру X, только в зоне задней стенки (Y≈0..wall_th).
- По нижней кромке можно включить фаску через edge_chamfer_* (значения автоматически ограничиваются толщиной стенки).
*/

// ===== Вспомогательные функции ====================
function clamp01(v) = clamp(v, 0, 1);

// ===== Вспомогательные модули ====================
// Wedge along X: triangle in (Y,Z), extruded along X
module wedge_along_x(len_x, depth_y, height_z) {
  rotate([0, 90, 0])
    linear_extrude(height=len_x)
      polygon(points=[
        [0, 0],          // z=0, y=0
        [0, depth_y],    // z=0, y=depth
        [height_z, 0]    // z=height, y=0
      ]);
}

// Wedge along Y: triangle in (X,Z), extruded along Y
module wedge_along_y(len_y, depth_x, height_z) {
  rotate([-90, 0, 0])
    linear_extrude(height=len_y)
      polygon(points=[
        [0, 0],          // x=0, z=0
        [depth_x, 0],    // x=depth, z=0
        [0, height_z]    // x=0, z=height
      ]);
}

// ===== Модули деталей ====================
module base_shell() {
  difference() {
    cube([outer_x_mm, outer_y_mm, cover_h_mm], center=false);
    translate([wall_th_mm, wall_th_mm, -tiny])
      cube([inner_x_mm, inner_y_mm, cover_h_mm + 2*tiny], center=false);
  }
}

module back_slit_cut() {
  if (back_slit_enable) {
    x0 = outer_x_mm/2 - back_slit_gap_mm/2;
    translate([x0, -tiny, -tiny])
      cube([back_slit_gap_mm, wall_th_mm + 2*tiny, cover_h_mm + 2*tiny], center=false);
  }
}

module bottom_chamfer_cuts() {
  chz = clamp(edge_chamfer_z, 0, cover_h_mm/2);
  chx = clamp(edge_chamfer_x, 0, wall_th_mm);
  chy = clamp(edge_chamfer_y, 0, wall_th_mm);

  if (chz > 0) {
    union() {
      if (chy > 0) {
        // back + front
        translate([0, 0, 0]) wedge_along_x(outer_x_mm, chy, chz);
        translate([0, outer_y_mm - chy, 0]) wedge_along_x(outer_x_mm, chy, chz);
      }
      if (chx > 0) {
        // left + right
        translate([0, 0, 0]) wedge_along_y(outer_y_mm, chx, chz);
        translate([outer_x_mm - chx, 0, 0]) wedge_along_y(outer_y_mm, chx, chz);
      }
    }
  }
}

// Основная деталь
module base() {
  difference() {
    difference() {
      base_shell();
      back_slit_cut();
    }
    bottom_chamfer_cuts();
  }
}

// ===== Вывод всех фрагментов ====================
module show_all() {
  clip_for_fragments_bbox(
    outer_x_mm,
    outer_y_mm,
    cover_h_mm,
    enabled=test_fragment,
    frag_size=frag_size,
    frag_index=frag_index,
    frag_h_extra=frag_h_extra
  ) base();
}

// ===== Точка входа ====================
module main() {
  show_all();
}

main();
