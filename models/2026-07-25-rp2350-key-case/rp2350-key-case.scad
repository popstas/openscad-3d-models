// 3D: RP2350 key case
// OpenSCAD: RP2350 key — корпус и крышка USB-брелка на плате RP2350
// Версия: v1.0 — восстановлено по сеткам RP2350-Case.3mf / rp2350-lid.3mf,
//                высота уменьшена 8.0 → 5.3 мм (выпаяно заднее гнездо),
//                стенки 1.5 → 1.0 мм, дно 2.0 → 0.8 мм

use <../modules.scad>;

description = "Case and lid for RP2350 USB key board, restored from 3MF, 20.2x27.35x5.3 mm, 1.0 mm walls";
version_str = "1.0";

// ===== Точность аппроксимации окружностей =====
$fn = 0;        // фиксированную сегментацию отключаем
$fa = 6;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий

// ===== Режим печати тест‑фрагментов =====
test_fragment = false;   // true — печатать только угловые фрагменты
frag_size     = 20;      // размер квадрата вырезки, мм
frag_index    = 0;       // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП (относительно основания)
frag_gap_x    = 10;      // зазор между фрагментами по X, мм
frag_h_extra  = 20;      // запас по высоте клипа, мм

// ===== Общие доп. параметры =====
tiny = 0.1;              // небольшой зазор для булевых операций
edge_chamfer_z = 1;      // высота фаски по Z (мм)
edge_chamfer_x = 5;      // горизонтальный вылет фаски по X, мм
edge_chamfer_y = 5;      // горизонтальный вылет фаски по Y, мм
screen_frame_gap = 0.2;  // только для высоты вычитаний

// ===== Параметры модели =====
// --- Полость под плату (задаёт габариты; менять только вместе с платой) ---
cav_w        = 18.2;     // ширина полости под плату, мм
cav_l        = 25.65;    // длина полости под плату, мм
wall         = 1.0;      // толщина боковых и задней стенок, мм (в оригинале 1.5)
front_wall   = 0.7;      // толщина передней стенки (со стороны USB), мм
floor_th     = 0.8;      // толщина дна (панели с кнопками), мм (в оригинале 2.0)
case_h       = 5.3;      // полная высота корпуса, мм (в оригинале 8.0)
edge_r       = 1.2;      // радиус скругления всех наружных рёбер, мм

// --- Полка под плату ---
niche_h      = 1.8;      // высота ниши под платой (под навесные детали снизу), мм
shelf_in_hw  = 7.1;      // полуширина ниши под платой, мм
shelf_l      = 15.7;     // длина полки от переднего торца, мм

// --- Вырез под USB-C ---
usb_hw       = 6.15;     // полуширина выреза, мм
usb_lift     = 0.2;      // от полки до низа выреза (толщина края платы), мм

// --- Пазы под защёлки крышки ---
groove_d     = 0.35;     // глубина паза в стенке, мм (оригинал 0.7 при стенке 1.5)
groove_dz    = 1.0;      // от верха корпуса до центра паза, мм
groove_hh    = 0.6;      // полувысота паза, мм
groove_y1    = [1.82, 8.58];    // передний боковой паз: диапазон по Y, мм
groove_y2    = [18.47, 25.23];  // задний боковой паз: диапазон по Y, мм
groove_back_hw = 3.29;   // полуширина заднего паза (под задний язычок крышки), мм

// --- Диагональные насечки-канавки на боковых стенках (врезаны внутрь) ---
notch_n      = 9;        // число насечек на каждой стороне
notch_pitch  = 2.3025;   // шаг насечек по Y, мм
notch_y0     = 4.94;     // Y центра первой насечки на середине её высоты, мм
notch_edge_gap = 0.3;    // отступ насечек от скруглений низа и верха стенки, мм
notch_depth  = 0.3;      // глубина канавки в стенке, мм
notch_bot_w  = 0.4;      // ширина дна канавки, мм
notch_open_w = 1.0;      // ширина канавки на поверхности стенки, мм
notch_slope  = 0.5733;   // наклон: смещение по -Y на 1 мм высоты

