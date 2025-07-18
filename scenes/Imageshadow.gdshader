shader_type canvas_item;

uniform float blur_size = 2.0;
uniform vec4 shadow_color = vec4(0.0, 0.0, 0.0, 0.5);
uniform vec2 shadow_offset = vec2(5.0, 5.0);

void fragment() {
    vec4 original = texture(TEXTURE, UV);
    vec4 sum = vec4(0.0);
    float total = 0.0;

    for (int x = -4; x <= 4; x++) {
        for (int y = -4; y <= 4; y++) {
            vec2 offset = vec2(float(x), float(y)) * (blur_size * 0.002);
            vec2 sample_uv = UV + (shadow_offset / TEXTURE_PIXEL_SIZE) + offset;
            sum += texture(TEXTURE, sample_uv);
            total += 1.0;
        }
    }

    vec4 shadow = (sum / total) * shadow_color;

    // Blend original on top of shadow
    COLOR = mix(shadow, original, original.a);
}
