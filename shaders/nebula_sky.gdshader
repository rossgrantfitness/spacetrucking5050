// The faint clouds of space gas painted across the whole sky, behind the
// stars, tinted with the solar system's color. Seen from the inside of a huge
// ball that follows the camera (see SkyBackdrop.gd). It's an ordinary solid
// surface on purpose: as a see-through one, it would be drawn last and cover
// engine trails and flares.
shader_type spatial;
render_mode unshaded, cull_front, fog_disabled;

uniform sampler2D clouds : source_color, filter_linear_mipmap, repeat_enable, hint_default_black;
uniform vec4 tint : source_color = vec4(0.8, 0.72, 1.0, 1.0);
// How bright the clouds get. Keep it low: space should stay mostly black.
uniform float strength = 0.35;

void fragment() {
	ALBEDO = texture(clouds, UV).rgb * tint.rgb * strength;
}
