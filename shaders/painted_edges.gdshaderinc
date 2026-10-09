// "Painted edges": the hand-painted look of late-PS1 games like Mega Man
// Legends, where every crate, wall and console has its lighting painted
// right into its texture: a bright bevel along the top and left edges, a
// dark one along the bottom and right, a thin dark seam at the very edge,
// and shadow gathering toward the bottom of each side.
//
// We paint that on every BOX automatically. It only works on boxes (BoxMesh
// with no subdivisions), so the model builders switch it on just for boxes
// (see _box() in tools/build_placeholder_models.gd).
//
// The trick: every corner of a box sits at +-half its size, so abs(VERTEX)
// at any corner IS the box's half size. A "flat" varying hands that to the
// pixel step untouched, and each pixel can work out how far it is from the
// box's edges.
//
// Included by psx_surface.gdshader and set_surface.gdshader.

// Switch the painted edges on (boxes only).
uniform bool painted_edges = false;
// How wide the painted bevel is, in meters. It's capped on small faces.
uniform float edge_width = 0.06;
// The bevel is painted in chunky pixels this many per meter (like a texture).
uniform float edge_pixels_per_meter = 24.0;
// How much brighter the lit bevel is, and how much darker the shaded one.
uniform float edge_light = 0.3;
uniform float edge_shadow = 0.38;
// How dark it gets toward the bottom of each side (painted-in shadow).
uniform float edge_floor_shadow = 0.3;
// How far up from the bottom that shadow reaches, in meters.
uniform float edge_floor_reach = 0.7;

varying vec3 edge_local;
varying flat vec3 edge_half;
varying vec3 edge_normal;

// Use in vertex(), before anything changes VERTEX.
#define EDGE_VERTEX { edge_local = VERTEX; edge_half = abs(VERTEX); edge_normal = NORMAL; panel_uv = UV; panel_size = UV2; }

// "Panel decals" (ships): instead of a texture tiled over and over, every
// panel is one solid color with a few painted details, once per panel: a
// thin dark seam round its edge, a darker band along its top and left, a
// bright trim line along its bottom and right, and a bolt in two opposite
// corners. Works on boxes (with painted_edges on) and on the model
// builders' lofted hull panels (which carry each panel's 0-1 position in UV
// and its size in meters in UV2).
uniform bool panel_decals = false;
// The decals are painted in chunky pixels this many per meter.
uniform float panel_pixels_per_meter = 14.0;
uniform vec4 bolt_color : source_color = vec4(0.45, 0.45, 0.5, 1.0);
// How big the details are (1 = rig size; huge ships use more).
uniform float panel_scale = 1.0;

varying vec2 panel_uv;
varying flat vec2 panel_size;

// The painted light/shade to multiply this pixel's color by (1 = no change).
float painted_edge_shade() {
	if (!painted_edges || panel_decals) {
		return 1.0;  // (Panels paint their own edges: see paint_panel.)
	}
	vec3 facing = abs(edge_normal);
	// 1 on the axis this face points along, 0 on the other two.
	vec3 face = vec3(0.0);
	if (facing.x >= facing.y && facing.x >= facing.z) {
		face.x = 1.0;
	} else if (facing.y >= facing.z) {
		face.y = 1.0;
	} else {
		face.z = 1.0;
	}
	float px = max(edge_pixels_per_meter, 1.0);
	// How far this pixel is from the box's sides along each axis, snapped to
	// chunky painted pixels. The face's own axis doesn't count.
	vec3 distance_to_side = floor(max(edge_half - abs(edge_local), 0.0) * px) / px;
	distance_to_side = mix(distance_to_side, vec3(1e6), face);
	float nearest = min(distance_to_side.x, min(distance_to_side.y, distance_to_side.z));
	// Smaller faces get a narrower bevel, so a thin plank isn't all edge.
	vec3 face_half = mix(edge_half, vec3(1e6), face);
	float smallest_half = min(face_half.x, min(face_half.y, face_half.z));
	float width = min(edge_width, smallest_half * 0.35);
	float shade = 1.0;
	if (nearest < width) {
		// Which edge: the direction from the face's middle out to it.
		vec3 out_dir = vec3(0.0);
		if (nearest == distance_to_side.x) {
			out_dir.x = sign(edge_local.x);
		} else if (nearest == distance_to_side.y) {
			out_dir.y = sign(edge_local.y);
		} else {
			out_dir.z = sign(edge_local.z);
		}
		// Painted as if lit from above, a little from the left and front.
		float lit = dot(out_dir, normalize(vec3(-0.45, 1.0, 0.35)));
		if (nearest < 1.0 / px) {
			shade = 0.62; // The thin dark seam right at the edge.
		} else if (lit > 0.05) {
			shade = 1.0 + edge_light;
		} else if (lit < -0.05) {
			shade = 1.0 - edge_shadow;
		}
	}
	// Painted-in shadow toward the bottom of each side, in a few flat bands.
	if (face.y < 0.5 && edge_floor_shadow > 0.0) {
		float height = edge_local.y + edge_half.y;
		float reach = min(edge_floor_reach, edge_half.y * 1.2);
		float low = 1.0 - clamp(height / max(reach, 0.001), 0.0, 1.0);
		low = floor(low * 4.0 + 0.5) / 4.0;
		shade *= 1.0 - edge_floor_shadow * low;
	}
	return shade;
}


