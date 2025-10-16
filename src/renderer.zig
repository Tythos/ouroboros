const std = @import("std");
const gl = @import("gl.zig");
const shader = @import("shader.zig");

pub const Renderer = struct {
    program: gl.GLuint,
    vao: gl.GLuint,
    vbo: gl.GLuint,
    angle_location: gl.GLint,
    
    /// Initialize the renderer: load shaders, create VAO/VBO
    pub fn init(allocator: std.mem.Allocator) !Renderer {
        std.debug.print("Initializing renderer...\n", .{});
        
        // Load and compile shaders
        const program = try shader.loadProgram(
            allocator,
            "resources/shaders/triangle.v.glsl",
            "resources/shaders/triangle.f.glsl",
        );
        
        // Get uniform location
        const angle_location = gl.glGetUniformLocation(program, "angle");
        if (angle_location == -1) {
            std.debug.print("Warning: 'angle' uniform not found in shader\n", .{});
        }
        
        // Define triangle vertices with rainbow colors
        // Each vertex: [x, y, z, r, g, b]
        const vertices = [_]f32{
            // Position       // Color (red)
             0.0,  0.5, 0.0,  1.0, 0.0, 0.0,
            // Position       // Color (green)
            -0.5, -0.5, 0.0,  0.0, 1.0, 0.0,
            // Position       // Color (blue)
             0.5, -0.5, 0.0,  0.0, 0.0, 1.0,
        };
        
        // Create and bind VAO
        var vao: gl.GLuint = 0;
        gl.glGenVertexArrays(1, &vao);
        gl.glBindVertexArray(vao);
        
        // Create and bind VBO
        var vbo: gl.GLuint = 0;
        gl.glGenBuffers(1, &vbo);
        gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vbo);
        gl.glBufferData(
            gl.GL_ARRAY_BUFFER,
            @intCast(vertices.len * @sizeOf(f32)),
            &vertices,
            gl.GL_STATIC_DRAW,
        );
        
        // Configure vertex attributes
        // Position attribute (location = 0)
        gl.glVertexAttribPointer(
            0,                                  // attribute location
            3,                                  // number of components (x, y, z)
            gl.GL_FLOAT,                        // type
            gl.GL_FALSE,                        // normalized?
            6 * @sizeOf(f32),                   // stride (6 floats per vertex)
            null,                               // offset (0)
        );
        gl.glEnableVertexAttribArray(0);
        
        // Color attribute (location = 1)
        gl.glVertexAttribPointer(
            1,                                  // attribute location
            3,                                  // number of components (r, g, b)
            gl.GL_FLOAT,                        // type
            gl.GL_FALSE,                        // normalized?
            6 * @sizeOf(f32),                   // stride (6 floats per vertex)
            @ptrFromInt(3 * @sizeOf(f32)),      // offset (3 floats in)
        );
        gl.glEnableVertexAttribArray(1);
        
        // Unbind VAO (good practice)
        gl.glBindVertexArray(0);
        
        std.debug.print("Renderer initialized successfully\n", .{});
        
        return Renderer{
            .program = program,
            .vao = vao,
            .vbo = vbo,
            .angle_location = angle_location,
        };
    }
    
    /// Render the triangle with the given rotation angle
    pub fn render(self: *const Renderer, angle: f32) void {
        // Clear the screen
        gl.glClearColor(0.1, 0.1, 0.2, 1.0);  // Dark blue background
        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);
        
        // Use our shader program
        gl.glUseProgram(self.program);
        
        // Set the angle uniform
        if (self.angle_location != -1) {
            gl.glUniform1f(self.angle_location, angle);
        }
        
        // Bind VAO and draw
        gl.glBindVertexArray(self.vao);
        gl.glDrawArrays(gl.GL_TRIANGLES, 0, 3);
        gl.glBindVertexArray(0);
    }
    
    /// Clean up OpenGL resources
    pub fn deinit(self: *const Renderer) void {
        std.debug.print("Cleaning up renderer resources...\n", .{});
        gl.glDeleteBuffers(1, &self.vbo);
        gl.glDeleteVertexArrays(1, &self.vao);
        gl.glDeleteProgram(self.program);
    }
};
