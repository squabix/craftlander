shader_type canvas_item;

uniform float radius : hint_range(0.0, 1.0) = 0.5; 
uniform float thickness : hint_range(0.0, 1.0) = 0.1; 
uniform float angle_offset : hint_range(-360.0, 360.0) = -90.0; 
uniform float fill_amount : hint_range(0.0, 1.0) = 1.0; 

void fragment() {
    vec2 centered_uv = UV - vec2(0.5);
    
    float current_radius = length(centered_uv);
    float inner_radius = radius - thickness;
    
    if (current_radius < inner_radius || current_radius > radius) {
        COLOR = vec4(0.0);
    } else {
        float current_angle = atan(centered_uv.y, centered_uv.x);
        
        float offset_rads = radians(angle_offset);
        float adjusted_angle = current_angle - offset_rads;
        
        adjusted_angle = mod(adjusted_angle + TAU, TAU);
        
        float u = adjusted_angle / TAU;
        float v = (current_radius - inner_radius) / thickness;
        
        if (u > fill_amount) {
            COLOR = vec4(0.0); 
        } else {
            COLOR = texture(TEXTURE, vec2(u, v));
        }
    }
}