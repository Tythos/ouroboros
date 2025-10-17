const std = @import("std");
const Camera = @import("camera.zig").Camera;
const Vec3 = @import("camera.zig").Vec3;
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

/// OrbitController manages orbit camera behavior using spherical coordinates.
/// The camera orbits around a fixed target point (origin) and can be controlled
/// via mouse input for rotation and zoom.
pub const OrbitController = struct {
    // Orbit parameters (spherical coordinates)
    target: Vec3,           // Point being orbited (fixed at origin for now)
    distance: f32,          // Distance from target
    azimuth: f32,           // Horizontal angle in radians (around Z-axis)
    elevation: f32,         // Vertical angle in radians (from XY plane)
    
    // Input state
    is_rotating: bool,      // Is left mouse button held?
    last_mouse_x: i32,      // Last mouse X position
    last_mouse_y: i32,      // Last mouse Y position
    
    // Configuration
    rotation_sensitivity: f32,  // Radians per pixel
    zoom_sensitivity: f32,      // Distance units per scroll tick
    min_distance: f32,          // Minimum zoom distance
    max_distance: f32,          // Maximum zoom distance
    min_elevation: f32,         // Minimum elevation angle (radians)
    max_elevation: f32,         // Maximum elevation angle (radians)
    
    /// Initialize orbit controller with default settings
    pub fn init() OrbitController {
        return OrbitController{
            .target = Vec3.new(0.0, 0.0, 0.0),
            .distance = 5.0,
            .azimuth = 0.0,        // Start looking from +X axis
            .elevation = 0.0,      // Level with XY plane
            .is_rotating = false,
            .last_mouse_x = 0,
            .last_mouse_y = 0,
            .rotation_sensitivity = 0.005,  // ~0.3 degrees per pixel
            .zoom_sensitivity = 0.5,
            .min_distance = 1.0,
            .max_distance = 50.0,
            .min_elevation = -std.math.pi / 2.0 + 0.1,  // Avoid gimbal lock at poles
            .max_elevation = std.math.pi / 2.0 - 0.1,
        };
    }
    
    /// Initialize from an existing camera position
    pub fn initFromCamera(camera: *const Camera) OrbitController {
        var controller = init();
        
        // Compute spherical coordinates from camera position
        // Assuming target is at origin
        const to_camera = camera.position;
        controller.distance = to_camera.length();
        
        // Compute azimuth (angle in XY plane from +X axis)
        controller.azimuth = std.math.atan2(to_camera.y, to_camera.x);
        
        // Compute elevation (angle from XY plane)
        const xy_distance = @sqrt(to_camera.x * to_camera.x + to_camera.y * to_camera.y);
        controller.elevation = std.math.atan2(to_camera.z, xy_distance);
        
        return controller;
    }
    
    /// Handle SDL events (mouse input)
    pub fn handleEvent(self: *OrbitController, event: *const sdl.SDL_Event) void {
        switch (event.type) {
            sdl.SDL_MOUSEBUTTONDOWN => {
                if (event.button.button == sdl.SDL_BUTTON_LEFT) {
                    self.is_rotating = true;
                    self.last_mouse_x = event.button.x;
                    self.last_mouse_y = event.button.y;
                }
            },
            sdl.SDL_MOUSEBUTTONUP => {
                if (event.button.button == sdl.SDL_BUTTON_LEFT) {
                    self.is_rotating = false;
                }
            },
            sdl.SDL_MOUSEMOTION => {
                if (self.is_rotating) {
                    const delta_x = event.motion.x - self.last_mouse_x;
                    const delta_y = event.motion.y - self.last_mouse_y;
                    
                    // Update azimuth and elevation based on mouse movement
                    // Left/right moves azimuth, up/down moves elevation
                    self.azimuth -= @as(f32, @floatFromInt(delta_x)) * self.rotation_sensitivity;
                    self.elevation += @as(f32, @floatFromInt(delta_y)) * self.rotation_sensitivity;
                    
                    // Clamp elevation to avoid gimbal lock
                    self.elevation = std.math.clamp(self.elevation, self.min_elevation, self.max_elevation);
                    
                    // Update last position
                    self.last_mouse_x = event.motion.x;
                    self.last_mouse_y = event.motion.y;
                }
            },
            sdl.SDL_MOUSEWHEEL => {
                // Zoom in/out with mouse wheel
                const zoom_delta = @as(f32, @floatFromInt(event.wheel.y)) * self.zoom_sensitivity;
                self.distance -= zoom_delta;
                
                // Clamp distance
                self.distance = std.math.clamp(self.distance, self.min_distance, self.max_distance);
            },
            else => {},
        }
    }
    
    /// Update the camera based on current orbit parameters
    pub fn updateCamera(self: *const OrbitController, camera: *Camera) void {
        // Convert spherical coordinates to Cartesian position
        const cos_elev = @cos(self.elevation);
        const sin_elev = @sin(self.elevation);
        const cos_azim = @cos(self.azimuth);
        const sin_azim = @sin(self.azimuth);
        
        // Compute camera position in spherical coordinates
        // X-Y plane is horizontal, Z is up
        const position = Vec3.new(
            self.distance * cos_elev * cos_azim + self.target.x,
            self.distance * cos_elev * sin_azim + self.target.y,
            self.distance * sin_elev + self.target.z,
        );
        
        // Compute look direction (from camera to target)
        const look = self.target.sub(position).normalize();
        
        // Use global +Z as the world up vector for orbit calculations
        const world_up = Vec3.new(0.0, 0.0, 1.0);
        
        // Compute right vector (perpendicular to both look and world_up)
        const right = look.cross(world_up).normalize();
        
        // Recompute up to ensure it's perpendicular to both look and right
        // This keeps the camera oriented properly relative to the global Z-axis
        const up = right.cross(look).normalize();
        
        // Update camera with explicit frame vectors to avoid drift
        camera.position = position;
        camera.look = look;
        camera.right = right;
        camera.up = up;
    }
};

