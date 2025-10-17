const std = @import("std");
const zlm = @import("zlm").as(f32);
const test_utils = @import("test_utilities.zig");

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

test "Camera frame orthonormality" {
    const camera = Camera.initDefault(16.0 / 9.0);
    try test_utils.expectNormalizedDefault(camera.look);
    try test_utils.expectNormalizedDefault(camera.up);
    try test_utils.expectNormalizedDefault(camera.right);
    try test_utils.expectAllOrthogonalDefault(&[_]zlm.Vec3{ camera.look, camera.up, camera.right });
    try test_utils.expectRightHandedSystemDefault(camera.right, camera.up, camera.look);
}

test "Camera view matrix" {
    const camera = Camera.init(zlm.Vec3.new(2.0, 3.0, 4.0), zlm.Vec3.new(0.0, 0.0, -1.0), zlm.Vec3.new(0.0, 1.0, 0.0), std.math.degreesToRadians(45.0), 1.0, 0.1, 100.0);
    const view = camera.getViewMatrix();
    
    // Camera position should transform to origin
    const origin = view.mulVec3(camera.position);
    try test_utils.expectVec3EqualDefault(origin, zlm.Vec3.new(0.0, 0.0, 0.0));
}

test "Camera projection matrix" {
    const camera = Camera.initDefault(16.0 / 9.0);
    const proj = camera.getProjectionMatrix();
    
    // Test near/far plane clipping
    const near_point = zlm.Vec3.new(0.0, 0.0, -camera.near);
    const far_point = zlm.Vec3.new(0.0, 0.0, -camera.far);
    const near_clip = proj.mulVec3(near_point);
    const far_clip = proj.mulVec3(far_point);
    
    try std.testing.expectApproxEqAbs(-1.0, near_clip.z, 0.0001);
    try std.testing.expectApproxEqAbs(1.0, far_clip.z, 0.0001);
}

test "Camera operations maintain frame" {
    var camera = Camera.initDefault(1.0);
    
    // Test lookAt operation
    camera.lookAt(zlm.Vec3.new(1.0, 0.0, 0.0));
    try test_utils.expectAllOrthogonalDefault(&[_]zlm.Vec3{ camera.look, camera.up, camera.right });
    
    // Test rotation
    camera.rotate(zlm.Vec3.new(0.0, 1.0, 0.0), std.math.degreesToRadians(90.0));
    try test_utils.expectAllOrthogonalDefault(&[_]zlm.Vec3{ camera.look, camera.up, camera.right });
    try test_utils.expectRightHandedSystemDefault(camera.right, camera.up, camera.look);
}

