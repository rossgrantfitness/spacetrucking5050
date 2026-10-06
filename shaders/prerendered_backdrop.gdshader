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
// For hand-made background art (a fixed picture, see HubRoom.ART_FOLDER):
// its width / height. The camera keeps the height of its view, so the art's
// full height fills the screen and its sides are trimmed (or, on a very wide
// window, the edge pixels stretch). 0 = the picture was painted to fit the
// screen exactly.
uniform float background_aspect = 0.0;
// A soft color cast over the whole room (each rig's rooms have their own;
// see interior_tint in res://data/ships/). White = none.
uniform vec3 tint : source_color = vec3(1.0);

void fragment() {
	vec2 uv = SCREEN_UV;
	if (background_aspect > 0.0) {
		float screen_aspect = VIEWPORT_SIZE.x / VIEWPORT_SIZE.y;
		uv.x = clamp(0.5 + (uv.x - 0.5) * screen_aspect / background_aspect, 0.0, 1.0);
	}
	ALBEDO = texture(background, uv).rgb * tint;
}
