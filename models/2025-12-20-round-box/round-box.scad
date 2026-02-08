// =============================================
// 3D: Round Box
// Version: 1.0
// Author: generator
// =============================================

description = "Round box with cap, inner diam 250mm, height 35mm, wall 1mm";
version_str = "1.0";

// ===== Комментарии ===========================
/*
Модель: круглая коробка с крышкой для хранения
Блоки:
- Переменные (вверху) для всех размеров
- Комментарии (этот блок)
- Функции фрагментов детали (ниже)
- Функция вывода всех фрагментов show_all()
- Функция обрезки через intersection при test_fragment=true

Детали: base (коробка), cap (крышка)
План: 
- base: цилиндрический контейнер с дном и стенками
- cap: плоский диск с цилиндрической юбкой, надевается на коробку
*/

use <../modules.scad>;

// ===== Точность аппроксимации окружностей =====
$fn = 0;        // фиксированную сегментацию отключаем
$fa = 1;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий
model_fa = 32; // угол округления коробки, 1 - круглая, 24 - 16 граней, 32 - 12 граней

// ===== Режим печати тест‑фрагментов =====
test_fragment = false;   // true — печатать только угловые фрагменты
frag_size     = 20;     // размер квадрата вырезки, мм
frag_index    = 0;      // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП (относительно основания)
frag_gap_x    = 10;     // зазор между фрагментами по X, мм
frag_h_extra  = 20;     // запас по высоте клипа, мм

// ===== Общие доп. параметры =====
tiny = 0.1;                  // небольшой зазор для булевых операций
edge_chamfer_z = 1;       // высота фаски по Z (мм)
edge_chamfer_x = 5;       // горизонтальный вылет фаски по X (с каждой стороны), мм
edge_chamfer_y = 5;       // горизонтальный вылет фаски по Y (с каждой стороны), мм
screen_frame_gap = 0.1;      // только для высоты вычитаний в рамке (не влияет на XY)
wall_th = 1.2;

// ===== Параметры модели =====
// Размеры коробки
box_inner_diam = 249;     // внутренний диаметр коробки, мм
box_height     = 35;      // высота коробки, мм
box_wall_th    = wall_th;       // толщина стенок коробки, мм
box_bottom_th  = wall_th;       // толщина дна коробки, мм

// Размеры крышки
cap_wall_th    = wall_th;       // толщина стенок крышки, мм
cap_top_th     = wall_th;       // толщина верхней части крышки, мм
cap_lip_h      = 10;      // высота юбки крышки (глубина посадки), мм
cap_fit_gap    = 0.00;     // зазор посадки крышки на коробку, мм
test_cut_d     = 20;      // диаметр вырезки в середине cap_inner_d для тестирования, мм
print_test_cut = false;   // true - делать вырез в середине cap_inner_d - test_cut_d

// Включение деталей для вывода
print_base = false;        // печатать коробку
print_cap  = true;        // печатать крышку

// ===== Вычисляемые размеры =====
box_inner_r = box_inner_diam / 2;
box_outer_diam = box_inner_diam + 2 * box_wall_th;
box_outer_r = box_outer_diam / 2;

cap_inner_diam = box_outer_diam + 2 * cap_fit_gap;
cap_inner_r = cap_inner_diam / 2;
cap_outer_diam = cap_inner_diam + 2 * cap_wall_th;
cap_outer_r = cap_outer_diam / 2;
cap_total_h = cap_top_th + cap_lip_h;

// Для совместимости с clip_for_fragments()
base_h = box_height;

// ===== Вспомогательные функции ====================
function clamp(val, lo, hi) = max(lo, min(val, hi));
function clamp_chz(t, chz) = clamp(chz, 0, t/2);

// ===== Модули деталей ====================
// Коробка: цилиндрический контейнер с дном и стенками
module base() {
  difference() {
    // Внешний цилиндр коробки
    cylinder(h=box_height, d=box_outer_diam, $fs=pin_fs, $fa=model_fa);
    // Внутренняя полость
    translate([0, 0, box_bottom_th])
      cylinder(h=box_height - box_bottom_th + tiny, d=box_inner_diam, $fs=pin_fs, $fa=model_fa);
    // Опциональный тестовый вырез в центре
    if (print_test_cut) {
      translate([0, 0, 0])
        cylinder(h=box_height + tiny, d=box_inner_diam - test_cut_d, $fs=pin_fs, $fa=model_fa);
    }
  }
}

// Крышка: плоский диск с цилиндрической юбкой
module cap() {
  difference() {
    // Внешний объём крышки
    cylinder(h=cap_total_h, d=cap_outer_diam, $fs=pin_fs, $fa=model_fa);
    // Внутренняя полость (юбка для посадки на коробку)
    translate([0, 0, cap_top_th])
      cylinder(h=cap_lip_h + tiny, d=cap_inner_diam, $fs=pin_fs, $fa=model_fa);
    // Опциональный тестовый вырез в центре
    if (print_test_cut) {
      translate([0, 0, 0])
        cylinder(h=cap_total_h + tiny, d=cap_inner_diam - test_cut_d, $fs=pin_fs, $fa=model_fa);
    }
  }
}

// ===== Вывод всех фрагментов ====================
module show_all() {
  if (print_base) base();
  if (print_cap) {
    translate([box_outer_diam + 20, 0, 0]) cap();
  }
}

// ===== Точка входа ====================
clip_for_fragments() show_all();
