const std = @import("std");
const zlm = @import("zlm").as(f32);
const gl = @import("gl.zig");
const Camera = @import("camera.zig").Camera;
const Geometry = @import("geometry.zig").Geometry;
const Material = @import("material.zig").Material;

/// SceneGraphNode represents a self-contained renderable object in 3D space
/// References geometry and material, owns transform and animation state
/// Supports parent-child relationships for scene graph hierarchy
pub const SceneGraphNode = struct {
    // Transform and animation
    base_transform: zlm.Mat4,  // Base transform (translation, scale, etc.)
    transform: zlm.Mat4,       // Final transform (base + animation)
    elapsed_time: f32,
    x_rotation_speed: f32,
    y_rotation_speed: f32,
    z_rotation_speed: f32,
    
    // Scene graph hierarchy
    parent: ?*SceneGraphNode,
    children: std.ArrayList(*SceneGraphNode),
    
    // Geometry reference (shared across multiple nodes)
    geometry: *Geometry,
    
    // Material reference (encapsulates shader program and uniforms)
    material: *Material,
    
    /// Initialize a new scene graph node with geometry and material
    pub fn init(allocator: std.mem.Allocator, geometry: *Geometry, material: *Material) !SceneGraphNode {
        std.debug.print("Initializing scene graph node...\n", .{});
        
        // Verify material is valid
        if (!material.isValid()) {
            std.debug.print("ERROR: Invalid material provided\n", .{});
            return error.InvalidMaterial;
        }
        
        std.debug.print("Scene graph node initialized successfully\n", .{});
        
        return SceneGraphNode{
            .base_transform = zlm.Mat4.identity,
            .transform = zlm.Mat4.identity,
            .elapsed_time = 0.0,
            .x_rotation_speed = 1.0,   // radians per second
            .y_rotation_speed = 1.5,   // slightly faster
            .z_rotation_speed = 0.7,   // slower
            .parent = null,
            .children = std.ArrayList(*SceneGraphNode).init(allocator),
            .geometry = geometry,
            .material = material,
        };
    }
    
    /// Add a child node to this node
    pub fn addChild(self: *SceneGraphNode, child: *SceneGraphNode) !void {
        // Set this node as the child's parent
        child.parent = self;
        
        // Add child to this node's children list
        try self.children.append(child);
    }
    
    /// Remove a child node from this node
    pub fn removeChild(self: *SceneGraphNode, child: *SceneGraphNode) void {
        // Find and remove the child
        for (self.children.items, 0..) |item, i| {
            if (item == child) {
                _ = self.children.swapRemove(i);
                child.parent = null;
                break;
            }
        }
    }
    
    /// Get the world transform matrix (parent transform * local transform)
    pub fn getWorldTransform(self: *const SceneGraphNode) zlm.Mat4 {
        if (self.parent) |parent| {
            return parent.getWorldTransform().mul(self.transform);
        } else {
            return self.transform;
        }
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
        const rotation = rotation_x.mul(rotation_y.mul(rotation_z));
        
        // Apply rotation to the base transform
        self.transform = self.base_transform.mul(rotation);
        
        // Update all children
        for (self.children.items) |child| {
            child.update(delta_time);
        }
    }
    
    /// Render the node with the given camera (recursive - renders this node and all children)
    pub fn render(self: *const SceneGraphNode, camera: *const Camera) void {
        // Render this node
        self.renderNode(camera);
        
        // Render all children recursively
        for (self.children.items) |child| {
            child.render(camera);
        }
    }
    
    /// Render just this node (not recursive)
    pub fn renderNode(self: *const SceneGraphNode, camera: *const Camera) void {
        // Bind the material (activates shader program)
        self.material.bind();
        
        // Get view and projection matrices from camera
        const view = camera.getViewMatrix();
        const projection = camera.getProjectionMatrix();
        
        // Get uniform locations for MVP matrices (these are scene/camera data, not material properties)
        const model_location = gl.glGetUniformLocation(self.material.getProgram(), "model");
        const view_location = gl.glGetUniformLocation(self.material.getProgram(), "view");
        const projection_location = gl.glGetUniformLocation(self.material.getProgram(), "projection");
        
        // Use world transform (parent transform * local transform)
        const world_transform = self.getWorldTransform();
        
        // Set MVP matrices (scene/camera/transform data)
        if (model_location != -1) {
            gl.glUniformMatrix4fv(model_location, 1, gl.GL_FALSE, @ptrCast(&world_transform.fields));
        }
        if (view_location != -1) {
            gl.glUniformMatrix4fv(view_location, 1, gl.GL_FALSE, @ptrCast(&view.fields));
        }
        if (projection_location != -1) {
            gl.glUniformMatrix4fv(projection_location, 1, gl.GL_FALSE, @ptrCast(&projection.fields));
        }
        
        // Render the geometry
        self.geometry.render();
    }
    
    /// Set the node's base transform (translation, scale, etc.)
    pub fn setTransform(self: *SceneGraphNode, transform: zlm.Mat4) void {
        self.base_transform = transform;
        self.transform = transform; // Initialize final transform with base
    }
    
    /// Get the node's current transform
    pub fn getTransform(self: *const SceneGraphNode) zlm.Mat4 {
        return self.transform;
    }
    
    
    /// Clean up OpenGL resources
    pub fn deinit(self: *SceneGraphNode) void {
        std.debug.print("Cleaning up scene graph node resources...\n", .{});
        
        // Clean up all children
        for (self.children.items) |child| {
            child.deinit();
        }
        self.children.deinit();
        
        // Note: We don't deinit geometry or material here as they may be shared
        // The caller is responsible for managing material and geometry lifecycle
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
    
    // Create a mock material for testing
    var material = Material{
        .program = 1, // Non-zero to pass isValid()
    };
    
    // Create a mock node for testing (without OpenGL initialization)
    var node = SceneGraphNode{
        .base_transform = zlm.Mat4.identity,
        .transform = zlm.Mat4.identity,
        .elapsed_time = 0.0,
        .x_rotation_speed = 1.0,
        .y_rotation_speed = 1.5,
        .z_rotation_speed = 0.7,
        .parent = null,
        .children = std.ArrayList(*SceneGraphNode).init(std.testing.allocator),
        .geometry = &geometry,
        .material = &material,
    };
    defer node.children.deinit();
    defer node.children.deinit();
    
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
    
    // Create a mock material for testing
    var material = Material{
        .program = 1, // Non-zero to pass isValid()
    };
    
    var node = SceneGraphNode{
        .transform = zlm.Mat4.identity,
        .elapsed_time = 0.0,
        .x_rotation_speed = 2.0,
        .y_rotation_speed = 1.0,
        .z_rotation_speed = 0.5,
        .parent = null,
        .children = std.ArrayList(*SceneGraphNode).init(std.testing.allocator),
        .geometry = &geometry,
        .material = &material,
    };
    defer node.children.deinit();
    
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
    
    // Create a mock material for testing
    var material = Material{
        .program = 1, // Non-zero to pass isValid()
    };
    
    var node = SceneGraphNode{
        .transform = zlm.Mat4.identity,
        .elapsed_time = 0.0,
        .x_rotation_speed = 1.0,
        .y_rotation_speed = 1.0,
        .z_rotation_speed = 1.0,
        .parent = null,
        .children = std.ArrayList(*SceneGraphNode).init(std.testing.allocator),
        .geometry = &geometry,
        .material = &material,
    };
    defer node.children.deinit();
    
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
    
    // Create a mock material for testing
    var material = Material{
        .program = 1, // Non-zero to pass isValid()
    };
    
    var node = SceneGraphNode{
        .transform = zlm.Mat4.identity,
        .elapsed_time = 0.0,
        .x_rotation_speed = 2.0,
        .y_rotation_speed = 1.0,
        .z_rotation_speed = 0.5,
        .parent = null,
        .children = std.ArrayList(*SceneGraphNode).init(std.testing.allocator),
        .geometry = &geometry,
        .material = &material,
    };
    defer node.children.deinit();
    
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

