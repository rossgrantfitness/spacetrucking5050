// A glowing four-pointed star that always faces the camera: the lens flare on
// an engine, the way late-90s PlayStation racers did it. Used by EngineFlare.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;

uniform sampler2D flare_texture : source_color, filter_linear_mipmap, hint_default_white;
uniform vec4 color : source_color = vec4(1.0);
uniform float brightness = 1.0;

void vertex() {
	// Turn to face the camera, but keep the node's size (its scale).
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
		vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
		vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
		vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
		vec4(0.0, 0.0, 0.0, 1.0));
}

void fragment() {
	float glow = texture(flare_texture, UV).a * brightness;
	// White-hot in the middle, the engine's color toward the edges.
	ALBEDO = mix(color.rgb, vec3(1.0), clamp(glow - 0.5, 0.0, 1.0)) * glow;
}
