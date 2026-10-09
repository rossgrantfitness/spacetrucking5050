// The spaceway's reflector beacons: little glowing lights lining the lane,
// always facing you. A pulse of brightness runs along the line toward the
// destination, like a runway's sequenced flashers. Each beacon's distance
// along the road comes in through INSTANCE_CUSTOM.x (in km).
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform sampler2D flare : source_color, filter_linear, hint_default_white;
uniform vec4 color : source_color = vec4(1.0, 0.8, 0.4, 1.0);
// How fast the pulse runs along the road, in km per second.
uniform float pulse_speed = 0.8;
// How far apart the pulses are, in km.
uniform float pulse_gap = 1.0;

varying float glow;

void vertex() {
	// Face the camera (a billboard), keeping the beacon's size.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0), vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0), vec4(0.0, 0.0, 0.0, 1.0));
	float along = INSTANCE_CUSTOM.x;
	float wave = fract(along / pulse_gap - TIME * pulse_speed / pulse_gap);
	glow = 0.8 + 1.2 * smoothstep(0.12, 0.0, wave);
}

void fragment() {
	vec4 picture = texture(flare, UV);
	ALBEDO = color.rgb * picture.rgb * glow;
	ALPHA = picture.a * color.a;
}
