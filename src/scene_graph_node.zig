const std = @import("std");
const zlm = @import("zlm").as(f32);
const gl = @import("gl.zig");
const shader = @import("shader.zig");
const Camera = @import("camera.zig").Camera;
const Geometry = @import("geometry.zig").Geometry;

/// SceneGraphNode represents a self-contained renderable object in 3D space
/// References geometry, owns shader program, transform, and animation state
pub const SceneGraphNode = struct {
    // Transform and animation
    transform: zlm.Mat4,
    elapsed_time: f32,
    x_rotation_speed: f32,
    y_rotation_speed: f32,
    z_rotation_speed: f32,
    
    // Geometry reference (shared across multiple nodes)
    geometry: *Geometry,
    
    // OpenGL rendering resources
    program: gl.GLuint,
    model_location: gl.GLint,
    view_location: gl.GLint,
    projection_location: gl.GLint,
    
    /// Initialize a new scene graph node with triangle geometry and shader
    pub fn init(allocator: std.mem.Allocator, geometry: *Geometry) !SceneGraphNode {
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
        
        std.debug.print("Scene graph node initialized successfully\n", .{});
        
        return SceneGraphNode{
            .transform = zlm.Mat4.identity,
            .elapsed_time = 0.0,
            .x_rotation_speed = 1.0,   // radians per second
            .y_rotation_speed = 1.5,   // slightly faster
            .z_rotation_speed = 0.7,   // slower
            .geometry = geometry,
            .program = program,
            .model_location = model_location,
            .view_location = view_location,
            .projection_location = projection_location,
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
        
        // Render the geometry
        self.geometry.render();
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
        // Note: We don't deinit geometry here as it may be shared
        gl.glDeleteProgram(self.program);
    }
};

// ============================================================================
// Tests
// ============================================================================

const test_utils = @import("test_utilities.zig");

test "SceneGraphNode transform management" {
    // Create a mock geometry for testing
    var geometry = Geometry{
        .vao = 0,
        .vbo = 0,
        .ebo = 0,
        .vertex_count = 0,
        .index_count = 0,
        .has_indices = false,
        .vertex_stride = 0,
        .position_offset = 0,
        .color_offset = 0,
    };
    
    // Create a mock node for testing (without OpenGL initialization)
    var node = SceneGraphNode{
        .transform = zlm.Mat4.identity,
        .elapsed_time = 0.0,
        .x_rotation_speed = 1.0,
        .y_rotation_speed = 1.5,
        .z_rotation_speed = 0.7,
        .geometry = &geometry,
        .program = 0,
        .model_location = 0,
        .view_location = 0,
        .projection_location = 0,
    };
    
    // Test initial state
    try test_utils.expectMat4IdentityDefault(node.getTransform());
    
    // Test transform setting
    const translation = zlm.Mat4.createTranslation(zlm.Vec3.new(1.0, 2.0, 3.0));
    node.setTransform(translation);
    try test_utils.expectMat4EqualDefault(node.getTransform(), translation);
}

test "SceneGraphNode animation timing" {
    // Create a mock geometry for testing
    var geometry = Geometry{
        .vao = 0,
        .vbo = 0,
        .ebo = 0,
        .vertex_count = 0,
        .index_count = 0,
        .has_indices = false,
        .vertex_stride = 0,
        .position_offset = 0,
        .color_offset = 0,
    };
    
    var node = SceneGraphNode{
        .transform = zlm.Mat4.identity,
        .elapsed_time = 0.0,
        .x_rotation_speed = 2.0,
        .y_rotation_speed = 1.0,
        .z_rotation_speed = 0.5,
        .geometry = &geometry,
        .program = 0,
        .model_location = 0,
        .view_location = 0,
        .projection_location = 0,
    };
    
    // Test time accumulation
    node.update(0.5);
    try std.testing.expectApproxEqAbs(@as(f32, 0.5), node.elapsed_time, 1e-6);
    
    node.update(1.0);
    try std.testing.expectApproxEqAbs(@as(f32, 1.5), node.elapsed_time, 1e-6);
    
    // Test zero delta time
    node.update(0.0);
    try std.testing.expectApproxEqAbs(@as(f32, 1.5), node.elapsed_time, 1e-6);
}

test "SceneGraphNode rotation mathematics" {
    // Create a mock geometry for testing
    var geometry = Geometry{
        .vao = 0,
        .vbo = 0,
        .ebo = 0,
        .vertex_count = 0,
        .index_count = 0,
        .has_indices = false,
        .vertex_stride = 0,
        .position_offset = 0,
        .color_offset = 0,
    };
    
    var node = SceneGraphNode{
        .transform = zlm.Mat4.identity,
        .elapsed_time = 0.0,
        .x_rotation_speed = 1.0,
        .y_rotation_speed = 1.0,
        .z_rotation_speed = 1.0,
        .geometry = &geometry,
        .program = 0,
        .model_location = 0,
        .view_location = 0,
        .projection_location = 0,
    };
    
    // Test rotation calculation at known time
    const test_time = std.math.pi / 4.0; // 45 degrees
    node.elapsed_time = test_time;
    node.update(0.0); // Don't advance time, just recalculate
    
    // Verify individual rotation components
    const expected_angle = test_time; // 45 degrees for all axes
    const x_axis = zlm.Vec3.new(1.0, 0.0, 0.0);
    const y_axis = zlm.Vec3.new(0.0, 1.0, 0.0);
    const z_axis = zlm.Vec3.new(0.0, 0.0, 1.0);
    
    const expected_rot_x = zlm.Mat4.createAngleAxis(x_axis, expected_angle);
    const expected_rot_y = zlm.Mat4.createAngleAxis(y_axis, expected_angle);
    const expected_rot_z = zlm.Mat4.createAngleAxis(z_axis, expected_angle);
    
    // Test rotation order: Z, then Y, then X
    const expected_combined = expected_rot_x.mul(expected_rot_y.mul(expected_rot_z));
    try test_utils.expectMat4EqualDefault(node.transform, expected_combined);
}

test "SceneGraphNode different rotation speeds" {
    // Create a mock geometry for testing
    var geometry = Geometry{
        .vao = 0,
        .vbo = 0,
        .ebo = 0,
        .vertex_count = 0,
        .index_count = 0,
        .has_indices = false,
        .vertex_stride = 0,
        .position_offset = 0,
        .color_offset = 0,
    };
    
    var node = SceneGraphNode{
        .transform = zlm.Mat4.identity,
        .elapsed_time = 0.0,
        .x_rotation_speed = 2.0,
        .y_rotation_speed = 1.0,
        .z_rotation_speed = 0.5,
        .geometry = &geometry,
        .program = 0,
        .model_location = 0,
        .view_location = 0,
        .projection_location = 0,
    };
    
    const test_time = 1.0; // 1 second
    node.elapsed_time = test_time;
    node.update(0.0);
    
    // Verify different angles for each axis
    const angle_x = test_time * node.x_rotation_speed; // 2.0 radians
    const angle_y = test_time * node.y_rotation_speed; // 1.0 radians  
    const angle_z = test_time * node.z_rotation_speed; // 0.5 radians
    
    const x_axis = zlm.Vec3.new(1.0, 0.0, 0.0);
    const y_axis = zlm.Vec3.new(0.0, 1.0, 0.0);
    const z_axis = zlm.Vec3.new(0.0, 0.0, 1.0);
    
    const expected_rot_x = zlm.Mat4.createAngleAxis(x_axis, angle_x);
    const expected_rot_y = zlm.Mat4.createAngleAxis(y_axis, angle_y);
    const expected_rot_z = zlm.Mat4.createAngleAxis(z_axis, angle_z);
    
    const expected_combined = expected_rot_x.mul(expected_rot_y.mul(expected_rot_z));
    try test_utils.expectMat4EqualDefault(node.transform, expected_combined);
}

