shader_type canvas_item;
render_mode unshaded;

void fragment() {
	// Sample a mip level about six texels wide so even lettering in the art is obscured.
	float level = log2(1.0 / (6.0 * TEXTURE_PIXEL_SIZE.x));
	vec3 blurred = textureLod(TEXTURE, UV, level).rgb;
	COLOR = vec4(blurred * vec3(0.62, 0.66, 0.72), 1.0);
}
