shader_type canvas_item;

uniform int texture_type = 0; // 0: Lava1 (Red), 1: Lava2 (Fire/Orange), 2: Lava3 (None)
uniform vec4 fire_color = vec4(1.0, 0.5, 0.0, 1.0);  // Fire color (orange)
uniform float outline_thickness = 1.0;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // If visible pixel, draw normally
    if (tex.a > 0.1) {
        if (texture_type != 2) {  // For Lava1 and Lava2, apply fire color
            COLOR = tex * fire_color;
        } else {
            COLOR = tex;  // For Lava3, retain the original texture without color change
        }
    }
    else {
        // Outline effect (for Lava1 and Lava2)
        if (texture_type != 2) {  // Skip outline for Lava3
            float alpha_sum = 0.0;
            alpha_sum += texture(TEXTURE, UV + vec2(outline_thickness, 0.0) / 100.0).a;
            alpha_sum += texture(TEXTURE, UV + vec2(-outline_thickness, 0.0) / 100.0).a;
            alpha_sum += texture(TEXTURE, UV + vec2(0.0, outline_thickness) / 100.0).a;
            alpha_sum += texture(TEXTURE, UV + vec2(0.0, -outline_thickness) / 100.0).a;

            if (alpha_sum > 0.1) {
                // Apply the fire color for outline as well for Lava1 and Lava2
                COLOR = fire_color;
            } else {
                COLOR = vec4(0.0);  // No outline
            }
        } else {
            COLOR = vec4(0.0);  // No outline for Lava3
        }
    }
}
