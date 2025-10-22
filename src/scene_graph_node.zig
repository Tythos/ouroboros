const std = @import("std");
const zlm = @import("zlm").as(f32);
const gl = @import("gl.zig");
const Camera = @import("camera.zig").Camera;
const Geometry = @import("geometry.zig").Geometry;
const Material = @import("material.zig").Material;

/// Quaternion type for GLTF-compatible rotations
/// Represents rotation as (x, y, z, w) where w is the scalar component
pub const Quat = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,
    
    /// Identity quaternion (no rotation)
    pub const identity = Quat{ .x = 0.0, .y = 0.0, .z = 0.0, .w = 1.0 };
    
    /// Create a quaternion from axis and angle (angle in radians)
    pub fn fromAxisAngle(axis: zlm.Vec3, angle: f32) Quat {
        const normalized = axis.normalize();
        const half_angle = angle * 0.5;
        const s = @sin(half_angle);
        return Quat{
            .x = normalized.x * s,
            .y = normalized.y * s,
            .z = normalized.z * s,
            .w = @cos(half_angle),
        };
    }
    
    /// Convert quaternion to 4x4 rotation matrix
    pub fn toMat4(self: Quat) zlm.Mat4 {
        const xx = self.x * self.x;
        const yy = self.y * self.y;
        const zz = self.z * self.z;
        const xy = self.x * self.y;
        const xz = self.x * self.z;
        const yz = self.y * self.z;
        const wx = self.w * self.x;
        const wy = self.w * self.y;
        const wz = self.w * self.z;
        
        return zlm.Mat4{
            .fields = [4][4]f32{
                [4]f32{ 1.0 - 2.0 * (yy + zz), 2.0 * (xy + wz), 2.0 * (xz - wy), 0.0 },
                [4]f32{ 2.0 * (xy - wz), 1.0 - 2.0 * (xx + zz), 2.0 * (yz + wx), 0.0 },
                [4]f32{ 2.0 * (xz + wy), 2.0 * (yz - wx), 1.0 - 2.0 * (xx + yy), 0.0 },
                [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            },
        };
    }
    
    /// Multiply two quaternions (combine rotations)
    pub fn mul(self: Quat, other: Quat) Quat {
        return Quat{
            .x = self.w * other.x + self.x * other.w + self.y * other.z - self.z * other.y,
            .y = self.w * other.y - self.x * other.z + self.y * other.w + self.z * other.x,
            .z = self.w * other.z + self.x * other.y - self.y * other.x + self.z * other.w,
            .w = self.w * other.w - self.x * other.x - self.y * other.y - self.z * other.z,
        };
    }
    
    /// Normalize the quaternion
    pub fn normalize(self: Quat) Quat {
        const len = @sqrt(self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w);
        if (len == 0.0) return identity;
        return Quat{
            .x = self.x / len,
            .y = self.y / len,
            .z = self.z / len,
            .w = self.w / len,
        };
    }
};

/// Transform representation type
pub const TransformType = enum {
    /// Transform stored as TRS (Translation-Rotation-Scale) components
    TRS,
    /// Transform stored as a 4x4 matrix
    Matrix,
};

