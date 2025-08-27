// =============================================
// Base reusable functions and modules for models
// Version: 1.2
// =============================================

// Short description for models table (library file)
description = "Reusable base functions and modules for OpenSCAD models";

// Notes:
// - This is a library; it does not set $fn/$fa/$fs to avoid overriding model settings.
// - It will use model-provided variables when present, but has safe fallbacks.
//   pin_fs -> fs_pin(pin_fs) default 0.25. Small epsilon uses eps() = 0.1.
// - All modules are top-scope and documented.
// - Order: Common 2D ops -> Rounded rectangles -> 3D chamfers/extrusions -> Rings -> Misc.
// - Migration map (old -> new):
//   rr2d -> rounded_rect
//   rr2d_centered -> rounded_rect_centered
//   rounded_rect2d -> rounded_rect_centered
//   rounded_rect2d_aniso -> rounded_rect_aniso
//   chamfered_plate_bottom_edges_sym -> plate_with_bottom_chamfer
//   chamfered_rr_bottom_edges_sym -> rounded_rect_extrude_bottom_chamfer
//   round_chamfer_ring -> chamfer_ring
//   rr2d_round_minY/minX, L2D -> removed (recreate locally if needed)

// -------------------------------------------------
// Common 2D operations: offset, inset, fillet, rounding, shell
// -------------------------------------------------
// NOTE: These operate on 2D children(). Use inside a 2D context or before linear_extrude.

// outset(d=1) — creates an offset polygon outward by distance d around a 2D shape
// Uses offset() when available; for very old versions, falls back to minkowski.
module outset(d=1){
    if (d == 0) children();
    else if (version_num() < 20130424) {
        // Fallback for very old OpenSCAD versions w/o robust offset()
        render() minkowski(){ circle(r=d); children(0); }
    } else {
        offset(delta=d) children(0);
    }
}

// outset_extruded(d=1) — helper used by some legacy workarounds
module outset_extruded(d=1){
    projection(cut=true) minkowski(){
        cylinder(r=d);
        linear_extrude(center=true) children(0);
    }
}

// inset(d=1) — creates an offset polygon inward by distance d inside a 2D shape
module inset(d=1){
    if (d == 0) children();
    else offset(delta=-d) children(0);
}

// fillet(r=1) — adds fillets of radius r to all concave corners of a 2D shape
// Implementation: inset(r) then outset(r)
module fillet(r=1){
    inset(d=r) outset(d=r) children(0);
}

// rounding(r=1) — rounds all convex corners of a 2D shape
// Implementation: outset(r) then inset(r)
module rounding(r=1){
    outset(d=r) inset(d=r) children(0);
}

// shell(d, center=false) — makes a ring shell of width d along the edge of a 2D shape
// - d>0: outside shell; d<0: inside shell; center=true: centered on the edge (d>0)
module shell(d, center=false){
    if (center && d > 0){
        difference(){
            outset(d=d/2) children(0);
            inset(d=d/2) children(0);
        }
    }
    if (!center && d > 0){
        difference(){
            outset(d=d) children(0);
            children(0);
        }
    }
    if (!center && d < 0){
        difference(){
            children(0);
            inset(d=-d) children(0);
        }
    }
    if (d == 0) children(0);
}

// -------------------------------------------------
// 2D: Rounded rectangles (simplified API)
// -------------------------------------------------
// rounded_rect(size=[x,y], r) — rounded rectangle by outer size; anchor at (0,0)
module rounded_rect(size=[10,10], r=2){
    sx = size[0]; sy = size[1];
    offset(r=r)
        square([max(sx-2*r, eps()), max(sy-2*r, eps())], center=false);
}

// rounded_rect_centered(w, h, r) — centered at origin
module rounded_rect_centered(w, h, r){
    r2 = min(r, min(w, h)/2);
    minkowski(){
        square([max(w - 2*r2, eps()), max(h - 2*r2, eps())], center=true);
        circle(r=r2);
    }
}

// rounded_rect_aniso(w, h, rx, ry) — centered, anisotropic radii
module rounded_rect_aniso(w, h, rx, ry){
    rx2 = min(rx, w/2);
    ry2 = min(ry, h/2);
    minkowski(){
        square([max(w - 2*rx2, eps()), max(h - 2*ry2, eps())], center=true);
        scale([rx2, ry2]) circle(r=1);
    }
}

