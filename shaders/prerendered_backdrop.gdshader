// The trick behind "pre-rendered backgrounds" (Final Fantasy VIII, Resident
// Evil, Dino Crisis): each room is painted once, from its fixed camera, into
// a picture. Then the room's shapes are drawn using THIS shader, which just
// shows the matching pixel of that picture. You see the painted picture, but
// the shapes still hide the bunny when she walks behind a desk or a doorway.
// Used by HubRoom.gd.
shader_type spatial;
render_mode unshaded, fog_disabled;

// The picture painted from the current camera.
uniform sampler2D background : source_color, filter_linear;

void fragment() {
	ALBEDO = texture(background, SCREEN_UV).rgb;
}
