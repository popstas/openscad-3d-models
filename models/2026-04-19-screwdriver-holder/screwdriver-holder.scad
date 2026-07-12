// OpenSCAD: держатель отвёртки — скорлупа со скруглённым прямоугольным пазом и боковым крепёжным блоком
// Версия: v1.0 — начальная геометрия по заданным размерам

description = "Rounded-rect shell (34 mm inner, r5), 1 mm wall, open bottom, side 17³ holder and two hex holes";
version_str = "1.0";

use <../modules.scad>;

// ===== Точность аппроксимации окружностей =====
$fn = 0;
$fa = 6;
$fs = 0.35;
pin_fs = 0.25;

// ===== Режим печати тест‑фрагментов =====
test_fragment = false;
frag_size = 20;
frag_index = 0;
frag_gap_x = 10;
frag_h_extra = 20;

// ===== Общие доп. параметры =====
tiny = 0.1;
edge_chamfer_z = 1;
edge_chamfer_x = 5;
edge_chamfer_y = 5;
screen_frame_gap = 0.2;

// ===== Комментарии ===========================
/*
Модель: одна деталь для печати — «стакан» под рукоятку и блок крепления на внешней стенке.
Ось Z вверх, дно стакана на Z=0.

Фрагменты (имена с _):
- shell_wall — внешняя скорлупа без дна: внутри скруглённый прямоугольник 34×34, r=5 мм, высота 35 мм
- holder_block — скруглённый блок, центрирован на выбранной внешней стенке
- holder_hex_cut — два вертикальных шестигранных отверстия (параллельные грани 6 мм), по горизонтали

Деталь для вывода: base = union(shell_wall, holder_block) − holder_hex_cut
*/

// ===== Параметры модели =====
// --- shell (скорлупа) ---
shell_h = 35;
inner_flat_x = 32;
inner_flat_y = 32;
inner_corner_r = 10;
wall_th = 1;
shell_bottom_th = 0;

// --- holder (блок на стенке) ---
holder_depth_x = 10;
holder_width_y = 18;
holder_height_z = 18;
holder_corner_r = 2; // скругление углов блока в плане XY
holder_shift_x = -0.7; // сдвиг holder по оси X, мм
holder_center_wall_z = 0.8; // перегородка по центру holder вдоль XY, мм
holder_face = "x_plus"; // x_plus | x_minus | y_plus | y_minus — внешняя стенка, к которой крепится блок
holder_overlap_shell = 0.25;

// шестигранник: расстояние между параллельными гранями (across flats), мм
hex_flat_to_flat = 6.35;
hex_depth_clearance = 0.2;

// ===== Вычисляемые размеры =====
outer_flat_x = inner_flat_x + 2 * wall_th;
outer_flat_y = inner_flat_y + 2 * wall_th;
outer_corner_r = inner_corner_r + wall_th;

base_h = shell_h;

function holder_min_x() =
  (
    (holder_face == "x_minus") ? (-holder_depth_x + holder_overlap_shell) :
    (holder_face == "y_plus" || holder_face == "y_minus") ? ((outer_flat_x - holder_width_y) / 2) :
    0
  ) + holder_shift_x;

function holder_max_x() =
  (
    (holder_face == "x_plus") ? (outer_flat_x + holder_depth_x) :
    outer_flat_x
  ) + holder_shift_x;

function holder_min_y() =
  (holder_face == "y_minus") ? (-holder_depth_x + holder_overlap_shell) :
  (holder_face == "x_plus" || holder_face == "x_minus") ? ((outer_flat_y - holder_width_y) / 2) :
  0;

function holder_max_y() =
  (holder_face == "y_plus") ? (outer_flat_y + holder_depth_x) :
  outer_flat_y;

footprint_l = holder_max_x() - holder_min_x();
footprint_w = holder_max_y() - holder_min_y();

function hex_circumradius_from_flat(ftf) = (ftf + hex_depth_clearance) / sqrt(3);

function clamp(val, lo, hi) = max(lo, min(val, hi));

// ===== Вспомогательные модули ====================
module hex_prism_vertical(h, ftf) {
  r = hex_circumradius_from_flat(ftf);
  translate([0, 0, -tiny])
    cylinder(h = h + 2 * tiny, r = r, $fn = 6, $fs = pin_fs, $fa = 6);
}

