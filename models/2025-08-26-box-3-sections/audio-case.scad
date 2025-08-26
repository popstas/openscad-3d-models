// =============================================
// 3D: Audio Tools Case — base
// Version: 1.0
// Author: Cascade generator
// =============================================

// Short description for models table
description = "Audio Tools Case — base";
version_str = "1.0";

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
// Тестовые фрагменты (стандартный блок)
// ----------------------------
test_fragment = false;     // true — печатать только угловые фрагменты (base+frame)
frag_size     = 20;      // размер квадрата вырезки, мм
frag_index    = 0;       // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП (относительно основания)
frag_gap_x    = 10;      // зазор между фрагментами по X, мм
frag_h_extra  = 20;      // запас по высоте клипа, мм

// ----------------------------
// Фаски/скругления по краям (совместимость)
// ----------------------------
edge_chamfer_z = 1;          // высота фаски по Z (мм)
edge_chamfer_x = 5;          // горизонтальный вылет фаски по X (каждая сторона), мм
edge_chamfer_y = 5;          // горизонтальный вылет фаски по Y (каждая сторона), мм
screen_frame_gap = 0.2;      // только для высоты вычитаний в рамке (не влияет на XY)

// ----------------------------
// Параметры модели (все размеры в мм)
// ----------------------------
// Коробка делится на 3 отдела: RED (провода), YELLOW (диктофон), GREEN (РФ передатчики)
// Входные требования:
// - внутренняя высота коробки = 31
// - высота зелёного отдела max 31, жёлтого 26 (красный TBD — по умолчанию 31)
// - толщины стенок (наружных и межсекционных) = 2
// - ширины отделов: RED=30, YELLOW=67.5, GREEN=37
// - ширина по Y (глубина) не указана (inner_y)

// Флаги печати
print_box = true;     // печатать основание (лоток)
print_cap = true;     // печатать крышку

// Толщины и высоты
wall_th      = 2;          // толщина наружных стенок
divider_th   = 2;          // толщина перегородок
bottom_th    = 2;          // толщина дна

// Все отсеки открыты до верха (inner_h); индивидуальные высоты не используются

// Ширины отсеков (по X)
red_w        = 10;//30;
yellow_w     = 10;//67.5;
green_w      = 10;//37;

// Глубина по Y (внутренняя)
inner_y      = 10;//158.6;        // фактическая длина по Y
inner_h      = 10;//31;         // внутренняя высота во всех отсеках (максимум)

// Скругление наружного прямоугольника
radius_r     = 3;          // радиус скругления углов
// Скругление углов внутренних секций
sec_corner_r = 2;          // радиус скругления углов вырезов секций

// Зазоры внутри не используются на этой итерации (оставлено место для будущих настроек)

// Параметры крышки (cap)
cap_top_th        = 2;     // толщина верхней пластины крышки
cap_lip_h         = 8;     // высота юбки (захват за стенки)
cap_fit_clearance = 0.2;   // зазор между наружными стенками коробки и внутренней поверхностью юбки
cap_outer_margin  = 0.8;   // выступ крышки наружу относительно корпуса (по всем сторонам)
cap_minkowski_r  = 2;   // радиус скругления краёв крышки через minkowski
base_minkowski_r = 2;   // радиус скругления краёв основания через minkowski

inner_y_shift = inner_y - wall_th;
cap_h = cap_top_th + cap_lip_h;   // итоговая высота крышки

// ----------------------------
// Фрагменты
// ----------------------------
// - base: основная деталь (лоток)
// - перегородки формируются автоматически, как остаток между вычитаниями отсеков

// ----------------------------
// Базовый контур корпуса для оффсетов
module base_outline2d(){
    rounded_rect([outer_x, outer_y], r=radius_r);
}

// ----------------------------
// Геометрия корпуса
// ----------------------------
outer_x = 2*wall_th + red_w + divider_th + yellow_w + divider_th + green_w;
outer_y = 2*wall_th + inner_y_shift;
outer_h = bottom_th + inner_h;

// Отсеки формируются перегородками; явные вырезы не используются

// Внутренняя полость (общая) — используется только для справки
module inner_cavity(){
    translate([wall_th, wall_th, bottom_th])
        rr_extrude(size=[outer_x - 2*wall_th, outer_y - 2*wall_th], r=max(radius_r - wall_th, 0), h=inner_h + eps());
}

// Базовый заполняющий объём (без вырезов) — внешний контур на полную высоту
module base_fill(){
    rr_extrude(size=[outer_x, outer_y], r=radius_r, h=outer_h);
}

section_x_offset = wall_th+wall_th/2;
section_y = wall_th+wall_th/2;
// Три выреза-отсека. Их суммарная ширина и позиции оставляют наружные стены и две перегородки толщиной divider_th.
module section_red(){
    translate([section_x_offset, section_y, bottom_th])
        rr_extrude(size=[red_w, inner_y_shift], r=sec_corner_r, h=inner_h);
}

module section_yellow(){
    translate([section_x_offset + red_w + divider_th, section_y, bottom_th])
        rr_extrude(size=[yellow_w, inner_y_shift], r=sec_corner_r, h=inner_h);
}

