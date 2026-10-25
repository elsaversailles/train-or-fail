shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, depth_draw_never;

uniform vec4 rain_color : source_color = vec4(0.72, 0.83, 0.92, 0.42);

void vertex() {
	// Keep each tiny particle facing the camera without a per-drop CPU update.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		vec4(1.0, 0.0, 0.0, 0.0),
		vec4(0.0, 1.0, 0.0, 0.0),
		vec4(0.0, 0.0, 1.0, 0.0),
		MODEL_MATRIX[3]
	);
}

void fragment() {
	float edge = smoothstep(0.0, 0.26, UV.x) * smoothstep(0.0, 0.26, 1.0 - UV.x);
	float taper = smoothstep(0.0, 0.15, UV.y) * smoothstep(0.0, 0.24, 1.0 - UV.y);
	ALBEDO = rain_color.rgb;
	ALPHA = rain_color.a * edge * taper * COLOR.a;
}
