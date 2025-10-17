const std = @import("std");
const gl = @import("gl.zig");
const shader = @import("shader.zig");
const zlm = @import("zlm").as(f32);
const Camera = @import("camera.zig").Camera;
const test_utils = @import("test_utilities.zig");

/// AxesRenderer draws RGB colored coordinate axes for reference
/// X-axis = Red, Y-axis = Green, Z-axis = Blue
pub const AxesRenderer = struct {
    program: gl.GLuint,
    vao: gl.GLuint,
    vbo: gl.GLuint,
    model_location: gl.GLint,
    view_location: gl.GLint,
    projection_location: gl.GLint,
    
    /// Initialize the axes renderer
    pub fn init(allocator: std.mem.Allocator) !AxesRenderer {
        std.debug.print("Initializing axes renderer...\n", .{});
        
        // Use the same shader program as the triangle (it handles position + color)
        const program = try shader.loadProgram(
            allocator,
            "resources/shaders/triangle.v.glsl",
            "resources/shaders/triangle.f.glsl",
        );
        
        // Get uniform locations
        const model_location = gl.glGetUniformLocation(program, "model");
        const view_location = gl.glGetUniformLocation(program, "view");
        const projection_location = gl.glGetUniformLocation(program, "projection");
        
        if (model_location == -1 or view_location == -1 or projection_location == -1) {
            std.debug.print("ERROR: Failed to locate MVP uniforms in shader\n", .{});
            return error.ShaderUniformNotFound;
        }
        
        // Define axes geometry as lines
        // 3 lines (6 vertices total): X-axis (red), Y-axis (green), Z-axis (blue)
        // Each vertex: [x, y, z, r, g, b]
        const axes_length: f32 = 2.0;
        const vertices = [_]f32{
            // X-axis (red line from origin to +X)
            0.0, 0.0, 0.0,  1.0, 0.0, 0.0,  // Origin
            axes_length, 0.0, 0.0,  1.0, 0.0, 0.0,  // +X
            
            // Y-axis (green line from origin to +Y)
            0.0, 0.0, 0.0,  0.0, 1.0, 0.0,  // Origin
            0.0, axes_length, 0.0,  0.0, 1.0, 0.0,  // +Y
            
            // Z-axis (blue line from origin to +Z)
            0.0, 0.0, 0.0,  0.0, 0.0, 1.0,  // Origin
            0.0, 0.0, axes_length,  0.0, 0.0, 1.0,  // +Z
        };
        
        // Create and bind VAO
        var vao: gl.GLuint = 0;
        gl.glGenVertexArrays(1, &vao);
        gl.glBindVertexArray(vao);
        
        // Create and bind VBO
        var vbo: gl.GLuint = 0;
        gl.glGenBuffers(1, &vbo);
        gl.glBindBuffer(gl.GL_ARRAY_BUFFER, vbo);
        gl.glBufferData(
            gl.GL_ARRAY_BUFFER,
            @intCast(vertices.len * @sizeOf(f32)),
            &vertices,
            gl.GL_STATIC_DRAW,
        );
        
        // Configure vertex attributes (same layout as triangle shader)
        // Position attribute (location = 0)
        gl.glVertexAttribPointer(
            0,
            3,
            gl.GL_FLOAT,
            gl.GL_FALSE,
            6 * @sizeOf(f32),
            null,
        );
        gl.glEnableVertexAttribArray(0);
        
        // Color attribute (location = 1)
        gl.glVertexAttribPointer(
            1,
            3,
            gl.GL_FLOAT,
            gl.GL_FALSE,
            6 * @sizeOf(f32),
            @ptrFromInt(3 * @sizeOf(f32)),
        );
        gl.glEnableVertexAttribArray(1);
        
        // Unbind VAO
        gl.glBindVertexArray(0);
        
        std.debug.print("Axes renderer initialized successfully\n", .{});
        
        return AxesRenderer{
            .program = program,
            .vao = vao,
            .vbo = vbo,
            .model_location = model_location,
            .view_location = view_location,
            .projection_location = projection_location,
        };
    }
    
    /// Render the coordinate axes with identity model matrix (world frame)
    pub fn render(self: *const AxesRenderer, camera: *const Camera) void {
        // Use shader program
        gl.glUseProgram(self.program);
        
        // Identity model matrix - axes stay in world frame
        const model = zlm.Mat4.identity;
        
        // Get view and projection from camera
        const view = camera.getViewMatrix();
        const projection = camera.getProjectionMatrix();
        
        // Upload matrices
        gl.glUniformMatrix4fv(self.model_location, 1, gl.GL_FALSE, @ptrCast(&model.fields));
        gl.glUniformMatrix4fv(self.view_location, 1, gl.GL_FALSE, @ptrCast(&view.fields));
        gl.glUniformMatrix4fv(self.projection_location, 1, gl.GL_FALSE, @ptrCast(&projection.fields));
        
        // Draw lines
        gl.glBindVertexArray(self.vao);
        gl.glDrawArrays(gl.GL_LINES, 0, 6);  // 6 vertices = 3 lines
        gl.glBindVertexArray(0);
    }
    
    /// Clean up OpenGL resources
    pub fn deinit(self: *const AxesRenderer) void {
        std.debug.print("Cleaning up axes renderer resources...\n", .{});
        gl.glDeleteBuffers(1, &self.vbo);
        gl.glDeleteVertexArrays(1, &self.vao);
        gl.glDeleteProgram(self.program);
    }
};

