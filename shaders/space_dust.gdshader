// Space dust: thousands of tiny glowing specks around the camera, the #1 cue
// for how fast you're going.
//
// Every speck has a fixed "home" spot inside a box. The box repeats forever
// in every direction, and we always draw the copy of each speck that's
// closest to the camera. So as you fly, specks stream past and new ones fade
// in ahead: an endless dust field for the cost of one small mesh.
// While you move, each speck stretches into a streak pointing back the way
// it came (like motion blur), so the faster you go, the longer the streaks.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, skip_vertex_transform, fog_disabled;

// Set by SpaceDust.gd every frame.
uniform float box_size = 80.0;
uniform vec3 streak = vec3(0.0); // The ship's velocity times the streak time, in world space.
uniform float speck_size = 0.045;
uniform vec3 tint : source_color = vec3(1.0);
uniform float brightness = 0.55;

varying float fade;

void vertex() {
	vec3 camera_position = INV_VIEW_MATRIX[3].xyz;
	float half_box = box_size * 0.5;
	// VERTEX holds this speck's home spot. Find its copy nearest the camera.
	vec3 offset = mod(VERTEX - camera_position + half_box, box_size) - half_box;
	vec3 center = (VIEW_MATRIX * vec4(camera_position + offset, 1.0)).xyz;

	// Build a thin quad along the streak, turned to face the camera.
	vec3 view_streak = (VIEW_MATRIX * vec4(streak, 0.0)).xyz;
	float streak_length = length(view_streak);
	vec3 along = streak_length > 0.0001 ? view_streak / streak_length : vec3(0.0, 1.0, 0.0);
	vec3 across = cross(along, center);
	across = length(across) > 0.0001 ? normalize(across) : vec3(1.0, 0.0, 0.0);
	// UV.x: 0 = the speck itself, 1 = the far end of its streak.
	// UV.y: -1 or +1 = which edge of the quad.
	VERTEX = center
		+ along * (UV.x * (streak_length + 2.0 * speck_size) - speck_size)
		+ across * speck_size * UV.y;

	// Fade specks out near the edge of the box (so wrapping never pops) and
	// close to the lens (so nothing smears across the whole screen).
	float distance_to_camera = length(center);
	fade = smoothstep(half_box, half_box * 0.6, distance_to_camera) * smoothstep(2.0, 8.0, distance_to_camera);
}

void fragment() {
	ALBEDO = tint * brightness;
	// Bright at the speck, fading along its streak.
	ALPHA = fade * (1.0 - UV.x * 0.85);
}