// --- Пружинящие кнопки в дне (B = BOOTSEL, R = RESET) ---
slot_w       = 0.3;      // ширина П-образной прорези, мм
tongue_y0    = 15.7;     // начало прорези (заделка язычка) по Y, мм
tongue_hw    = 2.625;    // полуширина язычка, мм
tongue_cx    = 6.175;    // смещение центра язычка от оси корпуса, мм
arch_cy      = 23.408;   // Y центра полукруглой арки прорези, мм
// Шарнирные карманы (утончение дна до 1.0 у заделки язычков) убраны:
// при дне 0.8 мм язычок гнётся и без них.

// --- Прочие элементы дна ---
// Карман под гнездо (тонкая мембрана 0.8 сзади по центру) убран — гнездо выпаяно.
hole_d       = 1.0;      // диаметр отверстия в дне под деталь платы, мм
hole_cx      = 2.1;      // смещение центра отверстия от оси X, мм
hole_cy      = 5.35;     // координата центра отверстия по Y, мм
label_size   = 5.41;     // кегль букв B/R, мм
label_depth  = 0.2;      // глубина гравировки букв, мм
label_flip   = true;     // true — буквы развёрнуты на 180° (взгляд с другой стороны)
// Буквы центруются по язычку кнопки (tongue_cx / tongue_cy). Поправки компенсируют
// метрику шрифта: у text() valign/halign="center" центрирует по боксу шрифта,
// а не по видимому контуру глифа, и у B и R он разный.
label_b_off  = [-0.145, 0.067];  // доводка буквы B [X, Y], мм
label_r_off  = [-0.205, 0.067];  // доводка буквы R [X, Y], мм
label_font   = "Liberation Sans:style=Bold";

// --- Крышка ---
lid_plate_th = 0.8;      // толщина пластины крышки, мм
lid_rim_h    = 0.7;      // высота бортика крышки, мм
lid_gap      = 0.12;     // зазор крышки в полости на сторону, мм
lid_rim_top_x = 11.576;  // проём бортика вверху по X (у пластины), мм
lid_rim_top_y = 19.142;  // проём бортика вверху по Y, мм
lid_rim_bot_x = 14.0;    // проём бортика внизу по X (шире — заходная фаска), мм
lid_rim_bot_y = 21.552;  // проём бортика внизу по Y, мм
lid_rim_r    = 2.65;     // радиус скругления проёма бортика, мм
lid_tab_out  = 0.33;     // выступ боковой защёлки, мм (оригинал 0.487)
lid_tab_len  = 6.46;     // длина боковой защёлки, мм
lid_tab_cy   = 8.275;    // Y центра боковых защёлок от центра пластины, мм
lid_tab_z0   = -0.05;    // низ защёлки от низа пластины, мм
lid_tab_z1   = 0.6;      // верх защёлки от низа пластины, мм
lid_ftab_hw  = 6.0;      // полуширина переднего язычка, мм
lid_ftab_len = 0.695;    // вылет переднего язычка, мм
lid_rtab_hw  = 3.04;     // полуширина заднего язычка, мм
lid_rtab_len = 0.5;      // вылет заднего язычка, мм
lid_rtab_th  = 0.59;     // толщина заднего язычка, мм

// --- Раскладка на столе ---
print_case   = true;     // печатать корпус
print_lid    = true;     // печатать крышку
part_gap_x   = 5;        // зазор между деталями по X, мм

// ===== Ожидаемая геометрия =====
expected_dims = [43.82, 27.35, 5.3];  // габариты раскладки [X, Y, Z], мм
expected_parts = 2;                   // корпус + крышка
expected_tol = 0.5;                   // допуск сверки, мм

