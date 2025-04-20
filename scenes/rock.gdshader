shader_type canvas_item;

uniform vec4 glow_color = vec4(1.0, 0.0, 0.0, 1.0); // Red
uniform float thickness = 1.0;
uniform float blink_speed = 6.0; // Fast blink

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float a = tex.a;

    // Glow sample offset
    float glow = 0.0;
    glow += texture(TEXTURE, UV + vec2(thickness, 0.0) / 100.0).a;
    glow += texture(TEXTURE, UV + vec2(-thickness, 0.0) / 100.0).a;
    glow += texture(TEXTURE, UV + vec2(0.0, thickness) / 100.0).a;
    glow += texture(TEXTURE, UV + vec2(0.0, -thickness) / 100.0).a;

    // Smooth blinking (from red to transparent)
    float blink = abs(sin(TIME * blink_speed)); // Smooth blink, fade from 0 to 1

    // If current pixel is transparent, but neighbors have alpha, add smooth red glow
    if (a < 0.1 && glow > 0.6) {
        COLOR = glow_color * blink; // Apply the smooth blink effect
    } else {
        COLOR = tex; // Keep original texture
    }
}
