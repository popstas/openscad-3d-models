// =============================================
// 3D: Ceiling Corner Support for Printer Frame
// Version: 1.1
// Author: ChatGPT (OpenSCAD)
// =============================================

// ----------------------------
// Описание модулей (фрагментов)
// ----------------------------
// base() — полная сборка: объединяет bottom_pad(len), corner_fillet_xy(...), post(h),
//          top_pad(), wrap_tabs(); len/h берутся из arm_len_full/post_h_full
//          или arm_len_tf/post_h_tf при test_fragment=true.
// top_pad() — верхняя площадка: pad_xy × pad_y, толщина top_pad_th; расположена на
//             Z = base_th + post_h_*; скругления контролируются radius_r.
// post(h) — вертикальная стойка сечением post_th × frame_w, высота h; основание на Z=base_th;
//           скругление рёбер ограничено min(radius_r, post_th/2).
// bottom_pad(len) — нижняя L‑образная площадка: две полосы шириной frame_w и длиной len,
//                   толщина base_th, внутренний угол со скруглением radius_r; уходит в +X и +Y.
// left_wrap() / right_wrap() — вертикальные «обжимные» лапки: ширина wrap_w, высота вниз wrap_h,
//                              толщина wrap_th; охватывают раму снаружи вдоль сторон Y и X.
// wrap_tabs() — объединяет обе лапки (left_wrap и right_wrap).
// add_supports(h, len) — опциональные косынки: вылет support_len, высота support_h,
//                        толщина экструзии = post_th; включаются флагом supports.
// clip_for_fragments() — при test_fragment=true выводит два укороченных фрагмента; окна клипа
//                        задаются frag_size, frag_gap_x, frag_h_extra.

// ----------------------------
// Настройка точности
// ----------------------------
$fn = 0;        // фиксированную сегментацию отключаем
$fa = 6;        // 5–8° обычно достаточно
$fs = 0.35;     // ≈ диаметр сопла (0.3–0.5 для сопла 0.4)
pin_fs = 0.25;  // чуть тоньше для штырей и отверстий


// ----------------------------
// Тестовые фрагменты (стандартный блок)
// ----------------------------
test_fragment = false; // true — печатать только укороченные фрагменты
frag_size     = 50;    // размер квадрата вырезки, мм (для обрезки intersection)
frag_index    = 0;     // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП (необязательно)
frag_gap_x    = 10;    // зазор между фрагментами по X, мм
frag_h_extra  = 50;    // запас по высоте клипа, мм

// ----------------------------
// Фаски/скругления по краям
// ----------------------------
tiny = 0.1;                  // небольшой зазор для булевых операций
edge_chamfer_z = 1;          // высота фаски по Z (мм)
edge_chamfer_x = 5;          // горизонтальный вылет фаски по X (с каждой стороны), мм
edge_chamfer_y = 5;          // горизонтальный вылет фаски по Y (с каждой стороны), мм
screen_frame_gap = 0.2;      // совместимость с шаблонами; здесь не влияет

// Скругления
radius_r = 30;                 // общий радиус скруглений по 2D-контуром (мм)

// ----------------------------
// Параметры модели (все размеры в мм)
// ----------------------------
// Габариты рамы и подпорки
frame_w         = 30;        // ширина рамы принтера (и ширина подпорки)
post_th         = 3;         // толщина вертикальной стойки (подпорки)
post_y = radius_r/2;
base_th         = 2;         // толщина нижних горизонтальных лапок (площадка сверху рамы)
top_pad_th      = 3;         // толщина верхней квадратной площадки

// Высота
gap_total       = 213;       // расстояние от верха рамы до потолка
post_h_full     = gap_total - (base_th + top_pad_th); //= 208

// Горизонтальные лапки (на раму)
arm_len_full    = 87;        // длина лапок от угла рамы (по X и по Y)
arm_th          = base_th;   // толщина лапок = толщина нижней платформы
// bottom_pad_r удалён — используем общий radius_r

// Вертикальные лапки (обхват снаружи)
wrap_h          = 15;        // высота вниз по Z (от 0 до -wrap_h)
wrap_w          = frame_w;   // ширина вдоль ребра (по X или Y)
wrap_y = post_y;
wrap_th         = 2;         // толщина каждой вертикальной лапки (наружу, по X/Y)

