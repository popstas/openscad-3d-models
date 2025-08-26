// =============================================
// 3D: phone iphone14 mini table holder — base
// Version: 1.0
// Author: generator
// =============================================
use <../modules.scad>;

// Short description for models table
description = "phone iphone14 mini table holder — base";

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

// Ориентация вывода
flip_upside_down = true; // повернуть модель дном вверх (для печати под стол)

// ----------------------------
// Фаски/скругления по краям (совместимость)
// ----------------------------
tiny = 0.1;                  // небольшой зазор для булевых операций
edge_chamfer_z = 1;          // высота фаски по Z (мм)
edge_chamfer_x = 5;          // горизонтальный вылет фаски по X (каждая сторона), мм
edge_chamfer_y = 5;          // горизонтальный вылет фаски по Y (каждая сторона), мм
screen_frame_gap = 0.2;      // совместимость

// ----------------------------
// Параметры модели (все размеры в мм)
// ----------------------------
// Телефон (с учётом чехла/кнопок)
phone_w = 65;          // ширина телефона по X
phone_h = 131;         // высота телефона (идёт в глубину кармана) по Y
phone_t = 10;          // толщина телефона по Z

// Зазоры кармана (внутренние)
pocket_clear_xy = 0.8; // общий запас по X (ширина) — суммарно
pocket_clear_z  = 0.8; // запас по Z (толщина)

// Стенки/толщины
wall_xy   = 2.6;       // толщина боковой стенки (X/Y)
wall_z    = 2.6;       // толщина снизу/сверху (Z)
back_wall = 4;         // задняя стенка глубины кармана

// Подложка (base_pad)
base_pad_extra_x = 2; // дополнительная ширина подложки по X

// Режущие элементы кармана
notch_depth_ratio = 0.5; // доля глубины для нижнего выреза (0..1)
notch_h           = 6;   // высота выреза снизу по Z
notch_r_xy        = 0;   // скругление выреза в плане
// Фаска вокруг кармана
pocket_chamfer          = 5;   // размер фаски (вылет по XY == высота по Z)
pocket_chamfer_at_bottom = true; // true: у дна кармана, false: у входа

// Скругления
body_r_xy   = 0; // внешнее скругление корпуса (в плане XY) — отключено по Z-краям
pocket_r_xy = 0; // скругление углов кармана (в плане XY)
bottom_chamfer_y = 0; // фаска по оси Y у низа корпуса (0 = выкл.)

// Производные размеры
pocket_w   = phone_w + pocket_clear_xy;                 // внутренняя ширина
pocket_d   = phone_h;                                   // глубина кармана
base_h     = phone_t + pocket_clear_z + 2*wall_z;       // общая высота детали
body_x     = pocket_w + 2*wall_xy;                      // ширина корпуса без ручек
body_y     = pocket_d + back_wall;                      // длина корпуса по Y

// ----------------------------
// Фрагменты: назовите элементы короткими именами с _
// ----------------------------
// - base: основная деталь
// - top_pad, base_pad, wrap_left, main_wall: примеры имён

// ----------------------------
// Вспомогательные
// ----------------------------
// Универсальный цилиндр-бар вдоль оси Y
// xc — центр по X, zc — центр по Z, r — радиус, h — длина по Y
module cyl_bar_y(xc, zc, r, h=phone_h){
    translate([xc, 0, zc]) rotate([-90,0,0])
        cylinder(h=h, radius=r, $fs=pin_fs, $fa=6);
}

// Призма для фаски низа корпуса вдоль оси Y (треугольный клин)
module chamfer_wedge_y(ch, len_y){
    linear_extrude(height=len_y)
        polygon(points=[[0,0],[ch,0],[0,ch]]);
}

// Фаски низа корпуса вдоль оси Y: вычитание треугольных призм по бокам
module base_bottom_chamfers(){
    ch = bottom_chamfer_y;
    if(ch > 0){
        // слева
        translate([0,0,0]) chamfer_wedge_y(ch, body_y);
        // справа (зеркалим по X у правого края)
        translate([body_x,0,0]) mirror([1,0,0]) chamfer_wedge_y(ch, body_y);
    }
}

