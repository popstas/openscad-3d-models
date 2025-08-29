// =============================================
// 3D: Mic Transceiver Box — inner 100x35x17, base + cap
// Version: 1.1
// Author: ChatGPT (OpenSCAD)
// =============================================

// Short description for models table
description = "Mic Transceiver Box — inner 100x35x17, base + cap";
version_str = "1.1";

// ----------------------------
// Параметры модели (мм)
// ----------------------------
inner_x = 100;               // внутренняя длина (X)
inner_y = 35;                // внутренняя ширина (Y)
inner_h = 31;                // внутренняя высота (Z)

wall_th    = 2;            // толщина стенок основания
bottom_th  = 2;            // толщина дна основания
corner_r   = 3.0;            // радиус скругления внутренних углов

// Крышка (накладная)
fit_clearance = 0.1;        // зазор на посадку (каждая сторона по радиусу/по XY)
cap_wall_th   = 1;         // толщина стенок крышки
cap_top_th    = 2;         // толщина верха крышки
cap_lip_h     = 5.0;        // глубина посадочного борта крышки (внутрь)

// Выбор вывода
print_base = true;
print_cap  = true;

// Shared library
use <../modules.scad>

// ----------------------------
// Настройка точности
// ----------------------------
$fn = 0;        // фиксированную сегментацию отключаем
$fa = 6;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий

// ----------------------------
// Вычисляемые размеры
// ----------------------------
base_outer_x = inner_x + 2*wall_th;
base_outer_y = inner_y + 2*wall_th;
base_outer_h = bottom_th + inner_h;

base_inner_r = max(corner_r, 0);
base_outer_r = base_inner_r + wall_th;

cap_inner_x = base_outer_x + 2*fit_clearance;
cap_inner_y = base_outer_y + 2*fit_clearance;
cap_inner_r = base_outer_r + fit_clearance;  // радиус по внутреннему борту крышки

cap_outer_x = cap_inner_x + 2*cap_wall_th;
cap_outer_y = cap_inner_y + 2*cap_wall_th;
cap_outer_h = cap_top_th + cap_lip_h;
cap_outer_r = cap_inner_r + cap_wall_th;

// ----------------------------
// Комментарии / фрагменты
// ----------------------------
// Фрагменты:
// - base: основание — лоток с закругленными углами и плоским дном
// - cap: крышка — закрытый верх + борт нужной глубины, посадка по fit_clearance
// ----------------------------
// Фрагменты детали
// ----------------------------
module base_body(){
    difference(){
        // внешний корпус основания с фаской снизу
        rounded_prism([base_outer_x, base_outer_y], base_outer_h, base_outer_r);
        // внутренняя полость
        translate([wall_th,wall_th,bottom_th])
            rounded_prism([inner_x, inner_y], inner_h, base_inner_r);
    }
}

module cap_shell(){
    difference(){
        // внешний объём крышки (без фаски сверху; опционально фаску снизу)
        rounded_prism([cap_outer_x, cap_outer_y], cap_outer_h, cap_outer_r);
        // внутренняя полость на глубину борта
        translate([cap_wall_th, cap_wall_th, cap_top_th])
            rounded_prism([cap_inner_x, cap_inner_y], cap_lip_h, cap_inner_r);
    }
}

// Главные детали
module base(){ base_body(); }
module cap(){ cap_shell(); }
module all_parts(){
    if (print_base) base();
    if (print_cap) {
        translate([0, base_outer_y + 10, 0]) cap();
    }
}
// ----------------------------
// ВЫВОД МОДЕЛИ
// ----------------------------
clip_for_fragments(){ all_parts(); }