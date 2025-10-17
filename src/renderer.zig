const std = @import("std");
const gl = @import("gl.zig");
const shader = @import("shader.zig");
const camera = @import("camera.zig");
const zlm = @import("zlm").as(f32);

pub const Renderer = struct {
    program: gl.GLuint,
    triangle_vao: gl.GLuint,
    triangle_vbo: gl.GLuint,
    axes_vao: gl.GLuint,
    axes_vbo: gl.GLuint,
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
        
        // Create triangle geometry
        const triangle_vao = try createTriangleGeometry();
        const triangle_vbo = try createTriangleVBO();
        
        // Create axes geometry
        const axes_vao = try createAxesGeometry();
        const axes_vbo = try createAxesVBO();
        
        std.debug.print("Renderer initialized successfully\n", .{});
        
        return Renderer{
            .program = program,
            .triangle_vao = triangle_vao,
            .triangle_vbo = triangle_vbo,
            .axes_vao = axes_vao,
            .axes_vbo = axes_vbo,
            .transform_location = transform_location,
        };
    }
    
    /// Create triangle VAO
    fn createTriangleGeometry() !gl.GLuint {
        // Define triangle vertices with rainbow colors at the origin, facing -X (towards camera)
        // Each vertex: [x, y, z, r, g, b]
        const vertices = [_]f32{
            // Position       // Color (red) - top vertex
             1.0,  1.0, 0.0,  1.0, 0.0, 0.0,
            // Position       // Color (green) - bottom left
             1.0, -1.0, -1.0, 0.0, 1.0, 0.0,
            // Position       // Color (blue) - bottom right
             1.0, -1.0,  1.0, 0.0, 0.0, 1.0,
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
        
        return vao;
    }
    
    /// Create triangle VBO (returns the VBO handle for cleanup)
    fn createTriangleVBO() !gl.GLuint {
        var vbo: gl.GLuint = 0;
        gl.glGenBuffers(1, &vbo);
        return vbo;
    }
    
    /// Create axes VAO
    fn createAxesGeometry() !gl.GLuint {
        // Define unit axes for Z-up coordinate system: X (red), Y (green), Z (blue)
        // Camera looks from +X towards origin, +Y to the right, +Z up
        // Each vertex: [x, y, z, r, g, b]
        const vertices = [_]f32{
            // X-axis (red) - from origin to (1,0,0) - forward direction
            0.0, 0.0, 0.0,  1.0, 0.0, 0.0,  // origin
            1.0, 0.0, 0.0,  1.0, 0.0, 0.0,  // X endpoint (forward)
            
            // Y-axis (green) - from origin to (0,1,0) - right direction
            0.0, 0.0, 0.0,  0.0, 1.0, 0.0,  // origin
            0.0, 1.0, 0.0,  0.0, 1.0, 0.0,  // Y endpoint (right)
            
            // Z-axis (blue) - from origin to (0,0,1) - up direction
            0.0, 0.0, 0.0,  0.0, 0.0, 1.0,  // origin
            0.0, 0.0, 1.0,  0.0, 0.0, 1.0,  // Z endpoint (up)
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
        
        // Configure vertex attributes (same as triangle)
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
        
        return vao;
    }
    
    /// Create axes VBO (returns the VBO handle for cleanup)
    fn createAxesVBO() !gl.GLuint {
        var vbo: gl.GLuint = 0;
        gl.glGenBuffers(1, &vbo);
        return vbo;
    }
    
    /// Render the scene with the given camera
    pub fn render(self: *const Renderer, cam: camera.Camera) void {
        // Clear the screen
        gl.glClearColor(0.05, 0.05, 0.1, 1.0);  // Darker background for better contrast
        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);
        
        // Use our shader program
        gl.glUseProgram(self.program);
        
        // Temporarily use identity matrix to test view matrix
        const model_matrix = zlm.Mat4.identity;
        
        // Render triangle with full MVP matrix pipeline
        self.renderTriangle(model_matrix, cam);
    }
    
    /// Render the axes (with view transform to show correct orientation)
    fn renderAxes(self: *const Renderer) void {
        // Transform from our coordinate system (X=forward, Y=right, Z=up) 
        // to OpenGL's default view (looking down -Z axis)
        // We need to rotate so that:
        // - Our +X (forward) becomes OpenGL's -Z (towards viewer)
        // - Our +Y (right) stays OpenGL's +Y (right)
        // - Our +Z (up) becomes OpenGL's +X (up in screen)
        
        // Create a proper view matrix to map our coordinate system to OpenGL's default view
        // Our system: X=forward, Y=right, Z=up
        // OpenGL default: looking down -Z, +Y up, +X right
        // We need: Our +X -> OpenGL -Z, Our +Y -> OpenGL +X, Our +Z -> OpenGL +Y
        
        // This requires a combination of rotations
        // First rotate around Y axis by -90 degrees, then around X axis by 90 degrees
        const y_axis = zlm.Vec3.new(0, 1, 0);
        const x_axis = zlm.Vec3.new(1, 0, 0);
        const rot_y = zlm.Mat4.createAngleAxis(y_axis, -std.math.pi / 2.0);
        const rot_x = zlm.Mat4.createAngleAxis(x_axis, std.math.pi / 2.0);
        const view_rotation = rot_x.mul(rot_y);
        
        // Set the transform uniform (mat4)
        if (self.transform_location != -1) {
            // OpenGL expects column-major matrices, but zlm stores row-major
            // We need to transpose before passing to OpenGL
            const transposed = view_rotation.transpose();
            gl.glUniformMatrix4fv(self.transform_location, 1, gl.GL_FALSE, @ptrCast(&transposed.fields));
        }
        
        // Bind axes VAO and draw as lines
        gl.glBindVertexArray(self.axes_vao);
        gl.glDrawArrays(gl.GL_LINES, 0, 6); // 3 lines = 6 vertices
        gl.glBindVertexArray(0);
    }
    
    /// Render the triangle with model matrix and camera (full MVP pipeline)
    fn renderTriangle(self: *const Renderer, model_matrix: zlm.Mat4, cam: camera.Camera) void {
        // Test with simple orthographic projection
        const mvp_matrix = cam.getMVPMatrix(model_matrix);
        
        // Set the transform uniform (mat4)
        if (self.transform_location != -1) {
            // OpenGL expects column-major matrices, but zlm stores row-major
            // We need to transpose before passing to OpenGL
            const transposed = mvp_matrix.transpose();
            gl.glUniformMatrix4fv(self.transform_location, 1, gl.GL_FALSE, @ptrCast(&transposed.fields));
        }
        
        // Bind triangle VAO and draw
        gl.glBindVertexArray(self.triangle_vao);
        gl.glDrawArrays(gl.GL_TRIANGLES, 0, 3);
        gl.glBindVertexArray(0);
    }
    
    /// Clean up OpenGL resources
    pub fn deinit(self: *const Renderer) void {
        std.debug.print("Cleaning up renderer resources...\n", .{});
        gl.glDeleteBuffers(1, &self.triangle_vbo);
        gl.glDeleteVertexArrays(1, &self.triangle_vao);
        gl.glDeleteBuffers(1, &self.axes_vbo);
        gl.glDeleteVertexArrays(1, &self.axes_vao);
        gl.glDeleteProgram(self.program);
    }
};
