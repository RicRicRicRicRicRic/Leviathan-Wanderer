shader_type canvas_item;

uniform float scroll_speed : hint_range(0.1, 5.0) = 1.0;
uniform float wave_strength : hint_range(0.0, 0.1) = 0.03;
uniform float wave_frequency : hint_range(5.0, 50.0) = 20.0;
uniform vec4 acid_color : source_color = vec4(2.0, 3.0, 0.5, 1.0);
uniform vec4 foam_color : source_color = vec4(0.8, 0.9, 0.7, 0.5);
uniform float foam_threshold : hint_range(0.0, 1.0) = 0.8;
uniform float foam_intensity : hint_range(0.0, 2.0) = 0.5;

uniform float top_wobble_strength : hint_range(0.0, 100.0) = 30.0;
uniform float top_wobble_frequency : hint_range(1.0, 20.0) = 5.0;
uniform float top_wobble_speed : hint_range(0.1, 5.0) = 0.5;

uniform float top_wiggle_strength : hint_range(0.0, 20.0) = 7.0;
uniform float top_wiggle_frequency_x : hint_range(10.0, 100.0) = 40.0;
uniform float top_wiggle_speed : hint_range(0.1, 5.0) = 1.0;

uniform float time_offset = 10.0;

float rand(vec2 n) {
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

void vertex() {
    float wobble_intensity_fade = 1.0 - UV.y;

    float current_time = TIME + time_offset;

    float per_vertex_random_offset = rand(UV * 1000.0) * 2.0 * PI;

    float main_vertex_wave = sin(UV.x * top_wobble_frequency + current_time * top_wobble_speed + per_vertex_random_offset);

    float wiggle_wave = sin(UV.x * top_wiggle_frequency_x + current_time * top_wiggle_speed + per_vertex_random_offset);

    float final_vertex_displacement = (main_vertex_wave * top_wobble_strength) + (wiggle_wave * top_wiggle_strength);

    VERTEX.y += final_vertex_displacement * wobble_intensity_fade;
}

void fragment() {
    vec2 offset_uv = UV;

    float current_time = TIME + time_offset;

    float wave1 = sin(UV.x * wave_frequency + current_time * scroll_speed) * wave_strength;
    float wave2 = cos(UV.y * wave_frequency * 0.7 + current_time * scroll_speed * 0.8) * wave_strength * 0.5;

    offset_uv.y += wave1;
    offset_uv.x += wave2;

    vec4 final_color = acid_color;

    float normalized_wave = (wave1 + wave_strength) / (2.0 * wave_strength);

    float foam_mask = smoothstep(foam_threshold, foam_threshold + 0.1, normalized_wave);

    float noise = rand(UV * 100.0 + current_time * 5.0);
    foam_mask *= (0.5 + noise * 0.5);

    final_color = mix(final_color, foam_color, foam_mask * foam_intensity);

    COLOR = final_color * texture(TEXTURE, offset_uv);
}
