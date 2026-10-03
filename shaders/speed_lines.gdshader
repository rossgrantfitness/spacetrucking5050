// Anime-style speed lines: thin dashes racing out from the middle of the
// screen. Only shown while boosting; SpeedLines.gd fades "intensity" in and out.
shader_type canvas_item;
render_mode blend_add;

uniform float intensity : hint_range(0.0, 2.0) = 0.0;
uniform float aspect = 1.7778; // Screen width divided by height.
uniform float line_count = 64.0;
uniform vec4 line_color : source_color = vec4(1.0, 0.95, 0.85, 0.9);

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

void fragment() {
	vec2 p = UV - 0.5;
	p.x *= aspect;
	float radius = length(p);
	// Split the screen into thin wedges around the middle.
	float slot = (atan(p.y, p.x) / TAU + 0.5) * line_count;
	float random = hash(floor(slot));
	float within = fract(slot);
	// Only some wedges get a line, and each line is a sliver of its wedge.
	float has_line = step(0.55, random);
	float thin = smoothstep(0.42, 0.5, within) * smoothstep(0.58, 0.5, within);
	// Each line is a dash racing outward at its own speed.
	float head = 0.25 + fract(TIME * (0.7 + random * 0.8) + random * 13.0) * 0.75;
	float dash = smoothstep(head - 0.22, head, radius) * smoothstep(head + 0.01, head, radius);
	// Keep the middle clear so you can still see where you're going.
	float edge = smoothstep(0.22, 0.45, radius);
	COLOR = vec4(line_color.rgb, has_line * thin * dash * edge * intensity * line_color.a);
}
