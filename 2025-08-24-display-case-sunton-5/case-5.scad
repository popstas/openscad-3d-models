// OpenSCAD: две детали — основание со стойками и штырями, и рамка с окном под экран
// Версия: v1.7 — анизотропная фаска снизу: независимые размеры по Z и по горизонтали (X/Y);
// добавлен режим тест‑фрагментов и echo-контроль полей до кромки.
// добавлен режим тест‑фрагментов и echo-контроль полей до кромки.

// ===== Точность аппроксимации окружностей =====
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

// ===== Общие доп. параметры =====
tiny = 0.1;                  // небольшой зазор для булевых операций
edge_chamfer_z = 4;       // высота фаски по Z (мм) - убрана фаска
edge_chamfer_x = 1.6;       // горизонтальный вылет фаски по X (с каждой стороны), мм - убрана фаска
edge_chamfer_y = 1.6;       // горизонтальный вылет фаски по Y (с каждой стороны), мм - убрана фаска
screen_frame_gap = 0.2;      // только для высоты вычитаний в рамке (не влияет на XY)

 
// ===== Параметры платы и экрана =====
board_length = 137;          // длина платы, мм
board_width  = 84;           // ширина платы, мм
board_thickness = 1.5;       // толщина платы, мм

screen_length = 120;         // длина (горизонталь) экрана, мм
screen_width  = 75.5;        // ширина (вертикаль) экрана, мм
 
// ===== Габариты основания/рамки =====
base_margin_x = 0;           // отступы к габариту НЕ используются — внешние размеры = board_length/board_width
base_margin_y = 0;           // внешняя ширина = board_width
base_thickness = 2;          // толщина основания, мм
base_edge_multiplier = 0;     // 

frame_thickness = 4;         // толщина рамки, мм
window_clearance_x = 2;      // припуск (каждая сторона) к окну под экран, мм
window_clearance_y = 0.5;

// ===== Параметры крепёжных отверстий, стоек и штырей =====
hole_spacing_x = 129;      // расстояние между отверстиями по X, мм
hole_spacing_y = 75;         // расстояние между отверстиями по Y, мм
hole_diameter_board = 3;     // диаметр отверстий в плате (под винт/штырь), мм
hole_edge_tweak_x = 0.5;   // на сколько ближе к краям по X
hole_edge_tweak_y = 1;   // на сколько ближе к краям по Y

standoff_outer_diam = 5;     // диаметр стоек (опора под плату), мм
standoff_height = 4.5;       // высота стоек до низа платы, мм

pin_extra = frame_thickness; // сколько штырь выступает над платой, мм (по умолч. = толщине рамки)
pin_diam  = hole_diameter_board - 0.1; // диаметр штыря = отверстие платы −0.1 мм
pin_tip_h = 0.8;             // конус-направляющая на конце штыря (0 — выключить)

// ===== Вычисляемые величины (общие для base и frame) =====
base_length = board_length;    // внешние габариты деталей строго равны размерам платы
base_width  = board_width;     // внешние габариты деталей строго равны размерам платы

// Отступы отверстий от краёв детали (симметричные) + сдвиг к краю на 1 мм
edge_x = max(0, (base_length - hole_spacing_x)/2 - hole_edge_tweak_x);
edge_y = max(0, (base_width  - hole_spacing_y)/2 - hole_edge_tweak_y);

// Позиции центров отверстий (общие для base и frame)
hole_positions = [
    [edge_x,                 edge_y                ], // нижний левый
    [edge_x,                 base_width - edge_y   ], // верхний левый
    [base_length - edge_x,   edge_y                ], // нижний правый
    [base_length - edge_x,   base_width - edge_y   ]  // верхний правый
];

// Проверочный вывод одинаковости полей (должны совпадать попарно)
left_margin   = hole_positions[0][0];
right_margin  = base_length - hole_positions[2][0];
bottom_margin = hole_positions[0][1];
top_margin    = base_width - hole_positions[1][1];
echo("Margins to edges (L,R,B,T):", left_margin, right_margin, bottom_margin, top_margin);

// Размер окна под экран (сквозное)
open_len = screen_length + 2*window_clearance_x;
open_wid = screen_width  + 2*window_clearance_y;
open_off_x = (base_length - open_len)/2;   // одинаково для base и frame
open_off_y = (base_width  - open_wid)/2;

// ===== Вспомогательное =====
function clamp(val, lo, hi) = max(lo, min(val, hi));
function clamp_chz(t, chz) = clamp(chz, 0, t/2);
function clamp_chxy(l,w,chx,chy) = [clamp(chx, 0, l/2 - tiny), clamp(chy, 0, w/2 - tiny)];

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
    color("lightgray") chamfered_plate_bottom_edges_sym(base_length, base_width, base_thickness, edge_chamfer_z*base_edge_multiplier, edge_chamfer_x*base_edge_multiplier, edge_chamfer_y*base_edge_multiplier);

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
        color("silver") chamfered_plate_bottom_edges_sym(base_length, base_width, frame_thickness, edge_chamfer_z, edge_chamfer_x, edge_chamfer_y);
        // окно под экран (сквозное). ВЫСОТА с учётом screen_frame_gap, НО XY не трогаем
        translate([open_off_x, open_off_y, -tiny])
            cube([open_len, open_wid, frame_thickness + screen_frame_gap + 2*tiny]);
        // отверстия под штыри
        for (pos = hole_positions)
            translate([pos[0], pos[1], -tiny])
                cylinder(h=frame_thickness + screen_frame_gap + 2*tiny, d=pin_diam + 0.2, $fs=pin_fs, $fa=$fa);
    }
}

// ===== Вывод на сцену =====
pos = hole_positions[frag_index];

if (test_fragment) {
    // Фрагмент основания
    intersection() {
        basePlate();
        translate([pos[0] - frag_size/2, pos[1] - frag_size/2, -1])
            cube([frag_size, frag_size, base_thickness + standoff_height + board_thickness + pin_extra + frag_h_extra]);
    }
    // Фрагмент рамки — справа
    intersection() {
        translate([frag_size + frag_gap_x, 0, 0]) screenFrame();
        translate([pos[0] - frag_size/2 + frag_size + frag_gap_x, pos[1] - frag_size/2, -1])
            cube([frag_size, frag_size, frame_thickness + screen_frame_gap + frag_h_extra]);
    }
} else {
    //basePlate();
    translate([0, base_width + 10, 0]) screenFrame();
}
