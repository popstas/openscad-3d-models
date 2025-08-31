// =============================================
// 3D: filament holder
// Version: 1.0
// Author: generator
// =============================================

description = "Держатель катушки, крепится сбоку на принтер, на magsafe магнит";
version_str = "1.0";

// ----------------------------
// Фрагменты: назовите элементы короткими именами с _
// - base: основная деталь
// - TODO: top_pad, base_pad, wrap_left, main_wall: примеры имён
// ----------------------------

// Параметры модели
// ----------------------------
// Главные размеры из ТЗ:
base_pad_d = 65;    // диаметр основания, мм
base_pad_h = 7;     // высота основания, мм

hook_d = 50;        // диаметр верхнего диска ("hook"), мм
hook_h = 6;         // высота верхнего диска, мм
hook_kr = 9;      // радиус скругления краёв hook через Minkowski (0 = без)
hook_z_inset = 8;   // наезд hook на основание, мм
hole_d = 5;         // диаметр центрального отверстия, мм

body_outer_d = 40;  // внешний диаметр корпуса (труба), мм
body_h = 75 + 2 + hook_z_inset;        // высота корпуса, мм
wall_th = 2.0;      // толщина стенки трубы, мм (Уточнить!)

// Полукруглый отросток вниз по Y (площадка z=2 мм)
tail_h = 2;                 // толщина по Z, мм
tail_len = 50;              // длина от точки касания основания вниз по Y, мм (Уточнить!)
tail_w = base_pad_d - 10;   // ширина отростка, мм (Уточнить!)

// Кольцевая выборка снизу основания (паз): наружный 55, внутренний 45, h=0.6
bottom_ring_inner_d = 41.5; //44;   // внутренний диаметр паза, мм
bottom_ring_outer_d = 58;   // внешний диаметр паза, мм
bottom_ring_h       = 5.6;  // высота (глубина) паза, мм

// Включение деталей для вывода
print_base = true;
print_body = true;
print_top_hook = true;
print_bottom_ring = true;   // вспомогательный фрагмент: показать кольцо-паз (для проверки)
print_hole = true;          // делать сквозное отверстие через base и hook
with_tail = true;           // добавлять полукруглый отросток к основанию

// ----------------------------
// Вычисляемые переменные
outer_z = base_pad_h + body_h + hook_h;



use <../modules.scad>;

// ----------------------------
// Настройка точности
// ----------------------------
$fn = 0;        // фиксированную сегментацию отключаем
$fa = 6;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий

// ----------------------------
// Вспомогательные модули
// ----------------------------
// Скруглённый цилиндр через Minkowski, сохраняет заданные d/h
module rounded_cyl(d=10, h=5, kr=0){
    k = max(kr, 0);
    if (k <= 0){
        cylinder(h=h, d=d);
    } else {
        d2 = max(d - 2*k, eps());
        h2 = max(h - 2*k, eps());
        translate([0,0,k])
            minkowski(){
                cylinder(h=h2, d=d2);
                sphere(r=k, $fs=fs_pin(), $fa=6);
            }
    }
}

// Полукруглый отросток вниз по Y, скруглённый внизу (нижняя кромка — полуокружность)
// Параметры по умолчанию берутся из tail_* переменных
module y_tail_semicircle(w=tail_w, len=tail_len, h=tail_h){
    // Делает цельный «капсульный» хвост: выпуклая оболочка (hull) между верхним кругом базы
    // (d=base_pad_d, центр в [0,0]) и нижним кругом (d=w, центр в [0, -(base_pad_d/2 + len)]),
    // затем обрезка по линии касания базы y = -base_pad_d/2 + eps() — чтобы хвост начинался под окружностью.
    r_top = base_pad_d/2;
    r_bot = w/2;
    y_top = 0;
    y_bot = -(r_top + len);
    y_clip = -r_top + eps();

    linear_extrude(height=h)
        intersection(){
            hull(){
                translate([0, y_top]) circle(r=r_top);
                translate([0, y_bot]) circle(r=r_bot);
            }
            // Полуплоскость y <= y_clip
            translate([-1000, -10000]) square([2000, 10000 + y_clip], center=false);
        }
}

// ----------------------------
// Вычисляемые переменные
// ----------------------------
inner_d = max(body_outer_d - 2*wall_th, 0.5);

// ----------------------------
// Модули фрагментов модели
// ----------------------------
module base(){
    // Основание с опциональным полукруглым отростком вниз по Y
    // Круглое основание с выборкой-кольцом снизу
    // Отросток (толщиной tail_h), выборку не вычитаем
    difference(){
        union(){
            cylinder(h=base_pad_h, d=base_pad_d);
            if (with_tail) translate([0, body_outer_d, 0]) y_tail_semicircle();
        }
        if(print_bottom_ring) bottom_ring();
    }
}

module body(){
        // Прямая часть стенки (до начала фаски)
        difference(){
            cylinder(h=max(body_h, eps()), d=body_outer_d);
            // translate([0,0,-eps()]) cylinder(h=max(body_h, eps()) + 2*eps(), d=inner_d);
        }
}

module top_hook(){
    // Верхний диск ("hook"): сплошной цилиндр Ø50, h=5
    difference(){
        rounded_cyl(hook_d, hook_h, hook_kr);
        // сквозное центральное отверстие Øhole_d
        if(print_hole)
            translate([0,0,-eps()])
                cylinder(h=hook_h + 2*eps(), d=hole_d, $fs=pin_fs, $fa=6);
    }
}

// Тонкое кольцо для выборки снизу основания (для difference())
// Размещено от z=0 вверх на bottom_ring_h, чтобы вычитать «снизу» основания
module bottom_ring(){
    difference(){
        cylinder(h=bottom_ring_h, d=bottom_ring_outer_d);
        translate([0,0,-eps()]) cylinder(h=bottom_ring_h + 2*eps(), d=bottom_ring_inner_d);
    }
}

// Вывод всех деталей
module all_details_without_hole(){
    // Стек деталей по Z: base -> body -> top_hook
    if (print_base) base();
    if (print_body) translate([0,0,base_pad_h]) body();
    if (print_top_hook) translate([0,0,base_pad_h + body_h - hook_z_inset]) top_hook();
}

module all_details(){
    if (print_hole)
        difference(){
            all_details_without_hole();
            translate([0,0,-eps()]) cylinder(h=outer_z + 2*eps() + 10, d=hole_d, $fs=pin_fs, $fa=6);
        }
    else all_details_without_hole();
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
