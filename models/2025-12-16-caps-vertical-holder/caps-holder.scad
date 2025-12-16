// =============================================
// 3D: Horizontal Holder for 2 Bottles (75x180)
// Version: 1.0
// Author: ChatGPT (OpenSCAD)
// =============================================

// ----------------------------
description = "Horizontal holder for 2 bottles, d=180, len=75";

// Shared library
use <../modules.scad>

// ----------------------------
// Параметры модели
// ----------------------------
cap_diam      = 180;     // диаметр крышки, мм
cap_width     = 20;     // ширина крышки, мм
num_caps      = 2;       // количество крышек
wall_th       = 1;       // толщина стенок, мм
holder_length = 180;      // длина держателя по X, мм

// Габариты/толщины
rail_w        = 0;       // боковые рельсы убраны
rail_h        = 0;       // высота рельса по Z, мм (не используется)
base_th       = 0;       // толщина тонкой базы (не используется)
bridge_th     = 2;       // толщина облегчённых перемычек (мостов), мм
bridge_pitch  = 35;      // шаг перемычек по X, мм
end_stop_h    = 0;       // высота торцевых упоров, мм (не используется)
end_stop_th   = 1;       // толщина торцевых упоров по X, мм
max_h         = 80;      // ограничение по высоте всей детали, мм

// Скругление краёв через minkowski
use_minkowski = false;    // включить скругление краёв
minkowski_r   = 1;       // радиус сферы для скругления, мм

// ----------------------------
// Настройка точности
// ----------------------------
$fn = 0;        // фиксированную сегментацию отключаем
$fa = 6;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // для цилиндров высокой точности

// ----------------------------
// Тестовые фрагменты
// ----------------------------
test_fragment = false;  // true — печатать только укороченные фрагменты
frag_size     = 20;     // размер окна вырезки по XY
frag_index    = 0;      // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП (относительно основания)
frag_gap_x    = 10;     // зазор между фрагментами по X, мм
frag_h_extra  = 12;     // запас по высоте клипа, мм

// ----------------------------
// Общие доп. параметры
// ----------------------------
tiny = 0.1;  // небольшой зазор для булевых операций

// Вычисляемые размеры
cap_radius = cap_diam / 2;  // радиус крышки
// Высота ограничена max_h
holder_height = max_h;
// Длина по Y ограничена holder_length
tot_y = holder_length;
// Длина по X - должна вмещать 2 крышки + стенки
pad_between = 1;  // зазор между крышками по X, мм
tot_x = num_caps * cap_width + (num_caps - 1) * pad_between + 2 * wall_th + 2 * end_stop_th;

// Центры крышек по X
// Крышки расположены одна за другой вдоль X, по центру по Y и Z
function cap_center_x(i) = end_stop_th + wall_th + cap_width/2 + i * (cap_width + pad_between);

// ----------------------------
// Вспомогательные модули
// ----------------------------
// Цилиндрический вырез для крышки (вдоль оси X)
module cylinder_cutter(center_x){
    // Цилиндр проходит вдоль оси X, ограничен по длине cap_width, поднят на радиус по Z
    // Длина цилиндра = ширина крышки (для каждой крышки отдельный цилиндр)
    translate([center_x - cap_width/2, tot_y/2, holder_height/2 + cap_radius / 2 + wall_th * 6])
        rotate([0, 90, 0])
            cylinder(h = cap_width + 2*tiny, d = cap_diam, $fs=pin_fs, $fa=6);
}

// Торцевые упоры по X
module end_stop(){
    // у левого края
    translate([0, 0, 0]) cube([end_stop_th, tot_y, holder_height], center=false);
    // у правого края
    translate([tot_x - end_stop_th, 0, 0]) cube([end_stop_th, tot_y, holder_height], center=false);
}

// Объединение всех выемок
module cradle_cuts(){
    for(i = [0 : num_caps - 1]) {
        cylinder_cutter(cap_center_x(i));
    }
}

// Основной корпус
module deck_core(){
    cube([tot_x, tot_y, holder_height], center=false);
}

// Полная сборка
module base_raw(){
    intersection(){
        difference(){
            union(){
                deck_core();
                end_stop();
            }
            cradle_cuts();
        }
        // Срезаем верх по max_h
        translate([-tiny, -tiny, -tiny])
            cube([tot_x + 2*tiny, tot_y + 2*tiny, max_h + tiny], center=false);
    }
}

// Срезаем верх по z_cap на всякий случай
module base(){
    if (use_minkowski) {
        minkowski() {
            base_raw();
            sphere(r=minkowski_r, $fs=pin_fs, $fa=6);
        }
    } else {
        base_raw();
    }
}

// ----------------------------
// Клиппер фрагментов
// ----------------------------
module clip_for_fragments(){
    if(test_fragment){
        // Фрагмент у нижнего левого угла
        intersection(){
            children();
            translate([-tiny, -tiny, -frag_h_extra])
                cube([frag_size, frag_size, holder_height + 2*frag_h_extra], center=false);
        }
        // Фрагмент у верхнего правого угла
        translate([tot_x - frag_size - frag_gap_x, tot_y - frag_size - frag_gap_x, 0])
            intersection(){
                children();
                translate([-tiny, -tiny, -frag_h_extra])
                    cube([frag_size + tiny, frag_size + tiny, holder_height + 2*frag_h_extra], center=false);
            }
    }else{
        children();
    }
}

// Вывод модели
module flipped(){
    // Переворачиваем по Z так, чтобы низ был на Z=0
    translate([0,0,0]) mirror([0,0,0]) base();
}

clip_for_fragments() flipped();
