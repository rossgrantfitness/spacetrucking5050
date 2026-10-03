// The standard PS1-style surface used by every model: wobbly snapped corners,
// swimming (affine) textures with crisp unfiltered pixels, and old-school
// per-corner (Gouraud) lighting instead of per-pixel lighting.
// See psx.gdshaderinc for how the tricks work.
shader_type spatial;
render_mode vertex_lighting, diffuse_lambert, specular_disabled;

#include "res://shaders/psx.gdshaderinc"

// The surface's color. Multiplies the texture.
uniform vec4 albedo : source_color = vec4(1.0);
// A small texture (64x64 is plenty). Pixels stay crisp: no smoothing.
uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable, hint_default_white;
// How many times the texture repeats (across, down): per meter when box_uv
// is on, otherwise across the model's own texture coordinates.
uniform vec2 uv_scale = vec2(1.0);
// Project the texture from the sides of the model in meters (for boxes and
// simple shapes), instead of using the model's own texture coordinates.
uniform bool box_uv = true;
// Multiply by the model's vertex colors (used for baked shading).
uniform bool use_vertex_color = false;
// Light the surface gives off by itself (lamps, windows, engine glow).
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_strength = 0.0;
// Glow only where the texture is bright (lit windows on a dark panel).
uniform bool emission_from_texture = false;

void vertex() {
	vec2 uv = box_uv ? psx_box_uv(VERTEX, NORMAL) : UV;
	PSX_VERTEX(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0), uv * uv_scale);
}

void fragment() {
	vec4 texel = texture(albedo_texture, PSX_UV);
	vec3 color = albedo.rgb * texel.rgb;
	if (use_vertex_color) {
		color *= COLOR.rgb;
	}
	ALBEDO = color;
	ROUGHNESS = 1.0;
	EMISSION = emission.rgb * emission_strength * (emission_from_texture ? texel.rgb : vec3(1.0));
}
