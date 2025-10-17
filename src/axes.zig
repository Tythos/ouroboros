const std = @import("std");
const gl = @import("gl.zig");
const shader = @import("shader.zig");
const zlm = @import("zlm").as(f32);
const Camera = @import("camera.zig").Camera;

/// AxesRenderer draws RGB colored coordinate axes for reference
/// X-axis = Red, Y-axis = Green, Z-axis = Blue
pub const AxesRenderer = struct {
    program: gl.GLuint,
    vao: gl.GLuint,
    vbo: gl.GLuint,
    model_location: gl.GLint,
    view_location: gl.GLint,
    projection_location: gl.GLint,
    
    /// Initialize the axes renderer
    pub fn init(allocator: std.mem.Allocator) !AxesRenderer {
        std.debug.print("Initializing axes renderer...\n", .{});
        
        // Use the same shader program as the triangle (it handles position + color)
        const program = try shader.loadProgram(
            allocator,
            "resources/shaders/triangle.v.glsl",
            "resources/shaders/triangle.f.glsl",
        );
        
        // Get uniform locations
        const model_location = gl.glGetUniformLocation(program, "model");
        const view_location = gl.glGetUniformLocation(program, "view");
        const projection_location = gl.glGetUniformLocation(program, "projection");
        
        if (model_location == -1 or view_location == -1 or projection_location == -1) {
            std.debug.print("ERROR: Failed to locate MVP uniforms in shader\n", .{});
            return error.ShaderUniformNotFound;
        }
        
        // Define axes geometry as lines
        // 3 lines (6 vertices total): X-axis (red), Y-axis (green), Z-axis (blue)
        // Each vertex: [x, y, z, r, g, b]
        const axes_length: f32 = 2.0;
        const vertices = [_]f32{
            // X-axis (red line from origin to +X)
            0.0, 0.0, 0.0,  1.0, 0.0, 0.0,  // Origin
            axes_length, 0.0, 0.0,  1.0, 0.0, 0.0,  // +X
            
            // Y-axis (green line from origin to +Y)
            0.0, 0.0, 0.0,  0.0, 1.0, 0.0,  // Origin
            0.0, axes_length, 0.0,  0.0, 1.0, 0.0,  // +Y
            
            // Z-axis (blue line from origin to +Z)
            0.0, 0.0, 0.0,  0.0, 0.0, 1.0,  // Origin
            0.0, 0.0, axes_length,  0.0, 0.0, 1.0,  // +Z
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
        
        // Configure vertex attributes (same layout as triangle shader)
        // Position attribute (location = 0)
        gl.glVertexAttribPointer(
            0,
            3,
            gl.GL_FLOAT,
            gl.GL_FALSE,
            6 * @sizeOf(f32),
            null,
        );
        gl.glEnableVertexAttribArray(0);
        
        // Color attribute (location = 1)
        gl.glVertexAttribPointer(
            1,
            3,
            gl.GL_FLOAT,
            gl.GL_FALSE,
            6 * @sizeOf(f32),
            @ptrFromInt(3 * @sizeOf(f32)),
        );
        gl.glEnableVertexAttribArray(1);
        
        // Unbind VAO
        gl.glBindVertexArray(0);
        
        std.debug.print("Axes renderer initialized successfully\n", .{});
        
        return AxesRenderer{
            .program = program,
            .vao = vao,
            .vbo = vbo,
            .model_location = model_location,
            .view_location = view_location,
            .projection_location = projection_location,
        };
    }
    
    /// Render the coordinate axes with identity model matrix (world frame)
    pub fn render(self: *const AxesRenderer, camera: *const Camera) void {
        // Use shader program
        gl.glUseProgram(self.program);
        
        // Identity model matrix - axes stay in world frame
        const model = zlm.Mat4.identity;
        
        // Get view and projection from camera
        const view = camera.getViewMatrix();
        const projection = camera.getProjectionMatrix();
        
        // Upload matrices
        gl.glUniformMatrix4fv(self.model_location, 1, gl.GL_FALSE, @ptrCast(&model.fields));
        gl.glUniformMatrix4fv(self.view_location, 1, gl.GL_FALSE, @ptrCast(&view.fields));
        gl.glUniformMatrix4fv(self.projection_location, 1, gl.GL_FALSE, @ptrCast(&projection.fields));
        
        // Draw lines
        gl.glBindVertexArray(self.vao);
        gl.glDrawArrays(gl.GL_LINES, 0, 6);  // 6 vertices = 3 lines
        gl.glBindVertexArray(0);
    }
    
    /// Clean up OpenGL resources
    pub fn deinit(self: *const AxesRenderer) void {
        std.debug.print("Cleaning up axes renderer resources...\n", .{});
        gl.glDeleteBuffers(1, &self.vbo);
        gl.glDeleteVertexArrays(1, &self.vao);
        gl.glDeleteProgram(self.program);
    }
};

