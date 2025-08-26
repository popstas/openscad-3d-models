// =============================================
// 3D: Mic Transceiver Box — inner 100x35x17, base + cap
// Version: 1.0
// Author: ChatGPT (OpenSCAD)
// =============================================

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
test_fragment = false;   // true — печатать только угловые фрагменты (base+cap)
frag_size     = 20;      // размер квадрата вырезки, мм
frag_index    = 0;       // 0=НЛ, 1=ВЛ, 2=НП, 3=ВП (относительно основания)
frag_gap_x    = 10;      // зазор между фрагментами по X, мм
frag_h_extra  = 20;      // запас по высоте клипа, мм

// ----------------------------
// Фаски/скругления по краям (совместимость)
// ----------------------------
tiny = 0.1;                  // небольшой зазор для булевых операций
edge_chamfer_z = 1;          // высота фаски по Z (мм)
edge_chamfer_x = 0.8;        // горизонтальный вылет фаски по X (каждая сторона), мм
edge_chamfer_y = 0.8;        // горизонтальный вылет фаски по Y (каждая сторона), мм
screen_frame_gap = 0.2;      // совместимость

// ----------------------------
// Параметры модели (мм)
// ----------------------------
inner_x = 100;               // внутренняя длина (X)
inner_y = 35;                // внутренняя ширина (Y)
inner_h = 31;                // внутренняя высота (Z)

wall_th    = 1.6;            // толщина стенок основания
bottom_th  = 1.6;            // толщина дна основания
corner_r   = 3.0;            // радиус скругления внутренних углов

// Крышка (накладная)
fit_clearance = 0.1;        // зазор на посадку (каждая сторона по радиусу/по XY)
cap_wall_th   = 1.0;         // толщина стенок крышки
cap_top_th    = 1;         // толщина верха крышки
cap_lip_h     = 5.0;        // глубина посадочного борта крышки (внутрь)

// Выбор вывода
print_base = true;
print_cap  = true;

// ----------------------------
// Вычисляемые размеры
// ----------------------------
base_outer_x = inner_x + 2*wall_th;
base_outer_y = inner_y + 2*wall_th;
base_outer_h = bottom_th + inner_h;

base_inner_r = max(corner_r, 0);
base_outer_r = base_inner_r + wall_th;

cap_inner_x = base_outer_x + 2*fit_clearance;
cap_inner_y = base_outer_y + 2*fit_clearance;
cap_inner_r = base_outer_r + fit_clearance;  // радиус по внутреннему борту крышки

cap_outer_x = cap_inner_x + 2*cap_wall_th;
cap_outer_y = cap_inner_y + 2*cap_wall_th;
cap_outer_r = cap_inner_r + cap_wall_th;

cap_h = cap_top_th + cap_lip_h;

// ----------------------------
// Комментарии / фрагменты
// ----------------------------
// Фрагменты:
// - base: основание — лоток с закругленными углами и плоским дном
// - cap: крышка — закрытый верх + борт нужной глубины, посадка по fit_clearance
// - clip_for_fragments: при test_fragment=true выводит по одному угловому фрагменту base и cap

// ----------------------------
// Вспомогательные функции/модули
// ----------------------------
function clamp(val, lo, hi) = max(lo, min(val, hi));
function clamp_chz(t, chz) = clamp(chz, 0, t/2);
function clamp_chxy(l,w,chx,chy) = [clamp(chx, 0, l/2 - tiny), clamp(chy, 0, w/2 - tiny)];

// 2D скруглённый прямоугольник внешнего размера size=[x,y]
module rr2d(size=[10,10], r=2){
    sx = size[0]; sy = size[1];
    offset(r=r)
        square([max(sx-2*r, tiny), max(sy-2*r, tiny)], center=false);
}

module rr2d_centered(size=[10,10], r=2){
    sx = size[0]; sy = size[1];
    translate([-sx/2, -sy/2]) rr2d(size, r);
}

