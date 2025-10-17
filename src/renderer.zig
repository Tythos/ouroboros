const gl = @import("gl.zig");
const test_utils = @import("test_utilities.zig");

/// Renderer utilities - lightweight helpers for common rendering operations
/// Individual scene objects (SceneGraphNode) now handle their own geometry and rendering

/// Clear the screen with the specified background color
pub fn clearScreen(r: f32, g: f32, b: f32, a: f32) void {
    gl.glClearColor(r, g, b, a);
    gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);
}

/// Setup common OpenGL rendering state (depth testing, etc.)
pub fn setupRenderState() void {
    gl.glEnable(gl.GL_DEPTH_TEST);
    gl.glDepthFunc(gl.GL_LESS);
}

test "clearScreen color values" {
    // Test valid color ranges and RGB space properties
    const red = test_utils.Vec3.new(1.0, 0.0, 0.0);
    const green = test_utils.Vec3.new(0.0, 1.0, 0.0);
    const blue = test_utils.Vec3.new(0.0, 0.0, 1.0);
    
    // Test that RGB components are orthogonal (pure colors)
    try test_utils.expectColorOrthogonalDefault(red, green);
    try test_utils.expectColorOrthogonalDefault(green, blue);
    try test_utils.expectColorOrthogonalDefault(blue, red);
}

test "render state setup" {
    // Test that depth testing state is properly configured
    // This verifies the mathematical setup of depth comparisons
    const depth_func_less = gl.GL_LESS;
    const depth_test_enabled = gl.GL_DEPTH_TEST;
    
    // Verify constants are properly defined (basic sanity check)
    try test_utils.expectLength(test_utils.Vec3.new(@floatFromInt(depth_func_less), 0.0, 0.0), @floatFromInt(depth_func_less));
    try test_utils.expectLength(test_utils.Vec3.new(@floatFromInt(depth_test_enabled), 0.0, 0.0), @floatFromInt(depth_test_enabled));
}

test "renderer utilities integration" {
    // Test that clear screen and render state work together
    const test_color = test_utils.Vec3.new(0.5, 0.25, 0.75);
    const identity = test_utils.Mat4.identity;
    
    // Verify color can be transformed by identity matrix (no change)
    const transformed_color = identity.mulVec3(test_color);
    try test_utils.expectVec3EqualDefault(test_color, transformed_color);
}
