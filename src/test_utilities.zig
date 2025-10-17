const std = @import("std");
const zlm = @import("zlm").as(f32);

// Export zlm types for convenience
pub const Vec3 = zlm.Vec3;
pub const Mat4 = zlm.Mat4;

/// Default tolerance for floating-point comparisons
pub const DEFAULT_TOLERANCE: f32 = 1e-6;

/// Compare two Vec3 vectors with tolerance
pub fn expectVec3Equal(actual: Vec3, expected: Vec3, tolerance: f32) !void {
    try std.testing.expectApproxEqAbs(actual.x, expected.x, tolerance);
    try std.testing.expectApproxEqAbs(actual.y, expected.y, tolerance);
    try std.testing.expectApproxEqAbs(actual.z, expected.z, tolerance);
}

/// Compare two Vec3 vectors with default tolerance
pub fn expectVec3EqualDefault(actual: Vec3, expected: Vec3) !void {
    try expectVec3Equal(actual, expected, DEFAULT_TOLERANCE);
}
    
/// Check if two Vec3 vectors are close within tolerance
pub fn expectVec3Close(actual: Vec3, expected: Vec3, tolerance: f32) !void {
    const diff = actual.sub(expected);
    const distance = diff.length();
    try std.testing.expect(distance <= tolerance);
}

/// Check if two Vec3 vectors are close with default tolerance
pub fn expectVec3CloseDefault(actual: Vec3, expected: Vec3) !void {
    try expectVec3Close(actual, expected, DEFAULT_TOLERANCE);
}
    
/// Test if two vectors are orthogonal (dot product ≈ 0)
pub fn expectVec3Orthogonal(v1: Vec3, v2: Vec3, tolerance: f32) !void {
        const dot_product = v1.dot(v2);
        try std.testing.expectApproxEqAbs(@as(f32, 0.0), dot_product, tolerance);
    }
    
/// Test if two vectors are orthogonal with default tolerance
pub fn expectVec3OrthogonalDefault(v1: Vec3, v2: Vec3) !void {
        try expectVec3Orthogonal(v1, v2, DEFAULT_TOLERANCE);
    }
    
/// Test vector length
pub fn expectLength(vector: Vec3, expected_length: f32, tolerance: f32) !void {
        const actual_length = vector.length();
        try std.testing.expectApproxEqAbs(expected_length, actual_length, tolerance);
    }
    
/// Test vector length with default tolerance
pub fn expectLengthDefault(vector: Vec3, expected_length: f32) !void {
        try expectLength(vector, expected_length, DEFAULT_TOLERANCE);
    }
    
/// Test dot product
pub fn expectDotProduct(v1: Vec3, v2: Vec3, expected: f32, tolerance: f32) !void {
        const actual = v1.dot(v2);
        try std.testing.expectApproxEqAbs(expected, actual, tolerance);
    }
    
/// Test dot product with default tolerance
pub fn expectDotProductDefault(v1: Vec3, v2: Vec3, expected: f32) !void {
        try expectDotProduct(v1, v2, expected, DEFAULT_TOLERANCE);
    }
    
/// Test cross product
pub fn expectCrossProduct(v1: Vec3, v2: Vec3, expected: Vec3, tolerance: f32) !void {
        const actual = v1.cross(v2);
        try expectVec3Equal(actual, expected, tolerance);
    }
    
/// Test cross product with default tolerance
pub fn expectCrossProductDefault(v1: Vec3, v2: Vec3, expected: Vec3) !void {
        try expectCrossProduct(v1, v2, expected, DEFAULT_TOLERANCE);
    }
    
/// Compare two Mat4 matrices with tolerance
pub fn expectMat4Equal(actual: Mat4, expected: Mat4, tolerance: f32) !void {
        for (0..16) |i| {
            try std.testing.expectApproxEqAbs(actual.fields[i], expected.fields[i], tolerance);
        }
    }
    
/// Compare two Mat4 matrices with default tolerance
pub fn expectMat4EqualDefault(actual: Mat4, expected: Mat4) !void {
        try expectMat4Equal(actual, expected, DEFAULT_TOLERANCE);
    }
    
/// Check if two Mat4 matrices are close within tolerance
pub fn expectMat4Close(actual: Mat4, expected: Mat4, tolerance: f32) !void {
        var max_diff: f32 = 0.0;
        for (0..16) |i| {
            const diff = @abs(actual.fields[i] - expected.fields[i]);
            max_diff = @max(max_diff, diff);
        }
        try std.testing.expect(max_diff <= tolerance);
    }
    
/// Check if two Mat4 matrices are close with default tolerance
pub fn expectMat4CloseDefault(actual: Mat4, expected: Mat4) !void {
        try expectMat4Close(actual, expected, DEFAULT_TOLERANCE);
    }
    
