// =============================================
// OpenSCAD: Handlebar stub (заглушка руля)
// Версия: v1.0 — первичная параметрическая модель
// =============================================

use <../modules.scad>;

// Короткое описание
description = "Dome cap with flexible petals for handlebar tube";
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
edge_chamfer_z = 1;          // высота фаски по Z (мм)
edge_chamfer_x = 5;          // вылет фаски по X (мм)
edge_chamfer_y = 5;          // вылет фаски по Y (мм)
screen_frame_gap = 0.2;      // только для высоты вычитаний

// =============================================
// ===== Параметры модели =====
// Основная геометрия по фото/описанию пользователя
// 1) Верхняя шапка (сферический сегмент)
cap_d_outer   = 24.8;   // внешний диаметр шапки, мм
cap_h         = 1.2;    // высота шапки над плоскостью, мм
cap_shell_th  = 1.2;    // толщина оболочки купола, мм

// 2) Вставка с лепестками (конус + прорези)
insert_d_bottom = 18.2;   // диаметр у основания (вход в трубу), мм
insert_d_top    = 16.5;   // диаметр у верхней кромки, мм
insert_h        = 14.0;   // общая высота вставки (уточните), мм
petal_ch        = 2.0;    // высота нижней фаски лепестков, мм
petals_n        = 6;      // количество лепестков (по фото — 6)
slot_w_mm       = 2.0;    // ширина прорези между лепестками, мм

// Вычисляемые служебные
cap_r_outer = cap_d_outer/2;
cap_R_sphere = (cap_r_outer*cap_r_outer + cap_h*cap_h) / (2*cap_h); // радиус сферы для сегмента
cap_r_inner = max(cap_r_outer - cap_shell_th, 0.5);
cap_R_inner = max(cap_R_sphere - cap_shell_th, 0.5);

// Габариты для клипа фрагментов
base_L = cap_d_outer;
base_W = cap_d_outer;
base_h = cap_h + insert_h;

// =============================================
// ===== Комментарии ===========================
/*
Детали/фрагменты:
- cap_top: сферическая шапка толщиной cap_shell_th
- cap_plate: круглая пластина под шапкой толщиной cap_plate_th, d = cap_plate_d
- petals_ring: конусная втулка с прорезями (лепестки), снизу фаска petal_ch
- base: сборка cap + petals_ring

Ориентация: Z вверх, плоскость сопряжения (верхним дном втулки) — Z=0.
Шапка располагается выше Z=0, лепестки — ниже.
*/

// =============================================
// ===== Вспомогательные модули =================
module spherical_cap_segment(d_outer, h){
  // Создаёт внешний сферический сегмент высоты h и диаметра d_outer, основание в плоскости Z=0
  r_out = d_outer/2;
  R = (r_out*r_out + h*h) / (2*h);
  // Ограничиваем сферу двумя плоскостями: z in [0, h]
  // translate([0,0,R - 1.1]) sphere(r=R, $fs=$fs, $fa=$fa);
  translate([0,0,-h]) intersection(){
    translate([0,0,R - 0]) sphere(r=R, $fs=$fs, $fa=$fa/3);
    cylinder(h=h, d=d_outer + 2*tiny);
  }
  translate([0,0,0]) cylinder(h=cap_shell_th, d=d_outer);
}

// Вырез для прорезей (тангенциальный прямоугольный нож)
module petal_slot_cutter(h, w, d_ref){
  R = d_ref/2 + 1; // +1 чтобы гарантированно пересечь наружу
  translate([-w/2, -R, 0]) cube([w, 2*R, h + 2*tiny]);
}

// =============================================
// ===== Модули деталей ========================

// 1) Купол
module cap_top(){
  difference(){
    spherical_cap_segment(cap_d_outer, cap_h);
    // внутренняя полость купола (приближённо тем же центром сферы)
    // translate([0,0,0])
    //   intersection(){
    //     translate([0,0,cap_R_inner - cap_h]) sphere(r=cap_R_inner, $fs=$fs, $fa=$fa);
    //     cylinder(h=cap_h + tiny, d=max(cap_d_outer - 2*cap_shell_th, tiny));
    //   }
  }
}

// 2) Круглая пластина соединения купола с втулкой
module cap(){
  // Только сферический сегмент толщины cap_shell_th без нижней пластины
  cap_top();
}

// 3) Втулка с лепестками (осевая заготовка + прорези)
module petals_body_up(){
  // Модель от Z=0 вверх; затем развернём вниз через upside_down(insert_h)
  union(){
    // нижний участок — фаска наружу (сужение к низу)
    cylinder(h=petal_ch, d1=max(insert_d_bottom - 2*petal_ch, tiny), d2=insert_d_bottom, $fs=pin_fs, $fa=6);
    // основной конусный участок
    translate([0,0,petal_ch])
      cylinder(h=max(insert_h - petal_ch, tiny), d1=insert_d_bottom, d2=insert_d_top, $fs=pin_fs, $fa=6);
  }
}

module petals_ring(){
  // Разворачиваем тело вниз: верх втулки совпадает с Z=0
  upside_down(insert_h)
    difference(){
      petals_body_up();
      // прорези
      for(i=[0:petals_n-1])
        rotate([0,0,i*360/petals_n])
          petal_slot_cutter(insert_h + tiny, slot_w_mm, max(insert_d_bottom, insert_d_top) + 4);
      // внутренняя полость втулки
      translate([0,0,0])
        cylinder(h=insert_h + tiny, d=max(insert_d_bottom /2, tiny), $fs=pin_fs, $fa=6);
    }
}

// 4) Сборка
module base(){
  union(){
    cap();
    petals_ring();
  }
}

// ===== Вывод всех фрагментов ====================
module show_all(){
  // Можно отключать элементы при необходимости
  base();
}

// ===== Обрезка тест‑фрагментов ==================
module show_all_clipped(){
  clip_for_fragments_bbox(base_L, base_W, base_h, enabled=test_fragment, frag_size=frag_size, frag_index=frag_index, frag_h_extra=frag_h_extra)
    show_all();
}

// ===== Точка входа ==============================
module main(){
  show_all_clipped();
}

main();