// ===== Комментарии ===========================
/*
Модель: корпус и крышка USB-брелка на плате RP2350.
Восстановлена по мешам RP2350-Case.3mf и rp2350-lid.3mf (FreeCAD/Bambu);
параметрического дерева в 3MF нет — все размеры сняты обмером сеток
(лучевое зондирование + срезы), поэтому воспроизводится форма, не триангуляция.

Оси: X — ширина, Y — длина (Y=0 — торец с USB-C), Z=0 — стол.
Начало координат корпуса — в минимальном углу габарита.

Отличия от оригинала (по заданию):
- дно 2.0 → 0.8 мм: карман под выпаянное гнездо (мембрана 0.8 сзади по центру)
  больше не нужен, а дно 2.0 было толстым именно ради него (карман 1.2 + остаток 0.8);
- высота 8.0 → 5.3 мм: полка опустилась вместе с дном до z=2.6, просвет для платы
  над дном ниши сохранён 3.2 мм;
- шарнирные карманы язычков убраны — дно 0.8 гнётся и без них;
- стенки 1.5 → 1.0 мм, полость под плату не изменилась, корпус ужался снаружи;
- глубина паза под защёлку 0.7 → 0.35 мм и выступ защёлки 0.487 → 0.33 мм:
  при стенке 1.0 мм паз 0.7 оставил бы 0.19 мм стенки у верхней кромки.

Фрагменты корпуса:
- case_body      — наружный объём со скруглением всех рёбер r=1.2
- case_cavity    — полость под плату: широкая часть над полкой + ниша под платой
- usb_cutout     — вырез под USB-C в передней стенке
- lid_grooves    — пазы под защёлки крышки в боковых стенках и в задней
- side_notches   — диагональные насечки-канавки (хват), врезаны в боковые стенки
- button_slots   — П-образные прорези, образующие пружинящие язычки-кнопки
- floor_hole     — сквозное отверстие ⌀1 в дне под деталь платы
- bottom_labels  — гравировка B (BOOTSEL) и R (RESET), читается снизу

Фрагменты крышки:
- lid_plate      — пластина 0.8 мм с передним и задним язычками
- lid_rim        — периметральный бортик с заходной фаской
- lid_side_tabs  — боковые защёлки, входящие в пазы корпуса
*/

// ===== Вычисляемые размеры =====
case_x   = cav_w + 2 * wall;              // 20.2
case_y   = front_wall + cav_l + wall;     // 27.35
case_z   = case_h;                        // 6.5
cx       = case_x / 2;                    // ось симметрии по X
cav_x0   = wall;                          // 1.0
cav_y0   = front_wall;                    // 0.7
cav_y1   = front_wall + cav_l;            // 26.35

shelf_z    = floor_th + niche_h;          // верх полки под плату = 2.6
usb_z      = shelf_z + usb_lift;          // низ выреза под USB-C = 2.8
groove_z   = case_z - groove_dz;          // центр паза по Z = 4.3

tongue_top = arch_cy + tongue_hw;         // свободный конец язычка = 26.033
tongue_cy  = (tongue_y0 + tongue_top) / 2; // центр язычка по Y = 20.867

notch_z0   = edge_r + notch_edge_gap;         // низ насечек = 1.5
notch_z1   = case_z - edge_r - notch_edge_gap; // верх насечек = 3.8
notch_zmid = (notch_z0 + notch_z1) / 2;
notch_ang  = atan(notch_slope);           // угол наклона насечки от вертикали
notch_len  = (notch_z1 - notch_z0) / cos(notch_ang);

// клип тест-фрагментов берёт высоту отсюда
base_L = case_x;
base_W = case_y;
base_h = case_z;

// крышка
lid_w    = cav_w - 2 * lid_gap;           // 17.96
lid_l    = cav_l - 2 * lid_gap;           // 25.41
lid_h    = lid_rim_h + lid_plate_th;      // 1.5

// ===== Вспомогательные функции ====================
function clamp(val, lo, hi) = max(lo, min(val, hi));

// профиль паза под защёлку: пары [доля глубины, смещение по Z]
function groove_pts() = [
  [0.000, -0.6], [0.237, -0.4], [0.713, -0.2], [0.951, -0.1],
  [1.000,  0.0],
  [0.951,  0.1], [0.713,  0.2], [0.237,  0.4], [0.000,  0.6]
];

// ===== Модули деталей ====================

// Наружный объём корпуса: все рёбра скруглены одним радиусом
module case_body(){
  rounded_prism(size = [case_x, case_y], h = case_z, r = edge_r, kr = edge_r);
}

