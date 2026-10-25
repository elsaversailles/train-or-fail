shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 bird_color : source_color = vec4(0.11, 0.14, 0.19, 1.0);

void vertex() {
	// UV.x marks the wing tips. Each instance has a different flap phase.
	VERTEX.y += UV.x * sin(TIME * 7.0 + INSTANCE_CUSTOM.x * 6.283185) * 0.34;
}

void fragment() {
	ALBEDO = bird_color.rgb;
}
