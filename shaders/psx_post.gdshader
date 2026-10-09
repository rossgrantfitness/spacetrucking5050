// The PS1's screen colors: 32 shades per color channel ("15-bit color"), with
// a fine checkered dither pattern hiding the steps between shades. Drawn over
// the whole 3D picture by PSXScreen.gd, under the HUD and menus.
shader_type canvas_item;

// What's on screen so far (the 3D world).
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
// Shades per color channel. 32 is what the PS1 had. Lower = more posterized.
uniform float color_levels = 32.0;
// How strong the dither pattern is. 0 = off, 1 = PS1-like.
uniform float dither_strength = 0.6;
// How many real screen pixels wide one dot of the pattern is.
uniform float dot_size = 1.0;

// A 4x4 "ordered dither" pattern (a Bayer matrix): each dot in a 4x4 block
// gets a different nudge, so in-between shades turn into a fine checker.
const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	ivec2 cell = ivec2(floor(FRAGCOORD.xy / dot_size));
	int index = (cell.x % 4) + (cell.y % 4) * 4;
	float nudge = (BAYER[index] + 0.5) / 16.0 - 0.5;
	float steps = color_levels - 1.0;
	color += nudge * dither_strength / steps;
	color = floor(color * steps + 0.5) / steps;
	COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}
