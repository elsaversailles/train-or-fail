shader_type sky;
render_mode use_debanding;

uniform vec4 zenith_color : source_color = vec4(0.25, 0.43, 0.72, 1.0);
uniform vec4 horizon_color : source_color = vec4(0.74, 0.79, 0.82, 1.0);
uniform vec4 sunset_color : source_color = vec4(0.94, 0.48, 0.25, 1.0);
uniform vec4 ground_color : source_color = vec4(0.21, 0.22, 0.24, 1.0);
uniform vec4 cloud_light_color : source_color = vec4(0.95, 0.94, 0.91, 1.0);
uniform vec4 cloud_shadow_color : source_color = vec4(0.51, 0.57, 0.64, 1.0);
uniform sampler2D cloud_texture : filter_linear_mipmap, repeat_enable;
uniform sampler2D cloud_texture2 : filter_linear_mipmap, repeat_enable;
uniform vec2 cloud_offset = vec2(0.0, 0.0);
uniform float cloud_threshold : hint_range(0.0, 1.0) = 0.56;
uniform float cloud_opacity : hint_range(0.0, 1.0) = 0.7;
uniform float haze_amount : hint_range(0.0, 1.0) = 0.2;
uniform float sun_cloud_transmission : hint_range(0.0, 1.0) = 0.65;

void sky() {
	float height = max(EYEDIR.y, 0.0);
	float sun_height = LIGHT0_ENABLED ? LIGHT0_DIRECTION.y : 0.45;
	float warm = 1.0 - smoothstep(0.06, 0.47, sun_height);
	float horizon_mix = pow(1.0 - height, 3.2);
	vec3 horizon = mix(horizon_color.rgb, sunset_color.rgb, warm * 0.82);
	vec3 color = mix(zenith_color.rgb, horizon, horizon_mix);

	// Approximate atmospheric scattering: warm near the horizon, blue above.
	float haze = pow(1.0 - height, 8.0) * haze_amount;
	color = mix(color, horizon, haze);

	if (LIGHT0_ENABLED && sun_height > -0.04) {
		float alignment = max(dot(normalize(LIGHT0_DIRECTION), EYEDIR), 0.0);
		float halo = pow(alignment, 32.0) * 0.12 + pow(alignment, 150.0) * 0.29 + pow(alignment, 650.0) * 0.23;
		vec3 glow_color = mix(vec3(1.0, 0.91, 0.71), vec3(1.0, 0.52, 0.28), warm);
		color += glow_color * halo * (1.0 - height * 0.28);
		float radius = max(LIGHT0_SIZE * 0.5, 0.012);
		float disc = smoothstep(cos(radius * 1.3), cos(radius * 0.7), alignment);
		color = mix(color, glow_color * (1.8 + LIGHT0_ENERGY * 0.4), disc);
	}

	// Clouds are omitted from the radiance pass to keep indirect lighting cheap.
	if (!AT_CUBEMAP_PASS && height > 0.025) {
		vec2 projected = EYEDIR.xz / max(height, 0.075);
		vec2 uv = projected * 0.047 + cloud_offset;
		float broad = texture(cloud_texture, uv).r;
		float detail = texture(cloud_texture2, uv * 1.9 - cloud_offset * 0.38).r;
		float coverage = broad * 0.72 + detail * 0.28;
		float cloud = smoothstep(cloud_threshold - 0.07, cloud_threshold + 0.08, coverage);
		cloud *= smoothstep(0.025, 0.17, height) * cloud_opacity;
		float sun_side = LIGHT0_ENABLED ? clamp(dot(EYEDIR, LIGHT0_DIRECTION) * 0.5 + 0.5, 0.0, 1.0) : 0.5;
		float sun_alignment = LIGHT0_ENABLED ? max(dot(EYEDIR, LIGHT0_DIRECTION), 0.0) : 0.0;
		cloud *= 1.0 - sun_cloud_transmission * smoothstep(0.91, 0.998, sun_alignment);
		vec3 cloud_color = mix(cloud_shadow_color.rgb, cloud_light_color.rgb, sun_side * (0.7 + detail * 0.3));
		color = mix(color, cloud_color, cloud);
	}

	float ground_haze = pow(1.0 + min(EYEDIR.y, 0.0), 5.0);
	vec3 below = mix(ground_color.rgb, horizon, ground_haze);
	COLOR = mix(below, color, step(0.0, EYEDIR.y));
}
