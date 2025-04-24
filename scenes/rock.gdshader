shader_type canvas_item;

uniform int texture_type = 0; // 0: Lava1 (Red), 1: Lava2 (Fire), 2: Lava3 (None)
uniform vec4 outline_color_lava1 = vec4(1.0, 0.0, 0.0, 1.0);      // Red
uniform vec4 outline_color_lava2 = vec4(1.0, 0.5, 0.0, 1.0);      // Fire/Orange
uniform float outline_thickness = 1.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	// If visible pixel, draw normally
	if (tex.a > 0.1) {
		COLOR = tex;
	}
	else {
		// Skip outline for Lava3
		if (texture_type == 2) {
			COLOR = vec4(0.0);
		} else {
			float alpha_sum = 0.0;
			alpha_sum += texture(TEXTURE, UV + vec2(outline_thickness, 0.0) / 100.0).a;
			alpha_sum += texture(TEXTURE, UV + vec2(-outline_thickness, 0.0) / 100.0).a;
			alpha_sum += texture(TEXTURE, UV + vec2(0.0, outline_thickness) / 100.0).a;
			alpha_sum += texture(TEXTURE, UV + vec2(0.0, -outline_thickness) / 100.0).a;

			if (alpha_sum > 0.1) {
				vec4 outline_color = texture_type == 1 ? outline_color_lava2 : outline_color_lava1;
				COLOR = outline_color;
			} else {
				COLOR = vec4(0.0);
			}
		}
	}
}