// -------------------------------------------------
// 3D: Chamfered plates and extrusions
// -------------------------------------------------
// plate_with_bottom_chamfer(l,w,t,chz,chx,chy)
// Plate l×w×t with a bottom-only chamfer of height chz and horizontal reach chx/chy per side.
module plate_with_bottom_chamfer(l, w, t, chz, chx, chy){
    chz2 = clamp_chz(t, chz);
    chxy = clamp_chxy(l, w, chx, chy);
    chx2 = chxy[0];
    chy2 = chxy[1];
    if (chz2 <= 0 || (chx2 <= 0 && chy2 <= 0)){
        cube([l,w,t]);
    } else {
        union(){
            translate([0,0,chz2]) cube([l,w,t-chz2]);
            translate([l/2, w/2, 0])
                linear_extrude(height=chz2, scale=[l/max(l-2*chx2, eps()), w/max(w-2*chy2, eps())])
                    square([max(l-2*chx2, eps()), max(w-2*chy2, eps())], center=true);
        }
    }
}

// rounded_rect_extrude_bottom_chamfer(size=[x,y], r, h, chz, chx, chy)
// Extruded rounded rectangle with bottom-only chamfer (anisotropic by chx/chy)
module rounded_rect_extrude_bottom_chamfer(size=[10,10], r=2, h=5, chz=0.8, chx=0.8, chy=0.8){
    sx = size[0]; sy = size[1];
    chz2 = clamp_chz(h, chz);
    chxy = clamp_chxy(sx, sy, chx, chy);
    chx2 = chxy[0];
    chy2 = chxy[1];
    if (chz2 <= 0 || (chx2 <= 0 && chy2 <= 0)){
        linear_extrude(height=h) rounded_rect([sx, sy], r);
    } else {
        union(){
            translate([0,0,chz2])
                linear_extrude(height=h - chz2)
                    rounded_rect([sx, sy], r);
            // bottom chamfer as scaled extrude from center
            r2 = max(r - min(chx2, chy2), eps());
        }
    }
}

// -------------------------------------------------
// 3D: Rect shells, trays, rings and chamfers
// -------------------------------------------------
// rr_extrude(size=[x,y], r, h) — sugar for linear_extrude(rounded_rect)
module rr_extrude(size=[10,10], r=2, h=5){
    linear_extrude(height=h) rounded_rect(size, r);
}

module rounded_rr_extrude(size=[10,10], r=2, h=5, s=0.7, mink_r=0){
    if (mink_r > 0){
        // Preserve outer size/height by pre-insetting and post-minkowski with a sphere
        sx = size[0]; sy = size[1];
        m = mink_r;
        sx2 = max(sx - 2*m, eps());
        sy2 = max(sy - 2*m, eps());
        r2 = max(r - m, 0);
        h2 = max(h - 2*m, eps());
        // Shift so final bbox matches [0..sx, 0..sy, 0..h]
        translate([m, m, m])
            minkowski(){
              linear_extrude(height=h2, scale=s, slices=30)
                rounded_rect([sx2, sy2], r2);
              sphere(r=m, $fs=fs_pin(), $fa=6);
            }
    } else {
        linear_extrude(height=h, scale=s, slices=30) rounded_rect(size, r);
    }
}

module chamfer_rr_extrude(size=[10,10], h=5, r=2, ch=1) {
  sx = size[0]; sy = size[1];
  // Clamp chamfer amounts using helpers (bottom chamfer)
  chz2 = clamp_chz(h, ch);
  chxy = clamp_chxy(sx, sy, ch, ch);
  chx2 = chxy[0];
  chy2 = chxy[1];

  if (chz2 <= 0 || (chx2 <= 0 && chy2 <= 0)){
    rr_extrude(size=size, r=r, h=h);
  } else {
    // Bottom reduced cross-section
    sx_bot = max(sx - 2*chx2, eps());
    sy_bot = max(sy - 2*chy2, eps());
    r_bot = max(r - min(chx2, chy2), 0);
    // Scale factors to expand from bottom reduced to top full
    sX = sx / sx_bot;
    sY = sy / sy_bot;

    union(){
      // Straight upper segment: full-size profile above chamfer height
      translate([0,0,chz2])
        linear_extrude(height=h - chz2)
          rounded_rect([sx, sy], r);

      // Bottom chamfer wedge: centered scale from reduced base up to full top
      translate([sx/2, sy/2, 0])
        linear_extrude(height=chz2, scale=[sX, sY])
          translate([-sx_bot/2, -sy_bot/2])
            rounded_rect([sx_bot, sy_bot], r_bot);
    }
  }
}

