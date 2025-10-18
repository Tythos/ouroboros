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
    // Transform (single 4x4 matrix representing this node's local transform)
    transform: zlm.Mat4,
    
    // Animation state
    elapsed_time: f32,
    x_rotation_speed: f32,
    y_rotation_speed: f32,
    z_rotation_speed: f32,
    
    // Static transform components (used to rebuild transform with animation)
    position: zlm.Vec3,
    scale: zlm.Vec3,
    
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
            .transform = zlm.Mat4.identity,
            .elapsed_time = 0.0,
            .x_rotation_speed = 0.0,
            .y_rotation_speed = 0.0,
            .z_rotation_speed = 0.0,
            .position = zlm.Vec3.zero,
            .scale = zlm.Vec3.one,
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
    
    /// Get the world transform matrix
    /// For row-major matrices: v' = v * (child_local * parent_world)
    /// This applies child's local transform first, then parent's transform
    pub fn getWorldTransform(self: *const SceneGraphNode) zlm.Mat4 {
        if (self.parent) |parent| {
            return self.transform.mul(parent.getWorldTransform());
        } else {
            return self.transform;
        }
    }
    
    /// Update the node's animation based on elapsed time
    /// Rebuilds the local transform from position, rotation, and scale
    pub fn update(self: *SceneGraphNode, delta_time: f32) void {
        self.elapsed_time += delta_time;
        
        // Build transform: Scale * Rotation * Translation
        // Standard TRS (Translation-Rotation-Scale) order
        
        // 1. Create scale matrix
        const scale_matrix = zlm.Mat4.createScale(self.scale.x, self.scale.y, self.scale.z);
        
        // 2. Create rotation matrix from animation
        const has_rotation = self.x_rotation_speed != 0.0 or self.y_rotation_speed != 0.0 or self.z_rotation_speed != 0.0;
        
        const rotation_matrix = if (has_rotation) blk: {
            const angle_x = self.elapsed_time * self.x_rotation_speed;
            const angle_y = self.elapsed_time * self.y_rotation_speed;
            const angle_z = self.elapsed_time * self.z_rotation_speed;
            
            const x_axis = zlm.Vec3.new(1.0, 0.0, 0.0);
            const y_axis = zlm.Vec3.new(0.0, 1.0, 0.0);
            const z_axis = zlm.Vec3.new(0.0, 0.0, 1.0);
            
            const rotation_x = zlm.Mat4.createAngleAxis(x_axis, angle_x);
            const rotation_y = zlm.Mat4.createAngleAxis(y_axis, angle_y);
            const rotation_z = zlm.Mat4.createAngleAxis(z_axis, angle_z);
            
            // Combine rotations: Z, then Y, then X
            break :blk rotation_x.mul(rotation_y.mul(rotation_z));
        } else zlm.Mat4.identity;
        
        // 3. Create translation matrix
        const translation_matrix = zlm.Mat4.createTranslation(self.position);
        
        // 4. Combine in SRT order (for row-major matrices with row vectors)
        // zlm uses row-major: v' = v * M, so v' = v * (S * R * T)
        // This applies scale first, then rotate (around local origin), then translate to position
        const temp = scale_matrix.mul(rotation_matrix);
        self.transform = temp.mul(translation_matrix);
        
        // Update all children recursively
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
    
    /// Set the node's position
    pub fn setPosition(self: *SceneGraphNode, position: zlm.Vec3) void {
        self.position = position;
    }
    
    /// Set the node's scale
    pub fn setScale(self: *SceneGraphNode, scale: zlm.Vec3) void {
        self.scale = scale;
    }
    
    /// Set the node's transform from a matrix (extracts position and scale)
    /// Note: This is a convenience method, prefer setting position/scale directly
    pub fn setTransform(self: *SceneGraphNode, transform: zlm.Mat4) void {
        // Extract translation from matrix
        self.position = zlm.Vec3.new(
            transform.fields[3][0],
            transform.fields[3][1],
            transform.fields[3][2],
        );
        
        // Extract scale from matrix (length of basis vectors)
        const scale_x = @sqrt(transform.fields[0][0] * transform.fields[0][0] + 
                              transform.fields[0][1] * transform.fields[0][1] + 
                              transform.fields[0][2] * transform.fields[0][2]);
        const scale_y = @sqrt(transform.fields[1][0] * transform.fields[1][0] + 
                              transform.fields[1][1] * transform.fields[1][1] + 
                              transform.fields[1][2] * transform.fields[1][2]);
        const scale_z = @sqrt(transform.fields[2][0] * transform.fields[2][0] + 
                              transform.fields[2][1] * transform.fields[2][1] + 
                              transform.fields[2][2] * transform.fields[2][2]);
        
        self.scale = zlm.Vec3.new(scale_x, scale_y, scale_z);
        
        // Rebuild transform
        self.transform = transform;
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
        .transform = zlm.Mat4.identity,
        .elapsed_time = 0.0,
        .x_rotation_speed = 0.0,
        .y_rotation_speed = 0.0,
        .z_rotation_speed = 0.0,
        .position = zlm.Vec3.zero,
        .scale = zlm.Vec3.one,
        .parent = null,
        .children = std.ArrayList(*SceneGraphNode).init(std.testing.allocator),
        .geometry = &geometry,
        .material = &material,
    };
    defer node.children.deinit();
    
    // Test initial state
    try test_utils.expectMat4IdentityDefault(node.getTransform());
    
    // Test position setting
    node.setPosition(zlm.Vec3.new(1.0, 2.0, 3.0));
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), node.position.x, 1e-6);
    try std.testing.expectApproxEqAbs(@as(f32, 2.0), node.position.y, 1e-6);
    try std.testing.expectApproxEqAbs(@as(f32, 3.0), node.position.z, 1e-6);
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
        .position = zlm.Vec3.zero,
        .scale = zlm.Vec3.one,
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
        .position = zlm.Vec3.zero,
        .scale = zlm.Vec3.one,
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
    // With identity translation and scale, transform should equal rotation
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
        .position = zlm.Vec3.zero,
        .scale = zlm.Vec3.one,
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

