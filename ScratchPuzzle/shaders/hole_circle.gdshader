shader_type canvas_item;

uniform vec2 hole_position = vec2(0.5, 0.5);
uniform float hole_radius = 0.15;
uniform float softness = 0.01;
uniform float darkness = 0.45;

void fragment() {
    vec2 uv = SCREEN_UV;
    float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;

    vec2 corrected_uv = vec2(
        (uv.x - hole_position.x) * aspect,
        uv.y - hole_position.y
    );

    float dist = length(corrected_uv);

    float alpha = smoothstep(
        hole_radius,
        hole_radius + softness,
        dist
    );
    COLOR = vec4(0.0, 0.0, 0.0, alpha * darkness);
}