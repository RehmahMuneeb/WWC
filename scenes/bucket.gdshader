shader_type canvas_item;

void fragment() {
    float fade = smoothstep(0.9, 0.7, UV.y); // Fade out only the bottom
    COLOR.a *= fade;
}

