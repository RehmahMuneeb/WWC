shader_type canvas_item;

uniform int texture_type = 0; // 0: Rock1, 1: Rock2, 2: Rock3
uniform vec4 lava1_color = vec4(0.1, 0.1, 0.1, 1.0); 
uniform vec4 lava2_color = vec4(0.4, 0.4, 0.4, 1.0); 
uniform vec4 lava3_color = vec4(1.0, 1.0, 1.0, 1.0); 

uniform float outline_thickness = 3.0; 
uniform float fog_strength = 0.6;   
uniform float glow_strength = 3.0;
uniform float glow_radius = 1.5;
uniform float aura_strength = 0.6;

// --- Shimmer effect controls ---
uniform float shimmer_speed = 2.0;     
uniform float shimmer_strength = 0.2; 
uniform float shimmer_scale = 10.0;   

// --- Smoke Puff Controls ---
uniform float puff_speed = 1.5;
uniform float puff_scale = 4.0;
uniform float puff_intensity = 0.6;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    vec4 final_color = vec4(0.0);

    // === Shimmer effect ===
    float shimmer = sin(UV.y * shimmer_scale + TIME * shimmer_speed) 
                  * cos(UV.x * shimmer_scale * 0.5 + TIME * shimmer_speed * 1.3);
    shimmer *= shimmer_strength;

    // === Rock fill ===
    if (tex.a > 0.1) {
        vec4 base_color;
        vec4 tint_color;

        if (texture_type == 0) {
            base_color = vec4(1.2, 0.6, 0.3, 1.0);
            tint_color = lava1_color;
            final_color = mix(tex * base_color, tex * tint_color * glow_strength, 0.6);
            final_color.rgb += shimmer;
        }
        else if (texture_type == 1) {
            base_color = vec4(0.4, 0.8, 1.0, 1.0);
            tint_color = lava2_color;
            final_color = mix(tex * base_color, tex * tint_color * glow_strength, 0.7);
            final_color.rgb += shimmer;
        }
        else if (texture_type == 2) {
            base_color = vec4(0.4, 0.8, 1.0, 1.0);
            tint_color = lava3_color;
            final_color = mix(tex * base_color, tex * tint_color * glow_strength, 0.7);
            final_color.rgb += shimmer;
        }
    }

    // === Puffy Smoke Outline ===
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    float outline_alpha = 0.0;

    for (float x = -outline_thickness; x <= outline_thickness; x++) {
        for (float y = -outline_thickness; y <= outline_thickness; y++) {
            vec2 offset = vec2(x, y) / tex_size;

            if (length(offset) <= outline_thickness / tex_size.x) {
                float wobble = sin((UV.x + offset.x) * 15.0 + TIME * 1.5) * 0.002
                             + cos((UV.y + offset.y) * 12.0 + TIME * 1.3) * 0.002;

                outline_alpha = max(outline_alpha, texture(TEXTURE, UV + offset + wobble).a);
            }
        }
    }

    if (outline_alpha > 0.1 && tex.a < 0.1) {
        // Smoke puff motion
        float puff = sin(UV.x * puff_scale + TIME * puff_speed) *
                     cos(UV.y * puff_scale * 0.8 + TIME * puff_speed * 1.2);

        puff = abs(puff) * puff_intensity;

        vec3 fog_color = vec3(1.0, 0.3, 0.1); // white smoke
        final_color.rgb = fog_color * (0.5 + puff);
        final_color.a = fog_strength * puff; // fade in/out instead of always showing
    }

    // === Aura Glow ===
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
        final_color.a = max(final_color.a, 0.6);
    }

    COLOR = final_color;
}

