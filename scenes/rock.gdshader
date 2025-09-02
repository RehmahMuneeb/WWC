shader_type canvas_item;

uniform int texture_type = 0; // 0: Lava1, 1: Lava2, 2: Lava3
uniform vec4 lava1_color = vec4(1.3, 0.4, 0.0, 1.0); // Fiery Orange
uniform vec4 lava2_color = vec4(1.3, 0.4, 0.0, 1.0);
uniform vec4 lava3_color = vec4(1.3, 0.4, 0.0, 1.0); // Vibrant Purple
uniform float outline_thickness = 2.0;
uniform float glow_strength = 3.0;
uniform float glow_radius = 1.5;
uniform float pulse_speed = 2.0; // Speed of the pulse effect

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    COLOR = vec4(0.0); // Default transparent

    // Pulse effect (oscillates between 0.0 and 1.0)
    float pulse = 0.5 + 0.5 * sin(TIME * pulse_speed);

    // === MAIN PIXEL ===
    if (tex.a > 0.1) {
        vec4 base_color;
        vec4 tint_color;
        
        if (texture_type == 0) {
            base_color = vec4(1.5, 0.7, 0.4, 1.0); // Base orange for Lava1
            tint_color = lava1_color; // Lava1 - Fiery Orange
        }
        else if (texture_type == 1) {
            base_color = vec4(1.5, 0.7, 0.4, 1.0); // Base blue for Lava2
            tint_color = lava2_color; // Lava2 - Bright Blue
        }
        else if (texture_type == 2) {
            base_color = vec4(1.0, 1.0, 1.0, 1.0); // Use original texture for Lava3
//            tint_color = lava3_color; // Lava3 - Vibrant Purple
        }
        
        // For Lava1 and Lava2: pulse between base color and tint color
        // For Lava3: pulse between original texture and tint color
        if (texture_type == 2) {
            COLOR = mix(tex, tex * tint_color * glow_strength, pulse);
        } else {
            COLOR = mix(tex * base_color, tex * tint_color * glow_strength, pulse);
        }
    }
    else {
        // === OUTLINE ===
        // Sample surrounding pixels with a more efficient approach
        vec2 pixel_size = vec2(outline_thickness) / vec2(textureSize(TEXTURE, 0));
        float alpha_sum = 0.0;
        
        // Check in a circular pattern for better outline detection
        for (float x = -1.0; x <= 1.0; x += 0.5) {
            for (float y = -1.0; y <= 1.0; y += 0.5) {
                // Skip the center pixel (we already know it's transparent)
                if (x == 0.0 && y == 0.0) continue;
                
                vec2 offset = vec2(x, y) * pixel_size * glow_radius;
                alpha_sum += texture(TEXTURE, UV + offset).a;
            }
        }
        
        // Create outline if any surrounding pixel has alpha
        if (alpha_sum > 0.1) {
            COLOR = vec4(0.1, 0.1, 0.1, 1.0); // Dark outline
        }
    }
}