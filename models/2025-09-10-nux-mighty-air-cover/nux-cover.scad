// =============================================
// 3D: nux mighty air cover
// Version: 1.0
// Author: generator
// =============================================

description = "Thin cover plate 140.9x52x1 mm, bottom corners R5, two holes";
version_str = "1.0";

// ----------------------------
// Фрагменты: назовите элементы короткими именами с _
// - base: основная деталь
// - TODO: top_pad, base_pad, wrap_left, main_wall: примеры имён
// ----------------------------

// Параметры модели (position: front at XZ axis, top view at XY, side view at YZ)
// base x, y, z указаны для внешних габаритов. Внутренние размеры меньше на ширину стенок
// ----------------------------
base_x = 140.9; // ширина X, мм, width
base_y = 52; // глубина Y, мм
base_z = 1.2; // толщина пластины по Z, мм
base_h = base_z; // для clip_for_fragments()
base_th = 1; // толщина стенки (не используется здесь)
radius_r = 8; // скругление только у нижних углов
mink_r = 0; // не используется

// Отверстия
big_hole_x = 16.9;  // мм (от левого края)
big_hole_y = 36;    // мм (от нижнего края)
big_hole_d = 6.3;   // мм

small_hole_x = 127; // мм
small_hole_y = 11;  // мм
small_hole_d = 3.5; // мм

// Джек-модули (отдельные детали рядом с основной пластиной)
height_to_body = 15; // высота над плоскостью
height_to_deep = 7; // глубина под плоскостью (суммарная высота = 30)
small_jack_d = 3.5 + 0.1;
big_jack_d   = 6.3 + 0.1;
small_jack_cap_d = 7;    // как указано
big_jack_cap_d   = 12.6; // 2x 6.3
jack_cap_th = 0.8;

// Флаги печати
print_body  = true;  // печатать основную пластину
print_jacks = true;  // печатать джек-цилиндры и их крышки

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

// ===== Режим печати тест‑фрагментов =====
test_fragment = false;   // true — печатать только угловые фрагменты
frag_size     = 20;      // размер квадрата вырезки, мм
frag_index    = 0;       // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП
frag_gap_x    = 10;      // зазор между фрагментами по X, мм
frag_h_extra  = 20;      // запас по высоте клипа, мм

// ===== Общие доп. параметры =====
tiny = 0.1;                  // небольшой зазор для булевых операций
edge_chamfer_z = 1;          // высота фаски по Z (мм)
edge_chamfer_x = 5;          // горизонтальный вылет фаски по X (мм)
edge_chamfer_y = 5;          // горизонтальный вылет фаски по Y (мм)
screen_frame_gap = 0.2;      // только для высоты вычитаний

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

// 2D прямоугольник со скруглением только по нижним углам (min Y)
module rounded_rect_min_y(size=[10,10], r=2){
    L = size[0];
    W = size[1];
    rr = min(r, min(L/2, W));
    hull(){
        // верхний прямоугольник сохраняет острые верхние углы
        translate([0, rr]) square([L, max(W - rr, eps())], center=false);
        // нижние углы — четверти окружности
        translate([rr, rr]) circle(r=rr);
        translate([L - rr, rr]) circle(r=rr);
    }
}

module plate_2d(){
    rounded_rect_min_y([base_x, base_y], r=radius_r);
}

module cover_plate(){
    linear_extrude(height=base_z)
        plate_2d();
}

module holes(){
    // Сквозные отверстия
    translate([big_hole_x, big_hole_y, -tiny])
        cylinder(h=base_z + 2*tiny, d=big_hole_d, $fs=pin_fs, $fa=6);
    translate([small_hole_x, small_hole_y, -tiny])
        cylinder(h=base_z + 2*tiny, d=small_hole_d, $fs=pin_fs, $fa=6);
}

module cover(){
    difference(){
        cover_plate();
        holes();
    }
}

// ----------------------------
// Джек-элементы (отдельные детали)
// ----------------------------
module small_jack(){
    cylinder(h=height_to_body + height_to_deep, d=small_jack_d, $fs=pin_fs, $fa=6);
}

module big_jack(){
    cylinder(h=height_to_body + height_to_deep, d=big_jack_d, $fs=pin_fs, $fa=6);
}

module small_jack_cap(){
    cylinder(h=jack_cap_th, d=small_jack_cap_d, $fs=pin_fs, $fa=6);
}

module big_jack_cap(){
    cylinder(h=jack_cap_th, d=big_jack_cap_d, $fs=pin_fs, $fa=6);
}

// Вывод всех деталей
module all_details(){
    if (print_body) cover();

    if (print_jacks){
        // Расположим справа от пластины, с зазором frag_gap_x
        col1_x = base_x + frag_gap_x;                       // колонка 1 (small)
        col2_x = col1_x + max(small_jack_d, small_jack_cap_d) + frag_gap_x; // колонка 2 (big)
        row_gap_y = frag_gap_x;                              // вертикальный зазор

        // Small jack + cap
        translate([col1_x, 0, 0]) small_jack();
        translate([col1_x, 0, 0]) small_jack_cap();

        // Big jack + cap
        translate([col2_x, 0, 0]) big_jack();
        translate([col2_x, 0, 0]) big_jack_cap();
    }
}

// Final rotate/translate
module orient(){
    translate([0,0,0]) rotate([0,0,0]) children();
}

// ----------------------------
// ВЫВОД МОДЕЛИ
// ----------------------------
module render(){
    clip_for_fragments_bbox(base_x, base_y, base_z, enabled=test_fragment, frag_size=frag_size, frag_index=frag_index, frag_h_extra=frag_h_extra){
        orient(){ all_details(); }
    }
}

render();
