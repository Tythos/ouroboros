#version 300 es

layout(location = 0) in vec3 position;
layout(location = 1) in vec3 color;

out vec3 fragColor;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

void main() {
    // Apply MVP transformation
    gl_Position = projection * view * model * vec4(position, 1.0);
    
    // Pass color to fragment shader
    fragColor = color;
}

