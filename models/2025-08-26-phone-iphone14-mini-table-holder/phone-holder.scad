// =============================================
// 3D: phone iphone14 mini table holder — base
// Version: 2.0
// Author: generator
// =============================================

// Short description for models table
description = "phone iphone14 mini table holder — base";
version_str = "2.0";

// Модель стоит вертикально, по xy вырезом вниз, его видно с фронтальной проекции
// Карман шириной с телефон с зазором, y - толщина телефона с зазором, z - высота телефона
// Спереди вырез под камеру, z - высота выреза. Телефон стоит камерами вверх, экраном назад.
// Телефон (с учётом чехла/кнопок)


// ----------------------------
// Параметры модели (все размеры в мм)
// ----------------------------
is_small = false;
phone_w = is_small ? 66 : 66; // ширина телефона по X, с боковыми кнопками
phone_h_gap = 10;
phone_h = is_small ? 20 : 131 - phone_h_gap; // высота телефона (идёт в глубину кармана) по Y
phone_th = is_small ? 8 : 8; // толщина телефона по Z
notch_camera_z = is_small ? phone_h - 10 : 32 - phone_h_gap;

// Зазоры кармана (внутренние)
pocket_clear_x = 0.4; // общий запас по X (ширина) — суммарно (0 для точного соответствия)
pocket_clear_y = 0.4; // запас по Y (толщина)
pocket_clear_z = 0; // запас по Z (высота)

// Стенки/толщины
wall_xy  = is_small ? 2 : 1.6;  // толщина боковой стенки (X/Y)
wall_z   = is_small ? 2 : 1.6;  // толщина снизу/сверху (Z)

// Скругления
radius_r = 2;
mink_r   = 1;

print_notch = true; // output notch difference




use <../modules.scad>

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
inner_x = phone_w + pocket_clear_x;
inner_y = phone_th + pocket_clear_y;
inner_z = phone_h + pocket_clear_z;
outer_x = inner_x + 2 * wall_xy;
outer_y = inner_y + 2 * wall_xy;
outer_z = inner_z + wall_z;

// ----------------------------
// Модули фрагментов модели
// ----------------------------
module base(){
    rounded_prism_with_pocket(
        size=[outer_x, outer_y],
        h=outer_z,
        r=radius_r,
        kr=mink_r,
        wall_th=wall_xy,
        h_th=wall_z
    );
}

module notch(){
    translate([wall_xy, -eps(), outer_z - notch_camera_z])
        rounded_prism(
            size=[inner_x, wall_xy + 2*eps()],
            h=notch_camera_z + eps()
        );
}

// Вывод всех деталей
module all_details(){
    // mink(mink_r, [outer_x, outer_y, outer_z], kernel="sphere"){ 
        if(print_notch) { difference(){ base(); notch(); } }
        else base();
    // }
}

// ----------------------------
// ВЫВОД МОДЕЛИ
// ----------------------------
module render(){
    clip_for_fragments(){ all_details(); }
}

render();
