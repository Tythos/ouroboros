const std = @import("std");
const gl = @import("gl.zig");
const shader = @import("shader.zig");
const zlm = @import("zlm").as(f32);

pub const Renderer = struct {
    program: gl.GLuint,
    vao: gl.GLuint,
    vbo: gl.GLuint,
    transform_location: gl.GLint,
    
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
        const transform_location = gl.glGetUniformLocation(program, "transform");
        if (transform_location == -1) {
            std.debug.print("Warning: 'transform' uniform not found in shader\n", .{});
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
            .transform_location = transform_location,
        };
    }
    
    /// Render the triangle with the given rotation angle
    pub fn render(self: *const Renderer, angle: f32) void {
        // Clear the screen
        gl.glClearColor(0.1, 0.1, 0.2, 1.0);  // Dark blue background
        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);
        
        // Use our shader program
        gl.glUseProgram(self.program);
        
        // Create a rotation matrix around the Z axis using zlm
        const z_axis = zlm.Vec3.new(0, 0, 1);
        const rotation_matrix = zlm.Mat4.createAngleAxis(z_axis, angle);
        
        // Set the transform uniform (mat4)
        if (self.transform_location != -1) {
            // OpenGL expects column-major matrices, but zlm stores row-major
            // We need to transpose before passing to OpenGL
            const transposed = rotation_matrix.transpose();
            gl.glUniformMatrix4fv(self.transform_location, 1, gl.GL_FALSE, @ptrCast(&transposed.fields));
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
