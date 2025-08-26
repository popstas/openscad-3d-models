// =============================================
// 3D: Audio Tools Case — base
// Version: 1.0
// Author: Cascade generator
// =============================================

// Short description for models table
description = "Audio Tools Case — base";

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
// - ширина по Y (глубина) не указана — требуется подтверждение (inner_y)

version_str = "1.0";

// Флаги печати
print_box = true;     // печатать основание (лоток)
print_cap = true;     // печатать крышку

// Толщины и высоты
wall_th      = 2;          // толщина наружных стенок
divider_th   = 2;          // толщина перегородок
bottom_th    = 2;          // толщина дна

// Все отсеки открыты до верха (inner_h); индивидуальные высоты не используются

// Ширины отсеков (по X)
red_w        = 25.5;
yellow_w     = 25.5;
green_w      = 25.5;

// Глубина по Y (внутренняя) — ТРЕБУЕТСЯ подтверждение
inner_y      = 38.6 * 2;        // фактическая длина по Y
inner_h      = 13.5 * 2;         // внутренняя высота во всех отсеках (максимум)

// Скругление наружного прямоугольника
radius_r     = 3;          // радиус скругления углов
// Скругление углов внутренних секций
sec_corner_r = 2;          // радиус скругления углов вырезов секций

// Зазоры внутри не используются на этой итерации (оставлено место для будущих настроек)

// Параметры крышки (cap)
cap_top_th        = 2;     // толщина верхней пластины крышки
cap_lip_h         = 8;     // высота юбки (захват за стенки)
cap_fit_clearance = 0.4;   // зазор между наружными стенками коробки и внутренней поверхностью юбки
cap_outer_margin  = 0.8;   // выступ крышки наружу относительно корпуса (по всем сторонам)

inner_y_shift = inner_y - wall_th;
inner_x_shift = inner_x - wall_th;

// ----------------------------
// Фрагменты
// ----------------------------
// - base: основная деталь (лоток)
// - перегородки формируются автоматически, как остаток между вычитаниями отсеков

// ----------------------------
// Вспомогательные
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
        linear_extrude(height=inner_h + eps())
            rounded_rect([outer_x - 2*wall_th, outer_y - 2*wall_th], r=max(radius_r - wall_th, 0));
}

// Базовый заполняющий объём (без вырезов) — внешний контур на полную высоту
module base_fill(){
    rr_extrude(size=[outer_x, outer_y], r=radius_r, h=outer_h);
}

section_x_offset = wall_th/2;
section_y = wall_th/2;
// Три выреза-отсека. Их суммарная ширина и позиции оставляют наружные стены и две перегородки толщиной divider_th.
module section_red(){
    translate([section_x_offset, section_y, bottom_th])
        linear_extrude(height=inner_h)
            rounded_rect([red_w, inner_y_shift], r=sec_corner_r);
}

module section_yellow(){
    translate([section_x_offset + red_w + divider_th, section_y, bottom_th])
        linear_extrude(height=inner_h)
            rounded_rect([yellow_w, inner_y_shift], r=sec_corner_r);
}

module section_green(){
    translate([section_x_offset + red_w + divider_th + yellow_w + divider_th, section_y, bottom_th])
        linear_extrude(height=inner_h)
            rounded_rect([green_w, inner_y_shift], r=sec_corner_r);
}

module base(){
    // Корпус-лоток как разность базового объёма и 3 секций
    difference(){
        base_fill();
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

// Верхняя пластина крышки
module cap_pad(){
    linear_extrude(height=cap_top_th)
        rounded_rect([outer_x + 2*cap_outer_margin, outer_y + 2*cap_outer_margin], r=radius_r + cap_outer_margin);
}

// Наружная юбка (тело)
module cap_skirt(){
    linear_extrude(height=cap_lip_h)
        rounded_rect([outer_x + 2*cap_outer_margin, outer_y + 2*cap_outer_margin], r=radius_r + cap_outer_margin);
}

// Внутренняя выемка юбки (для difference)
module cap_skirt_inner(){
    translate([0,0,-eps()])
        linear_extrude(height=cap_lip_h + 2*eps())
            rounded_rect([outer_x + 2*cap_fit_clearance, outer_y + 2*cap_fit_clearance], r=radius_r + cap_fit_clearance);
}
module cap(){
    union(){
        // Верхняя пластина
        cap_pad();

        // Юбка под верхней пластиной
        difference(){
            cap_skirt();
            // Внутренняя поверхность юбки: чуть больше, чем наружный размер корпуса, на зазор
            cap_skirt_inner();
        }
    }
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
    if (print_cap) translate([x_shift, 0, 0]) cap();
}

// ----------------------------
// ВЫВОД МОДЕЛИ
// ----------------------------
clip_for_fragments(){ all_parts(); }
