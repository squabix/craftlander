shader_type spatial;
render_mode unshaded, cull_disabled, blend_add;
stencil_mode read, compare_equal, 1;

#include "res://assets/shaders/boat_interaction_ring.gdshaderinc"

void vertex() {
    local_pos = VERTEX;
    camera_distance = ring_camera_distance(MODELVIEW_MATRIX);
}

void fragment() {
    vec3 emission;
    vec4 ring = ring_shade(TIME, emission);
    ALBEDO = ring.rgb;
    EMISSION = emission;
    ALPHA = ring.a;
}
