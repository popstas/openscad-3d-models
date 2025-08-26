// MODEL_VERSION = "v1.3.1"  // обновляйте номер при изменениях

// Short description for models table
description = "ECig platform stand with oval cup";

// ====================== Точность рендера ======================
$fn = 0;        // фиксированную сегментацию отключаем
$fa = 6;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий

// ====================== Служебные параметры ===================
tiny = 0.10;            // небольшой зазор для булевых операций
screen_frame_gap = 0.2; // только для высоты вычитаний (не влияет на XY)

// ====================== Режим фрагмента ======================
test_fragment = false;   // true — печатать только угловые фрагменты (base)
frag_size     = 20;     // размер квадрата вырезки, мм
frag_index    = 0;      // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП (относительно основания)
frag_gap_x    = 10;     // зазор между фрагментами по X, мм
frag_h_extra  = 20;     // запас по высоте клипа, мм

// ====================== Габариты сигареты =====================
cig_w = 26.3;   // ширина (длинная ось «капсулы»), мм
cig_t = 15.0;   // толщина (короткая ось), мм

// Посадка стакана
fit_gap   = 0.00; // технологический зазор на сторону, мм
wall_thk  = 2.0;  // толщина стенок по умолчанию, мм (информативно)
cup_depth = 15.0; // глубина стакана, мм

// Анизотропное скругление профиля стакана
cup_r_ratio = 0.75; // радиус по ширине в cup_r_ratio раза больше, чем по длине

// Подставка (основание на 1 см шире по каждой стороне)
base_margin   = 10.0;  // прибавка по X и Y с каждой стороны, мм
bottom_floor  = 1.0;   // толщина дна под стаканом, мм
base_h        = cup_depth + bottom_floor; // высота постамента, мм
base_round_r  = 6.0;   // радиус скруглений по XY у постамента, мм

// Сужение внешних стенок от низа к верху (скос)
// Режимы: "auto" — верх внешнего контура автоматически подгоняется
//          к размеру горловины стакана + 2*rim_w (слияние при rim_w=0)
//          "manual" — использовать явные величины сокращения.
taper_mode = "auto";      // "auto" | "manual"
rim_w      = 0.0;          // ширина буртика сверху между внешней стенкой и стаканом, мм
manual_outer_taper_total_x = 15.0; // ручное уменьшение по X, мм
manual_outer_taper_total_y = 15.0; // ручное уменьшение по Y, мм

// Фаска по кромке стакана (верхняя кромка внутренней полости)
edge_chamfer_z = 1.0;  // высота фаски по Z, мм
edge_chamfer_x = 1.5;  // «вылет» фаски по X (на сторону), мм
edge_chamfer_y = 1.5;  // «вылет» фаски по Y (на сторону), мм

// ====================== Комментарии ===========================
/*
Модель: постамент с внутренним «стаканом» под овально-прямоугольный корпус
Блоки:
- Переменные (вверху) для всех размеров
- Комментарии (этот блок)
- Функции фрагментов детали (ниже)
- Функция вывода всех фрагментов show_all()
- Функция обрезки через intersection при test_fragment=true

Детали: base (главная деталь)
План:
- Основание — скруглённый прямоугольник (капсула) по XY, высотой base_h.
- Стакан — внутренний вырез-«капсула» размером (cig_w + 2*fit_gap) × (cig_t + 2*fit_gap)
  на глубину cup_depth с фаской edge_chamfer_* по верхней кромке.
- Габариты основания больше сигареты на base_margin с каждой стороны (т.е. +20 мм по каждой оси).
*/

// ====================== Вспомогательные 2D ====================
module rounded_rect2d(w, h, r) {
    r2 = min(r, min(w, h)/2);
    minkowski() {
        square([max(w - 2*r2, tiny), max(h - 2*r2, tiny)], center=true);
        circle(r=r2);
    }
}

// Анизотропный скруглённый прямоугольник (разные радиусы по X/Y)
module rounded_rect2d_aniso(w, h, rx, ry) {
    rx2 = min(rx, w/2);
    ry2 = min(ry, h/2);
    minkowski() {
        square([max(w - 2*rx2, tiny), max(h - 2*ry2, tiny)], center=true);
        scale([rx2, ry2]) circle(r=1);
    }
}