// Экструзия скруглённого прямоугольника с фаской снизу (симметрия по X/Y)
module chamfered_rr_bottom_edges_sym(size=[10,10], r=2, h=5, chz=0.8, chx=0.8, chy=0.8){
    sx = size[0]; sy = size[1];
    chz2 = clamp_chz(h, chz);
    chxy = clamp_chxy(sx, sy, chx, chy);
    chx2 = chxy[0];
    chy2 = chxy[1];

    if (chz2 <= 0 || (chx2 <= 0 && chy2 <= 0)) {
        linear_extrude(height=h) rr2d([sx, sy], r);
    } else {
        union(){
            // верхнее тело
            translate([0,0,chz2])
                linear_extrude(height=h - chz2)
                    rr2d([sx, sy], r);
            // нижняя фаска (аппрокс. масштабом из центра)
            //r2 = max(r - min(chx2, chy2), tiny);
            //translate([sx/2, sy/2, 0])
            //    linear_extrude(height=chz2, scale=[sx/max(sx - 2*chx2, tiny), sy/max(sy - 2*chy2, tiny)])
            //        rr2d_centered([max(sx - 2*chx2, tiny), max(sy - 2*chy2, tiny)], r2);
        }
    }
}

// ----------------------------
// Фрагменты детали
// ----------------------------
module base_body(){
    difference(){
        // внешний корпус основания с фаской снизу
        chamfered_rr_bottom_edges_sym([base_outer_x, base_outer_y], base_outer_r, base_outer_h, edge_chamfer_z, edge_chamfer_x, edge_chamfer_y);
        // внутренняя полость
        translate([0,0,bottom_th - tiny])
            linear_extrude(height=inner_h + 2*tiny)
                rr2d([inner_x, inner_y], base_inner_r);
    }
}

module cap_shell(){
    difference(){
        // внешний объём крышки (без фаски сверху; опционально фаску снизу)
        chamfered_rr_bottom_edges_sym([cap_outer_x, cap_outer_y], cap_outer_r, cap_h, edge_chamfer_z, edge_chamfer_x, edge_chamfer_y);
        // внутренняя полость на глубину борта
        translate([0,0,0])
            linear_extrude(height=cap_lip_h + tiny)
                rr2d([cap_inner_x, cap_inner_y], cap_inner_r);
    }
}

// Главные детали
module base(){ base_body(); }
module cap(){ cap_shell(); }

// ---------------
// Клиппер фрагментов
// ---------------
function corner_offset(ix, L, W, s) =
    (ix == 0) ? [0, 0] :
    (ix == 1) ? [0, max(W - s, 0)] :
    (ix == 2) ? [max(L - s, 0), 0] :
                [max(L - s, 0), max(W - s, 0)];

module clip_for_fragments(){
    if(test_fragment){
        // Фрагмент основания
        intersection(){
            children(0);
            ofs = corner_offset(frag_index, base_outer_x, base_outer_y, frag_size);
            translate([ofs[0], ofs[1], -frag_h_extra])
                cube([frag_size, frag_size, base_outer_h + 2*frag_h_extra], center=false);
        }
        // Фрагмент крышки — справа
        translate([base_outer_x + frag_gap_x + frag_size, 0, 0])
            intersection(){
                children(1);
                ofs2 = corner_offset(frag_index, cap_outer_x, cap_outer_y, frag_size);
                translate([ofs2[0], ofs2[1], -frag_h_extra])
                    cube([frag_size, frag_size, cap_h + 2*frag_h_extra], center=false);
            }
    }else{
        // Полные детали
        children();
    }
}

// ----------------------------
// ВЫВОД МОДЕЛИ
// ----------------------------
if(test_fragment){
    clip_for_fragments(){ base(); }{ cap(); }
}else{
    if (print_base) base();
    if (print_cap) translate([0, base_outer_y + 10, 0]) cap();
}
