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
#define EDGE_VERTEX { edge_local = VERTEX; edge_half = abs(VERTEX); edge_normal = NORMAL; }

// The painted light/shade to multiply this pixel's color by (1 = no change).
float painted_edge_shade() {
	if (!painted_edges) {
		return 1.0;
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
