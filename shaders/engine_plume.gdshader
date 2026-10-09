// The flame out the back of an engine: a glowing cone that's white-hot at
// the nozzle, takes on the engine's color further out and fades to nothing
// at the tip. It flickers, and while boosting it grows bright "shock
// diamonds" (the bands you see in real rocket exhaust). The colors are
// squashed to a few steps, PS1 style, and it adds light on top of whatever
// is behind it. Used by EngineExhaust.gd.
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;

uniform vec4 color : source_color = vec4(1.0, 0.5, 0.2, 1.0);
// 0 = idling, 1 = full throttle.
uniform float power = 1.0;
// 0 = no boost, 1 = boosting flat out.
uniform float boost = 0.0;
// The inner cone is the hot core (whiter, sharper).
uniform bool core = false;
// How many color steps (fewer = crunchier).
uniform float steps = 8.0;

void fragment() {
	float t = UV.y;  // 0 at the nozzle, 1 at the tip.
	// Brighter through the middle of the cone, soft at its edges.
	float facing = abs(dot(NORMAL, VIEW));
	float body = pow(facing, core ? 1.5 : 3.0);
	float fade = pow(1.0 - t, core ? 2.6 : 1.8);
	float flicker = 0.85 + 0.15 * sin(TIME * 47.0 + t * 9.0) * sin(TIME * 31.0);
	// Shock diamonds: bright bands marching down the flame while boosting.
	float diamonds = pow(0.5 + 0.5 * cos(t * 26.0 - TIME * 40.0), 6.0) * boost * (1.0 - t);
	float glow = (body * fade * flicker * (core ? 1.0 : 0.7) + diamonds * 0.9) * (0.35 + 0.65 * power);
	// White-hot near the nozzle, the engine's color further out, and a
	// blue-white boost color while boosting.
	vec3 hot = mix(vec3(1.0, 0.95, 0.8), vec3(0.75, 0.9, 1.0), boost);
	vec3 tint = mix(color.rgb, vec3(0.45, 0.65, 1.0), boost * 0.6);
	vec3 rgb = mix(hot, tint, smoothstep(0.0, core ? 0.8 : 0.45, t)) * glow * (core ? 1.6 : 1.0);
	ALBEDO = floor(rgb * steps + 0.5) / steps;
}
