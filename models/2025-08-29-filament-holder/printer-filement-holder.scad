// =============================================
// 3D: filament holder
// Version: 1.0
// Author: generator
// =============================================

description = "Держатель катушки, крепится сбоку на принтер, на magsafe магнит";
version_str = "1.0";

// ----------------------------
// Фрагменты: назовите элементы короткими именами с _
// - base: основная деталь
// - TODO: top_pad, base_pad, wrap_left, main_wall: примеры имён
// ----------------------------

// Параметры модели
// ----------------------------
// Главные размеры из ТЗ:
base_pad_d = 60;    // диаметр основания, мм
base_pad_h = 2;     // высота основания, мм

body_outer_d = 45;  // внешний диаметр корпуса (труба), мм
body_h = 77;        // высота корпуса, мм
wall_th = 2.0;      // толщина стенки трубы, мм (Уточнить!)

hook_d = 50;        // диаметр верхнего диска ("hook"), мм
hook_h = 5;         // высота верхнего диска, мм
hook_kr = 3.0;      // радиус скругления краёв hook через Minkowski (0 = без)

// Фаски/скругления
edge_ch = 0.8;      // фаска по верхнему краю трубы, мм (0 = без фаски)
tiny = 0.1;         // eps helper for booleans

// Включение деталей для вывода
print_base = true;
print_body = true;
print_top_hook = true;

// ----------------------------




use <../modules.scad>;

// ----------------------------
// Настройка точности
// ----------------------------
$fn = 0;        // фиксированную сегментацию отключаем
$fa = 6;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий

// ----------------------------
// Вспомогательные модули
// ----------------------------
// Скруглённый цилиндр через Minkowski, сохраняет заданные d/h
module rounded_cyl(d=10, h=5, kr=0){
    k = max(kr, 0);
    if (k <= 0){
        cylinder(h=h, d=d);
    } else {
        d2 = max(d - 2*k, eps());
        h2 = max(h - 2*k, eps());
        translate([0,0,k])
            minkowski(){
                cylinder(h=h2, d=d2);
                sphere(r=k, $fs=fs_pin(), $fa=6);
            }
    }
}

// ----------------------------
// Вычисляемые переменные
// ----------------------------
inner_d = max(body_outer_d - 2*wall_th, 0.5);
ch = clamp(edge_ch, 0, body_h/2);

// ----------------------------
// Модули фрагментов модели
// ----------------------------
module base(){
    // Основание: сплошной диск Ø60, h=2
    cylinder(h=base_pad_h, d=base_pad_d);
}

module body(){
        // Прямая часть стенки (до начала фаски)
        difference(){
            cylinder(h=max(body_h, eps()), d=body_outer_d);
            translate([0,0,-eps()]) cylinder(h=max(body_h, eps()) + 2*eps(), d=inner_d);
        }
}

module top_hook(){
    // Верхний диск ("hook"): сплошной цилиндр Ø50, h=5
    rounded_cyl(hook_d, hook_h, hook_kr);
}

// Вывод всех деталей
module all_details(){
    // Стек деталей по Z: base -> body -> top_hook
    if (print_base) base();
    if (print_body) translate([0,0,base_pad_h]) body();
    if (print_top_hook) translate([0,0,base_pad_h + body_h]) top_hook();
}

// Final rotate/translate
module orient(){
    translate([0,0,0]) rotate([0,0,0]) children();
}

// ----------------------------
// ВЫВОД МОДЕЛИ
// ----------------------------
module render(){
    clip_for_fragments(){ orient(){ all_details(); } }
}

render();
