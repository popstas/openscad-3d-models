// OpenSCAD: съёмный погон майора 80×45 мм
// Версия: v1.4 — сборка или раскладка деталей для печати

description = "Removable Major shoulder board 80x45 mm, 3-part multicolor";
version_str = "1.4";

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
edge_chamfer_z = 0;
edge_chamfer_x = 0;
edge_chamfer_y = 0;
screen_frame_gap = 0.2;

// ===== Параметры модели =====
board_length = 80;
board_width = 45;
board_th = 2.0;

top_round_r = board_width / 2;
rect_h = board_length - top_round_r;

border_w = 2.0;
border_relief = 0.35;

stripe_w = 3.5;
stripe_center_gap = 18.0;
stripe_relief = 0.3;

star_d = 20;
star_center_x = board_width / 2;
star_center_y = 45;
star_outer_r = star_d / 2;
star_inner_r = star_outer_r * 0.42;
star_relief = 1.6;

color_parts = true;
layout_parts = false; // false — сборка (для Bambu/3 STL); true — разнести по столу
part_gap_x = 10; // зазор между деталями при layout_parts=true, мм
part_stack_gap = 0.02; // микрозазор между слоями в сборке, мм (0 = вплотную)
print_blue_base = true;
print_red_trim = true;
print_rank_star = true;

// ===== Комментарии ===========================
/*
Модель: съёмный погон майора для рубашки/куртки.
Блоки:
- Переменные (вверху) для всех размеров
- Комментарии (этот блок)
- Модули фрагментов детали (ниже)
- show_all() — вывод включённых деталей

layout_parts=false: детали в сборочной позиции (экспорт STL для Bambu).
layout_parts=true: каждая деталь на Z=0, разнесена по X для печати по отдельности.

Детали (3 модуля для печати):
- blue_base — синее поле погона
- red_trim — красная окантовка и два просвета
- rank_star — золотая звезда с 5 рёбрами
Контур: прямоугольник board_width × rect_h с полукруглым верхом (радиус top_round_r).
Ось погона: X = board_width/2.
*/

// ===== Вспомогательные функции ====================
function part_slot_step() = board_width + part_gap_x;

function red_trim_h() = max(border_relief, stripe_relief);

function stack_red_z() = board_th + part_stack_gap;

function stack_star_z() = stack_red_z() + red_trim_h() + part_stack_gap;

function count_print_parts() =
  (print_blue_base ? 1 : 0) +
  (print_red_trim ? 1 : 0) +
  (print_rank_star ? 1 : 0);

function layout_index(enabled, after_blue, after_red) =
  layout_parts && count_print_parts() > 1 && enabled ?
    (after_blue + after_red) * part_slot_step() :
    0;

// ===== Модули деталей ====================
module board_outline_2d() {
  union() {
    square([board_width, board_rect_h()]);
    translate([board_width / 2, board_rect_h()])
      circle(r = top_round_r, $fs = pin_fs, $fa = 6);
  }
}

function star_xy_points(outer_r, inner_r, n = 5, rot = -90) = [
  for (i = [0 : 2 * n - 1])
    let(
      a = rot + i * 180 / n,
      r = (i % 2 == 0) ? outer_r : inner_r
    )
    [r * cos(a), r * sin(a)]
];

function star_ridge_top_faces(n = 5) = [
  for (k = [0 : n - 1])
    let(
      outer = 1 + 2 * k,
      inner_after = 1 + (2 * k + 1) % (2 * n),
      inner_before = 1 + (2 * k - 1 + 2 * n) % (2 * n)
    )
    each [[0, outer, inner_after], [0, inner_before, outer]]
];

function star_ridge_bottom_faces(n = 5) = [
  for (i = [0 : 2 * n - 1])
    [2 * n + 1, 1 + i, 1 + (i + 1) % (2 * n)]
];

function star_ridge_vertices(outer_r, inner_r, peak_h, n = 5, rot = -90) =
  let(pts = star_xy_points(outer_r, inner_r, n, rot))
  concat(
    [[0, 0, peak_h]],
    [for (p = pts) [p[0], p[1], 0]],
    [[0, 0, 0]]
  );

module rank_star_body() {
  polyhedron(
    points = star_ridge_vertices(star_outer_r, star_inner_r, star_relief),
    faces = concat(star_ridge_top_faces(), star_ridge_bottom_faces()),
    convexity = 10
  );
}

module base_pad() {
  linear_extrude(height = board_th)
    board_outline_2d();
}

module red_border() {
  linear_extrude(height = border_relief)
    difference() {
      board_outline_2d();
      inset(d = border_w)
        board_outline_2d();
    }
}

module red_stripe(offset_x) {
  intersection() {
    linear_extrude(height = stripe_relief)
      translate([offset_x - stripe_w / 2, -tiny])
        square([stripe_w, board_length + 2 * tiny]);
    linear_extrude(height = stripe_relief + tiny)
      board_outline_2d();
  }
}

module red_stripe_left() {
  red_stripe(star_center_x - (stripe_center_gap + stripe_w) / 2);
}

module red_stripe_right() {
  red_stripe(star_center_x + (stripe_center_gap + stripe_w) / 2);
}

function board_rect_h() = board_length - top_round_r;

// ===== Геометрия деталей (локально от Z=0) ====================
module blue_base_geom() {
  if (color_parts) color("MidnightBlue") base_pad();
  else base_pad();
}

module red_trim_geom() {
  intersection() {
    linear_extrude(height = max(border_relief, stripe_relief) + tiny)
      board_outline_2d();
    union() {
      red_border();
      red_stripe_left();
      red_stripe_right();
    }
  }
}

module rank_star_geom() {
  if (color_parts) color("Gold") rank_star_body();
  else rank_star_body();
}

// ===== Детали в сборочной позиции ====================
module blue_base() {
  blue_base_geom();
}

module red_trim() {
  translate([0, 0, stack_red_z()]) {
    if (color_parts) color("FireBrick") red_trim_geom();
    else red_trim_geom();
  }
}

module rank_star() {
  translate([star_center_x, star_center_y, stack_star_z()])
    rank_star_geom();
}

// ===== Размещение деталей ====================
module placed_blue_base() {
  translate([layout_index(true, 0, 0), 0, 0])
    blue_base();
}

module placed_red_trim() {
  translate([
    layout_index(print_red_trim, print_blue_base, 0),
    0,
    layout_parts ? 0 : stack_red_z()
  ]) {
    if (color_parts) color("FireBrick") red_trim_geom();
    else red_trim_geom();
  }
}

module placed_rank_star() {
  translate([
    layout_index(
      print_rank_star,
      print_blue_base,
      print_red_trim
    ),
    0,
    0
  ])
    translate([
      layout_parts ? 0 : star_center_x,
      layout_parts ? 0 : star_center_y,
      layout_parts ? 0 : stack_star_z()
    ])
      rank_star_geom();
}

module show_all() {
  clip_for_fragments_bbox(
    layout_parts ?
      part_slot_step() * max(0, count_print_parts() - 1) + board_width :
      board_width,
    board_length,
    stack_star_z() + star_relief + 1,
    test_fragment,
    frag_size,
    frag_index,
    frag_h_extra
  ) {
    if (print_blue_base) placed_blue_base();
    if (print_red_trim) placed_red_trim();
    if (print_rank_star) placed_rank_star();
  }
}

// ===== Точка входа ====================
show_all();
