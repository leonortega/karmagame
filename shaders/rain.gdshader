shader_type canvas_item;

// Single full-screen rain sheet: animated drops covering the whole viewport.
uniform float speed : hint_range(0.1, 5.0) = 1.6;
uniform float density : hint_range(10.0, 200.0) = 60.0;
uniform vec4 rain_color : source_color = vec4(0.82, 0.90, 1.0, 0.55);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME * speed;
	float rain = 0.0;
	// Three layers for depth, all tiling across the whole viewport.
	for (int li = 0; li < 2; li++) {
		float fli = float(li);
		vec2 scale = vec2(density + fli * 30.0, 1.0);
		vec2 p = uv * scale + vec2(fli * 17.3, -t * (1.0 + fli * 0.4));
		vec2 cell = floor(p);
		vec2 fp = fract(p);
		float r = hash(cell);
		// Only some cells carry a drop.
		float has_drop = step(0.90, r);
		// Elongated vertical drop shape.
		float dx = abs(fp.x - (0.2 + 0.6 * r));
		float dy = fp.y;
		float ry = 1.0 - dy;
		float streak = smoothstep(0.05, 0.0, dx) * smoothstep(0.0, 0.04, ry) * (1.0 - smoothstep(0.2, 0.45, ry));
		float layer = has_drop * streak * (0.6 + 0.4 * r);
		rain += layer * (1.0 - fli * 0.3);
	}
	COLOR = vec4(rain_color.rgb, clamp(rain * rain_color.a, 0.0, 1.0));
}