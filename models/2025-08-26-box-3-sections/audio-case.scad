// =============================================
// 3D: Audio Tools Case — base
// Version: 1.0
// Author: Cascade generator
// =============================================

// Short description for models table
description = "Audio Tools Case — base";
version_str = "1.0";

// Shared library
use <../modules.scad>;

// ----------------------------
// Настройка точности
// ----------------------------
$fn = 0;        // фиксированную сегментацию отключаем
$fa = 6;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий

// Малый зазор для булевых операций/пересечений
tiny = 0.1;

// ----------------------------
// Тестовые фрагменты (стандартный блок)
// ----------------------------
test_fragment = false;     // true — печатать только угловые фрагменты (base+frame)
frag_size     = 20;      // размер квадрата вырезки, мм
frag_index    = 0;       // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП (относительно основания)
frag_gap_x    = 10;      // зазор между фрагментами по X, мм
frag_h_extra  = 20;      // запас по высоте клипа, мм

// ----------------------------
// Параметры модели (все размеры в мм)
// ----------------------------
// Коробка делится на N отделов: section 1, section 2, ... section N
// Входные требования:
// - внутренняя высота коробки = 31
// - толщины стенок (наружных и межсекционных) = 2
// - ширины отделов задаются массивом sections_w, любое количество
// - ширина по Y (глубина) не указана (inner_y)

// Флаги печати
print_box = true;     // печатать основание (лоток)
print_cap = true;     // печатать крышку

// Толщины и высоты
wall_th      = 1.6;          // толщина наружных стенок
divider_th   = 1.6;          // толщина перегородок
bottom_th    = 1.6;          // толщина дна

// Все отсеки открыты до верха (inner_h); индивидуальные высоты не используются

// Ширины отсеков (по X). Любое количество.
sections_w = [10, 20, 30];

// Насадка крышки: опустить вершины межсекционных перегородок на заданную высоту
// Делает перегородки ниже на Z, чтобы крышка/вкладыш входили без упора в перегородки
sections_to_cap_gap = 5; // мм

// Поправки размеров (фактические измерения)
sec_w_delta  = 1;        // каждая секция по X на 1 мм уже
inner_y_delta= 3;     // внутренняя глубина по Y меньше на 2.5 мм (уменьшаем номинал)

// Глубина по Y (внутренняя, номинал)
inner_y      = 20;//158.6;        // номинальная длина по Y
inner_h      = 10;//31;           // внутренняя высота во всех отсеках (максимум)

// Эффективные размеры с учётом поправок
sections_w_e = [ for (w = sections_w) w + sec_w_delta ];
inner_y_e  = inner_y  + inner_y_delta;

// Вспомогательные функции суммирования
function sum_first(v, n, i=0, acc=0) = (i >= n) ? acc : sum_first(v, n, i+1, acc + v[i]);
function vec_sum(v) = sum_first(v, len(v));

// Скругление наружного прямоугольника
radius_r     = 3;          // радиус скругления углов
// Скругление углов внутренних секций
sec_corner_r = 2;          // радиус скругления углов вырезов секций

// Зазоры внутри не используются на этой итерации (оставлено место для будущих настроек)

// Параметры крышки (cap)
cap_top_th        = 2;     // толщина верхней пластины крышки
cap_lip_h         = 8;     // высота юбки (захват за стенки)
cap_fit_clearance = 0.1;   // зазор между наружными стенками коробки и внутренней поверхностью юбки
cap_outer_margin  = 0.8;   // выступ крышки наружу относительно корпуса (по всем сторонам)
cap_th            = 1.6; // толщина стенки крышки; по умолчанию согласована с margin и зазором
cap_minkowski_r  = 2;   // радиус скругления краёв крышки через minkowski
base_minkowski_r = 2;   // радиус скругления краёв основания через minkowski

inner_y_shift = inner_y_e - wall_th;
cap_h = cap_top_th + cap_lip_h;   // итоговая высота крышки

// ----------------------------
// Фрагменты
// ----------------------------
// - base: основная деталь (лоток)
// - перегородки формируются автоматически, как остаток между вычитаниями отсеков

// ----------------------------
// Геометрия корпуса
// ----------------------------
// Общая ширина X: стены + сумма секций + перегородки между ними
n_sections = len(sections_w_e);
outer_x = 2*wall_th + vec_sum(sections_w_e) + divider_th * max(n_sections - 1, 0);
outer_y = 2*wall_th + inner_y_shift;
outer_h = bottom_th + inner_h;

// Отсеки формируются перегородками; явные вырезы не используются


// Базовый заполняющий объём (без вырезов) — внешний контур на полную высоту
module base_fill(){
    // Только внешний контур на полную высоту; срез верха делаем позже, локально по перегородкам
    rr_extrude(size=[outer_x, outer_y], r=radius_r, h=outer_h);
}

