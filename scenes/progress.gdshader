shader_type canvas_item;

uniform float time;

void fragment() {
    // Particle color is based on white and alpha channel for transparency
    vec4 base_color = vec4(1.0, 1.0, 1.0, 1.0); // Sparkling white
    float sparkle = sin(time * 10.0 + FRAGCOORD.x * 10.0 + FRAGCOORD.y * 10.0);
    sparkle = abs(sparkle); // Ensures positive values
    sparkle = step(0.95, sparkle); // Glitter threshold

    // Add transparency and modify size based on sparkle intensity
    base_color.a *= sparkle; // Only show particles based on the threshold

    COLOR = base_color;
}
