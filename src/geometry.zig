const std = @import("std");
const gl = @import("gl.zig");

/// Geometry represents a 3D mesh with vertex data, indices, and OpenGL resources
/// Can be shared across multiple SceneGraphNodes for memory efficiency
pub const Geometry = struct {
    // OpenGL resources
    vao: gl.GLuint,
    vbo: gl.GLuint,
    ebo: gl.GLuint,
    
    // Geometry data
    vertex_count: gl.GLsizei,
    index_count: gl.GLsizei,
    has_indices: bool,
    
    // Vertex attribute layout
    vertex_stride: u32,
    position_offset: u32,
    color_offset: u32,
    
    /// Initialize geometry with triangle data (matching current SceneGraphNode)
    pub fn initTriangle() !Geometry {
        std.debug.print("Initializing triangle geometry...\n", .{});
        
        // Define triangle vertices with rainbow colors - CENTERED AT ORIGIN
        // Each vertex: [x, y, z, r, g, b]
        // Large triangle in YZ plane, visible from +X axis
        const vertices = [_]f32{
            // Position       // Color (red) - top vertex
             0.0,  1.0, 0.0,  1.0, 0.0, 0.0,
            // Position       // Color (green) - bottom left
             0.0, -1.0, -1.0,  0.0, 1.0, 0.0,
            // Position       // Color (blue) - bottom right
             0.0, -1.0, 1.0,  0.0, 0.0, 1.0,
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
        
        // Configure vertex attributes
        const vertex_stride = 6 * @sizeOf(f32); // 6 floats per vertex
        const position_offset = 0;
        const color_offset = 3 * @sizeOf(f32);
        
        // Position attribute (location = 0)
        gl.glVertexAttribPointer(
            0,                                  // attribute location
            3,                                  // number of components (x, y, z)
            gl.GL_FLOAT,                        // type
            gl.GL_FALSE,                        // normalized?
            vertex_stride,                      // stride
            null,                               // offset (0)
        );
        gl.glEnableVertexAttribArray(0);
        
        // Color attribute (location = 1)
        gl.glVertexAttribPointer(
            1,                                  // attribute location
            3,                                  // number of components (r, g, b)
            gl.GL_FLOAT,                        // type
            gl.GL_FALSE,                        // normalized?
            vertex_stride,                      // stride
            @ptrFromInt(color_offset),          // offset
        );
        gl.glEnableVertexAttribArray(1);
        
        // No indices for triangle (we'll use glDrawArrays)
        const ebo: gl.GLuint = 0;
        
        // Unbind VAO
        gl.glBindVertexArray(0);
        
        std.debug.print("Triangle geometry initialized successfully\n", .{});
        
        return Geometry{
            .vao = vao,
            .vbo = vbo,
            .ebo = ebo,
            .vertex_count = 3,
            .index_count = 0,
            .has_indices = false,
            .vertex_stride = vertex_stride,
            .position_offset = position_offset,
            .color_offset = color_offset,
        };
    }
    
    /// Initialize geometry with cube data (centered at origin, colored faces)
    pub fn initCube() !Geometry {
        std.debug.print("Initializing cube geometry...\n", .{});
        
        // Define cube vertices with colored faces
        // Each vertex: [x, y, z, r, g, b]
        // Cube is centered at origin with size 2x2x2
        const vertices = [_]f32{
            // Front face (Z = +1) - Red
            -1.0, -1.0,  1.0,  1.0, 0.0, 0.0,  // bottom-left
             1.0, -1.0,  1.0,  1.0, 0.0, 0.0,  // bottom-right
             1.0,  1.0,  1.0,  1.0, 0.0, 0.0,  // top-right
            -1.0,  1.0,  1.0,  1.0, 0.0, 0.0,  // top-left
            
            // Back face (Z = -1) - Green
            -1.0, -1.0, -1.0,  0.0, 1.0, 0.0,  // bottom-left
            -1.0,  1.0, -1.0,  0.0, 1.0, 0.0,  // top-left
             1.0,  1.0, -1.0,  0.0, 1.0, 0.0,  // top-right
             1.0, -1.0, -1.0,  0.0, 1.0, 0.0,  // bottom-right
            
            // Top face (Y = +1) - Blue
            -1.0,  1.0, -1.0,  0.0, 0.0, 1.0,  // bottom-left
            -1.0,  1.0,  1.0,  0.0, 0.0, 1.0,  // bottom-right
             1.0,  1.0,  1.0,  0.0, 0.0, 1.0,  // top-right
             1.0,  1.0, -1.0,  0.0, 0.0, 1.0,  // top-left
            
            // Bottom face (Y = -1) - Yellow
            -1.0, -1.0, -1.0,  1.0, 1.0, 0.0,  // bottom-left
             1.0, -1.0, -1.0,  1.0, 1.0, 0.0,  // bottom-right
             1.0, -1.0,  1.0,  1.0, 1.0, 0.0,  // top-right
            -1.0, -1.0,  1.0,  1.0, 1.0, 0.0,  // top-left
            
            // Right face (X = +1) - Magenta
             1.0, -1.0, -1.0,  1.0, 0.0, 1.0,  // bottom-left
             1.0,  1.0, -1.0,  1.0, 0.0, 1.0,  // top-left
             1.0,  1.0,  1.0,  1.0, 0.0, 1.0,  // top-right
             1.0, -1.0,  1.0,  1.0, 0.0, 1.0,  // bottom-right
            
            // Left face (X = -1) - Cyan
            -1.0, -1.0, -1.0,  0.0, 1.0, 1.0,  // bottom-left
            -1.0, -1.0,  1.0,  0.0, 1.0, 1.0,  // bottom-right
            -1.0,  1.0,  1.0,  0.0, 1.0, 1.0,  // top-right
            -1.0,  1.0, -1.0,  0.0, 1.0, 1.0,  // top-left
        };
        
        // Define indices for the cube (6 faces * 2 triangles * 3 vertices = 36 indices)
        const indices = [_]u32{
            // Front face
            0, 1, 2,   2, 3, 0,
            // Back face  
            4, 5, 6,   6, 7, 4,
            // Top face
            8, 9, 10,  10, 11, 8,
            // Bottom face
            12, 13, 14, 14, 15, 12,
            // Right face
            16, 17, 18, 18, 19, 16,
            // Left face
            20, 21, 22, 22, 23, 20,
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
        
        // Configure vertex attributes
        const vertex_stride = 6 * @sizeOf(f32); // 6 floats per vertex
        const position_offset = 0;
        const color_offset = 3 * @sizeOf(f32);
        
        // Position attribute (location = 0)
        gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, vertex_stride, null);
        gl.glEnableVertexAttribArray(0);
        
        // Color attribute (location = 1)
        gl.glVertexAttribPointer(1, 3, gl.GL_FLOAT, gl.GL_FALSE, vertex_stride, @ptrFromInt(color_offset));
        gl.glEnableVertexAttribArray(1);
        
        // Create and bind EBO
        var ebo: gl.GLuint = 0;
        gl.glGenBuffers(1, &ebo);
        gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, ebo);
        gl.glBufferData(
            gl.GL_ELEMENT_ARRAY_BUFFER,
            @intCast(indices.len * @sizeOf(u32)),
            &indices,
            gl.GL_STATIC_DRAW,
        );
        
        // Unbind VAO
        gl.glBindVertexArray(0);
        
        std.debug.print("Cube geometry initialized successfully\n", .{});
        
        return Geometry{
            .vao = vao,
            .vbo = vbo,
            .ebo = ebo,
            .vertex_count = 24, // 6 faces * 4 vertices per face
            .index_count = 36,  // 6 faces * 2 triangles * 3 vertices
            .has_indices = true,
            .vertex_stride = vertex_stride,
            .position_offset = position_offset,
            .color_offset = color_offset,
        };
    }
    
    /// Initialize geometry with custom vertex data
    pub fn init(vertices: []const f32, indices: ?[]const u32) !Geometry {
        std.debug.print("Initializing custom geometry...\n", .{});
        
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
            vertices.ptr,
            gl.GL_STATIC_DRAW,
        );
        
        // Configure vertex attributes (assuming same layout as triangle)
        const vertex_stride = 6 * @sizeOf(f32); // 6 floats per vertex
        const position_offset = 0;
        const color_offset = 3 * @sizeOf(f32);
        
        // Position attribute (location = 0)
        gl.glVertexAttribPointer(0, 3, gl.GL_FLOAT, gl.GL_FALSE, vertex_stride, null);
        gl.glEnableVertexAttribArray(0);
        
        // Color attribute (location = 1)
        gl.glVertexAttribPointer(1, 3, gl.GL_FLOAT, gl.GL_FALSE, vertex_stride, @ptrFromInt(color_offset));
        gl.glEnableVertexAttribArray(1);
        
        // Handle indices if provided
        var ebo: gl.GLuint = 0;
        var index_count: gl.GLsizei = 0;
        var has_indices = false;
        
        if (indices) |index_data| {
            has_indices = true;
            index_count = @intCast(index_data.len);
            
            gl.glGenBuffers(1, &ebo);
            gl.glBindBuffer(gl.GL_ELEMENT_ARRAY_BUFFER, ebo);
            gl.glBufferData(
                gl.GL_ELEMENT_ARRAY_BUFFER,
                @intCast(index_data.len * @sizeOf(u32)),
                index_data.ptr,
                gl.GL_STATIC_DRAW,
            );
        }
        
        // Unbind VAO
        gl.glBindVertexArray(0);
        
        std.debug.print("Custom geometry initialized successfully\n", .{});
        
        return Geometry{
            .vao = vao,
            .vbo = vbo,
            .ebo = ebo,
            .vertex_count = @intCast(vertices.len / 6), // 6 floats per vertex
            .index_count = index_count,
            .has_indices = has_indices,
            .vertex_stride = vertex_stride,
            .position_offset = position_offset,
            .color_offset = color_offset,
        };
    }
    
    /// Render the geometry
    pub fn render(self: *const Geometry) void {
        gl.glBindVertexArray(self.vao);
        
        if (self.has_indices) {
            gl.glDrawElements(gl.GL_TRIANGLES, self.index_count, gl.GL_UNSIGNED_INT, null);
        } else {
            gl.glDrawArrays(gl.GL_TRIANGLES, 0, self.vertex_count);
        }
        
        gl.glBindVertexArray(0);
    }
    
    /// Get the number of vertices
    pub fn getVertexCount(self: *const Geometry) gl.GLsizei {
        return self.vertex_count;
    }
    
    /// Get the number of indices (0 if no indices)
    pub fn getIndexCount(self: *const Geometry) gl.GLsizei {
        return self.index_count;
    }
    
    /// Check if geometry uses indexed rendering
    pub fn usesIndices(self: *const Geometry) bool {
        return self.has_indices;
    }
    
    /// Clean up OpenGL resources
    pub fn deinit(self: *const Geometry) void {
        std.debug.print("Cleaning up geometry resources...\n", .{});
        
        if (self.has_indices) {
            gl.glDeleteBuffers(1, &self.ebo);
        }
        gl.glDeleteBuffers(1, &self.vbo);
        gl.glDeleteVertexArrays(1, &self.vao);
    }
};