// Верхняя площадка
pad_xy          = 30;        // 30x30 мм квадратная площадка сверху
pad_y           = 2*post_y;  // ширина по Y верхней площадки (в 2 раза больше post_y)
// Доп. сдвиг верхней площадки по X, чтобы точно начать от X=0 (тонкая подстройка)
top_pad_off_x_extra = 0;     // мм (обычно 0; увеличьте, если визуально уходит в X<0)

// Рёбра жёсткости
supports        = true;      // флаг для добавления косынок/ребер
support_len     = 28;        // вылет ребра от стойки (по X/Y)
support_h       = 40;        // высота ребра по Z

// ----------------------------
// Значения для test_fragment
// ----------------------------
arm_len_tf      = 40;        // укороченная длина лапок
height_tf_total = 50;        // общая высота фрагмента
post_h_tf       = height_tf_total - (base_th + top_pad_th); // укороченная высота стойки

// ----------------------------
// Вспомогательные функции/модули
// ----------------------------
// 2D-скруглённый прямоугольник заданного размера (внешний габарит size=[x,y])
module rr2d(size=[10,10], r=2){
    sx = size[0]; sy = size[1];
    // стартовая внутренняя заготовка меньше на 2*r, затем offset(r)
    offset(r=r)
        square([max(sx-2*r, tiny), max(sy-2*r, tiny)], center=false);
}

// 2D-прямоугольник с закруглением ТОЛЬКО на стороне minY (низу)
module rr2d_round_minY(size=[10,10], r=2){
    w = size[0]; h = size[1];
    r2 = min(r, w/2 - tiny, h/2 - tiny);
    union(){
        // Верхняя часть без скруглений
        translate([0, r2]) square([w, max(h - r2, tiny)], center=false);
        // Нижняя перемычка между кругами
        translate([r2, 0]) square([max(w - 2*r2, tiny), r2], center=false);
        // Кварткруги снизу слева и справа
        translate([r2, r2]) circle(r=r2);
        translate([w - r2, r2]) circle(r=r2);
    }
}

// 2D-прямоугольник с закруглением ТОЛЬКО на стороне minX (слева)
module rr2d_round_minX(size=[10,10], r=2){
    // Скругление только на стороне ПРАВАЯ (maxX); minX остаётся прямой
    w = size[0]; h = size[1];
    r2 = min(r, w/2 - tiny, h/2 - tiny);
    union(){
        // Основной прямоугольник по всей ширине без скругления слева
        square([w - r2, h], center=false);
        // Правые верх/низ закругляем четвертями круга у точки (w - r2, ...)
        translate([w - r2, r2]) circle(r=r2, $fs=pin_fs, $fa=6);
        translate([w - r2, h - r2]) circle(r=r2, $fs=pin_fs, $fa=6);
        // Вертикальная перемычка между четвертями
        translate([w - r2, r2]) square([r2, max(h - 2*r2, tiny)], center=false);
    }
}

// 2D-скруглённая L-форма: две полосы шириной w и длиной len, сходящиеся в углу (0,0)
module L2D(len, w, r){
    // Скругляем внешние углы без увеличения общей толщины w.
    r_eff = min(r, w/2 - tiny, len/2 - tiny);
    inner_len = max(len - 2*r_eff, tiny);
    inner_w   = max(w   - 2*r_eff, tiny);
    // Основная L-форма со скруглёнными внешними кромками
    offset(r=r_eff)
        union(){
            square([inner_len, inner_w], center=false);   // полоса по X (внутренняя)
            square([inner_w, inner_len], center=false);   // полоса по Y (внутренняя)
        }
}

// Четверть круга для скругления внутреннего угла на плоскости XY (у (0,0))
module corner_fillet_xy(r, h){
    linear_extrude(height=h)
        intersection(){
            square([r, r], center=false);
            circle(r=r, $fs=pin_fs, $fa=6);
        }
}



// Верхняя квадратная площадка (с полукругом справа и скруглением левого края)
module top_pad(){
    translate([0, post_y, base_th + (test_fragment?post_h_tf:post_h_full)])
        linear_extrude(height=top_pad_th)
            rr2d_round_minX([pad_xy, pad_y], r=radius_r/4);
}