// Профиль стакана с овальными торцами (rx:ry = cup_r_ratio:1)
module cup_profile2d(w, h) {
    ry = min(h/2, w/(2*cup_r_ratio));
    rx = min(w/2, cup_r_ratio*ry);
    rounded_rect2d_aniso(w, h, rx, ry);
}

// Профиль основания (внешний контур) с тем же cup_r_ratio
module base_profile2d(w, h, rr) {
    // rr — отношение радиусов rx/ry, общее для всех прямоугольников
    // ограничиваем максимальный малый радиус параметром base_round_r
    ry = min(h/2, w/(2*rr), base_round_r);
    rx = min(w/2, rr*ry, base_round_r*rr);
    rounded_rect2d_aniso(w, h, rx, ry);
}

// ====================== Геометрия деталей =====================
module base_solid() {
    base_w = cig_w + 2*base_margin;
    base_t = cig_t + 2*base_margin;

    // Автоподгонка сужения к горловине стакана
    cup_w = cig_w + 2*fit_gap;
    cup_t = cig_t + 2*fit_gap;
    top_w_auto = cup_w + 2*edge_chamfer_x + 2*rim_w;
    top_t_auto = cup_t + 2*edge_chamfer_y + 2*rim_w;

    taper_x = (taper_mode=="auto") ? (base_w - top_w_auto) : manual_outer_taper_total_x;
    taper_y = (taper_mode=="auto") ? (base_t - top_t_auto) : manual_outer_taper_total_y;

    sx = max((base_w - taper_x) / max(base_w, tiny), 0.1);
    sy = max((base_t - taper_y) / max(base_t, tiny), 0.1);

    // Чтобы верхняя кромка имела те же пропорции скруглений, что и стакан,
    // компенсируем анизотропное масштабирование: на дне ставим rr_bottom,
    // которое после масштабов [sx,sy] даст cup_r_ratio на верху.
    rr_bottom = cup_r_ratio * (sy / sx);

    linear_extrude(height=base_h, scale=[sx, sy])
        base_profile2d(base_w, base_t, rr_bottom);
}

// Вырез стакана (основной объём + фаска верхней кромки)
module cup_cut() {
    cup_w = cig_w + 2*fit_gap;
    cup_t = cig_t + 2*fit_gap;

    // Главный вертикальный вырез
    translate([0,0, base_h - cup_depth - screen_frame_gap])
        linear_extrude(height=cup_depth + 2*screen_frame_gap)
            cup_profile2d(cup_w, cup_t);

    // Фаска: конический (frustum) вырез сверху
    sx = (cup_w + 2*edge_chamfer_x) / max(cup_w, tiny);
    sy = (cup_t + 2*edge_chamfer_y) / max(cup_t, tiny);
    translate([0,0, base_h - edge_chamfer_z - screen_frame_gap])
        linear_extrude(height=edge_chamfer_z + 2*screen_frame_gap, scale=[sx, sy])
            cup_profile2d(cup_w, cup_t);
}
 
// Основная деталь
module base() {
    difference() {
        base_solid();
        cup_cut();
    }
} 

// ====================== Клипперы фрагментов ===================
module corner_clipper(i=0) {
    // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП
    base_w = cig_w + 2*base_margin;
    base_t = cig_t + 2*base_margin;
    dx = (i==0 || i==1) ? -(base_w/2 - frag_size/2)
       : (i==2 || i==3) ?  (base_w/2 - frag_size/2) : 0;
    dy = (i==0 || i==2) ? -(base_t/2 - frag_size/2)
       : (i==1 || i==3) ?  (base_t/2 - frag_size/2) : 0;

    translate([dx, dy, base_h/2])
        cube([frag_size, frag_size, base_h + frag_h_extra], center=true);
}

// Показ либо целой модели, либо тестового фрагмента
module show_all() {
    if (!test_fragment) {
        base();
    } else {
        translate([- (frag_size/2 + frag_gap_x/2), 0, 0])
            intersection() { base(); corner_clipper(frag_index); }
        translate([  (frag_size/2 + frag_gap_x/2), 0, 0])
            intersection() { base(); corner_clipper(frag_index); }
    }
}

// ====================== Старт рендера =========================
show_all();
