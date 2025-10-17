const std = @import("std");
const zlm = @import("zlm").as(f32);

// Export zlm for convenience
pub const Vec3 = zlm.Vec3;
pub const Mat4 = zlm.Mat4;

/// Camera represents a viewpoint in 3D space with projection properties.
/// Uses a Look/Up/Right (LUR) frame for explicit camera orientation.
pub const Camera = struct {
    // View transform properties
    position: zlm.Vec3,
    look: zlm.Vec3,      // Camera-relative forward direction (normalized)
    up: zlm.Vec3,        // Camera-relative up direction (normalized)
    right: zlm.Vec3,     // Camera-relative right direction (normalized)
    
    // Projection properties
    fov: f32,        // Field of view in radians
    aspect: f32,     // Aspect ratio (width / height)
    near: f32,       // Near clipping plane
    far: f32,        // Far clipping plane
    
    /// Initialize a new perspective camera with explicit LUR frame
    pub fn init(position: zlm.Vec3, look: zlm.Vec3, up: zlm.Vec3, fov: f32, aspect: f32, near: f32, far: f32) Camera {
        // Normalize the look and up vectors
        const look_norm = look.normalize();
        const up_norm = up.normalize();
        
        // Compute right as cross product of look and up
        const right_norm = look_norm.cross(up_norm).normalize();
        
        // Recompute up to ensure orthogonality (right cross look)
        const up_ortho = right_norm.cross(look_norm).normalize();
        
        return Camera{
            .position = position,
            .look = look_norm,
            .up = up_ortho,
            .right = right_norm,
            .fov = fov,
            .aspect = aspect,
            .near = near,
            .far = far,
        };
    }
    
    /// Create a default camera positioned back from the origin, looking forward
    pub fn initDefault(aspect: f32) Camera {
        return init(
            zlm.Vec3.new(0.0, 0.0, 3.0),     // Position: 3 units back on Z
            zlm.Vec3.new(0.0, 0.0, -1.0),    // Look: forward along -Z (into screen)
            zlm.Vec3.new(0.0, 1.0, 0.0),     // Up: +Y
            std.math.degreesToRadians(45.0), // FOV: 45 degrees
            aspect,
            0.1,                              // Near: 0.1 units
            100.0,                            // Far: 100 units
        );
    }
    
    /// Initialize from a target point (convenience method)
    pub fn initLookAt(position: zlm.Vec3, target: zlm.Vec3, up: zlm.Vec3, fov: f32, aspect: f32, near: f32, far: f32) Camera {
        const look = target.sub(position).normalize();
        return init(position, look, up, fov, aspect, near, far);
    }
    
    /// Get the view matrix (world-space to camera-space transform)
    /// Uses zlm's createLook function which constructs from position, direction, and up
    pub fn getViewMatrix(self: *const Camera) zlm.Mat4 {
        // Use zlm's proven implementation
        // createLook takes: eye position, look direction, up vector
        return zlm.Mat4.createLook(self.position, self.look, self.up);
    }
    
    /// Get the projection matrix (camera-space to clip-space transform)
    /// Uses perspective projection with the camera's FOV and clipping planes
    pub fn getProjectionMatrix(self: *const Camera) zlm.Mat4 {
        return zlm.Mat4.createPerspective(self.fov, self.aspect, self.near, self.far);
    }
    
    /// Update the aspect ratio (useful for handling window resize)
    pub fn setAspectRatio(self: *Camera, aspect: f32) void {
        self.aspect = aspect;
    }
    
    /// Set the camera position
    pub fn setPosition(self: *Camera, position: zlm.Vec3) void {
        self.position = position;
    }
    
    /// Set the camera orientation by looking at a target point
    pub fn lookAt(self: *Camera, target: zlm.Vec3) void {
        const new_look = target.sub(self.position).normalize();
        const new_right = new_look.cross(self.up).normalize();
        const new_up = new_right.cross(new_look).normalize();
        
        self.look = new_look;
        self.right = new_right;
        self.up = new_up;
    }
    
    /// Set the look direction directly (will recompute right and up)
    pub fn setLook(self: *Camera, look: zlm.Vec3) void {
        const look_norm = look.normalize();
        const right_norm = look_norm.cross(self.up).normalize();
        const up_norm = right_norm.cross(look_norm).normalize();
        
        self.look = look_norm;
        self.right = right_norm;
        self.up = up_norm;
    }
    
    /// Rotate the camera frame around an arbitrary axis
    pub fn rotate(self: *Camera, axis: zlm.Vec3, angle: f32) void {
        const rotation = zlm.Mat4.createAngleAxis(axis.normalize(), angle);
        
        // Rotate each frame vector
        self.look = rotation.mulByVec4(zlm.Vec4.new(self.look.x, self.look.y, self.look.z, 0.0)).toVec3().normalize();
        self.up = rotation.mulByVec4(zlm.Vec4.new(self.up.x, self.up.y, self.up.z, 0.0)).toVec3().normalize();
        self.right = rotation.mulByVec4(zlm.Vec4.new(self.right.x, self.right.y, self.right.z, 0.0)).toVec3().normalize();
    }
};