// One bolt: lit on its top half, with a "/" slot across it, and a dark ring
// of shadow round it. `d` is this pixel's offset from the bolt's middle.
vec3 panel_bolt(vec3 color, vec2 d, float r, float px) {
	float dist = length(d);
	if (dist < r) {
		vec3 bolt = bolt_color.rgb * (d.y < 0.0 ? 1.2 : 0.8);
		if (abs(d.x + d.y) < r * 0.35) {
			bolt *= 0.35;  // The screwdriver slot.
		}
		return bolt;
	}
	if (dist < r + 1.0 / px) {
		return color * 0.55;
	}
	return color;
}

// Paints this pixel's panel details over `color` (see "Panel decals").
vec3 paint_panel(vec3 color) {
	if (!panel_decals) {
		return color;
	}
	vec2 p;  // Where on the panel, in meters from its top-left corner.
	vec2 size;  // The panel's size in meters.
	if (painted_edges) {
		vec3 facing = abs(edge_normal);
		vec2 local;
		vec2 half_size;
		if (facing.x >= facing.y && facing.x >= facing.z) {
			local = vec2(edge_local.z * sign(edge_normal.x), -edge_local.y);
			half_size = edge_half.zy;
		} else if (facing.y >= facing.z) {
			local = vec2(edge_local.x, edge_local.z * sign(edge_normal.y));
			half_size = edge_half.xz;
		} else {
			local = vec2(-edge_local.x * sign(edge_normal.z), -edge_local.y);
			half_size = edge_half.xy;
		}
		p = local + half_size;
		size = half_size * 2.0;
	} else if (panel_size.x > 0.01 && panel_size.y > 0.01) {
		p = panel_uv * panel_size;
		size = panel_size;
	} else {
		return color;  // Not a panel (an end cap): just the solid color.
	}
	float px = max(panel_pixels_per_meter, 1.0);
	p = (floor(p * px) + 0.5) / px;  // Chunky painted pixels.
	vec2 far_side = size - p;
	float smallest = min(size.x, size.y);
	float band = clamp(smallest * 0.05, 1.0 / px, 0.25 * panel_scale);
	float seam = 1.0 / px;
	float shade = 1.0;
	if (min(min(p.x, p.y), min(far_side.x, far_side.y)) < seam) {
		shade = 0.6;  // The seam between panels.
	} else if (far_side.x < band + seam || far_side.y < band + seam) {
		shade = 1.32;  // The bright trim line, bottom and right.
	} else if (p.x < band + seam || p.y < band + seam) {
		shade = 0.8;  // The darker band, top and left.
	}
	vec3 result = color * shade;
	if (smallest > panel_scale) {
		float r = clamp(smallest * 0.045, 0.1 * panel_scale, 0.32 * panel_scale);
		float inset = band + r * 2.0;
		result = panel_bolt(result, p - vec2(inset), r, px);
		result = panel_bolt(result, p - (size - vec2(inset)), r, px);
	}
	return result;
}
