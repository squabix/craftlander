shader_type canvas_item;
// Origin code from https://www.shadertoy.com/view/MdlXz8
// Ported by haruyou27

uniform int iteration_times : hint_range(1, 20) = 5;
uniform float speed : hint_range(0.0, 5.0) = 1.0;
uniform vec4 color : source_color = vec4(0.0, 0.35, 0.5, 1.0);
uniform float intensity : hint_range(0.001, 0.05) = 0.005;
uniform float scale : hint_range(0.1, 10.0) = 1.0;

void fragment() 
{
    // High-precision coordinate math without lowp constraints
    vec2 p = mod(UV * TAU * scale, TAU) - 250.0;
    vec2 i = vec2(p);
    float c = 1.0;
    float t = TIME * speed;

    for (int n = 0; n < iteration_times; n++) 
    {
        i = p + vec2(cos(t - i.x) + sin(t + i.y), sin(t - i.y) + cos(t + i.x));
        c += 1.0 / length(vec2(p.x / (sin(i.x + t) / intensity), p.y / (cos(i.y + t) / intensity)));
    }
    c /= float(iteration_times);
    c = 1.17 - pow(c, 1.4);
    vec4 colour = vec4(pow(abs(c), 8.0));
    colour = clamp(colour + color, 0.0, 1.0);
    
    COLOR = colour;
}