section_x_offset = wall_th+wall_th/2;
section_y = wall_th+wall_th/2;
// Вырезы-отсеки формируются по массиву sections_w_e
// Позиция i-го отсека: сдвиг от левой стены = сумма предыдущих ширин + перегородки между ними
function section_x_at(i) = section_x_offset + sum_first(sections_w_e, i) + divider_th * i;
module section_at(i){
    translate([section_x_at(i), section_y, bottom_th])
        rr_extrude(size=[sections_w_e[i], inner_y_shift], r=sec_corner_r, h=inner_h);
}

module base(){
    // Корпус-лоток как разность наружного корпуса (с опциональным Minkowski) минус секции,
    // а затем локальный срез верхушек перегородок
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

        // Вырезы секций по массиву ширин (section 1..N)
        for (i = [0 : n_sections - 1])
            section_at(i);

        // Срезать верх перегородок на заданную высоту, не затрагивая наружные стены
        dividers_top_cut();
    }
}

// Сервис: левый X-край перегородки между секцией i и i+1
function divider_x_at(i) = section_x_at(i) + sections_w_e[i];

// Локальный верхний срез только по перегородкам (полосы шириной divider_th)
module dividers_top_cut(){
    // Безопасный зажим высоты среза: 0..(inner_h-eps)
    g = min(max(sections_to_cap_gap, 0), inner_h - eps());
    if (g > 0 && n_sections > 1){
        for (i = [0 : n_sections - 2])
            translate([
                divider_x_at(i) - divider_th * 3,
                inner_y_shift - inner_y - wall_th/2 - tiny*2,
                // немного уводим вниз на eps, чтобы исключить выход выше верха
                bottom_th + inner_h - g - eps()
            ])
                cube([divider_th*6 + tiny, inner_y_shift, g + 2*eps()]);
    }
}

// ---------------
// Крышка (cap)
// ---------------
// Крышка состоит из:
// - верхней пластины толщиной cap_top_th, размерами больше корпуса на cap_outer_margin с каждой стороны
// - внутренней юбки высотой cap_lip_h, которая надевается на корпус с зазором cap_fit_clearance
// Реализовано двумя модулями: cap() и cap_upside_down(); без вспомогательных подмодулей
module cap(){
    // Эффективный внешний отступ для формирования внешнего габарита крышки через толщину и зазор
    outer_margin_eff = cap_fit_clearance + cap_th;
    // Внешний сплошной объём крышки: цельное тело высотой cap_top_th+cap_lip_h
    // При включённом Minkowski предварительно уменьшаем высоту на 2*cap_minkowski_r,
    // чтобы итоговая высота сохранилась после скругления сферы, поднятой на r.
    difference(){
        // Наружный контур с опциональным скруглением краёв
        if (cap_minkowski_r > 0){
            minkowski(){
                // предварительно сжимаем по XY и Z, чтобы габариты после minkowski совпали с расчётными
                cap_h_target = cap_top_th + cap_lip_h;
                h_outer = cap_h_target - 2*cap_minkowski_r;
                rr_extrude(
                    size=[
                        max(outer_x + 2*outer_margin_eff - 2*cap_minkowski_r, eps()),
                        max(outer_y + 2*outer_margin_eff - 2*cap_minkowski_r, eps())
                    ],
                    r=max(radius_r + outer_margin_eff - cap_minkowski_r, 0),
                    h=max(h_outer, eps())
                );
                // Сдвиг сферы вверх на r сохраняет нижнюю плоскость без скругления
                translate([0,0,cap_minkowski_r]) sphere(r=cap_minkowski_r);
            }
        } else {
            rr_extrude(
                size=[outer_x + 2*outer_margin_eff, outer_y + 2*outer_margin_eff],
                r=radius_r + outer_margin_eff,
                h=cap_top_th + cap_lip_h
            );
        }

        // Внутренняя поверхность юбки (посадка по зазору)
        if (cap_minkowski_r > 0){
            // Подгоняем профиль вычитания под внешний minkowski, чтобы толщина была ровно cap_th
            translate([0,0,-eps()])
            minkowski(){
                h_inner = cap_lip_h + 2*eps() - 2*cap_minkowski_r;
                rr_extrude(
                    size=[
                        max(outer_x + 2*cap_fit_clearance - 2*cap_minkowski_r, eps()),
                        max(outer_y + 2*cap_fit_clearance - 2*cap_minkowski_r, eps())
                    ],
                    r=max(radius_r + cap_fit_clearance - cap_minkowski_r, 0),
                    h=max(h_inner, eps())
                );
                translate([0,0,cap_minkowski_r]) sphere(r=cap_minkowski_r);
            }
        } else {
            translate([0,0,-eps()])
                rr_extrude(
                    size=[outer_x + 2*cap_fit_clearance, outer_y + 2*cap_fit_clearance],
                    r=radius_r + cap_fit_clearance,
                    h=cap_lip_h + 2*eps()
                );
        }
    }
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
 