/// Test if matrix is identity
pub fn expectMat4Identity(matrix: Mat4, tolerance: f32) !void {
        const identity = Mat4.identity;
        try expectMat4Equal(matrix, identity, tolerance);
    }
    
/// Test if matrix is identity with default tolerance
pub fn expectMat4IdentityDefault(matrix: Mat4) !void {
        try expectMat4Identity(matrix, DEFAULT_TOLERANCE);
    }
    
/// Test matrix-vector multiplication
pub fn expectMat4MulVec3(matrix: Mat4, vector: Vec3, expected: Vec3, tolerance: f32) !void {
        const actual = matrix.mulVec3(vector);
        try expectVec3Equal(actual, expected, tolerance);
    }
    
/// Test matrix-vector multiplication with default tolerance
pub fn expectMat4MulVec3Default(matrix: Mat4, vector: Vec3, expected: Vec3) !void {
        try expectMat4MulVec3(matrix, vector, expected, DEFAULT_TOLERANCE);
    }
    
/// Test matrix multiplication
pub fn expectMat4Mul(m1: Mat4, m2: Mat4, expected: Mat4, tolerance: f32) !void {
        const actual = m1.mul(m2);
        try expectMat4Equal(actual, expected, tolerance);
    }
    
/// Test matrix multiplication with default tolerance
pub fn expectMat4MulDefault(m1: Mat4, m2: Mat4, expected: Mat4) !void {
        try expectMat4Mul(m1, m2, expected, DEFAULT_TOLERANCE);
    }
    
/// Test color equality (RGB vectors)
pub fn expectColorEqual(actual: Vec3, expected: Vec3, tolerance: f32) !void {
        try expectVec3Equal(actual, expected, tolerance);
    }
    
/// Test color equality with default tolerance
pub fn expectColorEqualDefault(actual: Vec3, expected: Vec3) !void {
        try expectColorEqual(actual, expected, DEFAULT_TOLERANCE);
    }
    
/// Test color orthogonality
pub fn expectColorOrthogonal(c1: Vec3, c2: Vec3, tolerance: f32) !void {
        try expectVec3Orthogonal(c1, c2, tolerance);
    }
    
/// Test color orthogonality with default tolerance
pub fn expectColorOrthogonalDefault(c1: Vec3, c2: Vec3) !void {
        try expectColorOrthogonal(c1, c2, DEFAULT_TOLERANCE);
    }
    
/// Test that a vector is normalized (length ≈ 1)
pub fn expectNormalized(vector: Vec3, tolerance: f32) !void {
        try expectLength(vector, 1.0, tolerance);
    }
    
/// Test that a vector is normalized with default tolerance
pub fn expectNormalizedDefault(vector: Vec3) !void {
        try expectNormalized(vector, DEFAULT_TOLERANCE);
    }
    
/// Test right-handed coordinate system (X × Y = Z, Y × Z = X, Z × X = Y)
pub fn expectRightHandedSystem(x_axis: Vec3, y_axis: Vec3, z_axis: Vec3, tolerance: f32) !void {
        try expectCrossProduct(x_axis, y_axis, z_axis, tolerance);
        try expectCrossProduct(y_axis, z_axis, x_axis, tolerance);
        try expectCrossProduct(z_axis, x_axis, y_axis, tolerance);
    }
    
/// Test right-handed coordinate system with default tolerance
pub fn expectRightHandedSystemDefault(x_axis: Vec3, y_axis: Vec3, z_axis: Vec3) !void {
        try expectRightHandedSystem(x_axis, y_axis, z_axis, DEFAULT_TOLERANCE);
    }
    
/// Test that all vectors in a set are orthogonal
pub fn expectAllOrthogonal(vectors: []const Vec3, tolerance: f32) !void {
        for (vectors, 0..) |v1, i| {
            for (vectors[i+1..]) |v2| {
                try expectVec3Orthogonal(v1, v2, tolerance);
            }
        }
    }
    
/// Test that all vectors in a set are orthogonal with default tolerance
pub fn expectAllOrthogonalDefault(vectors: []const Vec3) !void {
        try expectAllOrthogonal(vectors, DEFAULT_TOLERANCE);
    }
    
/// Test bounding box properties
pub fn expectBoundingBox(min_bounds: Vec3, max_bounds: Vec3, center: Vec3, size: Vec3, tolerance: f32) !void {
        const calculated_center = min_bounds.add(max_bounds).scale(0.5);
        const calculated_size = max_bounds.sub(min_bounds);
        
        try expectVec3Equal(calculated_center, center, tolerance);
        try expectVec3Equal(calculated_size, size, tolerance);
    }
    
