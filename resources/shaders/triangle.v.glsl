#version 300 es

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 color;

out vec3 fragColor;

uniform mat4 transform;

void main() {
    // Apply transformation matrix
    gl_Position = transform * vec4(position, 1.0);
    
    // Pass color to fragment shader
    fragColor = color;
}

