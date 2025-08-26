description = "Common reusable OpenSCAD functions and modules";

// Clamp numeric value between bounds
function clamp(val, lo, hi) = max(lo, min(val, hi));

// Clamp chamfer height to half of available thickness
function clamp_chz(t, chz) = clamp(chz, 0, t/2);

// Clamp chamfer offsets to available XY span
function clamp_chxy(l, w, chx, chy) = [
  clamp(chx, 0, l/2 - tiny),
  clamp(chy, 0, w/2 - tiny)
];

// 2D rounded rectangle
// size = [width, height]
module rounded_rect(size=[10,10], radius=1, center=false) {
  width = size[0];
  height = size[1];
  r = min(radius, min(width, height)/2);
  translate(center ? [-width/2, -height/2] : [0, 0])
    offset(r=r)
      square([max(width - 2*r, tiny), max(height - 2*r, tiny)], center=false);
}

// 3D rounded box
// size = [width, depth, height]
module rounded_box(size=[10,10,10], radius=1, center=false) {
  width = size[0];
  depth = size[1];
  height = size[2];
  linear_extrude(height=height, center=center)
    rounded_rect([width, depth], radius, center=center);
}

// Cylindrical ring with chamfered top edge
// d_outer - outer diameter
// d_inner - inner diameter
// h - total height
// chamfer - radius for top edge transition
module round_chamfer_ring(d_outer, d_inner, h, chamfer) {
  h_ch = min(chamfer, h/2);
  difference() {
    cylinder(h=h - h_ch, d=d_outer);
    translate([0, 0, 0]) cylinder(h=h - h_ch + tiny, d=d_inner);
  }
  difference() {
    translate([0, 0, h - h_ch]) cylinder(h=h_ch, d1=d_outer, d2=max(d_outer - 2*h_ch, tiny));
    translate([0, 0, h - h_ch]) cylinder(h=h_ch + tiny, d1=d_inner, d2=max(d_inner + 2*h_ch, tiny));
  }
}

// Boolean inverse of child 2D geometry using large bounding square
module inverse_2d() {
  difference() {
    square([1e5, 1e5], center=true);
    children();
  }
}

// Offset a 2D shape outward by distance d
module offset_outside(d=1) {
  if (version_num() < 20130424)
    render() projection(cut=true) minkowski() {
      cylinder(r=d);
      linear_extrude(center=true) children(0);
    };
  else
    minkowski() {
      circle(r=d);
      children(0);
    }
}

// Offset a 2D shape inward by distance d
module offset_inside(d=1) {
  render() inverse_2d() offset_outside(d=d) inverse_2d() children(0);
}

// Add fillets of radius r to concave corners of a 2D shape
module fillet_corners(r=1) {
  offset_inside(d=r) render() offset_outside(d=r) children(0);
}

// Round convex corners of a 2D shape with radius r
module round_corners(r=1) {
  offset_outside(d=r) offset_inside(d=r) children(0);
}

// Create shell of width d along the edge of a 2D shape
// Positive d grows outward, negative inward; center=true centers on edge
module edge_shell(d, center=false) {
  if (center && d > 0) {
    difference() {
      offset_outside(d=d/2) children(0);
      offset_inside(d=d/2) children(0);
    }
  } else if (!center && d > 0) {
    difference() {
      offset_outside(d=d) children(0);
      children(0);
    }
  } else if (!center && d < 0) {
    difference() {
      children(0);
      offset_inside(d=-d) children(0);
    }
  } else {
    children(0);
  }
}

