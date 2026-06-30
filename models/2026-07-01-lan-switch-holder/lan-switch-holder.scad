// OpenSCAD: LAN switch wall holder — open-top U-cradle
// Version: v1.0 — initial parametric model

use <../modules.scad>;

description = "Wall U-cradle for LAN switch (D-Link DGS-1005A), 90x23 pocket, 30 mm deep";
version_str = "1.0";

// ===== Точность аппроксимации окружностей =====
$fn = 0;
$fa = 6;
$fs = 0.35;
pin_fs = 0.25;

// ===== Режим печати тест‑фрагментов =====
test_fragment = false;
frag_size = 20;
frag_index = 0;
frag_gap_x = 10;
frag_h_extra = 20;

// ===== Общие доп. параметры =====
tiny = 0.1;
edge_chamfer_z = 1;
edge_chamfer_x = 5;
edge_chamfer_y = 5;
screen_frame_gap = 0.2;

// ===== Параметры модели =====
inner_w = 90;           // внутренняя ширина по X, мм
inner_h = 23;           // внутренняя высота кармана по Z, мм
depth_y = 30;           // глубина люльки по Y, мм
wall_th = 3;            // толщина стенок и дна, мм

lapka_out = 6;          // выступ лапок внутрь по X — одинаковый у передних и боковых, мм

screw_d = 3;            // диаметр отверстия под винт, мм
screw_head_d = 7;       // диаметр разверстия под головку, мм
screw_head_depth = 2;   // глубина разверстия под головку, мм
screw_clearance = 0.4;  // запас на отверстие, мм

corner_r = 3;           // скругление внешних вертикальных рёбер, мм

// ===== Комментарии ===========================
/*
Модель: настенный держатель коммутатора. Коммутатор вкладывается сверху внутрь
и обхватывается передними лапками.
Целевое устройство: D-Link DGS-1005A (5-port Gigabit Unmanaged Desktop Switch),
габариты корпуса 94 x 75 x 22.45 мм (datasheet) — посадка подтверждена натурно.
Оси: X — ширина, Y — глубина (от стены), Z — высота.
Дно (часть с отверстием) — пластина в плоскости XZ при Y=0, прилегает к стене.
Origin: нижний левый угол дна.

Фрагменты:
- bottom_plate — дно с центральным отверстием под винт (плоскость XZ, Y=0)
- left_wall, right_wall — боковые стенки на всю глубину
- left_lapka, right_lapka — передние обхватывающие лапки (плоскость параллельна дну, Y=depth)
- left_rail, right_rail — нижние опорные рельсы (вторые лапки), на них ложится коммутатор
- mount_hole — центральное крепление (Ø3 + коническая зенковка Ø7×2)
- holder — полная сборка
*/

// ===== Вычисляемые размеры =====
outer_x = inner_w + 2 * wall_th;   // 96
outer_z = inner_h + wall_th;       // 26 (дно + карман)

base_L = outer_x;                  // для clip_for_fragments
base_W = depth_y;
base_h = outer_z;

mount_x = outer_x / 2;             // центр по X
mount_z = outer_z / 2;            // центр по Z

// ===== Вспомогательные модули ====================
// Сквозное отверстие под винт с разверстием под головку, ось вдоль +Y.
module mount_hole() {
  translate([mount_x, 0, mount_z])
    rotate([-90, 0, 0]) {
      // сквозное отверстие
      translate([0, 0, -tiny])
        cylinder(h = wall_th + 2 * tiny, d = screw_d + screw_clearance, $fs = pin_fs, $fa = 6);
      // зенковка под головку: плавное сужение Ø_head -> Ø_screw, открыта внутрь кармана
      translate([0, 0, wall_th - screw_head_depth])
        cylinder(
          h = screw_head_depth + tiny,
          d1 = screw_d + screw_clearance,
          d2 = screw_head_d + screw_clearance,
          $fs = pin_fs,
          $fa = 6
        );
    }
}

// ===== Модули деталей ====================
// Внешний скруглённый объём люльки (footprint скруглён по углам, выдавлен по Z).
module outer_block() {
  linear_extrude(height = outer_z)
    rounded_rect(size = [outer_x, depth_y], r = corner_r);
}

// Вырез кармана: открыт сверху, спереди и снизу, оставляет дно (пластину при Y=0).
module cavity_cut() {
  translate([wall_th, wall_th, -tiny])
    cube([inner_w, depth_y, inner_h + outer_z]);
}

// Дно — пластина с отверстием (часть outer_block при y in [0, wall_th]).
module bottom_plate() {
  intersection() {
    outer_block();
    cube([outer_x, wall_th, outer_z]);
  }
}

module left_wall() {
  intersection() {
    outer_block();
    cube([wall_th, depth_y, outer_z]);
  }
}

module right_wall() {
  intersection() {
    outer_block();
    translate([outer_x - wall_th, 0, 0]) cube([wall_th, depth_y, outer_z]);
  }
}

// Передние (верхние) обхватывающие лапки: во фронтальной плоскости (параллельной дну),
// на всю высоту базы (по Z), выступают внутрь на lapka_out и держат коммутатор от выпадения.
module left_lapka() {
  translate([wall_th, depth_y - wall_th, 0])
    cube([lapka_out, wall_th, outer_z]);
}

module right_lapka() {
  translate([outer_x - wall_th - lapka_out, depth_y - wall_th, 0])
    cube([lapka_out, wall_th, outer_z]);
}

// Боковые (нижние) опорные лапки‑рельсы: на всю глубину базы (по Y), на уровне дна,
// тот же выступ внутрь lapka_out.
module left_rail() {
  translate([wall_th, 0, 0])
    cube([lapka_out, depth_y, wall_th]);
}

module right_rail() {
  translate([outer_x - wall_th - lapka_out, 0, 0])
    cube([lapka_out, depth_y, wall_th]);
}

module holder() {
  difference() {
    union() {
      // каркас = внешний объём минус карман (остаются дно + боковые стенки)
      difference() {
        outer_block();
        cavity_cut();
      }
      left_lapka();
      right_lapka();
      left_rail();
      right_rail();
    }
    mount_hole();
  }
}

// ===== Вывод всех фрагментов ====================
module show_all() {
  clip_for_fragments() {
    holder();
  }
}

// ===== Точка входа ====================
show_all();
