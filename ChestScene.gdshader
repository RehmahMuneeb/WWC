shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    if (UV.y < 1.0 - progress) {
        tex_color.rgb = vec3(0.0); // black-out unrevealed part
        tex_color.a = tex_color.a; // keep alpha shape
    }

    COLOR = tex_color;
}
