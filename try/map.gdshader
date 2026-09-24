shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform bool debug_mode = false;
uniform bool use_vertex_color = true; // Keeps low-poly mesh colors (green leaves / brown trunk)

uniform float wind_direction = 90.0f;
uniform float wind_strenth = 3.0f;
uniform float sway_speed = 3.0f;
uniform float bendieness_multiplier = 0.0f;

uniform vec4 albedo_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D albedo_texture : source_color, hint_default_white;

vec2 rotation_to_direction() {
	float rotation_radians = wind_direction * (3.14159265f / 180.0f);
	vec2 direction = vec2(cos(rotation_radians), sin(rotation_radians));
	return normalize(direction);
}

void vertex() {
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dist = max(world_pos.y, 0.0);
	
	if (debug_mode) {
		float gradient = clamp(dist * 0.2, 0.0, 1.0);
		COLOR = vec4(gradient, gradient, gradient, 1.0);
	}
	
	// Sway calculation
	float sway = sin(TIME * sway_speed + VERTEX.y) * (wind_strenth / 100.0f);
	VERTEX.x += (sway * dist);
	
	// Wind direction bending
	vec2 wind_bending = vec2((wind_strenth / 100.0f) * dist) * rotation_to_direction();
	VERTEX.xz += wind_bending * bendieness_multiplier;
}

void fragment() {
	if (debug_mode) {
		ALBEDO = COLOR.rgb;
	} else {
		vec4 tex = texture(albedo_texture, UV);
		vec3 final_color = tex.rgb * albedo_color.rgb;
		
		if (use_vertex_color) {
			final_color *= COLOR.rgb;
		}
		
		ALBEDO = final_color;
	}
}