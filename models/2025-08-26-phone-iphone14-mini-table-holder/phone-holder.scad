// =============================================
// 3D: phone iphone14 mini table holder — base
// Version: 1.0
// Author: generator
// =============================================

// Short description for models table
description = "phone iphone14 mini table holder — base";

// ----------------------------
// Параметры модели (все размеры в мм)
// ----------------------------
// Телефон (с учётом чехла/кнопок)
phone_w = 66;          // ширина телефона по X
phone_h_gap = 10;
phone_h = 131 - phone_h_gap;         // высота телефона (идёт в глубину кармана) по Y
phone_t = 8;          // толщина телефона по Z

// Зазоры кармана (внутренние)
// Требование: внутренние размеры должны быть ровно phone_w и phone_h.
// Поэтому убираем дополнительный XY-зазор, а размеры кармана компенсируем на 2*whole_mink_r.
pocket_clear_xy = 0;   // общий запас по X (ширина) — суммарно (0 для точного соответствия)
pocket_clear_z  = 0.5; // запас по Z (толщина)

// Стенки/толщины
wall_xy   = 1.6;       // толщина боковой стенки (X/Y)
wall_z    = 2.6;       // толщина снизу/сверху (Z)
back_wall = 1.6;         // задняя стенка глубины кармана

// Подложка (base_pad)
base_pad_extra_x = 2; // дополнительная ширина подложки по X

// Режущие элементы кармана
notch_camera_y    = 32 - phone_h_gap;
notch_h           = 6;   // высота выреза снизу по Z
notch_r_xy        = 0;   // скругление выреза в плане

// Скругления
body_r_xy   = 0; // внешнее скругление корпуса (в плане XY) — отключено по Z-краям
pocket_r_xy = 0; // скругление углов кармана (в плане XY)
bottom_chamfer_y = 0; // фаска по оси Y у низа корпуса (0 = выкл.)
body_mink_r = 0; // радиус сферического скругления (preserve size)
pocket_mink_r = 0; // радиус сферического скругления внутри кармана (preserve size)
whole_mink_r = 1; // глобальное скругление всей базы Minkowski (увеличит внешние размеры и уменьшит внутренние) — 0=выкл.






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
test_fragment = false;   // true — печатать только угловые фрагменты (base+frame)
frag_size     = 20;      // размер квадрата вырезки, мм
frag_index    = 0;       // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП (относительно основания)
frag_gap_x    = 10;      // зазор между фрагментами по X, мм
frag_h_extra  = 20;      // запас по высоте клипа, мм



// Производные размеры
// Компенсируем глобальное сглаживание whole_mink_r (уменьшает внутренние размеры на ~2*r)
pocket_w   = phone_w + 2*whole_mink_r + pocket_clear_xy; // цель: после -2*r получить ровно phone_w
pocket_d   = phone_h + 2*whole_mink_r;                   // цель: после -2*r получить ровно phone_h
base_h     = phone_t + pocket_clear_z + 2*wall_z;       // общая высота детали
body_x     = pocket_w + 2*wall_xy;                      // ширина корпуса без ручек
body_y     = pocket_d + back_wall;                      // длина корпуса по Y

// ----------------------------
// ФРАГМЕНТЫ ДЕТАЛИ
// ----------------------------
// - base: корпус с подложкой (base_pad)
// - pocket_cut: вычитание кармана

// убраны handles/holes — модель упрощена до базы и кармана

module pocket_cut(){
    // Основная полость под телефон
    translate([wall_xy, 0, wall_z])
        rounded_rr_extrude(
            size=[pocket_w, pocket_d],
            r=pocket_r_xy,
            // Компенсация глобального сглаживания whole_mink_r, которое сжимает внутренние полости на ~2*r
            h=phone_t + pocket_clear_z + 2*whole_mink_r,
            s=1,
            mink_r=pocket_mink_r
        );

    // Нижний вырез от края стола внутрь на долю глубины (50%)
    translate([wall_xy, 0, 0])
        rounded_rr_extrude(
            size=[pocket_w, notch_camera_y],
            r=notch_r_xy,
            // Тоже компенсируем, чтобы итоговая высота выреза соответствовала настройке
            h=notch_h + 2*whole_mink_r,
            s=1,
            mink_r=pocket_mink_r
        );

    // Призматическая фаска (треугольная по Z) ВНУТРИ кармана: кольцо между
    // уменьшенным сечением (сверху) и базовым (снизу), чтобы клин смотрел внутрь
}

// Вырезы на ручках по всей длине phone_h, построены из цилиндров
module handles_front_cut(){
    if(handles_cut_use_rr2d){
        // Сильно скруглённый прямоугольник на всю phone_h, по Z — насквозь
        linear_extrude(height=base_h + 2*eps()){
            union(){
                translate([-handle_ext, 0]) rounded_rect([handle_ext, phone_h], r=handles_front_cut_r);
                translate([body_x, 0])      rounded_rect([handle_ext, phone_h], r=handles_front_cut_r);
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
                rounded_rr_extrude(
                    size=[body_x + 2*base_pad_extra_x, body_y],
                    r=body_r_xy,
                    h=base_h,
                    s=1,            // без конусности по Z
                    mink_r=body_mink_r // сферическое сглаживание краёв
                );
        }
        // Полость и нижний вырез
        pocket_cut();
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
    translate([0,0,pocket_d]) rotate([270,0,0]) children();
}

// Обёртка для применения глобального Minkowski ко всей базе
module render_base(){
    if (whole_mink_r > 0){
        minkowski(){
            base();
            sphere(r=whole_mink_r, $fs=fs_pin(), $fa=6);
        }
    } else {
        base();
    }
}

clip_for_fragments(){ orient(){ render_base(); } }
