// OpenSCAD: крышка 38-400 с воронкой 20мм и колпаком сверху
// Версия: 1.1 — добавлен колпак сверху воронки

description = "Bottle cap 38-400 with 20mm funnel and top cap for dispenser";

use <../modules.scad>
include <../BOSL2/std.scad>
include <../BOSL2/bottlecaps.scad>

// ===== Точность аппроксимации окружностей =====
$fn = 0;        // фиксированную сегментацию отключаем
$fa = 6;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий

// ===== Параметры печати =====
print_lid = true;     // печатать крышку 38-400 с воронкой
print_cap = true;     // печатать колпак сверху воронки

// ===== Параметры крышки 38-400 =====
diam = 38;           // диаметр резьбы 38-400 / GL38 class
type = 400;          // тип резьбы
wall = 1;            // толщина стенки крышки
slop = 0.7;          // дополнительный зазор под принтер/пластик
lid_height = 5;      // высота крышки 38-400, мм

// ===== Параметры воронки =====
funnel_top_diam = 20;    // верхний диаметр воронки (подключен к крышке), мм
funnel_bottom_diam = diam + wall*2 - 0.5; // нижний диаметр воронки (выход, больше), мм
funnel_length = 30;      // длина воронки, мм
funnel_thin_length = 10; // длина тонкой части воронки, мм
funnel_wall = 1.0;       // толщина стенки воронки, мм

// ===== Параметры колпака сверху =====
// Колпак зависит от диаметра воронки
cap_inner_d     = funnel_top_diam - 0.4; // внутренний диаметр колпака (посадка на воронку)
cap_wall_th     = 1.0;     // толщина стенки (радиальная)
cap_top_th      = 1.6;     // толщина крышки сверху
cap_height      = 8;       // общая наружная высота колпака
cap_fit_extra   = 0.15;    // технологический запас внутрь (увеличение внутреннего Ø)
mink_r          = 0.7;     // радиус скругления колпака через minkowski
test_cut_d      = 5;       // диаметр вырезки в середине cap_inner_d для теста
print_test_cut  = false;   // false - не делать вырез в середине

// Вычисляемые размеры колпака
cap_inner_d_eff = cap_inner_d + 2*cap_fit_extra; // реальный внутренний Ø для печати
cap_outer_d     = cap_inner_d_eff + 2*cap_wall_th;     // наружный Ø
cap_skirt_h     = max(cap_height - cap_top_th - mink_r - mink_r * 0.175, eps());  // высота юбки
// ===== Комментарии ===========================
/*
Модель: крышка 38-400 с воронкой и колпаком для дозатора
Блоки:
- Переменные (вверху) для всех размеров
- Комментарии (этот блок)
- Модули деталей (ниже)
- Функция вывода всех фрагментов show_all()

Детали: 
- lid_cap — крышка 38-400 (BOSL2 sp_cap)
- funnel — воронка с узким входом 20мм (подключен к крышке) и широким выходом ~40мм
- top_cap — простой колпак сверху воронки (закрывает отверстие 20мм)

План: крышка создаётся через sp_cap, воронка добавляется снизу, колпак сверху
Параметры print_lid и print_cap управляют выводом деталей
*/

// ===== Модули деталей ====================
module lid_cap() {
  difference() {
    sp_cap(diam, type, wall,
           style="M",            // "M" = асимметричная buttress-резьба
           texture="ribbed",     // "knurled" | "ribbed" | "none"
           $slop=slop);
    // Удаляем нижнюю часть крышки, оставляя стены
    translate([0, 0, -6])
      cylinder(h=3, d=diam - 0*wall, $fs=pin_fs, $fa=6);
  }
}

module cap_body() {
  difference() {
    // Плоский диск со скруглением через minkowski
    if (mink_r > 0) {
      translate([0, 0, mink_r])
        minkowski() {
          cylinder(h=cap_skirt_h, d=cap_outer_d - 2*mink_r);
          sphere(r=mink_r, $fs=pin_fs, $fa=6);
        }
    } else {
      cylinder(h=cap_top_th, d=cap_outer_d);
    }
    // Вырез сверху
    translate([0, 0, cap_top_th])
      cylinder(h=cap_height, d=cap_inner_d_eff);
    
    // Опциональный тестовый вырез в центре
    if (print_test_cut) {
      translate([0, 0, 0])
        cylinder(h=cap_height, d=cap_inner_d_eff - test_cut_d);
    }
  }
}

module top_cap() {
  cap_body();
}

module funnel() {
  // Воронка: тонкая цилиндрическая часть + усечённый конус с внутренним отверстием
  difference() {
    union() {
      // Тонкая цилиндрическая часть сверху
      cylinder(h=funnel_thin_length, 
               d=funnel_top_diam,
               $fs=pin_fs, $fa=6);
      
      // Внешний конус (остальная часть)
      translate([0, 0, funnel_thin_length])
        cylinder(h=funnel_length - funnel_thin_length, 
                 d1=funnel_top_diam, 
                 d2=funnel_bottom_diam,
                 $fs=pin_fs, $fa=6);
    }
    
    // Внутренний вырез
    translate([0, 0, -0.1])
      union() {
        // Тонкая цилиндрическая часть (вырез)
        cylinder(h=funnel_thin_length + 0.1, 
                 d=funnel_top_diam - 2*funnel_wall,
                 $fs=pin_fs, $fa=6);
        
        // Внутренний конус (вырез)
        translate([0, 0, funnel_thin_length])
          cylinder(h=funnel_length - funnel_thin_length + 0.2, 
                   d1=funnel_top_diam - 2*funnel_wall, 
                   d2=funnel_bottom_diam - 2*funnel_wall,
                   $fs=pin_fs, $fa=6);
      }
  }
}

// ===== Вывод всех фрагментов ====================
module show_all() {
  // sp_cap имеет нижнюю точку примерно на z=-7.5, поднимаем всё на эту высоту
  // чтобы низ крышки был на z=0
  lid_bottom_offset = 7.5;
  
  if (print_lid) {
    translate([0, 0, lid_bottom_offset]) {
      // Крышка 38-400 (центрирована по умолчанию)
      lid_cap();
      
      // Воронка снизу крышки
      // sp_cap центрирован, его нижняя точка примерно на -7.5mm
      // Позиционируем воронку так, чтобы её верх совпадал с низом крышки
      // Воронка идёт вниз от низа крышки
      translate([0, 0, -lid_bottom_offset - funnel_length])
        funnel();
    }
  }
  
  if (print_cap) {
    // Колпак сверху воронки
    // Если печатается вместе с крышкой, позиционируем на верху воронки
    // Если отдельно, просто выводим в центре на z=0
    if (print_lid) {
      // Верх воронки находится на высоте lid_bottom_offset - lid_bottom_offset = 0
      // Размещаем колпак сбоку для удобства просмотра
      translate([cap_outer_d + 20, 0, 0])
        top_cap();
    } else {
      top_cap();
    }
  }
}

// ===== Точка входа ====================
show_all();