shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_prepass_alpha;

uniform vec4 base_color : source_color = vec4(1.0, 0.87, 0.22, 0.9);
uniform vec4 accent_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float emission_strength = 5.5;
uniform float stripe_count = 18.0;
uniform float stripe_speed = 0.7;
uniform float stripe_softness = 0.18;
uniform float ring_radius = 1.15;
uniform float ring_width = 0.28;
uniform float edge_softness = 0.06;
uniform float pulse_speed = 1.5;
uniform float pulse_amount = 0.18;
uniform float vertical_fade = 1.25;

varying vec3 local_pos;

void vertex() {
    local_pos = VERTEX;
}

float ring_band(float radius) {
    float inner = ring_radius - ring_width * 0.5;
    float outer = ring_radius + ring_width * 0.5;
    float inner_mask = smoothstep(inner - edge_softness, inner + edge_softness, radius);
    float outer_mask = 1.0 - smoothstep(outer - edge_softness, outer + edge_softness, radius);
    return inner_mask * outer_mask;
}

void fragment() {
    vec2 ring_plane = local_pos.xz;
    float radius = length(ring_plane);
    float angle = atan(ring_plane.y, ring_plane.x);
    float angle01 = fract(angle / TAU + 0.5);

    float stripe_wave = sin((angle01 - TIME * stripe_speed) * TAU * stripe_count) * 0.5 + 0.5;
    float stripe_mask = smoothstep(0.5 - stripe_softness, 1.0, stripe_wave);
    float band_mask = ring_band(radius);
    float height_mask = pow(max(0.0, 1.0 - abs(local_pos.y) * vertical_fade), 1.6);
    float pulse = 1.0 + sin(TIME * pulse_speed) * pulse_amount;

    vec3 color = mix(base_color.rgb, accent_color.rgb, stripe_mask);
    float alpha = band_mask * height_mask * (0.45 + stripe_mask * 0.55) * pulse * base_color.a;

    ALBEDO = color;
    EMISSION = color * emission_strength * (0.45 + stripe_mask * 0.55) * band_mask * pulse;
    ALPHA = clamp(alpha, 0.0, 1.0);
}
