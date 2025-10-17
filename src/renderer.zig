const std = @import("std");
const gl = @import("gl.zig");
const shader = @import("shader.zig");
const zlm = @import("zlm").as(f32);
const Camera = @import("camera.zig").Camera;

pub const Renderer = struct {
    program: gl.GLuint,
    vao: gl.GLuint,
    vbo: gl.GLuint,
    model_location: gl.GLint,
    view_location: gl.GLint,
    projection_location: gl.GLint,
    
    /// Initialize the renderer: load shaders, create VAO/VBO
    pub fn init(allocator: std.mem.Allocator) !Renderer {
        std.debug.print("Initializing renderer...\n", .{});
        
        // Load and compile shaders
        const program = try shader.loadProgram(
            allocator,
            "resources/shaders/triangle.v.glsl",
            "resources/shaders/triangle.f.glsl",
        );
        
        // Get uniform locations for MVP matrices
        const model_location = gl.glGetUniformLocation(program, "model");
        const view_location = gl.glGetUniformLocation(program, "view");
        const projection_location = gl.glGetUniformLocation(program, "projection");
        
        // Verify uniforms were found
        if (model_location == -1 or view_location == -1 or projection_location == -1) {
            std.debug.print("ERROR: Failed to locate MVP uniforms in shader\n", .{});
            return error.ShaderUniformNotFound;
        }
        
        // Define triangle vertices with rainbow colors - CENTERED AT ORIGIN
        // Each vertex: [x, y, z, r, g, b]
        // Large triangle in YZ plane, visible from +X axis
        const vertices = [_]f32{
            // Position       // Color (red) - top vertex
             0.0,  1.0, 0.0,  1.0, 0.0, 0.0,
            // Position       // Color (green) - bottom left
             0.0, -1.0, -1.0,  0.0, 1.0, 0.0,
            // Position       // Color (blue) - bottom right
             0.0, -1.0, 1.0,  0.0, 0.0, 1.0,
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
        
        // Enable depth testing for proper 3D rendering
        gl.glEnable(gl.GL_DEPTH_TEST);
        gl.glDepthFunc(gl.GL_LESS);
        
        std.debug.print("Renderer initialized successfully\n", .{});
        
        return Renderer{
            .program = program,
            .vao = vao,
            .vbo = vbo,
            .model_location = model_location,
            .view_location = view_location,
            .projection_location = projection_location,
        };
    }
    
    /// Render with the given model matrix and camera
    /// This is the core rendering function following the pattern: render(model, camera)
    pub fn render(self: *const Renderer, model: zlm.Mat4, camera: *const Camera) void {
        // Clear the screen and depth buffer
        gl.glClearColor(0.1, 0.1, 0.2, 1.0);  // Dark blue background
        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);
        
        // Use our shader program
        gl.glUseProgram(self.program);
        
        // Get view and projection matrices from camera
        const view = camera.getViewMatrix();
        const projection = camera.getProjectionMatrix();
        
        // Upload MVP matrices to shader
        // Note: zlm matrices work directly with OpenGL without transposition
        gl.glUniformMatrix4fv(self.model_location, 1, gl.GL_FALSE, @ptrCast(&model.fields));
        gl.glUniformMatrix4fv(self.view_location, 1, gl.GL_FALSE, @ptrCast(&view.fields));
        gl.glUniformMatrix4fv(self.projection_location, 1, gl.GL_FALSE, @ptrCast(&projection.fields));
        
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