// ============================================================================
// TESTS
// ============================================================================

test "axes renderer vertex data structure" {
    // Test the mathematical correctness of the axes vertex data
    const axes_length: f32 = 2.0;
    
    // Expected vertex data structure: [x, y, z, r, g, b]
    const expected_vertices = [_]f32{
        // X-axis (red line from origin to +X)
        0.0, 0.0, 0.0,  1.0, 0.0, 0.0,  // Origin
        axes_length, 0.0, 0.0,  1.0, 0.0, 0.0,  // +X
        
        // Y-axis (green line from origin to +Y)
        0.0, 0.0, 0.0,  0.0, 1.0, 0.0,  // Origin
        0.0, axes_length, 0.0,  0.0, 1.0, 0.0,  // +Y
        
        // Z-axis (blue line from origin to +Z)
        0.0, 0.0, 0.0,  0.0, 0.0, 1.0,  // Origin
        0.0, 0.0, axes_length,  0.0, 0.0, 1.0,  // +Z
    };
    
    // Test axes vertex data using stride/slice mechanism
    try test_utils.expectAxesVertexData(&expected_vertices, axes_length);
    
    // Test line geometry properties
    const stride = 6; // [x, y, z, r, g, b]
    const line_count = 3; // X, Y, Z axes
    try test_utils.expectLineGeometry(&expected_vertices, stride, line_count);
}

test "axes renderer mathematical properties" {
    // Test mathematical properties of the axes system
    const axes_length: f32 = 2.0;
    
    const x_axis = zlm.Vec3.new(axes_length, 0.0, 0.0);
    const y_axis = zlm.Vec3.new(0.0, axes_length, 0.0);
    const z_axis = zlm.Vec3.new(0.0, 0.0, axes_length);
    
    // Test orthogonality
    try test_utils.expectVec3Orthogonal(x_axis, y_axis);
    try test_utils.expectVec3Orthogonal(y_axis, z_axis);
    try test_utils.expectVec3Orthogonal(z_axis, x_axis);
    
    // Test axis lengths
    try test_utils.expectLength(x_axis, axes_length);
    try test_utils.expectLength(y_axis, axes_length);
    try test_utils.expectLength(z_axis, axes_length);
    
    // Test normalized axes are unit vectors
    try test_utils.expectNormalized(x_axis.normalize());
    try test_utils.expectNormalized(y_axis.normalize());
    try test_utils.expectNormalized(z_axis.normalize());
}