// ============================================================================
// Unit Tests
// ============================================================================

test "Camera LUR frame orthonormality" {
    const aspect: f32 = 16.0 / 9.0;
    const camera = Camera.initDefault(aspect);
    
    // Test that all frame vectors are normalized
    const look_len = camera.look.length();
    const up_len = camera.up.length();
    const right_len = camera.right.length();
    
    try std.testing.expectApproxEqAbs(1.0, look_len, 0.0001);
    try std.testing.expectApproxEqAbs(1.0, up_len, 0.0001);
    try std.testing.expectApproxEqAbs(1.0, right_len, 0.0001);
    
    // Test that frame vectors are orthogonal (dot product = 0)
    const look_dot_up = camera.look.dot(camera.up);
    const look_dot_right = camera.look.dot(camera.right);
    const up_dot_right = camera.up.dot(camera.right);
    
    try std.testing.expectApproxEqAbs(0.0, look_dot_up, 0.0001);
    try std.testing.expectApproxEqAbs(0.0, look_dot_right, 0.0001);
    try std.testing.expectApproxEqAbs(0.0, up_dot_right, 0.0001);
}

test "Camera LUR frame handedness" {
    const aspect: f32 = 1.0;
    const camera = Camera.initDefault(aspect);
    
    // Verify right-handed coordinate system: right = look × up
    const computed_right = camera.look.cross(camera.up);
    
    try std.testing.expectApproxEqAbs(camera.right.x, computed_right.x, 0.0001);
    try std.testing.expectApproxEqAbs(camera.right.y, computed_right.y, 0.0001);
    try std.testing.expectApproxEqAbs(camera.right.z, computed_right.z, 0.0001);
}

test "Camera initLookAt" {
    const aspect: f32 = 1.0;
    const position = zlm.Vec3.new(0.0, 0.0, 5.0);
    const target = zlm.Vec3.new(0.0, 0.0, 0.0);
    const up = zlm.Vec3.new(0.0, 1.0, 0.0);
    
    const camera = Camera.initLookAt(
        position,
        target,
        up,
        std.math.degreesToRadians(45.0),
        aspect,
        0.1,
        100.0,
    );
    
    // Camera should be looking along -Z (into the scene)
    const expected_look = zlm.Vec3.new(0.0, 0.0, -1.0);
    try std.testing.expectApproxEqAbs(expected_look.x, camera.look.x, 0.0001);
    try std.testing.expectApproxEqAbs(expected_look.y, camera.look.y, 0.0001);
    try std.testing.expectApproxEqAbs(expected_look.z, camera.look.z, 0.0001);
    
    // Up should remain +Y
    try std.testing.expectApproxEqAbs(0.0, camera.up.x, 0.0001);
    try std.testing.expectApproxEqAbs(1.0, camera.up.y, 0.0001);
    try std.testing.expectApproxEqAbs(0.0, camera.up.z, 0.0001);
    
    // Right should be +X
    try std.testing.expectApproxEqAbs(1.0, camera.right.x, 0.0001);
    try std.testing.expectApproxEqAbs(0.0, camera.right.y, 0.0001);
    try std.testing.expectApproxEqAbs(0.0, camera.right.z, 0.0001);
}

