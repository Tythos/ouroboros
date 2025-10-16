#version 300 es

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 color;

out vec3 fragColor;

uniform float angle;

void main() {
    // Apply 2D rotation around the Z axis
    float c = cos(angle);
    float s = sin(angle);
    mat2 rotation = mat2(c, s, -s, c);
    
    // Rotate the XY coordinates
    vec2 rotated = rotation * position.xy;
    
    // Output position
    gl_Position = vec4(rotated, position.z, 1.0);
    
    // Pass color to fragment shader
    fragColor = color;
}

