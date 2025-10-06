// =============================================
// 3D: Audio Tools Case — base
// Version: 2.0
// Author: Cascade generator
// =============================================

// Short description for models table
description = "";
version_str = "2.0";

// ----------------------------
// Параметры модели (все размеры в мм)
// ----------------------------
// Коробка делится на N отделов: section 1, section 2, ... section N
// x, y, z - подразумевают внутренние размеры. Внешние размеры вычисляются автоматически.

is_small = false;
// Ширины отсеков (по X). Любое количество
sections_x = is_small ? [10, 20, 30] : [17];
// глубина по Y
inner_y    = is_small ? 20 : 42;
// внутренняя глубина во всех отсеках
inner_h    = is_small ? 10 : 53;
    
// Скругление наружного прямоугольника
radius_r     = 1;          // радиус скругления углов
sec_corner_r = 2;          // радиус скругления углов вырезов секций
minkowski_r  = 2;          // радиус скругления краёв крышки через minkowski

// Толщины
wall_th      = 1.0;          // толщина наружных стенок
divider_th   = 1.0;          // толщина перегородок
bottom_th    = 1.0;          // толщина дна

// Параметры крышки (cap)
cap_top_th        = 1.0;     // толщина верхней пластины крышки
cap_lip_h         = 5;     // высота юбки (захват за стенки)
cap_fit_clearance = 0.0;   // зазор между наружными стенками коробки и внутренней поверхностью юбки
cap_th            = 1.2; // толщина стенки крышки; по умолчанию согласована с margin и зазором

// Насадка крышки: опустить вершины межсекционных перегородок на заданную высоту
// Делает перегородки ниже на Z, чтобы крышка/вкладыш входили без упора в перегородки
sections_to_cap_gap = 5; // мм

// Поправки размеров (фактические измерения)
sec_x_delta   = 0;     // каждая секция по X шире, чем надо
y_delta       = 0;     // каждая секция по Y шире, чем надо

// Флаги печати
print_box = false;     // печатать основание (лоток)
print_cap = true;     // печатать крышку





use <../modules.scad>;

// ----------------------------
// Настройка точности
// ----------------------------
$fn = 0;        // фиксированную сегментацию отключаем
$fa = 6;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий

// Эффективные размеры с учётом поправок
sections_x_e = [ for (w = sections_x) w + sec_x_delta ];

// Вспомогательные функции суммирования
function sum_first(v, n, i=0, acc=0) = (i >= n) ? acc : sum_first(v, n, i+1, acc + v[i]);
function vec_sum(v) = sum_first(v, len(v));

cap_h = cap_top_th + cap_lip_h;   // итоговая высота крышки

// Предвычисленные вспомогательные величины (для читаемости, без изменения формул)
n_sections = len(sections_x_e);
sum_sections_x = vec_sum(sections_x_e);
outer_margin_eff = cap_fit_clearance + cap_th; // посадка крышки
cap_h_target = cap_top_th + cap_lip_h;

// ----------------------------
// Геометрия корпуса
// ----------------------------
// Общая ширина X: стены + сумма секций + перегородки между ними
inner_y_e = inner_y + y_delta;
outer_x = 2*wall_th + sum_sections_x + divider_th * max(n_sections - 1, 0);
outer_y = 2*wall_th + inner_y_e;
outer_h = bottom_th + inner_h;

// Отсеки формируются перегородками; явные вырезы не используются

// Базовый заполняющий объём (без вырезов) — внешний контур на полную высоту
module base_fill(){
    // Только внешний контур на полную высоту; срез верха делаем позже, локально по перегородкам
    rounded_prism(size=[outer_x, outer_y], h=outer_h, r=radius_r);
}

section_x_offset = wall_th;
section_y = wall_th;
// Вырезы-отсеки формируются по массиву sections_x_e
// Позиция i-го отсека: сдвиг от левой стены = сумма предыдущих ширин + перегородки между ними
function section_x_at(i) = section_x_offset + sum_first(sections_x_e, i) + divider_th * i;
module section_at(i){
    translate([section_x_at(i), section_y, bottom_th])
        rounded_prism(size=[sections_x_e[i], inner_y_e], h=inner_h, r=sec_corner_r);
}

module base(){
    // Корпус-лоток как разность наружного корпуса (с опциональным Minkowski) минус секции,
    // а затем локальный срез верхушек перегородок
    difference(){
        // Наружный корпус
        rounded_prism([outer_x, outer_y], outer_h, radius_r, minkowski_r);

        // Вырезы секций по массиву ширин (section 1..N)
        for (i = [0 : n_sections - 1])
            section_at(i);

        // Срезать верх перегородок на заданную высоту, не затрагивая наружные стены
        dividers_top_cut();
    }
}

// Сервис: левый X-край перегородки между секцией i и i+1
function divider_x_at(i) = section_x_at(i) + sections_x_e[i];

// Локальный верхний срез только по перегородкам (полосы шириной divider_th)
module dividers_top_cut(){
    // Безопасный зажим высоты среза: 0..(inner_h-eps)
    g = min(max(sections_to_cap_gap, 0), inner_h);
    if (g > 0 && n_sections > 1){
        for (i = [0 : n_sections - 2])
            translate([
                divider_x_at(i) - sec_corner_r*2,
                wall_th,
                // немного уводим вниз на eps, чтобы исключить выход выше верха
                bottom_th + inner_h - g
            ])
                cube([sec_corner_r*4+divider_th, inner_y_e, g]);
    }
}

// ---------------
// Крышка (cap)
// ---------------
// Крышка состоит из:
// - верхней пластины толщиной cap_top_th, размерами больше корпуса с каждой стороны
// - внутренней юбки высотой cap_lip_h, которая надевается на корпус с зазором cap_fit_clearance
module cap(){
    difference(){
        // Наружный контур с опциональным скруглением краёв
        rounded_prism(
            [outer_x + 2*outer_margin_eff, outer_y + 2*outer_margin_eff],
            h=cap_h_target,
            r=radius_r,
            kr=minkowski_r
        );

        // Внутренняя поверхность юбки (посадка по зазору)
        translate([cap_th, cap_th, 0])
            rounded_prism(
                size=[outer_x + 2*cap_fit_clearance, outer_y + 2*cap_fit_clearance],
                h=cap_lip_h + 2*eps(),
                r=radius_r + cap_fit_clearance
            );
    }
}

// Вывод всех фрагментов
// ----------------------------
module all_parts(){
    // Раскладка деталей по Y при одновременной печати
    x_gap = 10;  // использовать существующий зазор
    y_shift = (print_box && print_cap) ? (outer_y + x_gap) : 0;

    if (print_box) translate([0, 0, 0]) base();
    if (print_cap) translate([0, y_shift, 0]) upside_down(cap_h) cap();
}

// ----------------------------
// ВЫВОД МОДЕЛИ
// ----------------------------
clip_for_fragments(){ all_parts(); }
 