/// SceneGraphNode represents a node in the scene graph hierarchy
/// GLTF-compatible design: supports both TRS and matrix representations
/// References geometry and material, owns transform state
/// Supports parent-child relationships for scene graph hierarchy
pub const SceneGraphNode = struct {
    // GLTF-compatible transform representation
    transform_type: TransformType,
    
    // Matrix representation (used when transform_type == Matrix)
    matrix: zlm.Mat4,
    
    // TRS representation (used when transform_type == TRS)
    translation: zlm.Vec3,
    rotation: Quat,
    scale: zlm.Vec3,
    
    // Animation state (separate from static transform)
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
    /// Defaults to TRS representation with identity transform
    pub fn init(allocator: std.mem.Allocator, geometry: *Geometry, material: *Material) !SceneGraphNode {
        std.debug.print("Initializing scene graph node...\n", .{});
        
        // Verify material is valid
        if (!material.isValid()) {
            std.debug.print("ERROR: Invalid material provided\n", .{});
            return error.InvalidMaterial;
        }
        
        std.debug.print("Scene graph node initialized successfully\n", .{});
        
        return SceneGraphNode{
            .transform_type = .TRS,
            .matrix = zlm.Mat4.identity,
            .translation = zlm.Vec3.zero,
            .rotation = Quat.identity,
            .scale = zlm.Vec3.one,
            .elapsed_time = 0.0,
            .x_rotation_speed = 0.0,
            .y_rotation_speed = 0.0,
            .z_rotation_speed = 0.0,
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
    
    /// Get the local transform matrix (computed from TRS or using matrix directly)
    pub fn getLocalTransform(self: *const SceneGraphNode) zlm.Mat4 {
        return switch (self.transform_type) {
            .Matrix => self.matrix,
            .TRS => blk: {
                // Build transform: T * R * S (Translation * Rotation * Scale)
                const scale_mat = zlm.Mat4.createScale(self.scale.x, self.scale.y, self.scale.z);
                const rotation_mat = self.rotation.toMat4();
                const translation_mat = zlm.Mat4.createTranslation(self.translation);
                
                // For row-major matrices: M = S * R * T
                break :blk scale_mat.mul(rotation_mat).mul(translation_mat);
            },
        };
    }
    
    /// Get the world transform matrix
    /// For row-major matrices: v' = v * (child_local * parent_world)
    /// This applies child's local transform first, then parent's transform
    pub fn getWorldTransform(self: *const SceneGraphNode) zlm.Mat4 {
        const local = self.getLocalTransform();
        if (self.parent) |parent| {
            return local.mul(parent.getWorldTransform());
        } else {
            return local;
        }
    }
    
    /// Update the node's animation based on elapsed time
    /// For TRS nodes: updates rotation quaternion based on animation speeds
    /// For Matrix nodes: animation is not supported (matrix is static)
    pub fn update(self: *SceneGraphNode, delta_time: f32) void {
        self.elapsed_time += delta_time;
        
        // Only update rotation for TRS representation with animation
        if (self.transform_type == .TRS) {
            const has_rotation = self.x_rotation_speed != 0.0 or 
                                 self.y_rotation_speed != 0.0 or 
                                 self.z_rotation_speed != 0.0;
            
            if (has_rotation) {
                // Calculate rotation angles from animation speeds
                const angle_x = self.elapsed_time * self.x_rotation_speed;
                const angle_y = self.elapsed_time * self.y_rotation_speed;
                const angle_z = self.elapsed_time * self.z_rotation_speed;
                
                const x_axis = zlm.Vec3.new(1.0, 0.0, 0.0);
                const y_axis = zlm.Vec3.new(0.0, 1.0, 0.0);
                const z_axis = zlm.Vec3.new(0.0, 0.0, 1.0);
                
                // Build quaternions for each axis rotation
                const quat_x = Quat.fromAxisAngle(x_axis, angle_x);
                const quat_y = Quat.fromAxisAngle(y_axis, angle_y);
                const quat_z = Quat.fromAxisAngle(z_axis, angle_z);
                
                // Combine rotations: Z, then Y, then X
                self.rotation = quat_x.mul(quat_y.mul(quat_z)).normalize();
            }
        }
        
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
    
    /// Set the node's position (TRS mode only)
    pub fn setPosition(self: *SceneGraphNode, position: zlm.Vec3) void {
        self.translation = position;
    }
    
    /// Set the node's scale (TRS mode only)
    pub fn setScale(self: *SceneGraphNode, scale: zlm.Vec3) void {
        self.scale = scale;
    }
    
    /// Set the node's rotation from a quaternion (TRS mode only)
    pub fn setRotation(self: *SceneGraphNode, rotation: Quat) void {
        self.rotation = rotation;
    }
    
    /// Set the node's transform using a matrix
    /// Switches to Matrix mode
    pub fn setTransformMatrix(self: *SceneGraphNode, matrix: zlm.Mat4) void {
        self.transform_type = .Matrix;
        self.matrix = matrix;
    }
    
    /// Get the current local transform matrix (computed on-demand)
    pub fn getTransform(self: *const SceneGraphNode) zlm.Mat4 {
        return self.getLocalTransform();
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
        .transform_type = .TRS,
        .matrix = zlm.Mat4.identity,
        .translation = zlm.Vec3.zero,
        .rotation = Quat.identity,
        .scale = zlm.Vec3.one,
        .elapsed_time = 0.0,
        .x_rotation_speed = 0.0,
        .y_rotation_speed = 0.0,
        .z_rotation_speed = 0.0,
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
    try std.testing.expectApproxEqAbs(@as(f32, 1.0), node.translation.x, 1e-6);
    try std.testing.expectApproxEqAbs(@as(f32, 2.0), node.translation.y, 1e-6);
    try std.testing.expectApproxEqAbs(@as(f32, 3.0), node.translation.z, 1e-6);
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
        .transform_type = .TRS,
        .matrix = zlm.Mat4.identity,
        .translation = zlm.Vec3.zero,
        .rotation = Quat.identity,
        .scale = zlm.Vec3.one,
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

test "SceneGraphNode quaternion rotation" {
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
        .transform_type = .TRS,
        .matrix = zlm.Mat4.identity,
        .translation = zlm.Vec3.zero,
        .rotation = Quat.identity,
        .scale = zlm.Vec3.one,
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
    
    // The rotation quaternion should have been updated
    // We can verify it produces a reasonable transform
    const transform = node.getLocalTransform();
    
    // Verify it's not identity (some rotation occurred)
    const is_identity = test_utils.mat4ApproxEqual(transform, zlm.Mat4.identity, 1e-6);
    try std.testing.expect(!is_identity);
}

test "SceneGraphNode GLTF compatibility" {
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
    
    // Test TRS mode (default, GLTF-compatible)
    var trs_node = SceneGraphNode{
        .transform_type = .TRS,
        .matrix = zlm.Mat4.identity,
        .translation = zlm.Vec3.new(1.0, 2.0, 3.0),
        .rotation = Quat.identity,
        .scale = zlm.Vec3.new(2.0, 2.0, 2.0),
        .elapsed_time = 0.0,
        .x_rotation_speed = 0.0,
        .y_rotation_speed = 0.0,
        .z_rotation_speed = 0.0,
        .parent = null,
        .children = std.ArrayList(*SceneGraphNode).init(std.testing.allocator),
        .geometry = &geometry,
        .material = &material,
    };
    defer trs_node.children.deinit();
    
    // Verify TRS mode computes correct transform
    const trs_transform = trs_node.getLocalTransform();
    try std.testing.expect(trs_transform.fields[3][0] == 1.0); // Translation X
    try std.testing.expect(trs_transform.fields[3][1] == 2.0); // Translation Y
    try std.testing.expect(trs_transform.fields[3][2] == 3.0); // Translation Z
    
    // Test Matrix mode (also GLTF-compatible)
    const test_matrix = zlm.Mat4.createTranslation(zlm.Vec3.new(5.0, 6.0, 7.0));
    var matrix_node = SceneGraphNode{
        .transform_type = .Matrix,
        .matrix = test_matrix,
        .translation = zlm.Vec3.zero,
        .rotation = Quat.identity,
        .scale = zlm.Vec3.one,
        .elapsed_time = 0.0,
        .x_rotation_speed = 0.0,
        .y_rotation_speed = 0.0,
        .z_rotation_speed = 0.0,
        .parent = null,
        .children = std.ArrayList(*SceneGraphNode).init(std.testing.allocator),
        .geometry = &geometry,
        .material = &material,
    };
    defer matrix_node.children.deinit();
    
    // Verify Matrix mode returns the matrix directly
    const matrix_transform = matrix_node.getLocalTransform();
    try test_utils.expectMat4EqualDefault(matrix_transform, test_matrix);
}
