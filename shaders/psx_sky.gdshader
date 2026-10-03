// Like psx_surface, but for huge faraway things in the sky (planets): they
// ignore the distance haze, which would otherwise wash them out completely.
shader_type spatial;
render_mode vertex_lighting, diffuse_lambert, specular_disabled, fog_disabled;

#include "res://shaders/psx.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_texture : source_color, filter_nearest_mipmap, repeat_enable, hint_default_white;
// How many times the texture repeats across the model's texture coordinates.
uniform vec2 uv_scale = vec2(1.0);
// Slowly turns the texture sideways (a planet's clouds drifting), per second.
uniform float drift_speed = 0.0;
// Glow on the planet's night side, so it never goes fully black.
uniform float night_glow = 0.12;

void vertex() {
	PSX_VERTEX(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0), UV * uv_scale + vec2(TIME * drift_speed, 0.0));
}

void fragment() {
	vec3 color = albedo.rgb * texture(albedo_texture, PSX_UV).rgb;
	ALBEDO = color;
	ROUGHNESS = 1.0;
	EMISSION = color * night_glow;
}
