// =============================================
// 3D: ${longName}
// Version: 1.0
// Author: generator
// =============================================

description = "${shortDescription}";
version_str = "1.0";

// ----------------------------
// Фрагменты: назовите элементы короткими именами с _
// - base: основная деталь
// - TODO: top_pad, base_pad, wrap_left, main_wall: примеры имён
// ----------------------------

// Параметры модели (position: front at XZ axis, top view at XY, side view at YZ)
// base x, y, z указаны для внешних габаритов. Внутренние размеры меньше на ширину стенок
// ----------------------------
base_x = 50; // ширина X, мм, width
base_y = 100; // глубина Y, мм, глубина при pow: XZ
base_z = 30; // высота Z, мм
base_th = 1.6; // толщина стенок
radius_r = 3; // скругление
mink_r = 3;

// Включение деталей для вывода
print_base = true; // print base
print_cap = true; // print cap
// TODO: print vars for each detail

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
// Вычисляемые переменные
// ----------------------------
// TODO:
walls_th = 2 * base_th;
cap_x = base_x + walls_th + walls_th;
cap_y = base_y + walls_th + walls_th;
cap_th = base_th;
cap_z = cap_th * 3;

// ----------------------------
// Модули фрагментов модели
// ----------------------------
module base(){
    rounded_prism_with_pocket(
        size=[base_x, base_y],
        h=base_z,
        r=radius_r,
        kr=mink_r,
        wall_th=base_th,
        h_th=base_th
    );
}

module cap(){
    rounded_prism_with_pocket(
        size=[cap_x, cap_y],
        h=cap_z,
        r=radius_r,
        kr=mink_r,
        wall_th=cap_th,
        h_th=cap_th
    );
}

// Вывод всех деталей
module all_details(){
    if(print_base) base();
    if(print_cap) translate([cap_x + walls_th, -cap_th, 0]) cap();
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
