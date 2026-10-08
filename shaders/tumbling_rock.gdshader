// Asteroids that slowly tumble, each around its own axis at its own speed.
// The spinning happens on the graphics card, so hundreds of rocks cost almost
// nothing to animate. Each rock's spin axis and speed come from its MultiMesh
// "custom data" (set by AsteroidField.gd), and its color from its instance color.
// Like every model, rocks get the PS1 treatment (see psx.gdshaderinc).
shader_type spatial;
render_mode vertex_lighting, diffuse_lambert, specular_disabled;

#include "res://shaders/psx.gdshaderinc"

uniform float spin_scale = 1.0;
// A small grayscale rock texture, tinted by each rock's color.
uniform sampler2D rock_texture : source_color, filter_nearest_mipmap, repeat_enable, hint_default_white;
// How many times the texture repeats across a rock (rocks are built about
// 1 meter across and scaled up, so the texture grows with the rock).
uniform float uv_scale = 1.5;
// On: use the model's own texture layout (the developer's junk pieces)
// instead of wrapping the rock texture around it like a box.
uniform bool mesh_uv = false;

// A rotation of `angle` radians around `axis` (Rodrigues' rotation formula).
mat3 axis_rotation(vec3 axis, float angle) {
	float s = sin(angle);
	float c = cos(angle);
	float t = 1.0 - c;
	return mat3(
		vec3(t * axis.x * axis.x + c, t * axis.x * axis.y + s * axis.z, t * axis.x * axis.z - s * axis.y),
		vec3(t * axis.x * axis.y - s * axis.z, t * axis.y * axis.y + c, t * axis.y * axis.z + s * axis.x),
		vec3(t * axis.x * axis.z + s * axis.y, t * axis.y * axis.z - s * axis.x, t * axis.z * axis.z + c));
}

void vertex() {
	// The texture is pinned to the rock before it spins, so it turns with it.
	vec2 uv = mesh_uv ? UV : psx_box_uv(VERTEX, NORMAL) * uv_scale;
	// Custom data stores the axis squeezed into 0..1, so unsqueeze it to -1..1.
	vec3 axis = normalize(INSTANCE_CUSTOM.rgb * 2.0 - 1.0);
	float angle = TIME * INSTANCE_CUSTOM.a * spin_scale + float(INSTANCE_ID) * 1.7;
	mat3 spin = axis_rotation(axis, angle);
	VERTEX = spin * VERTEX;
	NORMAL = spin * NORMAL;
	PSX_VERTEX(PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0), uv);
}

void fragment() {
	// Facet shade times the rock's own color, times the texture.
	ALBEDO = COLOR.rgb * texture(rock_texture, PSX_UV).rgb;
	ROUGHNESS = 1.0;
}
