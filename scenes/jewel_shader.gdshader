shader_type canvas_item;

void fragment() {
    // Clip the bottom 30% of the texture
    if (UV.y > 0.7) {  // 0.7 means 70% from the top (30% from the bottom)
        discard;  // Discard fragments in the bottom 30%
    }

    // Output the color
    COLOR = texture(TEXTURE, UV);
}