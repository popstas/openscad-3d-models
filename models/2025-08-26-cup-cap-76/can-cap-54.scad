// =============================================
// 3D: Can Cap Ø53.7 (shell 1 mm, height 5 mm)
// Version: 1.2
// Author: ChatGPT (OpenSCAD)
// =============================================

// ----------------------------
// Настройка точности
// ----------------------------
description = "Can cap Ø53.7 minkowski washer with 1 mm top edge";
version_str = "1.2";

// ----------------------------
// Комментарии по устройству модели
// ----------------------------
// Фрагменты:
// - base: шайба-крышка из внешнего minkowski-корпуса
// - Внутренний меньший minkowski-вырез оставляет внешние стенки
// - Дно bottom_th остаётся закрытым, верхний цилиндрический вырез оставляет кромку top_edge_w = 1 мм

// ----------------------------
// Параметры модели (все размеры в мм)
// ----------------------------

cap_inner_d     = 52.8; // 76 - стакан, 53.7 - маленькая банка, 78.2 - кофейная кружка, 87 - чайная кружка, 125.1 - блюдце // внутренний диаметр колпака (посадка)
wall_th         = 1.0;     // толщина стенки (радиальная)
bottom_th       = 1.6;     // толщина закрытого дна крышки, мм
cap_height      = 5;       // общая наружная высота колпака
cap_rounding    = 1.0;     // радиус скругления внешнего корпуса через minkowski, мм
top_edge_w      = 1.0;     // ширина верхней кромки после цилиндрического выреза, мм
tiny            = 0.1;     // небольшой зазор для булевых операций
fit_extra_inner = 0.05;    // технологический запас внутрь (увеличение внутреннего Ø)
grip_straight_h = 2.4;     // высота прямой внутренней стенки у края, мм
grip_taper_d    = -1.0;     // сужение внутреннего Ø за зону taper, мм
test_cut_d      = 15;      // диаметр вырезки в середине cap_inner_d - 

print_test_cut = false; // false - делать вырез в середине cap_inner_d - test_cut_d

 



use <../modules.scad>

$fn = 0;        // фиксированную сегментацию отключаем
$fa = 1;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий

// Вычисляемые размеры
cap_inner_d_eff = cap_inner_d + 2*fit_extra_inner; // реальный внутренний Ø для печати
cap_outer_d     = cap_inner_d_eff + 2*wall_th;     // наружный Ø
top_cut_d       = cap_outer_d - 2*top_edge_w;     // Ø верхнего выреза, оставляет кромку 1 мм
inner_cut_d     = top_cut_d - grip_taper_d;       // меньший Ø внутреннего minkowski-выреза
inner_cut_h     = cap_height - bottom_th;         // глубина внутренней полости, дно остаётся закрытым
grip_taper_h    = inner_cut_h - grip_straight_h;  // высота сужения перед ровной стенкой

module outer_body(){
  if (cap_rounding > 0) {
    translate([0, 0, cap_rounding]) {
      minkowski() {
        cylinder(
          h=cap_height - 2*cap_rounding,
          d=cap_outer_d - 2*cap_rounding,
          $fs=pin_fs,
          $fa=6
        );
        translate([0, 0, 0]) sphere(r=cap_rounding, $fs=pin_fs, $fa=6);
      }
    }
  } else {
    cylinder(h=cap_height, d=cap_outer_d, $fs=pin_fs, $fa=6);
  }
}

module inner_minkowski_cut(){
  if (cap_rounding > 0) {
    translate([0, 0, bottom_th + cap_rounding - tiny]) {
      minkowski() {
        cylinder(
          h=inner_cut_h - 2*cap_rounding + 2*tiny,
          d=inner_cut_d - 2*cap_rounding,
          $fs=pin_fs,
          $fa=6
        );
        translate([0, 0, 0]) sphere(r=cap_rounding, $fs=pin_fs, $fa=6);
      }
    }
  } else {
    translate([0, 0, bottom_th - tiny])
      cylinder(h=inner_cut_h + 2*tiny, d=inner_cut_d, $fs=pin_fs, $fa=6);
  }
}

module top_open_cut(){
  translate([0, 0, bottom_th + grip_taper_h - tiny])
    cylinder(h=grip_straight_h + 2*tiny, d=top_cut_d, $fs=pin_fs, $fa=6);
}

module cap_body(){
  difference(){
    // Внешний корпус со скруглением как у propane-connector/bottom_cylinder.
    outer_body();
    inner_minkowski_cut();
    top_open_cut();
    if (print_test_cut) {
      translate([0, 0, 0])
        cylinder(h=cap_height, d=cap_inner_d_eff - test_cut_d);
    }
  }
}

// ----------------------------
// Основная деталь
// ----------------------------
module base(){
    cap_body();
}

// ----------------------------
// ВЫВОД МОДЕЛИ
// ----------------------------
clip_for_fragments() base();