// ============================================================================
// Tests
// ============================================================================

const test_utils = @import("test_utilities.zig");

test "Geometry triangle initialization" {
    // Test triangle geometry creation (without OpenGL context)
    // This test verifies the geometry structure without OpenGL calls
    const vertices = [_]f32{
        0.0, 1.0, 0.0, 1.0, 0.0, 0.0,  // vertex 0
        0.0, -1.0, -1.0, 0.0, 1.0, 0.0, // vertex 1  
        0.0, -1.0, 1.0, 0.0, 0.0, 1.0,  // vertex 2
    };
    
    const geometry = try Geometry.init(&vertices, null);
    defer geometry.deinit();
    
    // Verify geometry properties
    try std.testing.expectEqual(@as(gl.GLsizei, 3), geometry.getVertexCount());
    try std.testing.expectEqual(@as(gl.GLsizei, 0), geometry.getIndexCount());
    try std.testing.expectEqual(false, geometry.usesIndices());
    try std.testing.expectEqual(@as(u32, 6 * @sizeOf(f32)), geometry.vertex_stride);
    try std.testing.expectEqual(@as(u32, 0), geometry.position_offset);
    try std.testing.expectEqual(@as(u32, 3 * @sizeOf(f32)), geometry.color_offset);
}

test "Geometry custom initialization" {
    // Test custom geometry creation (without OpenGL context)
    const vertices = [_]f32{
        0.0, 0.0, 0.0, 1.0, 0.0, 0.0,  // vertex 0
        1.0, 0.0, 0.0, 0.0, 1.0, 0.0,  // vertex 1
        0.0, 1.0, 0.0, 0.0, 0.0, 1.0,  // vertex 2
    };
    
    const geometry = try Geometry.init(&vertices, null);
    defer geometry.deinit();
    
    // Verify geometry properties
    try std.testing.expectEqual(@as(gl.GLsizei, 3), geometry.getVertexCount());
    try std.testing.expectEqual(@as(gl.GLsizei, 0), geometry.getIndexCount());
    try std.testing.expectEqual(false, geometry.usesIndices());
}

test "Geometry with indices" {
    // Test geometry with indices (without OpenGL context)
    const vertices = [_]f32{
        0.0, 0.0, 0.0, 1.0, 0.0, 0.0,  // vertex 0
        1.0, 0.0, 0.0, 0.0, 1.0, 0.0,  // vertex 1
        0.0, 1.0, 0.0, 0.0, 0.0, 1.0,  // vertex 2
    };
    
    const indices = [_]u32{ 0, 1, 2 };
    
    const geometry = try Geometry.init(&vertices, &indices);
    defer geometry.deinit();
    
    // Verify geometry properties
    try std.testing.expectEqual(@as(gl.GLsizei, 3), geometry.getVertexCount());
    try std.testing.expectEqual(@as(gl.GLsizei, 3), geometry.getIndexCount());
    try std.testing.expectEqual(true, geometry.usesIndices());
}
