const std = @import("std");
const zlm = @import("zlm").as(f32);
const gl = @import("gl.zig");
const shader = @import("shader.zig");
const Camera = @import("camera.zig").Camera;

/// SceneGraphNode represents a self-contained renderable object in 3D space
/// Owns its geometry (VAO/VBO), shader program, transform, and animation state
pub const SceneGraphNode = struct {
    // Transform and animation
    transform: zlm.Mat4,
    elapsed_time: f32,
    x_rotation_speed: f32,
    y_rotation_speed: f32,
    z_rotation_speed: f32,
    
    // OpenGL rendering resources
    program: gl.GLuint,
    vao: gl.GLuint,
    vbo: gl.GLuint,
    model_location: gl.GLint,
    view_location: gl.GLint,
    projection_location: gl.GLint,
    vertex_count: gl.GLsizei,
    
    /// Initialize a new scene graph node with triangle geometry and shader
    pub fn init(allocator: std.mem.Allocator) !SceneGraphNode {
        std.debug.print("Initializing scene graph node...\n", .{});
        
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
        
        // Unbind VAO
        gl.glBindVertexArray(0);
        
        std.debug.print("Scene graph node initialized successfully\n", .{});
        
        return SceneGraphNode{
            .transform = zlm.Mat4.identity,
            .elapsed_time = 0.0,
            .x_rotation_speed = 1.0,   // radians per second
            .y_rotation_speed = 1.5,   // slightly faster
            .z_rotation_speed = 0.7,   // slower
            .program = program,
            .vao = vao,
            .vbo = vbo,
            .model_location = model_location,
            .view_location = view_location,
            .projection_location = projection_location,
            .vertex_count = 3,
        };
    }
    
    /// Update the node's animation based on elapsed time
    pub fn update(self: *SceneGraphNode, delta_time: f32) void {
        self.elapsed_time += delta_time;
        
        // Compute rotation angles based on elapsed time
        const angle_x = self.elapsed_time * self.x_rotation_speed;
        const angle_y = self.elapsed_time * self.y_rotation_speed;
        const angle_z = self.elapsed_time * self.z_rotation_speed;
        
        // Create rotation axes
        const x_axis = zlm.Vec3.new(1.0, 0.0, 0.0);
        const y_axis = zlm.Vec3.new(0.0, 1.0, 0.0);
        const z_axis = zlm.Vec3.new(0.0, 0.0, 1.0);
        
        // Create rotation matrices
        const rotation_x = zlm.Mat4.createAngleAxis(x_axis, angle_x);
        const rotation_y = zlm.Mat4.createAngleAxis(y_axis, angle_y);
        const rotation_z = zlm.Mat4.createAngleAxis(z_axis, angle_z);
        
        // Combine rotations: apply Z, then Y, then X (order matters!)
        self.transform = rotation_x.mul(rotation_y.mul(rotation_z));
    }
    
    /// Render the node with the given camera
    pub fn render(self: *const SceneGraphNode, camera: *const Camera) void {
        // Use shader program
        gl.glUseProgram(self.program);
        
        // Get view and projection matrices from camera
        const view = camera.getViewMatrix();
        const projection = camera.getProjectionMatrix();
        
        // Upload MVP matrices to shader
        gl.glUniformMatrix4fv(self.model_location, 1, gl.GL_FALSE, @ptrCast(&self.transform.fields));
        gl.glUniformMatrix4fv(self.view_location, 1, gl.GL_FALSE, @ptrCast(&view.fields));
        gl.glUniformMatrix4fv(self.projection_location, 1, gl.GL_FALSE, @ptrCast(&projection.fields));
        
        // Bind VAO and draw
        gl.glBindVertexArray(self.vao);
        gl.glDrawArrays(gl.GL_TRIANGLES, 0, self.vertex_count);
        gl.glBindVertexArray(0);
    }
    
    /// Set the node's local transform (model matrix) directly
    pub fn setTransform(self: *SceneGraphNode, transform: zlm.Mat4) void {
        self.transform = transform;
    }
    
    /// Get the node's current transform
    pub fn getTransform(self: *const SceneGraphNode) zlm.Mat4 {
        return self.transform;
    }
    
    /// Clean up OpenGL resources
    pub fn deinit(self: *const SceneGraphNode) void {
        std.debug.print("Cleaning up scene graph node resources...\n", .{});
        gl.glDeleteBuffers(1, &self.vbo);
        gl.glDeleteVertexArrays(1, &self.vao);
        gl.glDeleteProgram(self.program);
    }
};