test "Camera view matrix identity at origin" {
    const aspect: f32 = 1.0;
    const position = zlm.Vec3.new(0.0, 0.0, 0.0);
    const look = zlm.Vec3.new(0.0, 0.0, -1.0);
    const up = zlm.Vec3.new(0.0, 1.0, 0.0);
    
    const camera = Camera.init(
        position,
        look,
        up,
        std.math.degreesToRadians(45.0),
        aspect,
        0.1,
        100.0,
    );
    
    const view = camera.getViewMatrix();
    
    // When camera is at origin looking down -Z with up as +Y,
    // view matrix should be close to identity (with Z flipped)
    // Top-left 3x3 should be rotation part (identity-like)
    try std.testing.expectApproxEqAbs(1.0, view.fields[0][0], 0.0001); // right.x
    try std.testing.expectApproxEqAbs(0.0, view.fields[0][1], 0.0001);
    try std.testing.expectApproxEqAbs(0.0, view.fields[0][2], 0.0001);
    
    try std.testing.expectApproxEqAbs(0.0, view.fields[1][0], 0.0001);
    try std.testing.expectApproxEqAbs(1.0, view.fields[1][1], 0.0001); // up.y
    try std.testing.expectApproxEqAbs(0.0, view.fields[1][2], 0.0001);
    
    try std.testing.expectApproxEqAbs(0.0, view.fields[2][0], 0.0001);
    try std.testing.expectApproxEqAbs(0.0, view.fields[2][1], 0.0001);
    try std.testing.expectApproxEqAbs(1.0, view.fields[2][2], 0.0001); // -look.z (flipped)
    
    // Translation should be zero
    try std.testing.expectApproxEqAbs(0.0, view.fields[3][0], 0.0001);
    try std.testing.expectApproxEqAbs(0.0, view.fields[3][1], 0.0001);
    try std.testing.expectApproxEqAbs(0.0, view.fields[3][2], 0.0001);
}

test "Camera projection matrix properties" {
    const aspect: f32 = 16.0 / 9.0;
    const camera = Camera.initDefault(aspect);
    
    const proj = camera.getProjectionMatrix();
    
    // Projection matrix should have specific structure for perspective
    // [0,0] relates to FOV and aspect
    // [1,1] relates to FOV
    // [2,2] and [2,3] relate to near/far clipping
    // [3,2] should be -1 for perspective divide
    
    // Just verify it's not identity and has the perspective structure
    try std.testing.expect(proj.fields[0][0] != 0.0);
    try std.testing.expect(proj.fields[1][1] != 0.0);
    try std.testing.expect(proj.fields[2][2] != 0.0);
    try std.testing.expectApproxEqAbs(-1.0, proj.fields[2][3], 0.0001);
}

test "Camera lookAt method" {
    const aspect: f32 = 1.0;
    var camera = Camera.initDefault(aspect);
    
    // Make camera look at a point to the right
    const target = zlm.Vec3.new(1.0, 0.0, 0.0);
    camera.lookAt(target);
    
    // Look direction should point toward +X
    const expected_look_dir = target.sub(camera.position).normalize();
    try std.testing.expectApproxEqAbs(expected_look_dir.x, camera.look.x, 0.0001);
    try std.testing.expectApproxEqAbs(expected_look_dir.y, camera.look.y, 0.0001);
    try std.testing.expectApproxEqAbs(expected_look_dir.z, camera.look.z, 0.0001);
    
    // Frame should still be orthonormal
    try std.testing.expectApproxEqAbs(0.0, camera.look.dot(camera.up), 0.0001);
    try std.testing.expectApproxEqAbs(0.0, camera.look.dot(camera.right), 0.0001);
    try std.testing.expectApproxEqAbs(0.0, camera.up.dot(camera.right), 0.0001);
}

test "Camera setLook maintains orthonormality" {
    const aspect: f32 = 1.0;
    var camera = Camera.initDefault(aspect);
    
    // Set a new look direction (diagonal)
    const new_look = zlm.Vec3.new(1.0, 1.0, 0.0);
    camera.setLook(new_look);
    
    // Verify orthonormality is maintained
    try std.testing.expectApproxEqAbs(1.0, camera.look.length(), 0.0001);
    try std.testing.expectApproxEqAbs(1.0, camera.up.length(), 0.0001);
    try std.testing.expectApproxEqAbs(1.0, camera.right.length(), 0.0001);
    
    try std.testing.expectApproxEqAbs(0.0, camera.look.dot(camera.up), 0.0001);
    try std.testing.expectApproxEqAbs(0.0, camera.look.dot(camera.right), 0.0001);
    try std.testing.expectApproxEqAbs(0.0, camera.up.dot(camera.right), 0.0001);
}

