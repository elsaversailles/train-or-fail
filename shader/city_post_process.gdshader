shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float rain_mix : hint_range(0.0, 1.0) = 0.0;
uniform float vignette_strength : hint_range(0.0, 0.3) = 0.07;
uniform float grain_strength : hint_range(0.0, 0.05) = 0.006;

void fragment() {
	vec3 color = texture(screen_texture, SCREEN_UV).rgb;
	float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float shadows = 1.0 - smoothstep(0.12, 0.55, luminance);
	float highlights = smoothstep(0.42, 0.9, luminance);
	color += vec3(-0.015, 0.0, 0.025) * shadows * rain_mix;
	color += vec3(0.018, 0.007, -0.008) * highlights * (1.0 - rain_mix * 0.45);

	vec2 centered = SCREEN_UV * 2.0 - 1.0;
	float edge = smoothstep(0.45, 1.6, dot(centered, centered));
	color *= 1.0 - edge * vignette_strength;

	vec2 pixel = floor(SCREEN_UV / SCREEN_PIXEL_SIZE);
	float grain = fract(sin(dot(pixel, vec2(12.9898, 78.233)) + floor(TIME * 24.0)) * 43758.5453);
	color += (grain - 0.5) * grain_strength;
	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), 1.0);
}
