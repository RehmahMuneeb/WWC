shader_type canvas_item;

uniform int texture_type = 0; // 0: Rock1, 1: Rock2, 2: Rock3
uniform vec4 lava1_color = vec4(0.1, 0.1, 0.1, 1.0); 
uniform vec4 lava2_color = vec4(0.4, 0.4, 0.4, 1.0); // Rock2 - Grey Glow
uniform vec4 lava3_color = vec4(1.0, 1.0, 1.0, 1.0); // Rock3 - White Hot Core

uniform float outline_thickness = 2.0;
uniform float glow_strength = 3.0;
uniform float glow_radius = 1.5;
uniform float aura_strength = 0.6; // Aura brightness

// --- Shimmer effect controls ---
uniform float shimmer_speed = 2.0;     // speed of shimmer
uniform float shimmer_strength = 0.2; // intensity of shimmer
uniform float shimmer_scale = 10.0;   // frequency scale

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    vec4 final_color = vec4(0.0);

    // === Shimmer calculation (used only for Rock 3) ===
    float shimmer = sin(UV.y * shimmer_scale + TIME * shimmer_speed) 
                  * cos(UV.x * shimmer_scale * 0.5 + TIME * shimmer_speed * 1.3);
    shimmer = shimmer * shimmer_strength;

    // Inside rock
    if (tex.a > 0.1) {
        vec4 base_color;
        vec4 tint_color;

        if (texture_type == 0) {
            base_color = vec4(1.2, 0.6, 0.3, 1.0);
            tint_color = lava1_color;
            final_color = mix(tex * base_color, tex * tint_color * glow_strength, 0.6);
        }
        else if (texture_type == 1) {
            base_color = vec4(0.4, 0.8, 1.0, 1.0);
            tint_color = lava2_color;
            final_color = mix(tex * base_color, tex * tint_color * glow_strength, 0.7);
        }
        else if (texture_type == 2) {
            base_color = vec4(0.4, 0.8, 1.0, 1.0);
            tint_color = lava3_color;
            final_color = mix(tex * base_color, tex * tint_color * glow_strength, 0.7);

            // Apply shimmer ONLY to Rock 3
            final_color.rgb += shimmer;
        }
    }

    // === Aura outside rock ===
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    float alpha_near = 0.0;

    for (float x = -1.0; x <= 1.0; x++) {
        for (float y = -1.0; y <= 1.0; y++) {
            vec2 offset = vec2(x, y) / tex_size * glow_radius;
            alpha_near = max(alpha_near, texture(TEXTURE, UV + offset).a);
        }
    }

    if (alpha_near > 0.1) {
        vec3 aura_color = vec3(0.0);

        if (texture_type == 0) aura_color = lava1_color.rgb;
        else if (texture_type == 1) aura_color = lava2_color.rgb;
        else if (texture_type == 2) aura_color = lava3_color.rgb;

        final_color.rgb += aura_color * aura_strength;
        final_color.a = max(final_color.a, 0.6); // keep aura visible
    }

    COLOR = final_color;
}
