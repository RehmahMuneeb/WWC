shader_type canvas_item;

uniform float scroll_speed = 0.2;

void vertex() {
    UV.x += TIME * scroll_speed;
}
