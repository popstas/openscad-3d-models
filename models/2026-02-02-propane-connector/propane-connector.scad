// OpenSCAD: propane connector — соединитель для пропанового баллона
// Версия: v1.0 — initial

description = "Propane connector with M8x1.5 thread, 20mm middle cylinder, 53mm hollow bottom cylinder";
version_str = "1.0";

// ===== Комментарии ===========================
/*
Модель: соединитель для пропанового баллона
Блоки:
- Переменные (вверху) для всех размеров
- Комментарии (этот блок)
- Функции фрагментов детали (ниже)
- Функция вывода всех фрагментов show_all()
- Функция обрезки через intersection при test_fragment=true

Детали: base (основная деталь)
Фрагменты:
- thread_section — резьбовая секция M8 x 1.5
- middle_cylinder — средний цилиндр 20мм диаметр, 32мм высота
- bottom_cylinder — нижний полый цилиндр 53мм внешний диаметр, 15мм высота, 5мм стенки

План: 
- Сверху вниз: резьба M8 x 1.5 (использует BOSL2 threaded_rod), затем средний цилиндр, затем нижний полый цилиндр
- Все части соединены в единую деталь
- Сквозное отверстие диаметром 5 мм проходит через всю модель по центру
*/

use <../modules.scad>;
include <../BOSL2/std.scad>;
include <../BOSL2/threading.scad>;

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
tiny = 0.1;                  // небольшой зазор для булевых операций
edge_chamfer_z = 1;       // высота фаски по Z (мм)
edge_chamfer_x = 5;       // горизонтальный вылет фаски по X (с каждой стороны), мм
edge_chamfer_y = 5;       // горизонтальный вылет фаски по Y (с каждой стороны), мм
screen_frame_gap = 0.2;      // только для высоты вычитаний в рамке (не влияет на XY)

// ===== Параметры модели =====
// Резьба M8 x 1.5
thread_diameter = 10.2;      // диаметр резьбы, мм
thread_pitch = 1.5;       // шаг резьбы, мм
thread_length = 10;      // длина резьбовой секции, мм

// Средний цилиндр
middle_diameter = 20;     // диаметр среднего цилиндра, мм
middle_height = 17;       // высота среднего цилиндра, мм

// Нижний цилиндр
bottom_outer_diameter = 53;  // внешний диаметр нижнего цилиндра, мм
bottom_height = 15;          // высота нижнего цилиндра, мм
bottom_wall_thickness = 2.5;   // толщина стенок нижнего цилиндра, мм
bottom_rounding = 3;         // радиус скругления нижнего цилиндра, мм
bottom_top_wall_thickness = 2;  // толщина верхней стенки модуля 3, мм
bottom_top_cut_diameter = 44;  // диаметр выреза сверху модуля 3, мм

// Сквозное отверстие
through_hole_diameter = 6;   // диаметр сквозного отверстия, мм

// Отверстия в модуле 3
bottom_holes_count = 4;      // количество отверстий
bottom_holes_radius = 16;    // расстояние от центра до отверстий, мм
bottom_holes_diameter = 6;   // диаметр отверстий, мм

// ===== Вычисляемые размеры =====
thread_radius = thread_diameter / 2;
middle_radius = middle_diameter / 2;
bottom_outer_radius = bottom_outer_diameter / 2;
bottom_inner_diameter = bottom_outer_diameter - 2 * bottom_wall_thickness;
bottom_inner_radius = bottom_inner_diameter / 2;
bottom_top_cut_radius = bottom_top_cut_diameter / 2;
through_hole_radius = through_hole_diameter / 2;
bottom_holes_radius_value = bottom_holes_radius;
bottom_holes_radius_hole = bottom_holes_diameter / 2;

// Общая высота модели
total_height = thread_length + middle_height + bottom_height;
base_h = total_height;  // для клиппера фрагментов

// ===== Вспомогательные функции ====================
function clamp(val, lo, hi) = max(lo, min(val, hi));
function clamp_chz(t, chz) = clamp(chz, 0, t/2);

// ===== Модуль резьбы M8 x 1.5 (использует BOSL2) =====
// Создаёт стандартную ISO метрическую резьбу M8 x 1.5
module thread_section() {
  threaded_rod(
    d=thread_diameter,
    pitch=thread_pitch,
    l=thread_length,
    anchor=BOTTOM,
    $fs=pin_fs,
    $fa=6
  );
}