// Вертикальная стойка (30 x 3, высота post_h)
module post(h){
    r_post = min(radius_r, post_th/2 - tiny, frame_w/2 - tiny);
    r_fillet = min(radius_r, frame_w/2 - tiny);
    translate([post_th/2, r_fillet, base_th])
        linear_extrude(height=h)
            rr2d([post_th, frame_w], r=r_post);
}

// Нижние горизонтальные лапки-"Г" (толщина base_th)
module bottom_pad(len){
    translate([radius_r/2, radius_r/2, 0])
        linear_extrude(height=base_th)
            L2D(len, frame_w, radius_r);
}

// Левая лапка (обхват по Y-стороне)
module left_wrap(){
    r_corner = min(radius_r, frame_w/2 - tiny);
    // wrap_w = max(wrap_w + wrap_th, tiny); // уменьшить охват по Y на wrap_th
    translate([wrap_th, wrap_w + r_corner - wrap_th, -wrap_h])
        rotate([270,180,90])
            linear_extrude(height=wrap_th)
                rr2d_round_minY([wrap_w, wrap_h], r=min(radius_r, wrap_w/2 - tiny, wrap_h/2 - tiny));
}

// Правая лапка (обхват по X-стороне)
module right_wrap(){
    r_corner = min(radius_r, frame_w/2 - tiny);
    translate([frame_w + r_corner, 0, 0])
        rotate([0,90,90])
            linear_extrude(height=wrap_th)
                rr2d_round_minX([wrap_h, wrap_w + wrap_th], r=min(radius_r, (wrap_w + wrap_th)/2 - tiny, wrap_h/2 - tiny));
}

// Совместимость: собрать обе лапки
module wrap_tabs(){
    left_wrap();
    right_wrap();
}

// Опциональные рёбра жёсткости (две косынки вдоль X и Y)
module add_supports(h, len){
    if(supports){
        // Косынка XZ, экструзия по Y = post_th
        translate([0,0,base_th])
            linear_extrude(height=post_th)
                polygon(points=[[0,0],[len,0],[0,min(h, post_h_full)]]);
        // Косынка YZ, экструзия по X = post_th (поворот)
        translate([0,0,base_th])
            rotate([0,0,90])
                linear_extrude(height=post_th)
                    polygon(points=[[0,0],[len,0],[0,min(h, post_h_full)]]);
    }
}

// Полная сборка модели
module base(){
    len = test_fragment ? arm_len_tf : arm_len_full;
    h   = test_fragment ? post_h_tf   : post_h_full;

    union(){
        top_pad();
        post(h);
        bottom_pad(len);
        wrap_tabs();
        // Скругление в месте стыка стойки и нижней площадки
        // corner_fillet_xy(min(radius_r, frame_w/2 - tiny), base_th);
        // add_supports(support_len, support_h);
    }
}

// ---------------
// Клиппер фрагментов
// ---------------
module clip_for_fragments(){
    if(test_fragment){
        // Фрагмент у основания
        translate([0,0,0])
            intersection(){
                children();
                translate([0,0,-frag_h_extra])
                    cube([frag_size, frag_size, base_th + post_h_tf + top_pad_th + 2*frag_h_extra], center=false);
            }
        // Фрагмент у вершины (сдвинем по X для разнесения)
        translate([frag_size + frag_gap_x, 0, 0])
            intersection(){
                children();
                // окно вокруг верхней площадки
                z0 = base_th + max(post_h_tf - frag_size/2, 0);
                translate([0,0,z0])
                    cube([frag_size, frag_size, frag_size + frag_h_extra], center=false);
            }
    }else{
        children();
    }
}

// ----------------------------
// ВЫВОД МОДЕЛИ
// ----------------------------
clip_for_fragments() base();

// ----------------------------
// Примечания по ориентации:
// - Система координат выбрана так, что угол рамы находится в (0,0,0).
// - Лапки и площадки уходят в +X и +Y от угла. Левый наружный край — плоскость X=0.
// - Топ-площадка 30x30 мм расположена строго над стойкой.
// - Вертикальные лапки вниз (wrap_tabs) находятся только с внешней стороны угла: у Y=frame_w и X=frame_w.
// - Радиусы скругления по 2D-контуром = radius_r. Для стойки радиус ограничен её толщиной (минимум из radius_r и post_th/2).
