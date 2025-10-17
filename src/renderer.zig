const gl = @import("gl.zig");

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