// rr_shell(size=[x,y], r, h, wall) — rectangular rounded shell of thickness wall
module rr_shell(size=[20,20], r=2, h=10, wall=2){
    difference(){
        rr_extrude(size=size, r=r, h=h);
        translate([0,0,-eps()])
            rr_extrude(size=[max(size[0]-2*wall, eps()), max(size[1]-2*wall, eps())], r=max(r-wall,0), h=h+2*eps());
    }
}

// rr_tray(outer=[x,y], outer_r, outer_h, inner=[x,y], inner_r, bottom_th)
// Makes a rectangular rounded tray: outer body minus inner cavity that starts at bottom_th
module rr_tray(outer=[40,30], outer_r=3, outer_h=20, inner=[36,26], inner_r=2, bottom_th=2){
    difference(){
        rr_extrude(size=outer, r=outer_r, h=outer_h);
        translate([0,0,bottom_th - eps()])
            rr_extrude(size=inner, r=inner_r, h=max(outer_h - bottom_th + 2*eps(), eps()));
    }
}

// chamfer_ring(d_outer, d_inner, h, chamfer)
// Cylindrical ring of height h with a top outward chamfer of size chamfer.
module chamfer_ring(d_outer, d_inner, h, chamfer){
    h_ch = min(chamfer, h/2);
    // straight wall part
    difference(){
        cylinder(h=h - h_ch, d=d_outer);
        translate([0,0,0]) cylinder(h=h - h_ch + eps(), d=d_inner);
    }
    // top chamfered frustum
    difference(){
        translate([0,0,h - h_ch]) cylinder(h=h_ch, d1=d_outer, d2=max(d_outer - 2*h_ch, eps()));
        translate([0,0,h - h_ch]) cylinder(h=h_ch + eps(), d1=d_inner, d2=max(d_inner + 2*h_ch, eps()));
    }
}

// -------------------------------------------------
// 3D: Misc utilities
// -------------------------------------------------
// cyl_bar_y(xc, zc, r, h) — cylinder bar along Y axis centered at (xc, zc)
// Useful for long slots/fillets made by subtracting cylinders.
module cyl_bar_y(xc, zc, r, h){
    translate([xc, 0, zc]) rotate([-90,0,0])
        cylinder(h=h, r=r, $fs=fs_pin(), $fa=6);
}

// chamfer_wedge_y(ch, len_y) — triangular wedge extruded along Y for bottom chamfers
// Creates a right triangle [0,0]-[ch,0]-[0,ch] and extrudes it along Y.
module chamfer_wedge_y(ch, len_y){
    linear_extrude(height=len_y)
        polygon(points=[[0,0],[ch,0],[0,ch]]);
}

// fragment clipper by bounding box at origin
// clip_for_fragments_bbox(L, W, H, enabled=false, frag_size=20, frag_index=0, frag_h_extra=20)
// Intersects children() with a corner cube of size frag_size at one of 4 corners of the LxW footprint, extended by H along Z.
// Use when your part's bounding box is aligned to origin [0,0]..[L,W].
module clip_for_fragments_bbox(L, W, H, enabled=false, frag_size=20, frag_index=0, frag_h_extra=20){
    if (enabled){
        ofs = corner_offset(frag_index, L, W, frag_size);
        intersection(){
            children();
            translate([ofs[0], ofs[1], -frag_h_extra])
                cube([frag_size, frag_size, H + 2*frag_h_extra], center=false);
        }
    } else {
        children();
    }
}

// -------------------------------------------------
// Math helpers
// -------------------------------------------------
// clamp(val, lo, hi) — limit value to [lo, hi]
function clamp(val, lo, hi) = max(lo, min(val, hi));

// clamp_chz(t, chz) — limit chamfer height to half of thickness t
function clamp_chz(t, chz) = clamp(chz, 0, t/2);

// clamp_chxy(l, w, chx, chy) — limit horizontal chamfers to half-size per axis
function clamp_chxy(l, w, chx, chy) = [
    clamp(chx, 0, l/2 - eps()),
    clamp(chy, 0, w/2 - eps())
];

// corner_offset(ix, L, W, s) — lower-left XY of a square clip of size s for corner index
// 0=NL, 1=VL, 2=NP, 3=VP relative to the part (X to right, Y up)
function corner_offset(ix, L, W, s) =
    (ix == 0) ? [0, 0] :
    (ix == 1) ? [0, max(W - s, 0)] :
    (ix == 2) ? [max(L - s, 0), 0] :
                [max(L - s, 0), max(W - s, 0)];

// Fallback helpers: safe defaults if model didn't define variables
function eps() = 0.1;
function fs_pin(x=undef) = is_undef(x) ? 0.25 : x;