// ----------------------------
// ФРАГМЕНТЫ ДЕТАЛИ
// ----------------------------
// - base: корпус с подложкой (base_pad)
// - pocket_cut: вычитание кармана

// убраны handles/holes — модель упрощена до базы и кармана

module pocket_cut(){
    // Основная полость под телефон
    translate([wall_xy, 0, wall_z])
        linear_extrude(height=phone_t + pocket_clear_z)
            rounded_rect([pocket_w, pocket_d], radius=pocket_r_xy);

    // Нижний вырез от края стола внутрь на долю глубины (50%)
    translate([wall_xy, 0, 0])
        linear_extrude(height=notch_h)
            rounded_rect([pocket_w, pocket_d*notch_depth_ratio], radius=notch_r_xy);

    // Призматическая фаска (треугольная по Z) ВНУТРИ кармана: кольцо между
    // уменьшенным сечением (сверху) и базовым (снизу), чтобы клин смотрел внутрь
    ch = min(pocket_chamfer, phone_t + pocket_clear_z);
    z0 = pocket_chamfer_at_bottom ? wall_z : wall_z + (phone_t + pocket_clear_z) - ch;
    translate([wall_xy, 0, z0])
        difference(){
            // Внешняя граница фаски — УМЕНЬШЕННОЕ сечение (верхняя грань)
            linear_extrude(height=ch)
                translate([ch, ch])
                    rounded_rect([max(pocket_w - 2*ch, tiny), max(pocket_d - 2*ch, tiny)], radius=max(pocket_r_xy - ch, tiny));
            // Внутренняя граница фаски — базовое сечение (нижняя грань)
            linear_extrude(height=ch) rounded_rect([pocket_w, pocket_d], radius=pocket_r_xy);
        }
}

// Вырезы на ручках по всей длине phone_h, построены из цилиндров
module handles_front_cut(){
    if(handles_cut_use_rect){
        // Сильно скруглённый прямоугольник на всю phone_h, по Z — насквозь
        linear_extrude(height=base_h + 2*tiny){
            union(){
                translate([-handle_ext, 0]) rounded_rect([handle_ext, phone_h], radius=handles_front_cut_r);
                translate([body_x, 0])      rounded_rect([handle_ext, phone_h], radius=handles_front_cut_r);
            }
        }
    } else {
        // Вариант цилиндрами вдоль оси Y — два цилиндра по центру каждой ручки
        rad = handles_front_cut_r;
        cyl_bar_y(-handle_ext/2, base_h/2, rad, phone_h);
        cyl_bar_y(body_x + handle_ext/2, base_h/2, rad, phone_h);
    }
}

// Убраны боковые вырезы

// Убраны отверстия

module base(){
    difference(){
        union(){
            // Корпус + расширенная подложка по X (симметрично: +/- base_pad_extra_x)
            translate([-base_pad_extra_x, 0, 0])
                linear_extrude(height=base_h)
                    rounded_rect([body_x + 2*base_pad_extra_x, body_y], radius=body_r_xy);
        }
        // Полость и нижний вырез
        pocket_cut();
        // Снятие фасок по оси Y у низа корпуса
        base_bottom_chamfers();
    }
}

// ---------------
// Клиппер фрагментов
// ---------------
module clip_for_fragments(){
    if(test_fragment){
        intersection(){
            children(0);
            translate([0, 0, -frag_h_extra]) cube([frag_size, frag_size, base_h + 2*frag_h_extra]);
        }
    } else { children(); }
}

// ----------------------------
// ВЫВОД МОДЕЛИ
// ----------------------------
module orient(){
    if(flip_upside_down){
        translate([0,0,base_h]) rotate([180,0,0]) children();
    } else children();
}

clip_for_fragments(){ orient(){ base(); } }