// Позиция блока: минимальный угол касания внешней грани — (hx, hy, hz)
function holder_origin() =
  (holder_face == "x_plus")
    ? [outer_flat_x - holder_overlap_shell + holder_shift_x, (outer_flat_y - holder_width_y) / 2, (shell_h - holder_height_z) / 2]
  : (holder_face == "x_minus")
    ? [-holder_depth_x + holder_overlap_shell + holder_shift_x, (outer_flat_y - holder_width_y) / 2, (shell_h - holder_height_z) / 2]
  : (holder_face == "y_plus")
    ? [(outer_flat_x - holder_width_y) / 2 + holder_shift_x, outer_flat_y - holder_overlap_shell, (shell_h - holder_height_z) / 2]
    : [(outer_flat_x - holder_width_y) / 2 + holder_shift_x, -holder_depth_x + holder_overlap_shell, (shell_h - holder_height_z) / 2];

// Локальные координаты отверстий в плане блока (ось отверстия Z): [u, v] в системе «глубина × ширина» блока
holder_hole_uv = [
  [holder_depth_x / 2, holder_width_y * 0.30],
  [holder_depth_x / 2, holder_width_y * 0.70],
];

// ===== Модули фрагментов детали ====================
module shell_wall() {
  // Стенка начинается на z=edge_chamfer_z: нижняя фаска у старого
  // rounded_rect_extrude_bottom_chamfer не генерировалась (баг modules.scad <1.3),
  // деталь напечатана именно так — геометрия закреплена явно.
  difference() {
    translate([0, 0, edge_chamfer_z])
      rr_extrude(
        size = [outer_flat_x, outer_flat_y],
        r = outer_corner_r,
        h = shell_h - edge_chamfer_z
      );
    translate([wall_th, wall_th, -tiny])
      rr_extrude(
        size = [inner_flat_x, inner_flat_y],
        r = max(inner_corner_r, 0),
        h = shell_h + 2 * tiny
      );
  }
}

module holder_block() {
  o = holder_origin();
  sx = (holder_face == "x_plus" || holder_face == "x_minus")
    ? (holder_depth_x + holder_overlap_shell)
    : holder_width_y;
  sy = (holder_face == "x_plus" || holder_face == "x_minus")
    ? holder_width_y
    : (holder_depth_x + holder_overlap_shell);
  r = clamp(holder_corner_r, 0, min(sx, sy) / 2 - tiny);

  if (holder_face == "x_plus" || holder_face == "x_minus") {
    translate(o)
      rr_extrude(size = [sx, sy], r = r, h = holder_height_z);
  } else {
    translate(o)
      rr_extrude(size = [sx, sy], r = r, h = holder_height_z);
  }
}

module holder_hex_cut() {
  o = holder_origin();
  hz = o[2];
  split_z = clamp(holder_center_wall_z, 0, holder_height_z - 2 * tiny);
  seg_h = (holder_height_z - split_z) / 2;
  z_bottom = 0;
  z_top = seg_h + split_z;
  if (holder_face == "x_plus" || holder_face == "x_minus") {
    for (p = holder_hole_uv) {
      translate([o[0], o[1], hz])
        translate([p[0], p[1], 0])
          union() {
            translate([0, 0, z_bottom])
              hex_prism_vertical(seg_h, hex_flat_to_flat);
            translate([0, 0, z_top])
              hex_prism_vertical(seg_h, hex_flat_to_flat);
          }
    }
  } else {
    for (p = holder_hole_uv) {
      translate([o[0], o[1], hz])
        translate([p[1], p[0], 0])
          union() {
            translate([0, 0, z_bottom])
              hex_prism_vertical(seg_h, hex_flat_to_flat);
            translate([0, 0, z_top])
              hex_prism_vertical(seg_h, hex_flat_to_flat);
          }
    }
  }
}

// ===== Сборка основной детали ====================
module base() {
  difference() {
    union() {
      shell_wall();
      holder_block();
    }
    holder_hex_cut();
  }
}

// ===== Вывод всех фрагментов ====================
module show_all() {
  clip_for_fragments_bbox(
    footprint_l,
    footprint_w,
    base_h,
    test_fragment,
    frag_size,
    frag_index,
    frag_h_extra
  ) {
    translate([-holder_min_x(), -holder_min_y(), 0])
      base();
  }
}

// ===== Точка входа ====================
module main() {
  show_all();
}

main();
