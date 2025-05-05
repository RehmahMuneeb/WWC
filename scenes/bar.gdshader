shader_type canvas_item;

uniform float time;
uniform vec4 progress_color;

void fragment() {
    // Get the current pixel's UV coordinates
    vec2 uv = FRAGCOORD.xy / SCREEN_PIXEL_SIZE;

    // Create a noise-based glitter effect
    float noise = sin(uv.x * 10.0 + time * 5.0) * sin(uv.y * 10.0 + time * 5.0);
    noise = abs(noise); // Make the noise positive
    noise = step(0.95, noise); // Glitter threshold

    // Apply the glitter effect on top of the progress bar fill
    vec4 base_color = mix(progress_color, vec4(1.0, 1.0, 1.0, 1.0), noise);

    // Output final color
    COLOR = base_color;
}
