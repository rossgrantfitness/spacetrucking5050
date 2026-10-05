// The surface for the hub rooms' sets (the parts that get pre-rendered into
// painted backgrounds, see HubRoom.gd). Unlike the wobbly PS1 surface, it's
// lit per pixel with real shadows, since it's only drawn once, into the
// painting. It adds the hand-painted Mega Man Legends touches:
// - a small texture tiled every `meters` meters, projected from the sides
//   (crisp pixels, no smoothing);
// - painted bevels and shadow on every box (painted_edges.gdshaderinc).
// Built by _set_paint() in tools/build_hub.gd.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

#include "res://shaders/psx.gdshaderinc"
#include "res://shaders/painted_edges.gdshaderinc"

// The paint color. Multiplies the texture.
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_nearest_mipmap, repeat_enable, hint_default_white;
// How many meters one copy of the texture covers.
uniform float meters = 1.0;
// Glowing things (signs, screens, lamps): the color they give off, and how
// strongly. With a texture, only the texture's bright parts glow.
uniform vec4 emission : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_strength = 0.0;

varying vec2 set_uv;

void vertex() {
	EDGE_VERTEX
	set_uv = psx_box_uv(VERTEX, NORMAL) / max(meters, 0.001);
}

void fragment() {
	vec4 texel = texture(albedo_texture, set_uv);
	ALBEDO = albedo.rgb * texel.rgb * painted_edge_shade();
	ROUGHNESS = 0.9;
	EMISSION = emission.rgb * emission_strength * texel.rgb;
}
