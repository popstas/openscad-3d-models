// OpenSCAD: две детали — основание со стойками и штырями, и рамка с окном под экран
// Версия: v1.7 — анизотропная фаска снизу: независимые размеры по Z и по горизонтали (X/Y);
// добавлен режим тест‑фрагментов и echo-контроль полей до кромки.
// добавлен режим тест‑фрагментов и echo-контроль полей до кромки.
use <../modules.scad>;

// Short description for models table
description = "Две детали: основание со стойками и штырями, и рамка с окном под экран";

// ===== Точность аппроксимации окружностей =====
$v = "1.7"; // Версия модели
$fn = 0;        // фикс. сегментация отключена
$fa = 6;        // макс. угол сегмента, град
$fs = 0.35;     // макс. длина сегмента, мм (≈диаметр сопла)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий

// ===== Режим печати тест‑фрагментов =====
test_fragment = false;   // true — печатать только угловые фрагменты (base+frame)
frag_size     = 20;     // размер квадрата вырезки, мм
frag_index    = 0;      // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП (относительно основания)
frag_gap_x    = 10;     // зазор между фрагментами по X, мм
frag_h_extra  = 20;     // запас по высоте клипа, мм

// Фрагменты модели:
// - base: основание с стойками и штырями
// - frame: рамка с окном под экран
// - base_top_pad: верхняя площадка основания (если потребуется)
// - base_wrap_left / base_wrap_right: возможные боковые обвязки (резерв)
// - frame_top_pad / frame_base_pad: элементы рамки (резерв)
// - test fragments: 4 угла основания/рамки для быстрой проверки посадки
//   индексы углов: 0=Нижний Левый, 1=Верхний Левый, 2=Нижний Правый, 3=Верхний Правый

// ===== Выбор печатаемых деталей =====
print_base  = true;     // печатать основание
print_frame = true;     // печатать рамку

// ===== Общие доп. параметры =====
tiny = 0.1;                  // небольшой зазор для булевых операций
edge_chamfer_z = 4;       // высота фаски по Z (мм) - убрана фаска
edge_chamfer_x = 1.6;       // горизонтальный вылет фаски по X (с каждой стороны), мм - убрана фаска
edge_chamfer_y = 1.6;       // горизонтальный вылет фаски по Y (с каждой стороны), мм - убрана фаска
screen_frame_gap = 0.2;      // только для высоты вычитаний в рамке (не влияет на XY)

// ===== Параметры платы и экрана =====
board_width  = 84;           // ширина платы (X), мм
board_height = 137;          // высота платы (Y), мм
board_thickness = 1.5;       // толщина платы, мм

screen_width  = 75.5;        // ширина (горизонталь, X) экрана, мм
screen_height = 120;         // высота (вертикаль, Y) экрана, мм
 
// ===== Габариты основания/рамки =====
base_margin_x = 0;           // отступы к габариту НЕ используются — внешние размеры = board_width/board_height
base_margin_y = 0;           // внешняя ширина = board_width
base_thickness = 3;          // толщина основания, мм
base_edge_multiplier = 0;     // 

frame_thickness = 5;         // толщина рамки, мм
window_clearance_x = 0.5;      // припуск (каждая сторона) к окну под экран, мм
window_clearance_y = 0.8;

// ===== Параметры крепёжных отверстий, стоек и штырей =====
hole_spacing_x = 75;      // расстояние между отверстиями по X, мм
hole_spacing_y = 129;         // расстояние между отверстиями по Y, мм
hole_diameter_board = 3;     // диаметр отверстий в плате (под винт/штырь), мм
hole_edge_tweak_x = 1;   // на сколько ближе к краям по X
hole_edge_tweak_y = 0.5;   // на сколько ближе к краям по Y

standoff_outer_diam = 5;     // диаметр стоек (опора под плату), мм
standoff_height = 4.5;       // высота стоек до низа платы, мм

pin_extra = frame_thickness; // сколько штырь выступает над платой, мм (по умолч. = толщине рамки)
pin_diam  = hole_diameter_board - 0.1; // диаметр штыря = отверстие платы −0.1 мм
pin_tip_h = 0.8;             // конус-направляющая на конце штыря (0 — выключить)

// ===== Вычисляемые величины (общие для base и frame) =====
base_width  = board_width;     // внешние габариты деталей (X) строго равны размерам платы
base_height = board_height;    // внешние габариты деталей (Y) строго равны размерам платы

// Отступы отверстий от краёв детали (симметричные) + сдвиг к краю на 1 мм
edge_x = max(0, (base_width  - hole_spacing_x)/2 - hole_edge_tweak_x);
edge_y = max(0, (base_height - hole_spacing_y)/2 - hole_edge_tweak_y);

