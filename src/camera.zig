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
    
    /// Create a default camera at (7, 5, 3) with LUR frame looking towards origin
    pub fn default() Camera {
        // Calculate look direction from position to origin
        const position = zlm.Vec3.new(7.0, 5.0, 3.0);
        const origin = zlm.Vec3.new(0.0, 0.0, 0.0);
        const look_direction = origin.sub(position).normalize();
        
        return Camera{
            .position = position,
            .look = look_direction, // Look towards origin
            .up = zlm.Vec3.new(0.0, 1.0, 0.0), // Y-up coordinate system
            .right = zlm.Vec3.new(1.0, 0.0, 0.0), // Will be recalculated in init
            .fov_degrees = 60.0, // 60 degree field of view
            .aspect_ratio = 16.0 / 9.0, // 16:9 aspect ratio
            .near_plane = 0.1, // Near clipping plane
            .far_plane = 100.0, // Far clipping plane
        };
    }
    
    /// Generate the view matrix using the LUR frame
    pub fn getViewMatrix(self: *const Camera) zlm.Mat4 {
        // Create the view matrix using the camera's LUR frame
        // This transforms world coordinates to camera/view coordinates
        const view_matrix = zlm.Mat4{
            .fields = [4][4]f32{
                [4]f32{ self.right.x, self.right.y, self.right.z, 0.0 },
                [4]f32{ self.up.x, self.up.y, self.up.z, 0.0 },
                [4]f32{ -self.look.x, -self.look.y, -self.look.z, 0.0 },
                [4]f32{ 0.0, 0.0, 0.0, 1.0 },
            },
        };
        
        // Translate by negative position
        const translation = zlm.Mat4.createTranslationXYZ(-self.position.x, -self.position.y, -self.position.z);
        
        return view_matrix.mul(translation);
    }
    
    /// Generate the perspective projection matrix
    pub fn getProjectionMatrix(self: *const Camera) zlm.Mat4 {
        const fov_radians = self.fov_degrees * std.math.pi / 180.0;
        const tan_half_fov = @tan(fov_radians / 2.0);
        
        // Calculate the projection matrix components
        const f = 1.0 / tan_half_fov;
        const aspect = self.aspect_ratio;
        const near = self.near_plane;
        const far = self.far_plane;
        
        // Perspective projection matrix (OpenGL-style)
        return zlm.Mat4{
            .fields = [4][4]f32{
                [4]f32{ f / aspect, 0.0, 0.0, 0.0 },
                [4]f32{ 0.0, f, 0.0, 0.0 },
                [4]f32{ 0.0, 0.0, (far + near) / (near - far), (2.0 * far * near) / (near - far) },
                [4]f32{ 0.0, 0.0, -1.0, 0.0 },
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
        
        // Just View * Model (no projection)
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
