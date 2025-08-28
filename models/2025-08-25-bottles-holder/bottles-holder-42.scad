// =============================================
// 3D: Horizontal Holder for 2 Bottles (75x42)
// Version: 1.0
// Author: ChatGPT (OpenSCAD)
// =============================================

// ----------------------------
description = "Horizontal holder for 2 bottles, d=42, len=75";

// Shared library
use <../modules.scad>

// ----------------------------
// Параметры модели
// ----------------------------
bottle_diam   = 42;      // диаметр бутылки, мм
bottle_y      = 75;     // длина бутылки по Y, мм
num_bottles   = 2;       // количество бутылок в ряду (по Y)
pad_between   = 1.5;     // прокладка/зазор между бутылками (1–2 мм)

// Габариты/толщины
rail_w        = 0;       // боковые рельсы убраны
rail_h        = 6;       // высота рельса по Z, мм
base_th       = 2;       // толщина тонкой базы между рельсами, мм
bridge_th     = 2;       // толщина облегчённых перемычек (мостов), мм
bridge_pitch  = 35;      // шаг перемычек по X, мм
end_stop_h    = 10;       // высота торцевых упоров, мм
end_stop_th   = 1;       // толщина торцевых упоров по X, мм
max_h         = 50;      // ограничение по высоте всей детали, мм

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

// Вычисляемые размеры
inner_w = num_bottles*bottle_diam + (num_bottles-1)*pad_between;      // рабочая ширина между рельсами
tot_w   = inner_w;// + 2*rail_w;                                          // общая ширина
tot_y   = bottle_y + end_stop_th;                                    // общая длина по Y (с упорами)

// Низкий подпрофиль «ложемента» — высота положительного сегмента
saddle_h = min(max_h - rail_h, bottle_diam/3);                         // не выше трети диаметра
saddle_w = max(bottle_diam/2, 12);                                     // ширина контакта по Y
// Срез по Z сверху на высоте торцевого упора
z_cap  = rail_h + end_stop_h;
// Полная высота модели для переворота по Z
total_h = z_cap;

// Центры бутылок по X (ранее по Y)
function bottle_center_x(i) = bottle_diam/2 + i*(bottle_diam + pad_between);

// ----------------------------
// Вспомогательные модули
// ----------------------------
// Режущий цилиндр для выемки (полуканавка) вдоль Y, ограниченный по высоте
module saddle_cutter(center_x){
    z_offset = 0;//bottle_diam / 10 * -1;
    intersection(){
        // цилиндр вдоль Y, начинается после нижнего упора и заканчивается перед верхним
        translate([center_x, end_stop_th, bottle_diam/2 + base_th])
            rotate([-90,0,0])
                cylinder(h=bottle_y, d=bottle_diam, $fs=pin_fs, $fa=6);
        // ограничиваем область выемки только внутренней зоной между рельсами и по Z до z_cap
        translate([0, end_stop_th, z_offset])
            cube([inner_w, bottle_y, z_cap], center=false);
    }
}


// Торцевые упоры по Y только между рельсами
module end_stop(){
    // у верхнего края
    translate([rail_w, tot_y - end_stop_th, rail_h]) cube([inner_w, end_stop_th, end_stop_h], center=false);
}

// Объединение всех выемок
module cradle_cuts(){
    for(i = [0 : num_bottles-1])
        saddle_cutter(bottle_center_x(i));
    // Убираем внешние стенки по краям: дополнительные полуканавки за пределами рабочей области
    saddle_cutter(-bottle_diam/2);
    saddle_cutter(inner_w + bottle_diam/2);
}

// Срезающий параллелепипед для верхней плоскости
module cut_top(){
    translate(v = [-10, -10, -z_cap])
        cube([inner_w+20, tot_y+20, 24], center=false);
}

// Сплошная внутреняя плита между рельсами на высоту выемки (будет облегчена вычитанием цилиндров)
module deck_core(){
    translate([0, end_stop_th, 0])
        cube([inner_w, bottle_y, z_cap], center=false);
}

// Полная сборка (сырая, без финального среза по Z)
module base_raw(){
    difference(){
        union(){
            deck_core();
            end_stop();
        }
        cradle_cuts();
        // cut_top();
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
        // Фрагмент у нижнего торца (по Y)
        intersection(){
            children();
            translate([-eps(), -eps(), -frag_h_extra])
                cube([tot_w + 2*eps(), frag_size, rail_h + end_stop_h + saddle_h + 2*frag_h_extra], center=false);
        }
        // Фрагмент у верхнего торца (по Y)
        translate([0, frag_size + frag_gap_x, 0])
            intersection(){
                children();
                translate([-eps(), tot_y - frag_size, -frag_h_extra])
                    cube([tot_w + 2*eps(), frag_size + eps(), rail_h + end_stop_h + saddle_h + 2*frag_h_extra], center=false);
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