// Позиции центров отверстий (общие для base и frame)
hole_positions = [
    [edge_x,                 edge_y                ], // нижний левый
    [edge_x,                 base_height - edge_y  ], // верхний левый
    [base_width  - edge_x,   edge_y                ], // нижний правый
    [base_width  - edge_x,   base_height - edge_y  ]  // верхний правый
];

// Проверочный вывод одинаковости полей (должны совпадать попарно)
left_margin   = hole_positions[0][0];
right_margin  = base_width - hole_positions[2][0];
bottom_margin = hole_positions[0][1];
top_margin    = base_height - hole_positions[1][1];
echo("Margins to edges (L,R,B,T):", left_margin, right_margin, bottom_margin, top_margin);

// Размер окна под экран (сквозное)
open_width = screen_width + 2*window_clearance_y; // X
open_height = screen_height  + 2*window_clearance_x; // Y
open_off_x = (base_width  - open_width)/2;   // одинаково для base и frame (X)
open_off_y = (base_height - open_height)/2;   // (Y)

// Пластина с фаской ТОЛЬКО СНИЗУ по внешнему периметру (симметрично по всем сторонам)
module chamfered_plate_bottom_edges_sym(l,w,t,chz,chx,chy){
    chz2 = clamp_chz(t, chz);
    chxy = clamp_chxy(l, w, chx, chy);
    chx2 = chxy[0];
    chy2 = chxy[1];
    if (chz2 <= 0 || (chx2 <= 0 && chy2 <= 0)) {
        cube([l,w,t]);
    } else {
        union(){
            translate([0,0,chz2]) cube([l,w,t-chz2]); // тело
            // нижняя фаска: масштабируем ИЗ ЦЕНТРА на требуемые горизонтальные вылеты
            translate([l/2, w/2, 0])
                linear_extrude(height=chz2, scale=[l/(l-2*chx2), w/(w-2*chy2)])
                    square([l-2*chx2, w-2*chy2], center=true);
        }
    }
}

// ===== Детали =====
module basePlate(){
    // Основание
    color("lightgray") chamfered_plate_bottom_edges_sym(base_width, base_height, base_thickness, edge_chamfer_z*base_edge_multiplier, edge_chamfer_x*base_edge_multiplier, edge_chamfer_y*base_edge_multiplier);

    // Стойки + штыри
    for (pos = hole_positions){
        translate([pos[0], pos[1], base_thickness])
            cylinder(h=standoff_height, d=standoff_outer_diam);
        translate([pos[0], pos[1], base_thickness + standoff_height])
            cylinder(h=board_thickness + pin_extra - (pin_tip_h>0?pin_tip_h:0), d=pin_diam, $fs=pin_fs, $fa=$fa);
        if (pin_tip_h > 0)
            translate([pos[0], pos[1], base_thickness + standoff_height + board_thickness + pin_extra - pin_tip_h])
                cylinder(h=pin_tip_h, d1=pin_diam, d2=max(pin_diam-0.6,0.5), $fs=pin_fs, $fa=$fa);
    }
}

module screenFrame(){
    // Рамка
    difference(){
        color("silver") chamfered_plate_bottom_edges_sym(base_width, base_height, frame_thickness, edge_chamfer_z, edge_chamfer_x, edge_chamfer_y);
        // окно под экран (сквозное). ВЫСОТА с учётом screen_frame_gap, НО XY не трогаем
        translate([open_off_x, open_off_y, -tiny])
            cube([open_width, open_height, frame_thickness + screen_frame_gap + 2*tiny]);
        // отверстия под штыри
        for (pos = hole_positions)
            translate([pos[0], pos[1], -tiny])
                cylinder(h=frame_thickness + screen_frame_gap + 2*tiny, d=pin_diam + 0.2, $fs=pin_fs, $fa=$fa);
    }
}

// ===== Вывод на сцену =====
pos = hole_positions[frag_index];

if (test_fragment) {
    if (print_base) {
        // Фрагмент основания
        intersection() {
            basePlate();
            translate([pos[0] - frag_size/2, pos[1] - frag_size/2, -1])
                cube([frag_size, frag_size, base_thickness + standoff_height + board_thickness + pin_extra + frag_h_extra]);
        }
    }
    if (print_frame) {
        // Фрагмент рамки — справа
        intersection() {
            translate([frag_size + frag_gap_x, 0, 0]) screenFrame();
            translate([pos[0] - frag_size/2 + frag_size + frag_gap_x, pos[1] - frag_size/2, -1])
                cube([frag_size, frag_size, frame_thickness + screen_frame_gap + frag_h_extra]);
        }
    }
} else {
    if (print_base) basePlate();
    if (print_frame) translate([0, base_height + 10, 0]) screenFrame();
}
