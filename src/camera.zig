const std = @import("std");
const zlm = @import("zlm").as(f32);

pub const Camera = struct {
    // Camera position in world space
    position: zlm.Vec3,
    
    // LUR frame (camera-relative coordinate system)
    look: zlm.Vec3,    // Forward direction (camera's -Z axis)
    up: zlm.Vec3,      // Up direction (camera's +Y axis)  
    right: zlm.Vec3,   // Right direction (camera's +X axis)
    
    // Perspective projection parameters
    fov_degrees: f32,
    aspect_ratio: f32,
    near_plane: f32,
    far_plane: f32,
    
    /// Initialize a camera with position and LUR frame vectors
    pub fn init(position: zlm.Vec3, look: zlm.Vec3, up: zlm.Vec3, fov_degrees: f32, aspect_ratio: f32, near_plane: f32, far_plane: f32) Camera {
        // Normalize the input vectors
        const normalized_look = look.normalize();
        const normalized_up = up.normalize();
        
        // Calculate right vector: look cross up
        const right = normalized_look.cross(normalized_up).normalize();
        
        // Recalculate up vector: right cross look (ensure orthogonality)
        const corrected_up = right.cross(normalized_look).normalize();
        
        return Camera{
            .position = position,
            .look = normalized_look,
            .up = corrected_up,
            .right = right,
            .fov_degrees = fov_degrees,
            .aspect_ratio = aspect_ratio,
            .near_plane = near_plane,
            .far_plane = far_plane,
        };
    }
    
    /// Create a default camera at (10, 0, 0) with LUR frame looking towards origin
    pub fn default() Camera {
        // Calculate look direction from position to origin
        const position = zlm.Vec3.new(3.0, 0.0, 0.0);
        const origin = zlm.Vec3.new(0.0, 0.0, 0.0);
        const look_direction = origin.sub(position).normalize();
        
        // Use init to properly calculate the LUR frame
        return Camera.init(
            position,
            look_direction,
            zlm.Vec3.new(0.0, 0.0, 1.0), // Z-up coordinate system
            60.0, // 60 degree field of view
            16.0 / 9.0, // 16:9 aspect ratio
           0.1, // Near clipping plane
           100.0 // Far clipping plane
        );
    }
    
    /// Generate the view matrix - start with identity for debugging
    pub fn getViewMatrix(_: *const Camera) zlm.Mat4 {
        // Start with identity matrix to isolate the issue
        return zlm.Mat4.identity;
    }
    
    /// Generate a simple orthographic projection matrix for debugging
    pub fn getProjectionMatrix(_: *const Camera) zlm.Mat4 {
        // Simple orthographic projection: scale down the triangle to fit in [-1,1] range
        const scale = 0.5; // Make triangle smaller
        return zlm.Mat4{
            .fields = [4][4]f32{
                [4]f32{ scale, 0.0, 0.0, 0.0 },
                [4]f32{ 0.0, scale, 0.0, 0.0 },
                [4]f32{ 0.0, 0.0, 1.0, 0.0 },
                [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            },
        };
    }
    
    /// Get the combined MVP matrix (Model-View-Projection)
    pub fn getMVPMatrix(self: *const Camera, model_matrix: zlm.Mat4) zlm.Mat4 {
        const view_matrix = self.getViewMatrix();
        const projection_matrix = self.getProjectionMatrix();
        
        // MVP = Projection * View * Model
        return projection_matrix.mul(view_matrix).mul(model_matrix);
    }
    
    /// Get just the view matrix for debugging (no projection)
    pub fn getViewOnlyMatrix(self: *const Camera, model_matrix: zlm.Mat4) zlm.Mat4 {
        const view_matrix = self.getViewMatrix();
        
        // Correct order: View * Model
        // This transforms from model space -> world space -> view space
        return view_matrix.mul(model_matrix);
    }
    
    /// Set camera position
    pub fn setPosition(self: *Camera, position: zlm.Vec3) void {
        self.position = position;
    }
    
    /// Set camera look direction (camera-relative)
    pub fn setLook(self: *Camera, look: zlm.Vec3) void {
        self.look = look.normalize();
        // Recalculate right vector
        self.right = self.look.cross(self.up).normalize();
        // Recalculate up vector for orthogonality
        self.up = self.right.cross(self.look).normalize();
    }
    
    /// Set up vector (camera-relative)
    pub fn setUp(self: *Camera, up: zlm.Vec3) void {
        self.up = up.normalize();
        // Recalculate right vector
        self.right = self.look.cross(self.up).normalize();
        // Recalculate up vector for orthogonality
        self.up = self.right.cross(self.look).normalize();
    }
    
    /// Set aspect ratio based on window dimensions
    pub fn setAspectRatio(self: *Camera, width: f32, height: f32) void {
        self.aspect_ratio = width / height;
    }
};
