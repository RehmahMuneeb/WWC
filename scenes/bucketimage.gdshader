shader_type canvas_item;

uniform vec2 hole_center = vec2(0.5, 0.5); // center of the hole in UV
uniform float hole_radius = 0.2; // Adjust based on image size (in UV units)

void fragment() {
    vec2 uv = UV;

    float dist = distance(uv, hole_center);
    if (dist > hole_radius) {
        discard;
    }

    COLOR = texture(TEXTURE, uv);
}