test "axes renderer color mathematics" {
    // Test color space properties
    const red = zlm.Vec3.new(1.0, 0.0, 0.0);
    const green = zlm.Vec3.new(0.0, 1.0, 0.0);
    const blue = zlm.Vec3.new(0.0, 0.0, 1.0);
    
    // Test that colors are normalized
    try test_utils.expectNormalized(red);
    try test_utils.expectNormalized(green);
    try test_utils.expectNormalized(blue);
    
    // Test that colors are orthogonal in RGB space
    try test_utils.expectColorOrthogonal(red, green);
    try test_utils.expectColorOrthogonal(green, blue);
    try test_utils.expectColorOrthogonal(blue, red);
    
    // Test color mixing (should produce white when all combined)
    const mixed = red.add(green).add(blue);
    const white = zlm.Vec3.new(1.0, 1.0, 1.0);
    try test_utils.expectColorEqual(mixed, white);
}

test "axes renderer matrix operations" {
    // Test matrix operations used in rendering
    const identity = zlm.Mat4.identity;
    
    // Test identity matrix properties
    try test_utils.expectMat4Identity(identity);
    
    // Test that identity matrix doesn't change vectors
    const test_vec = zlm.Vec3.new(1.0, 2.0, 3.0);
    const transformed = identity.mulVec3(test_vec);
    try test_utils.expectVec3Equal(test_vec, transformed);
    
    // Test matrix multiplication with identity
    const result = identity.mul(identity);
    try test_utils.expectMat4Equal(identity, result);
}

test "axes renderer vertex attribute layout" {
    // Test vertex attribute layout mathematics
    const vertex_size = 6 * @sizeOf(f32); // 6 floats per vertex
    const position_offset = 0;
    const color_offset = 3 * @sizeOf(f32);
    const stride = 6 * @sizeOf(f32);
    
    // Test vertex layout using helper
    try test_utils.expectVertexLayout(vertex_size, position_offset, color_offset, stride);
}

test "axes renderer coordinate system" {
    // Test that the axes form a right-handed coordinate system
    const x_axis = zlm.Vec3.new(1.0, 0.0, 0.0);
    const y_axis = zlm.Vec3.new(0.0, 1.0, 0.0);
    const z_axis = zlm.Vec3.new(0.0, 0.0, 1.0);
    
    // Test right-handed coordinate system
    try test_utils.expectRightHandedSystem(x_axis, y_axis, z_axis);
}

test "axes renderer line geometry" {
    // Test line geometry properties
    const axes_length: f32 = 2.0;
    const origin = zlm.Vec3.new(0.0, 0.0, 0.0);
    
    // X-axis line: origin to (length, 0, 0)
    const x_end = zlm.Vec3.new(axes_length, 0.0, 0.0);
    const x_line = x_end.sub(origin);
    try test_utils.expectLength(x_line, axes_length);
    
    // Y-axis line: origin to (0, length, 0)
    const y_end = zlm.Vec3.new(0.0, axes_length, 0.0);
    const y_line = y_end.sub(origin);
    try test_utils.expectLength(y_line, axes_length);
    
    // Z-axis line: origin to (0, 0, length)
    const z_end = zlm.Vec3.new(0.0, 0.0, axes_length);
    const z_line = z_end.sub(origin);
    try test_utils.expectLength(z_line, axes_length);
    
    // Test that all lines are orthogonal
    const lines = [_]zlm.Vec3{ x_line, y_line, z_line };
    try test_utils.expectAllOrthogonal(&lines);
}

test "axes renderer bounds and scaling" {
    // Test mathematical bounds of the axes system
    const axes_length: f32 = 2.0;
    const center = zlm.Vec3.new(0.0, 0.0, 0.0);
    const min_bounds = zlm.Vec3.new(-axes_length, -axes_length, -axes_length);
    const max_bounds = zlm.Vec3.new(axes_length, axes_length, axes_length);
    const expected_size = zlm.Vec3.new(2.0 * axes_length, 2.0 * axes_length, 2.0 * axes_length);
    
    // Test bounding box properties
    try test_utils.expectBoundingBox(min_bounds, max_bounds, center, expected_size);
}