// ============================================================================
// Unit Tests
// ============================================================================

test "OrbitController initialization" {
    const controller = OrbitController.init();
    
    try std.testing.expectEqual(0.0, controller.target.x);
    try std.testing.expectEqual(0.0, controller.target.y);
    try std.testing.expectEqual(0.0, controller.target.z);
    try std.testing.expectEqual(5.0, controller.distance);
    try std.testing.expectEqual(false, controller.is_rotating);
}

test "OrbitController initFromCamera" {
    const aspect: f32 = 1.0;
    const camera = Camera.initLookAt(
        Vec3.new(5.0, 0.0, 0.0),
        Vec3.new(0.0, 0.0, 0.0),
        Vec3.new(0.0, 0.0, 1.0),
        std.math.degreesToRadians(60.0),
        aspect,
        0.1,
        100.0,
    );
    
    const controller = OrbitController.initFromCamera(&camera);
    
    // Should extract distance correctly
    try std.testing.expectApproxEqAbs(5.0, controller.distance, 0.0001);
    
    // Should compute azimuth (from +X axis, camera is at +X so azimuth = 0)
    try std.testing.expectApproxEqAbs(0.0, controller.azimuth, 0.0001);
    
    // Should compute elevation (camera is in XY plane, so elevation = 0)
    try std.testing.expectApproxEqAbs(0.0, controller.elevation, 0.0001);
}

test "OrbitController updateCamera position" {
    const aspect: f32 = 1.0;
    var camera = Camera.initDefault(aspect);
    
    var controller = OrbitController.init();
    controller.distance = 10.0;
    controller.azimuth = 0.0;
    controller.elevation = 0.0;
    
    controller.updateCamera(&camera);
    
    // Camera should be at (10, 0, 0) looking at origin
    try std.testing.expectApproxEqAbs(10.0, camera.position.x, 0.0001);
    try std.testing.expectApproxEqAbs(0.0, camera.position.y, 0.0001);
    try std.testing.expectApproxEqAbs(0.0, camera.position.z, 0.0001);
}

test "OrbitController azimuth rotation" {
    const aspect: f32 = 1.0;
    var camera = Camera.initDefault(aspect);
    
    var controller = OrbitController.init();
    controller.distance = 10.0;
    controller.azimuth = std.math.pi / 2.0;  // 90 degrees around Z-axis
    controller.elevation = 0.0;
    
    controller.updateCamera(&camera);
    
    // Camera should be at (0, 10, 0) - rotated 90 degrees to +Y axis
    try std.testing.expectApproxEqAbs(0.0, camera.position.x, 0.0001);
    try std.testing.expectApproxEqAbs(10.0, camera.position.y, 0.0001);
    try std.testing.expectApproxEqAbs(0.0, camera.position.z, 0.0001);
}

test "OrbitController elevation rotation" {
    const aspect: f32 = 1.0;
    var camera = Camera.initDefault(aspect);
    
    var controller = OrbitController.init();
    controller.distance = 10.0;
    controller.azimuth = 0.0;
    controller.elevation = std.math.pi / 4.0;  // 45 degrees up from XY plane
    
    controller.updateCamera(&camera);
    
    // Camera should be elevated
    // At 45 degrees: z = distance * sin(45°) ≈ 7.07
    //                xy_plane_distance = distance * cos(45°) ≈ 7.07
    const expected_z = 10.0 * @sin(std.math.pi / 4.0);
    const expected_x = 10.0 * @cos(std.math.pi / 4.0);
    
    try std.testing.expectApproxEqAbs(expected_x, camera.position.x, 0.0001);
    try std.testing.expectApproxEqAbs(0.0, camera.position.y, 0.0001);
    try std.testing.expectApproxEqAbs(expected_z, camera.position.z, 0.0001);
}

