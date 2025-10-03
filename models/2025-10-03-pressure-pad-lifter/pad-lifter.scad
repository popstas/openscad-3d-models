// =============================================
// 3D: pressure pad lifter (PETG)
// Version: 1.0
// =============================================

use <../modules.scad>;

// ===== Short description =====
description = "Frame lifter to deflect cassette pressure pad by A while keeping ≥0.30mm tape clearance";
version_str = "1.0";

// ===== Точность аппроксимации окружностей =====
$fn = 0;        // фиксированную сегментацию отключаем
$fa = 6;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий

// ===== Режим печати тест‑фрагментов =====
test_fragment = false;   // true — печатать только угловые фрагменты (base+frame)
frag_size     = 20;      // размер квадрата вырезки, мм
frag_index    = 0;       // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП (относительно основания)
frag_gap_x    = 10;      // зазор между фрагментами по X, мм
frag_h_extra  = 20;      // запас по высоте клипа, мм

// ===== Общие доп. параметры =====
tiny = 0.1;                  // небольшой зазор для булевых операций
edge_chamfer_z = 1;       // высота фаски по Z (мм)
edge_chamfer_x = 5;       // горизонтальный вылет фаски по X (с каждой стороны), мм
edge_chamfer_y = 5;       // горизонтальный вылет фаски по Y (с каждой стороны), мм
screen_frame_gap = 0.2;      // только для высоты вычитаний в рамке (не влияет на XY)

// =============================================
// ===== Параметры модели (все размеры в мм) =====
// Геометрия головы
W_head = 4.0;          // ширина рабочей части головы
H_head = 9.0;          // высота корпуса в зоне окна
C_gap  = 0.6;          // суммарный зазор окна относительно головы (и по X, и по Z)

// Кинематика лифтера
A = 0.8;               // вынос скосов вперед от плоскости лица головы
B_deg = 30;            // угол скоса щёк (25/30/35)
D_radius = 0.5;        // радиус скругления кромок контакта с подушкой (R0.5–R1.0)
t = 1.8;               // толщина рамки по Z
depth_y = 7.0;         // глубина рамки вдоль движения ленты (6–8 рекоменд.)

// Крепление
screw_pitch = 12.0;    // межосевое расстояние отверстий (9–14)
screw_slot_len = 4.0;  // длина продольного паза
screw_diameter = 2.5;  // 2.0 для M2, 2.5 для M2.5
slot_w_m2   = 2.2;     // ширина паза под M2
slot_w_m25  = 2.7;     // ширина паза под M2.5
both_screw_variants = false; // если true — вырезать оба варианта пазов

// Монтажные подпятники (VHB опора)
pad_h = 0.3;           // высота микроподпятников
pad_size = [5, 3];     // размер подпятников (X,Y)

// Безопасный зазор до ленты
clearance_tape = 0.30; // минимальный зазор до ленты

// Каркас рамки
min_ring_x = 1.6;      // минимальная ширина рамки по X с каждой стороны
outer_corner_r = 0.8;  // скругление внешних углов

// ===== Вычисляемые размеры =====
inner_w = W_head + C_gap;     // окно по X
inner_h = H_head + C_gap;     // окно по Z

// Пробег щеки по X для получения выноса A при угле B: run = A / tan(B)
cheek_run_x = (B_deg > 0) ? (A / tan(B_deg)) : 0;
ring_x = max(min_ring_x, cheek_run_x + 0.6);  // запас, чтобы поместить скос
outer_x = inner_w + 2*ring_x;                 // полный размер по X
outer_y = depth_y + A;                        // спереди добавка A под щёки
outer_h = t + pad_h;                          // высота с подпятниками

inner_x0 = (outer_x - inner_w)/2;            // левый X окна
inner_x1 = inner_x0 + inner_w;                // правый X окна
front_y  = depth_y;                           // фронт плиты (до скосов)

// Отладка
echo("cheek_run_x:", cheek_run_x, "; ring_x:", ring_x, "; outer_x:", outer_x, "; outer_y:", outer_y);
echo("Tape clearance target >=", clearance_tape, "mm; A:", A, "; angle:", B_deg);

// =============================================
// ===== Вспомогательные модули =====

// Продольный паз по X через оболочку из двух цилиндров
module slot_x(center, len, width, h){
    cx = center[0]; cy = center[1];
    r = width/2;
    hull(){
        translate([cx - len/2, cy, 0]) cylinder(h=h, r=r, $fs=fs_pin(), $fa=6);
        translate([cx + len/2, cy, 0]) cylinder(h=h, r=r, $fs=fs_pin(), $fa=6);
    }
}