/// Test bounding box properties with default tolerance
pub fn expectBoundingBoxDefault(min_bounds: Vec3, max_bounds: Vec3, center: Vec3, size: Vec3) !void {
        try expectBoundingBox(min_bounds, max_bounds, center, size, DEFAULT_TOLERANCE);
    }
    
/// Test vertex data structure with stride/slice mechanism
pub fn expectVertexData(vertices: []const f32, stride: usize, expected_vertices: []const Vec3, expected_colors: []const Vec3, tolerance: f32) !void {
        const vertex_count = vertices.len / stride;
        try std.testing.expectEqual(expected_vertices.len, vertex_count);
        try std.testing.expectEqual(expected_colors.len, vertex_count);
        
        for (0..vertex_count) |i| {
            const vertex_start = i * stride;
            const position = Vec3.new(
                vertices[vertex_start + 0],
                vertices[vertex_start + 1], 
                vertices[vertex_start + 2]
            );
            const color = Vec3.new(
                vertices[vertex_start + 3],
                vertices[vertex_start + 4],
                vertices[vertex_start + 5]
            );
            
            try expectVec3Equal(position, expected_vertices[i], tolerance);
            try expectColorEqual(color, expected_colors[i], tolerance);
        }
    }
    
/// Test vertex data structure with default tolerance
pub fn expectVertexDataDefault(vertices: []const f32, stride: usize, expected_vertices: []const Vec3, expected_colors: []const Vec3) !void {
        try expectVertexData(vertices, stride, expected_vertices, expected_colors, DEFAULT_TOLERANCE);
    }
    
/// Test vertex data for axes (3 lines: X, Y, Z axes)
pub fn expectAxesVertexData(vertices: []const f32, axes_length: f32, tolerance: f32) !void {
        const stride = 6; // [x, y, z, r, g, b]
        const expected_vertices = [_]Vec3{
            // X-axis line
            Vec3.new(0.0, 0.0, 0.0),           // Origin
            Vec3.new(axes_length, 0.0, 0.0),  // +X
            
            // Y-axis line  
            Vec3.new(0.0, 0.0, 0.0),           // Origin
            Vec3.new(0.0, axes_length, 0.0),  // +Y
            
            // Z-axis line
            Vec3.new(0.0, 0.0, 0.0),           // Origin
            Vec3.new(0.0, 0.0, axes_length),  // +Z
        };
        const expected_colors = [_]Vec3{
            // X-axis colors (red)
            Vec3.new(1.0, 0.0, 0.0),  // Red
            Vec3.new(1.0, 0.0, 0.0),  // Red
            
            // Y-axis colors (green)
            Vec3.new(0.0, 1.0, 0.0),  // Green
            Vec3.new(0.0, 1.0, 0.0),  // Green
            
            // Z-axis colors (blue)
            Vec3.new(0.0, 0.0, 1.0),  // Blue
            Vec3.new(0.0, 0.0, 1.0),  // Blue
        };
        
        try expectVertexData(vertices, stride, &expected_vertices, &expected_colors, tolerance);
    }
    
/// Test vertex data for axes with default tolerance
pub fn expectAxesVertexDataDefault(vertices: []const f32, axes_length: f32) !void {
        try expectAxesVertexData(vertices, axes_length, DEFAULT_TOLERANCE);
    }
    
/// Test vertex attribute layout
pub fn expectVertexLayout(vertex_size: usize, position_offset: usize, color_offset: usize, stride: usize) !void {
        try std.testing.expectEqual(@as(usize, 0), position_offset);
        try std.testing.expectEqual(@as(usize, 12), color_offset); // 3 * 4 bytes
        try std.testing.expectEqual(@as(usize, 24), stride); // 6 * 4 bytes
        try std.testing.expectEqual(vertex_size, stride);
    }
    
/// Test that vertex data represents lines (pairs of vertices)
pub fn expectLineGeometry(vertices: []const f32, stride: usize, line_count: usize, tolerance: f32) !void {
        const vertex_count = vertices.len / stride;
        try std.testing.expectEqual(line_count * 2, vertex_count);
        
        // Test that each line starts at origin
        for (0..line_count) |line_idx| {
            const vertex_start = line_idx * 2 * stride;
            const origin = Vec3.new(
                vertices[vertex_start + 0],
                vertices[vertex_start + 1],
                vertices[vertex_start + 2]
            );
            const expected_origin = Vec3.new(0.0, 0.0, 0.0);
            try expectVec3Equal(origin, expected_origin, tolerance);
        }
}

/// Test line geometry with default tolerance
pub fn expectLineGeometryDefault(vertices: []const f32, stride: usize, line_count: usize) !void {
    try expectLineGeometry(vertices, stride, line_count, DEFAULT_TOLERANCE);
}