module section_green(){
    translate([section_x_offset + red_w + divider_th + yellow_w + divider_th, section_y, bottom_th])
        rr_extrude(size=[green_w, inner_y_shift], r=sec_corner_r, h=inner_h);
}

module base(){
    // Корпус-лоток как разность наружного корпуса (с опциональным Minkowski) и 3 секций
    difference(){
        // Наружный корпус
        if (base_minkowski_r > 0){
            // Сохраняем габариты и выравнивание в (0,0):
            // 1) предварительно уменьшаем XY и Z на 2*r
            // 2) выполняем minkowski со сферой, сдвинутой на [r,r,r], чтобы min-угол оставался в (0,0)
            minkowski(){
                rr_extrude(size=[max(outer_x - 2*base_minkowski_r, eps()), max(outer_y - 2*base_minkowski_r, eps())],
                           r=max(radius_r - base_minkowski_r, 0),
                           h=max(outer_h - 2*base_minkowski_r, eps()));
                translate([base_minkowski_r, base_minkowski_r, base_minkowski_r]) sphere(r=base_minkowski_r);
            }
        } else {
            base_fill();
        }

        // Вырезы секций
        section_red();
        section_yellow();
        section_green();
    }
}

// ---------------
// Крышка (cap)
// ---------------
// Крышка состоит из:
// - верхней пластины толщиной cap_top_th, размерами больше корпуса на cap_outer_margin с каждой стороны
// - внутренней юбки высотой cap_lip_h, которая надевается на корпус с зазором cap_fit_clearance
// Компоненты крышки вынесены в отдельные модули: cap_pad, cap_skirt, cap_skirt_inner

// Верхняя пластина крышки (top pad)
module cap_pad(){
    rr_extrude(size=[outer_x + 2*cap_outer_margin, outer_y + 2*cap_outer_margin], r=radius_r + cap_outer_margin, h=cap_top_th);
}

// Наружная юбка (outer skirt)
module cap_skirt(){
    rr_extrude(size=[outer_x + 2*cap_outer_margin, outer_y + 2*cap_outer_margin], r=radius_r + cap_outer_margin, h=cap_lip_h);
}

// Внутренняя поверхность юбки (inner cut) — делает посадку по зазору
module cap_skirt_inner(){
    translate([0,0,-eps()])
        rr_extrude(size=[outer_x + 2*cap_fit_clearance, outer_y + 2*cap_fit_clearance], r=radius_r + cap_fit_clearance, h=cap_lip_h + 2*eps());
}

// Внешний сплошной объём крышки: цельное тело высотой cap_top_th+cap_lip_h
// При включённом Minkowski предварительно уменьшаем высоту на cap_minkowski_r, чтобы итоговая высота сохранилась
module cap_outer_solid(){
    cap_h_target = cap_top_th + cap_lip_h;
    // Minkowski with translate([0,0,r]) sphere(r) increases height by +2r while keeping bottom at Z=0
    h_outer = cap_h_target - (cap_minkowski_r > 0 ? 2*cap_minkowski_r : 0);
    rr_extrude(size=[outer_x + 2*cap_outer_margin, outer_y + 2*cap_outer_margin], r=radius_r + cap_outer_margin, h=max(h_outer, eps()));
}

// Готовая крышка: внешнее тело (с опциональным скруглением через Minkowski) минус внутренняя выемка юбки
module cap_body(){
    difference(){
        // Наружный контур с опциональным скруглением краёв
        if (cap_minkowski_r > 0){
            minkowski(){
                cap_outer_solid();
                // Сдвиг сферы вверх на r сохраняет нижнюю плоскость без скругления
                translate([0,0,cap_minkowski_r]) sphere(r=cap_minkowski_r);
            }
        } else {
            cap_outer_solid();
        }
        // Внутренняя выемка юбки (посадка по зазору)
        cap_skirt_inner();
    }
}

module cap(){
    cap_body();
}

// Разворот крышки вверх дном для печати (лежит плоской верхней стороной на столе)
module cap_upside_down(){
    translate([0, 0, cap_h])
        mirror([0, 0, 1])
            cap();
}

// ---------------
// Клиппер фрагментов
// ---------------
module clip_for_fragments(){
    clip_for_fragments_bbox(L=outer_x, W=outer_y, H=outer_h,
        enabled=test_fragment, frag_size=frag_size, frag_index=frag_index, frag_h_extra=frag_h_extra)
    children();
}

// ----------------------------
// Вывод всех фрагментов
// ----------------------------
module all_parts(){
    // Раскладка деталей по X при одновременной печати
    x_gap = frag_gap_x;  // использовать существующий зазор
    x_shift = (print_box && print_cap) ? (outer_x + x_gap) : 0;

    if (print_box) translate([0, 0, 0]) base();
    if (print_cap) translate([x_shift, 0, 0]) cap_upside_down();
}

// ----------------------------
// ВЫВОД МОДЕЛИ
// ----------------------------
clip_for_fragments(){ all_parts(); }