// Полость под плату: широкая над полкой, узкая ниша под платой,
// за полкой (Y > shelf_l) полость на всю ширину до дна
module case_cavity(){
  // над полкой — вся ширина полости
  translate([cav_x0, cav_y0, shelf_z])
    cube([cav_w, cav_l, case_z - shelf_z + tiny]);
  // ниша под платой — узкая, на всю длину
  translate([cx - shelf_in_hw, cav_y0, floor_th])
    cube([2 * shelf_in_hw, cav_l, shelf_z - floor_th]);
  // за концом полки — вся ширина до дна
  translate([cav_x0, shelf_l, floor_th])
    cube([cav_w, cav_y1 - shelf_l, shelf_z - floor_th]);
}

// Вырез под USB-C в передней стенке
module usb_cutout(){
  translate([cx - usb_hw, -tiny, usb_z])
    cube([2 * usb_hw, cav_y0 + 2 * tiny, case_z - usb_z + tiny]);
}

// Брусок-паз: режет в -X от плоскости x=0, тянется по Y от 0 до len
module groove_bar(len, depth){
  pts = groove_pts();
  profile = concat(
    [for (p = pts) [-depth * p[0], p[1]]],
    [[tiny, groove_hh], [tiny, -groove_hh]]
  );
  translate([0, len, 0]) rotate([90, 0, 0])
    linear_extrude(height = len) polygon(points = profile);
}

// Пазы под защёлки крышки: по два на каждой боковой стенке + один в задней
module lid_grooves(){
  for (g = [groove_y1, groove_y2]){
    // левая стенка: режем наружу от внутренней грани x=cav_x0
    translate([cav_x0, g[0], groove_z]) groove_bar(g[1] - g[0], groove_d);
    // правая стенка — зеркально
    translate([case_x, 0, 0]) mirror([1, 0, 0])
      translate([cav_x0, g[0], groove_z]) groove_bar(g[1] - g[0], groove_d);
  }
  // задняя стенка: тот же профиль, развёрнут на 90° (режет в +Y)
  translate([cx - groove_back_hw, cav_y1, groove_z]) rotate([0, 0, -90])
    groove_bar(2 * groove_back_hw, groove_d);
}

// Одна диагональная насечка: врезается в +X от плоскости стенки x=0
module side_notch(){
  profile = [
    [-tiny, -notch_open_w / 2], [0, -notch_open_w / 2],
    [notch_depth, -notch_bot_w / 2], [notch_depth, notch_bot_w / 2],
    [0, notch_open_w / 2], [-tiny, notch_open_w / 2]
  ];
  rotate([notch_ang, 0, 0])
    linear_extrude(height = notch_len, center = true) polygon(points = profile);
}

// Насечки на обеих боковых стенках
module side_notches(){
  for (i = [0 : notch_n - 1]){
    yc = notch_y0 + i * notch_pitch;
    translate([0, yc, notch_zmid]) side_notch();
    translate([case_x, 0, 0]) mirror([1, 0, 0])
      translate([0, yc, notch_zmid]) side_notch();
  }
}

// П-образная прорезь вокруг одного язычка-кнопки (2D, центр в центре арки)
module button_slot_2d(){
  r_in  = tongue_hw;
  r_out = tongue_hw + slot_w;
  leg_l = arch_cy - tongue_y0;
  union(){
    // арка: верхняя половина кольца. Вычитаем низ только у кольца —
    // если применить вычитание ко всему объединению, оно срежет верх ножек
    // и оставит перемычку между язычком и дном
    difference(){
      difference(){
        circle(r = r_out);
        circle(r = r_in);
      }
      translate([-r_out - tiny, -r_out - tiny, 0])
        square([2 * r_out + 2 * tiny, r_out + tiny]);
    }
    // ножки прорези вниз от центра арки до заделки язычка
    translate([-r_out, -leg_l, 0]) square([slot_w, leg_l]);
    translate([r_in, -leg_l, 0]) square([slot_w, leg_l]);
  }
}

// Прорези обеих кнопок насквозь через дно
module button_slots(){
  for (s = [-1, 1])
    translate([cx + s * tongue_cx, arch_cy, -tiny])
      linear_extrude(height = floor_th + 2 * tiny) button_slot_2d();
}

// Отверстие в дне под деталь платы (в оригинале — глухой карман глубиной 1.2
// с остатком 0.8; при дне 0.8 мм становится сквозным)
module floor_hole(){
  translate([cx + hole_cx, hole_cy, -tiny])
    cylinder(h = floor_th + 2 * tiny, d = hole_d, $fs = pin_fs);
}

