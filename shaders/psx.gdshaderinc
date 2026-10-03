// The PlayStation-1 tricks shared by every 3D surface in the game.
// Included by psx_surface.gdshader and tumbling_rock.gdshader.
//
// 1. WOBBLY VERTS: the PS1 had no sub-pixel precision, so every corner of
//    every triangle got snapped to whole screen pixels. As things move, their
//    corners hop from pixel to pixel and models gently wobble and shimmer.
//    We fake it by snapping each corner to a coarse screen grid.
// 2. AFFINE TEXTURES: the PS1 stretched textures across triangles without
//    correcting for perspective, so textures bend and swim on big polygons
//    close to the camera. We fake it by mixing in "uncorrected" texture
//    coordinates.
//
// Both strengths are "global shader uniforms" (Project Settings → Shader
// Globals). PSXView.gd sets them from res://data/tuning.tres at runtime.

// The grid the corners snap to, in "pixels" across and down the screen.
// Smaller = chunkier, wobblier models.
global uniform vec2 psx_snap_resolution;
// 0 = textures stay put (modern), 1 = full PS1 texture swim.
global uniform float psx_affine_strength;

// Texture coordinates, handed from the vertex step to the pixel step.
varying vec2 psx_uv;
// The same coordinates multiplied by depth (xy) plus that depth (z): dividing
// them back in the pixel step undoes the perspective correction. That's the
// affine trick.
varying vec3 psx_affine_uv;

// Where a corner lands on screen, snapped to the PSX grid.
vec4 psx_snap(vec4 clip) {
	if (clip.w <= 0.0) {
		return clip; // Behind the camera: leave it alone.
	}
	vec2 grid = psx_snap_resolution * 0.5; // Screen space runs from -1 to 1.
	vec2 on_screen = clip.xy / clip.w;
	on_screen = round(on_screen * grid) / grid;
	return vec4(on_screen * clip.w, clip.zw);
}

// Use at the end of vertex(): snaps the corner to the grid and prepares the
// wobbly texture coordinates. (A macro rather than a function, because only
// vertex() itself may write to varyings.)
//     PSX_VERTEX(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0), uv);
#define PSX_VERTEX(clip, uv) { vec4 psx_clip = psx_snap(clip); psx_uv = (uv); psx_affine_uv = vec3((uv) * psx_clip.w, psx_clip.w); POSITION = psx_clip; }

// Use in fragment(): this pixel's (wobbly) texture coordinates.
#define PSX_UV mix(psx_uv, psx_affine_uv.xy / psx_affine_uv.z, psx_affine_strength)

// Texture coordinates projected from the sides of the model (in meters), for
// shapes that don't have good ones of their own. Each face picks the side it
// faces most, which is perfect for boxes and fine for everything else.
vec2 psx_box_uv(vec3 position, vec3 normal) {
	vec3 facing = abs(normal);
	if (facing.x > facing.y && facing.x > facing.z) {
		return vec2(position.z * sign(normal.x), -position.y);
	} else if (facing.y > facing.z) {
		return vec2(position.x, position.z * sign(normal.y));
	}
	return vec2(-position.x * sign(normal.z), -position.y);
}