// Микроподпятник (RR пластинка)
module micro_pad_xy(at=[0,0], size=[5,3], h=0.3, r=0.6){
    translate([at[0]-size[0]/2, at[1]-size[1]/2, 0])
        rr_extrude(size=size, r=r, h=h);
}

// Щека-треугольник у внутреннего окна, слева/справа
// side = -1 (левая), +1 (правая)
module cheek(side=1){
    x_edge = (side < 0) ? inner_x0 : inner_x1;   // внутренняя кромка щёки
    // Треугольник в XY: вершины у фронта плиты и выноса A
    polygon_pts = (side < 0)
        ? [[x_edge, front_y], [x_edge, front_y + A], [max(x_edge - cheek_run_x, 0), front_y]]
        : [[x_edge, front_y], [x_edge, front_y + A], [min(x_edge + cheek_run_x, outer_x), front_y]];
    linear_extrude(height=t)
        polygon(points=polygon_pts);
}

// Внутреннее окно (скругление углов D_radius)
module inner_window(){
    translate([inner_x0, front_y - inner_h])
        rr_extrude(size=[inner_w, inner_h], r=D_radius, h=t + screen_frame_gap);
}

// Внешний контур плиты (с опциональной нижней фаской)
module outer_plate(){
    // Плита тела: [0..outer_x] x [0..depth_y]
    chamfered = edge_chamfer_z > 0 ? edge_chamfer_z : 0;
    module base_plate(){ rr_extrude(size=[outer_x, depth_y], r=outer_corner_r, h=t); }
    if (chamfered > 0){
        chamfer_rr_extrude(size=[outer_x, depth_y], h=t, r=outer_corner_r, ch=chamfered);
    } else {
        base_plate();
    }
}

// Два паза под винты (X‑продольные), один комплект — по screw_diameter
module screw_slots(){
    w_sel = (abs(screw_diameter - 2.0) < 0.01) ? slot_w_m2 : slot_w_m25;
    y_center = depth_y * 0.35;
    x_left = outer_x/2 - screw_pitch/2;
    x_right = outer_x/2 + screw_pitch/2;

    // Основной комплект по выбранному диаметру
    slot_x([x_left,  y_center], len=screw_slot_len, width=w_sel, h=t + screen_frame_gap);
    slot_x([x_right, y_center], len=screw_slot_len, width=w_sel, h=t + screen_frame_gap);

    // Опционально — второй комплект
    if (both_screw_variants){
        slot_x([x_left,  y_center], len=screw_slot_len, width=slot_w_m2,  h=t + screen_frame_gap);
        slot_x([x_right, y_center], len=screw_slot_len, width=slot_w_m2,  h=t + screen_frame_gap);
        slot_x([x_left,  y_center], len=screw_slot_len, width=slot_w_m25, h=t + screen_frame_gap);
        slot_x([x_right, y_center], len=screw_slot_len, width=slot_w_m25, h=t + screen_frame_gap);
    }
}

// Три микроподпятника на тыльной стороне
module back_pads(){
    y1 = depth_y * 0.20; y2 = depth_y * 0.80; yc = depth_y * 0.50;
    x1 = outer_x * 0.20; x2 = outer_x * 0.80; xc = outer_x * 0.50;
    micro_pad_xy([x1, y1], size=pad_size, h=pad_h, r=0.6);
    micro_pad_xy([x2, y1], size=pad_size, h=pad_h, r=0.6);
    micro_pad_xy([xc, y2], size=pad_size, h=pad_h, r=0.6);
}

// =============================================
// ===== Фрагменты детали =====

// Главная деталь: рамка с внутренним окном, щёчными скосами, пазами и подпятниками
module base(){
    difference(){
        union(){
            // Плита
            outer_plate();
            // Щёки (вынесены на A вперёд от фронта плиты)
            cheek(side=-1);
            cheek(side=+1);
            // Подпятники
            back_pads();
        }
        // Внутреннее окно
        inner_window();
        // Пазы под винты
        screw_slots();
    }
}

// Для совместимости с принятым стилем — модуль вывода всех фрагментов
module show_all(){
    base();
}

// Обрезка на тест-фрагменты по габаритам детали
module render_all(){
    clip_for_fragments_bbox(L=outer_x, W=outer_y, H=outer_h, enabled=test_fragment, frag_size=frag_size, frag_index=frag_index, frag_h_extra=frag_h_extra){
        show_all();
    }
}

// ===== Точка входа =====
module main(){
    render_all();
}

main();