// Гравировка B и R на дне (читается снизу).
// label_flip = true — буквы развёрнуты на 180° (взгляд на девайс с другой стороны):
// «верх» буквы смотрит в -Y. Каждая буква остаётся на своём язычке-кнопке.
module bottom_labels(){
  for (i = [0, 1]){
    s = (i == 0) ? -1 : 1;
    off = (i == 0) ? label_b_off : label_r_off;
    translate([cx + s * tongue_cx + off[0], tongue_cy + off[1], -tiny])
      linear_extrude(height = label_depth + tiny)
        rotate([0, 0, label_flip ? 180 : 0])
          mirror([1, 0, 0])
            text(text = (i == 0) ? "B" : "R", size = label_size, font = label_font,
                 halign = "center", valign = "center");
  }
}

// Корпус целиком
module case_part(){
  difference(){
    case_body();
    side_notches();
    case_cavity();
    usb_cutout();
    lid_grooves();
    button_slots();
    floor_hole();
    bottom_labels();
  }
}

// --- Крышка: локальный центр в центре пластины, низ бортика в z=0 ---

// Контур пластины с передним и задним язычками
module lid_plate_2d(){
  square([lid_w, lid_l], center = true);
  translate([0, -(lid_l / 2 + lid_ftab_len / 2)])
    square([2 * lid_ftab_hw, lid_ftab_len], center = true);
  translate([0, lid_l / 2 + lid_rtab_len / 2])
    square([2 * lid_rtab_hw, lid_rtab_len], center = true);
}

// Пластина крышки
module lid_plate(){
  translate([0, 0, lid_rim_h])
    linear_extrude(height = lid_plate_th) lid_plate_2d();
}

// Передний язычок на всю высоту крышки (заходит в вырез USB)
module lid_front_tab(){
  translate([-lid_ftab_hw, -(lid_l / 2 + lid_ftab_len), 0])
    cube([2 * lid_ftab_hw, lid_ftab_len, lid_rim_h]);
}

// Бортик: рамка с заходной фаской по внутреннему контуру
module lid_rim(){
  difference(){
    linear_extrude(height = lid_rim_h) square([lid_w, lid_l], center = true);
    hull(){
      translate([0, 0, -tiny])
        linear_extrude(height = tiny)
          offset(r = lid_rim_r) offset(r = -lid_rim_r)
            square([lid_rim_bot_x, lid_rim_bot_y], center = true);
      translate([0, 0, lid_rim_h])
        linear_extrude(height = tiny)
          offset(r = lid_rim_r) offset(r = -lid_rim_r)
            square([lid_rim_top_x, lid_rim_top_y], center = true);
    }
  }
}

// Боковые защёлки крышки: скруглённый гребень по краю пластины
module lid_side_tabs(){
  z0 = lid_rim_h + lid_tab_z0;
  z1 = lid_rim_h + lid_tab_z1;
  th = z1 - z0;
  for (sy = [-1, 1]) for (sx = [-1, 1]){
    translate([sx * lid_w / 2, sy * lid_tab_cy, (z0 + z1) / 2])
      rotate([-90, 0, 0])
        linear_extrude(height = lid_tab_len, center = true)
          polygon(points = [
            [0, -th / 2], [sx * lid_tab_out, -th / 4],
            [sx * lid_tab_out, th / 4], [0, th / 2]
          ]);
  }
}

// Крышка целиком
module lid_part(){
  difference(){
    union(){
      lid_rim();
      lid_front_tab();
      lid_plate();
      lid_side_tabs();
    }
    // задний язычок тоньше пластины — снимаем сверху
    translate([-lid_rtab_hw, lid_l / 2 - tiny, lid_rim_h + lid_rtab_th])
      cube([2 * lid_rtab_hw, lid_rtab_len + 2 * tiny, lid_plate_th]);
  }
}

// ===== Вывод всех фрагментов ====================
module all_parts(){
  if (print_case) case_part();
  if (print_lid)
    translate([case_x + part_gap_x + lid_w / 2 + lid_tab_out, case_y / 2, 0])
      lid_part();
}

module main(){
  clip_for_fragments(){ all_parts(); }
}

// ===== Точка входа ====================
main();