// ===== Модули деталей ====================
// Средний цилиндр
module middle_cylinder() {
  // Начинается сразу после резьбы
  // Продолжается вниз, входя внутрь нижнего цилиндра для соединения
  connection_depth = 3;  // глубина входа среднего цилиндра в нижний, мм
  translate([0, 0, thread_length]) {
    cylinder(h=middle_height + connection_depth, r=middle_radius, $fs=pin_fs, $fa=6);
  }
}

// Нижний полый цилиндр
module bottom_cylinder() {
  // Начинается так, чтобы средний цилиндр входил внутрь него
  connection_depth = 3;  // глубина входа среднего цилиндра в нижний, мм
  translate([0, 0, thread_length + middle_height - connection_depth]) {
    difference() {
      // Внешний цилиндр со скруглёнными краями (как в can-cap-54.scad)
      if (bottom_rounding > 0) {
        translate([0, 0, bottom_rounding]) {
          minkowski() {
            cylinder(h=bottom_height - 2*bottom_rounding, d=bottom_outer_diameter - 2*bottom_rounding, $fs=pin_fs, $fa=6);
            translate([0, 0, 0]) sphere(r=bottom_rounding, $fs=pin_fs, $fa=6);
          }
        }
      } else {
        cylinder(h=bottom_height, r=bottom_outer_radius, $fs=pin_fs, $fa=6);
      }
      // Внутренняя полость - уменьшенный minkowski на толщину стенок х2
      // Уменьшена на 5 мм по высоте и сдвинута вверх на 5 мм (т.к. модель перевёрнута)
      // Ограничена сверху для создания верхней стенки толщиной 2 мм
      inner_cavity_offset = 5;  // смещение вверх, мм
      inner_cavity_height_reduction = 5;  // уменьшение высоты, мм
      top_wall_thickness = bottom_top_wall_thickness;  // толщина верхней стенки, мм
      if (bottom_rounding > 0) {
        translate([0, 0, bottom_rounding - tiny + inner_cavity_offset]) {
          minkowski() {
            cylinder(h=bottom_height - 2*bottom_rounding + 2*tiny - inner_cavity_height_reduction - top_wall_thickness, d=bottom_inner_diameter - 2*bottom_rounding, $fs=pin_fs, $fa=6);
            translate([0, 0, 0]) sphere(r=bottom_rounding, $fs=pin_fs, $fa=6);
          }
        }
      } else {
        translate([0, 0, -tiny + inner_cavity_offset]) {
          cylinder(h=bottom_height + 2*tiny - inner_cavity_height_reduction - top_wall_thickness, r=bottom_inner_radius, $fs=pin_fs, $fa=6);
        }
      }
      
      // Вырез сверху для видимости (глубина 3 мм)
      top_cut_depth = 3;  // глубина выреза сверху, мм
      translate([0, 0, bottom_height - top_cut_depth - tiny]) {
        cylinder(h=top_cut_depth + 2*tiny, r=bottom_top_cut_radius, $fs=pin_fs, $fa=6);
      }
      
      // 4 сквозных отверстия на расстоянии 16 мм от центра, диаметр 6 мм
      for (i = [0:bottom_holes_count - 1]) {
        angle = i * 360 / bottom_holes_count;
        translate([bottom_holes_radius_value * cos(angle), bottom_holes_radius_value * sin(angle), -tiny]) {
          cylinder(h=bottom_height + 2*tiny, r=bottom_holes_radius_hole, $fs=pin_fs, $fa=6);
        }
      }
    }
  }
}

// Основная деталь (все части вместе)
module base() {
  // Переворачиваем модель: резьба сверху, нижний цилиндр снизу
  translate([0, 0, total_height]) {
    mirror([0, 0, 1]) {
      difference() {
        // Все части модели
        union() {
          thread_section();
          middle_cylinder();
          bottom_cylinder();
        }
        // Сквозное отверстие по центру
        translate([0, 0, -tiny]) {
          cylinder(h=total_height + 2*tiny, r=through_hole_radius, $fs=pin_fs, $fa=6);
        }
      }
    }
  }
}

// ===== Вывод всех фрагментов ====================
module show_all() {
  if (test_fragment) {
    // Режим тест-фрагментов: обрезка через intersection
    intersection() {
      base();
      // Вырезка углового фрагмента
      translate([0, 0, -frag_h_extra]) {
        cube([frag_size, frag_size, total_height + 2*frag_h_extra], center=false);
      }
    }
  } else {
    // Полный рендер
    base();
  }
}

// ===== Точка входа ====================
show_all();
