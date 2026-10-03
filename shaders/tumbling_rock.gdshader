// Asteroids that slowly tumble, each around its own axis at its own speed.
// The spinning happens on the graphics card, so hundreds of rocks cost almost
// nothing to animate. Each rock's spin axis and speed come from its MultiMesh
// "custom data" (set by AsteroidField.gd), and its color from its instance color.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform float spin_scale = 1.0;

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
	// Custom data stores the axis squeezed into 0..1, so unsqueeze it to -1..1.
	vec3 axis = normalize(INSTANCE_CUSTOM.rgb * 2.0 - 1.0);
	float angle = TIME * INSTANCE_CUSTOM.a * spin_scale + float(INSTANCE_ID) * 1.7;
	mat3 spin = axis_rotation(axis, angle);
	VERTEX = spin * VERTEX;
	NORMAL = spin * NORMAL;
}

void fragment() {
	ALBEDO = COLOR.rgb; // Facet shade times the rock's own color.
	ROUGHNESS = 1.0;
}
