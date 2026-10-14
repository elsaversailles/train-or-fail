shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 foam_color : source_color = vec4(1.0, 1.0, 1.0, 0.95);
uniform float speed : hint_range(0.1, 10.0) = 2.2;
uniform float frequency : hint_range(1.0, 40.0) = 14.0;
uniform float v_spread : hint_range(0.1, 2.0) = 0.6;
uniform float band_thickness : hint_range(0.01, 0.5) = 0.18;

void fragment() {
    // 0.0 at mesh center line, 1.0 at outer left/right edges
    float centered_x = abs(UV.x - 0.5) * 2.0;

    // Chevron / V-angle wave coordinate pointing toward the boat
    float v_wave = UV.y - (centered_x * v_spread);
    float wave_pattern = sin(v_wave * frequency - TIME * speed);

    // Stepped low-poly foam bands
    float foam_band = step(1.0 - band_thickness, wave_pattern);

    // V-shaped boundary: narrow at boat stern (UV.y = 0), wider trailing back (UV.y = 1)
    float wake_expansion = mix(0.25, 1.0, UV.y);
    float wake_boundary = step(centered_x, wake_expansion);

    // Dissolve smoothly towards the far end and outer edges
    float dissolve = (1.0 - UV.y) * (1.0 - centered_x);

    ALBEDO = foam_color.rgb;
    ALPHA = foam_band * wake_boundary * clamp(dissolve * 1.6, 0.0, 1.0) * foam_color.a;
}