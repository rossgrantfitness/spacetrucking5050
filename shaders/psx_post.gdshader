// The PS1's screen: fewer colors than a modern screen (32 shades per color
// channel, "15-bit color"), with a fine checkered dither pattern hiding the
// steps between shades. Used by PSXView on the low-resolution 3D picture
// before it's blown up to the window with chunky, unsmoothed pixels.
shader_type canvas_item;

// Shades per color channel. 32 is what the PS1 had. Lower = more posterized.
uniform float color_levels = 32.0;
// How strong the dither pattern is. 0 = off, 1 = PS1-like.
uniform float dither_strength = 1.0;

// A 4x4 "ordered dither" pattern (a Bayer matrix): each pixel in a 4x4 block
// gets a different nudge, so in-between shades turn into a fine checker.
const float BAYER[16] = float[16](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0);

void fragment() {
	vec3 color = texture(TEXTURE, UV).rgb;
	// Which low-res pixel this is, so the pattern lines up with the big pixels.
	ivec2 pixel = ivec2(floor(UV / TEXTURE_PIXEL_SIZE));
	int index = (pixel.x % 4) + (pixel.y % 4) * 4;
	float nudge = (BAYER[index] + 0.5) / 16.0 - 0.5;
	float steps = color_levels - 1.0;
	color += nudge * dither_strength / steps;
	color = floor(color * steps + 0.5) / steps;
	COLOR = vec4(clamp(color, 0.0, 1.0), 1.0);
}
