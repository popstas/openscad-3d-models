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
base_th = 4; // толщина стенок
radius_r = 3; // скругление
base_mink_r = 3; // сферическое сглаживание краёв

// Включение деталей для вывода
print_base = true; // print base
print_cap = false; // print cap
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
// Тестовые фрагменты (стандартный блок)
// ----------------------------
test_fragment = false;   // true — печатать только угловые фрагменты (base+frame)
frag_size     = 20;      // размер квадрата вырезки, мм
frag_index    = 0;       // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП (относительно основания)
frag_gap_x    = 10;      // зазор между фрагментами по X, мм
frag_h_extra  = 20;      // запас по высоте клипа, мм

// ----------------------------
// Вычисляемые переменные
// ----------------------------
// TODO:
walls_th = 2 * base_th;
cap_x = base_x;
cap_y = base_y;

// ----------------------------
// Модули фрагментов модели
// ----------------------------
module base(){
    difference(){
        rounded_rr_extrude(
            size=[base_x, base_y],
            r=radius_r,
            h=base_z,
            s=1,
            mink_r=base_mink_r // сферическое сглаживание краёв
        );
        pocket_cut();
    }
}

// cut from top, to make desired base_th walls
module pocket_cut(){
    translate([base_th, base_th, base_th])
        rounded_rr_extrude(
            size=[
                base_x - walls_th,
                base_y - walls_th
            ],
            r=radius_r,
            h=base_z,
            s=1,
            mink_r=base_mink_r
        );
}

module cap(){
    translate([cap_x + walls_th, 0, 0])
        rounded_rr_extrude(
            size=[cap_x, cap_y],
            r=radius_r,
            h=base_th,
            s=1,
            mink_r=base_mink_r
        );
}

// Вывод всех деталей
module all_details(){
    if(print_base) base();
    if(print_cap) cap();
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
