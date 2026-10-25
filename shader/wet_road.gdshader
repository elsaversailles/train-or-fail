shader_type spatial;

uniform sampler2D road_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 albedo_tint : source_color = vec4(1.0);
uniform float wetness : hint_range(0.0, 1.0) = 0.7;

varying vec3 world_position;

float hash21(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 blend = fract(point);
	blend = blend * blend * (3.0 - 2.0 * blend);
	return mix(
		mix(hash21(cell), hash21(cell + vec2(1.0, 0.0)), blend.x),
		mix(hash21(cell + vec2(0.0, 1.0)), hash21(cell + vec2(1.0, 1.0)), blend.x),
		blend.y
	);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base = texture(road_texture, UV).rgb * albedo_tint.rgb;
	float broad = value_noise(world_position.xz * 0.13);
	float detail = value_noise(world_position.xz * 0.65);
	float patches = smoothstep(0.4, 0.73, broad * 0.7 + detail * 0.3);
	float marking = smoothstep(0.5, 0.85, max(base.r, max(base.g, base.b)));
	float damp = wetness * mix(0.32, 1.0, patches) * (1.0 - marking * 0.55);
	ALBEDO = base * (1.0 - damp * 0.27);
	ROUGHNESS = mix(0.86, 0.17, damp);
	SPECULAR = mix(0.5, 0.75, damp);
	METALLIC = 0.0;
}
